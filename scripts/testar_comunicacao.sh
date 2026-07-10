#!/bin/bash

NODEPORT="32594"

echo "Verificando o status do Ingress Controller..."
if ! kubectl get pods -n ingress-nginx | grep -q "Running"; then
  echo "FALHA: O Ingress Controller não está em execução."
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
  echo "FALHA: Não foi possível obter os IPs dos nós."
  exit 1
fi

WORKING_IP=""

for IP in $NODE_IPS; do
  echo -n "Testando conectividade com o nó $IP na porta $NODEPORT... "
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
  echo "ERRO: Nenhum nó acessível. Verifique a regra liberada no Security Group associado às instâncias."
  exit 1
fi

BASE_URL="http://${WORKING_IP}:${NODEPORT}"

declare -A ENDPOINTS
ENDPOINTS=(
  ["auth-service"]="/validate"
  ["flag-service"]="/flag"
  ["targeting-service"]="/targeting"
  ["evaluation-service"]="/evaluation"
  ["analytics-service"]="/analytics"
)

echo "--------------------------------------------------------"
echo "Iniciando a validacao automatizada das rotas do Ingress..."
echo "Ponto de entrada selecionado: ${BASE_URL}"
echo "--------------------------------------------------------"

FALHAS=0

for SERVICO in "${!ENDPOINTS[@]}"; do
  ROTA="${ENDPOINTS[$SERVICO]}"
  URL="${BASE_URL}${ROTA}"
  
  echo -n "Testando ${SERVICO} em ${ROTA}... "
  
  HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$URL")
  
  if [ "$HTTP_STATUS" -eq 000 ]; then
    echo "FALHA: Timeout ou servico inacessivel externamente."
    FALHAS=$((FALHAS + 1))
  elif [ "$HTTP_STATUS" -eq 502 ] || [ "$HTTP_STATUS" -eq 503 ] || [ "$HTTP_STATUS" -eq 504 ]; then
    echo "FALHA: Erro de Gateway (Status ${HTTP_STATUS}). O Ingress nao encontrou o Pod."
    FALHAS=$((FALHAS + 1))
  else
    echo "OK (Status HTTP recebido: ${HTTP_STATUS})"
  fi
done

echo "--------------------------------------------------------"
if [ "$FALHAS" -eq 0 ]; then
  echo "Sucesso: Todas as rotas de comunicacao estao respondendo atraves do Ingress."
else
  echo "Atencao: Foram detectadas ${FALHAS} falhas na validacao do trafego."
fi