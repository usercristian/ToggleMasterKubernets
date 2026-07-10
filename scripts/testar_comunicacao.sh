#!/bin/bash

EXTERNAL_IP="35.174.115.227"
NODEPORT="32594"
BASE_URL="http://${EXTERNAL_IP}:${NODEPORT}"

declare -A ENDPOINTS
ENDPOINTS=(
  ["auth-service"]="/auth"
  ["flag-service"]="/flag"
  ["targeting-service"]="/targeting"
  ["evaluation-service"]="/evaluation"
  ["analytics-service"]="/analytics"
)

echo "Iniciando a validacao automatizada das rotas do Ingress..."
echo "Ponto de entrada: ${BASE_URL}"
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