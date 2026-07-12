#!/usr/bin/env bash

set -euo pipefail

DIR_ATUAL="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIR_RAIZ="$(dirname "$DIR_ATUAL")"

FICHEIRO_ENV="$DIR_RAIZ/.env"

if [ ! -f "$FICHEIRO_ENV" ]; then
    echo "Erro: ficheiro .env não encontrado em:"
    echo "$FICHEIRO_ENV"
    exit 1
fi

set -a
source "$FICHEIRO_ENV"
set +a

# Extrair credenciais da AWS dinamicamente
AWS_ACCESS_KEY_ID=$(aws configure get aws_access_key_id || echo "")
AWS_SECRET_ACCESS_KEY=$(aws configure get aws_secret_access_key || echo "")
AWS_SESSION_TOKEN=$(aws configure get aws_session_token || echo "")

# Validação das variáveis obrigatórias do .env
VARIAVEIS_ENV=(
    POSTGRES_USER
    POSTGRES_PASSWORD
    MASTER_KEY
    SERVICE_API_KEY
)

for VAR in "${VARIAVEIS_ENV[@]}"; do
    if [ -z "${!VAR:-}" ]; then
        echo "Erro: variável $VAR não encontrada no .env"
        exit 1
    fi
done

# Validação das credenciais da AWS
VARIAVEIS_AWS=(
    AWS_ACCESS_KEY_ID
    AWS_SECRET_ACCESS_KEY
    AWS_SESSION_TOKEN
)

for VAR in "${VARIAVEIS_AWS[@]}"; do
    if [ -z "${!VAR:-}" ]; then
        echo "Erro: credencial $VAR não encontrada nas configurações locais da AWS."
        exit 1
    fi
done

# Terraform RDS
DIR_TF="$DIR_RAIZ/terraform/rds"
mkdir -p "$DIR_TF"

cat > "$DIR_TF/secrets.auto.tfvars" <<EOF
db_username = "$POSTGRES_USER"
db_password = "$POSTGRES_PASSWORD"
EOF

echo "✓ terraform/rds/secrets.auto.tfvars gerado."

# Kubernetes Secret
DIR_K8S="$DIR_RAIZ/k8s/services"
mkdir -p "$DIR_K8S"

POSTGRES_USER_B64=$(printf "%s" "$POSTGRES_USER" | base64 -w0)
POSTGRES_PASSWORD_B64=$(printf "%s" "$POSTGRES_PASSWORD" | base64 -w0)
MASTER_KEY_B64=$(printf "%s" "$MASTER_KEY" | base64 -w0)
SERVICE_API_KEY_B64=$(printf "%s" "$SERVICE_API_KEY" | base64 -w0)
AWS_ACCESS_KEY_ID_B64=$(printf "%s" "$AWS_ACCESS_KEY_ID" | base64 -w0)
AWS_SECRET_ACCESS_KEY_B64=$(printf "%s" "$AWS_SECRET_ACCESS_KEY" | base64 -w0)
AWS_SESSION_TOKEN_B64=$(printf "%s" "$AWS_SESSION_TOKEN" | base64 -w0)

cat > "$DIR_K8S/secret.yaml" <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: togglemaster-secrets
  namespace: togglemaster
type: Opaque

data:
  POSTGRES_USER: $POSTGRES_USER_B64
  POSTGRES_PASSWORD: $POSTGRES_PASSWORD_B64
  MASTER_KEY: $MASTER_KEY_B64
  SERVICE_API_KEY: $SERVICE_API_KEY_B64
  AWS_ACCESS_KEY_ID: $AWS_ACCESS_KEY_ID_B64
  AWS_SECRET_ACCESS_KEY: $AWS_SECRET_ACCESS_KEY_B64
  AWS_SESSION_TOKEN: $AWS_SESSION_TOKEN_B64
EOF

echo "✓ k8s/services/secret.yaml gerado."
echo
echo "Tudo concluído com sucesso."