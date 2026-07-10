#!/bin/bash

NODEPORT=$(kubectl get svc ingress-nginx-controller -n togglemaster -o jsonpath='{.spec.ports[?(@.name=="http")].nodePort}')

if [ -z "$NODEPORT" ]; then
  echo "ERRO: Nao foi possivel identificar o NodePort do Ingress."
  exit 1
fi

echo "Porta detectada: $NODEPORT"

echo "Obtendo a MASTER_KEY diretamente do cluster Kubernetes..."
MASTER_KEY=$(kubectl get secret togglemaster-secrets -n togglemaster -o jsonpath="{.data.MASTER_KEY}" | base64 --decode)

if [ -z "$MASTER_KEY" ]; then
  echo "FALHA: Nao foi possivel recuperar a MASTER_KEY da secret togglemaster-secrets."
  exit 1
fi
echo "Chave mestra recuperada com sucesso."
echo "--------------------------------------------------------"

echo "Verificando o status do Ingress Controller..."
if ! kubectl get pods -n togglemaster | grep -q "Running"; then
  echo "FALHA: O Ingress Controller nao esta em execucao."
  exit 1
fi
echo "Ingress Controller operante."
echo "--------------------------------------------------------"

echo "Coletando IPs externos dos Worker Nodes..."
NODE_IPS=$(kubectl get nodes -o jsonpath='{.items[*].status.addresses[?(@.type=="ExternalIP")].address}')

if [ -z "$NODE_IPS" ]; then
  NODE_IPS=$(kubectl get nodes -o jsonpath='{.items[*].status.addresses[?(@.type=="InternalIP")].address}')
fi

if [ -z "$NODE_IPS" ]; then
  echo "FALHA: Nao foi possivel obter os IPs dos nos."
  exit 1
fi

WORKING_IP=""

for IP in $NODE_IPS; do
  echo -n "Testando conectividade com o no $IP na porta $NODEPORT... "
  HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --max-time 3 "http://${IP}:${NODEPORT}")
  
  if [ "$HTTP_STATUS" != "000" ]; then
    echo "SUCESSO"
    WORKING_IP=$IP
    break
  else
    echo "FALHA (Timeout)"
  fi
done

if [ -z "$WORKING_IP" ]; then
  echo "--------------------------------------------------------"
  echo "ERRO: Nenhum no acessivel. Verifique o cluster."
  exit 1
fi

BASE_URL="http://${WORKING_IP}:${NODEPORT}"

echo "--------------------------------------------------------"
echo "Selecione o modo de execucao dos testes:"
echo "1) Criar uma nova flag e avaliar (evita conflitos)"
echo "2) Avaliar flag existente (ignora etapas de criacao)"
read -p "Opcao: " OPCAO

if [ "$OPCAO" == "1" ]; then
  TIMESTAMP=$(date +%s)
  FLAG_NAME="enable-new-dashboard-$TIMESTAMP"
elif [ "$OPCAO" == "2" ]; then
  FLAG_NAME="enable-new-dashboard"
else
  echo "Opcao invalida. Encerrando."
  exit 1
fi

echo "--------------------------------------------------------"
echo "Iniciando testes funcionais da arquitetura..."
echo "Ponto de entrada selecionado: ${BASE_URL}"
echo "Flag alvo selecionada: ${FLAG_NAME}"
echo "--------------------------------------------------------"

echo "Etapa 1: Autenticacao no auth-service"
AUTH_RESPONSE=$(curl -s -X POST "${BASE_URL}/validate/admin/keys" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${MASTER_KEY}" \
  -d '{"name": "script-test-key"}')

API_KEY=$(echo "$AUTH_RESPONSE" | jq -r '.key')

if [ "$API_KEY" == "null" ] || [ -z "$API_KEY" ]; then
  echo "Falha na autenticacao. Resposta do servidor:"
  echo "$AUTH_RESPONSE"
  exit 1
fi
echo "Chave de API gerada com sucesso."
echo "--------------------------------------------------------"

if [ "$OPCAO" == "1" ]; then
  echo "Etapa 2: Criacao da Flag no flag-service"
  FLAG_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "${BASE_URL}/flag/flags" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${API_KEY}" \
    -d "{
        \"name\": \"$FLAG_NAME\",
        \"description\": \"Ativa o novo dashboard para usuarios\",
        \"is_enabled\": true
    }")

  HTTP_STATUS_FLAG=$(echo "$FLAG_RESPONSE" | tail -n 1)
  if [ "$HTTP_STATUS_FLAG" != "201" ] && [ "$HTTP_STATUS_FLAG" != "200" ]; then
    echo "Falha ao criar flag. Status HTTP: $HTTP_STATUS_FLAG"
    echo "$FLAG_RESPONSE"
    exit 1
  fi
  echo "Flag criada com sucesso."
  echo "--------------------------------------------------------"

  echo "Etapa 3: Criacao da regra no targeting-service"
  TARGETING_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "${BASE_URL}/targeting/rules" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${API_KEY}" \
    -d "{
        \"flag_name\": \"$FLAG_NAME\",
        \"is_enabled\": true,
        \"rules\": {
            \"type\": \"PERCENTAGE\",
            \"value\": 50
        }
    }")

  HTTP_STATUS_TARGETING=$(echo "$TARGETING_RESPONSE" | tail -n 1)
  if [ "$HTTP_STATUS_TARGETING" != "201" ] && [ "$HTTP_STATUS_TARGETING" != "200" ]; then
    echo "Falha ao criar regra. Status HTTP: $HTTP_STATUS_TARGETING"
    echo "$TARGETING_RESPONSE"
    exit 1
  fi
  echo "Regra de segmentacao criada com sucesso."
  echo "--------------------------------------------------------"
else
  echo "Etapas 2 e 3 ignoradas conforme modo selecionado."
  echo "--------------------------------------------------------"
fi

echo "Etapa 4: Avaliacao no evaluation-service"
EVALUATION_RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "${BASE_URL}/evaluation/evaluate?user_id=user-12345&flag_name=${FLAG_NAME}" \
  -H "Authorization: Bearer ${API_KEY}")

HTTP_STATUS_EVALUATION=$(echo "$EVALUATION_RESPONSE" | tail -n 1)
if [ "$HTTP_STATUS_EVALUATION" != "200" ]; then
  echo "Falha na avaliacao. Status HTTP: $HTTP_STATUS_EVALUATION"
  echo "$EVALUATION_RESPONSE"
  exit 1
fi
echo "Avaliacao processada com sucesso."
echo "Resultado retornado: $(echo "$EVALUATION_RESPONSE" | head -n -1)"
echo "--------------------------------------------------------"

echo "Todas as operacoes de integracao foram validadas e concluidas."