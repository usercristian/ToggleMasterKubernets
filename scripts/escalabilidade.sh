#!/bin/bash

NAMESPACE="togglemaster"
NODEPORT=$(kubectl get svc ingress-nginx-controller -n togglemaster -o jsonpath='{.spec.ports[?(@.name=="http")].nodePort}')

if [ -z "$NODEPORT" ]; then
  echo "ERRO: Nao foi possivel identificar o NodePort do Ingress."
  exit 1
fi

echo "Porta detectada: $NODEPORT"
HPA_NAME="evaluation-service-hpa"

echo "--- Descobrindo Ponto de Entrada do Cluster ---"
# Coleta os IPs dos nós e testa a conectividade como no seu script anterior
NODE_IPS=$(kubectl get nodes -o jsonpath='{.items[*].status.addresses[?(@.type=="ExternalIP")].address}')
[ -z "$NODE_IPS" ] && NODE_IPS=$(kubectl get nodes -o jsonpath='{.items[*].status.addresses[?(@.type=="InternalIP")].address}')

WORKING_IP=""
for IP in $NODE_IPS; do
  if curl -s -o /dev/null -w "%{http_code}" --max-time 3 "http://${IP}:${NODEPORT}" | grep -qE "200|404|401|403"; then
    WORKING_IP=$IP
    break
  fi
done

if [ -z "$WORKING_IP" ]; then
  echo "ERRO: Nenhum nó acessível."
  exit 1
fi

BASE_URL="http://${WORKING_IP}:${NODEPORT}"
SERVICE_URL="${BASE_URL}/evaluation/evaluate?user_id=user-123&flag_name=enable-new-dashboard"

echo "URL Alvo detectada: $SERVICE_URL"

echo "--- Iniciando Coleta de Dados ---"
TARGET_DEPLOYMENT=$(kubectl get hpa $HPA_NAME -n $NAMESPACE -o jsonpath='{.spec.scaleTargetRef.name}')
MAX_REPLICAS=$(kubectl get hpa $HPA_NAME -n $NAMESPACE -o jsonpath='{.spec.maxReplicas}')

echo "Alvo: $TARGET_DEPLOYMENT | Limite de Réplicas: $MAX_REPLICAS"

# Define a ordem de busca pelo binario hey
HEY_BIN=$(which hey 2>/dev/null)

if [ -z "$HEY_BIN" ]; then
  # Se nao esta no PATH, procura em locais comuns
  [ -f "$HOME/go/bin/hey" ] && HEY_BIN="$HOME/go/bin/hey"
fi

if [ -z "$HEY_BIN" ]; then
  echo "ERRO: O binario 'hey' nao foi encontrado."
  echo "Instale-o ou adicione ao PATH do sistema."
  exit 1
fi

echo "Utilizando binario: $HEY_BIN"

# Agora utilize $HEY_BIN na execucao
echo "Iniciando teste de carga com 500 requisições concorrentes por 60 segundos..."
$HEY_BIN -z 60s -c 500 "$SERVICE_URL" > carga.log 2>&1 &

echo "--- Monitoramento em Tempo Real ---"
START_TIME=$(date +%s)
for i in {1..10}; do
  echo "--- Ciclo $i ($(date +%H:%M:%S)) ---"
  kubectl get hpa $HPA_NAME -n $NAMESPACE
  kubectl get pods -n $NAMESPACE -l app=evaluation --no-headers | wc -l | awk '{print "Pods Atuais: "$1}'
  kubectl get nodes --no-headers | wc -l | awk '{print "Nodes Atuais: "$1}'
  sleep 10
done

echo "--- Aguardando Scale Down ---"
sleep 60

echo "--- RELATÓRIO FINAL ---"
END_TIME=$(date +%s)
echo "Duração total: $((END_TIME - START_TIME)) segundos"
echo "Performance (hey output):"
tail -n 6 carga.log
echo "--- Fim do Relatório ---"