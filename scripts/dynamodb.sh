#!/usr/bin/env bash

set -euo pipefail

NOME_TABELA="ToggleMasterAnalytics"
REGIAO="us-east-1"

echo "Iniciando validacao de dados no DynamoDB..."
echo "Tabela: $NOME_TABELA"
echo "Regiao: $REGIAO"
echo "----------------------------------------"

TOTAL_ITENS=$(aws dynamodb scan \
    --table-name "$NOME_TABELA" \
    --region "$REGIAO" \
    --select "COUNT" \
    --output text \
    --query "Count")

echo "Total de registros encontrados: $TOTAL_ITENS"
echo "----------------------------------------"

if [ "$TOTAL_ITENS" -gt 0 ]; then
    echo "Amostra dos registros inseridos:"
    aws dynamodb scan \
        --table-name "$NOME_TABELA" \
        --region "$REGIAO" \
        --max-items 5 \
        --output json | jq '.Items[] | map_values(.S // .N // .BOOL // .M // .L)'
else
    echo "Nenhum dado encontrado na tabela. Verifique se o analytics-service consumiu as mensagens da fila SQS."
fi