#!/bin/bash

if command -v podman &> /dev/null; then
  CLI="podman"
elif command -v docker &> /dev/null; then
  CLI="docker"
else
  echo "Erro: Nem podman nem docker foram encontrados no sistema."
  exit 1
fi

echo "Motor de container detectado: $CLI"

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null)

if [ -z "$ACCOUNT_ID" ]; then
  echo "Erro: Sessao da AWS inativa ou credenciais invalidas."
  echo "Por favor, atualize suas credenciais da AWS Academy e tente novamente."
  exit 1
fi

REGISTO="$ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com"

echo "Autenticando no ECR..."
aws ecr get-login-password --region us-east-1 | $CLI login --username AWS --password-stdin $REGISTO

if [ $? -ne 0 ]; then
  echo "Falha ao realizar login no AWS ECR."
  exit 1
fi

SERVICOS="auth-service flag-service targeting-service evaluation-service analytics-service"

for SERVICO in $SERVICOS; do
  echo "Iniciando processo para: $SERVICO"
  
  $CLI build -t $SERVICO ../$SERVICO
  
  $CLI tag $SERVICO:latest $REGISTO/$SERVICO:latest
  
  $CLI push $REGISTO/$SERVICO:latest
done

echo "Todos os servicos foram processados."