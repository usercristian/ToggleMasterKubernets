#!/bin/bash

DIR_ATUAL="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIR_RAIZ="$(dirname "$DIR_ATUAL")"

FICHEIRO_ENV="$DIR_RAIZ/.env"

if [ ! -f "$FICHEIRO_ENV" ]; then
    echo "Ficheiro .env nao encontrado na raiz do projeto: $FICHEIRO_ENV"
    exit 1
fi

set -a
source "$FICHEIRO_ENV"
set +a

DIR_TF="$DIR_RAIZ/terraform/rds"
FICHEIRO_TFVARS="$DIR_TF/secrets.auto.tfvars"

if [ -f "$FICHEIRO_TFVARS" ]; then
    rm "$FICHEIRO_TFVARS"
fi

mkdir -p "$DIR_TF"

cat <<EOF > "$FICHEIRO_TFVARS"
db_username = "$POSTGRES_USER"
db_password = "$POSTGRES_PASSWORD"
EOF

echo "Ficheiro $FICHEIRO_TFVARS gerado com sucesso."

DIR_K8S="$DIR_RAIZ/k8s"
FICHEIRO_SECRET="$DIR_K8S/secret.yaml"

if [ -f "$FICHEIRO_SECRET" ]; then
    rm "$FICHEIRO_SECRET"
fi

mkdir -p "$DIR_K8S"

POSTGRES_USER_B64=$(echo -n "$POSTGRES_USER" | base64 -w 0)
POSTGRES_PASSWORD_B64=$(echo -n "$POSTGRES_PASSWORD" | base64 -w 0)
MASTER_KEY_B64=$(echo -n "$MASTER_KEY" | base64 -w 0)
SERVICE_API_KEY_B64=$(echo -n "$SERVICE_API_KEY" | base64 -w 0)
AWS_ACCESS_KEY_ID_B64=$(echo -n "$AWS_ACCESS_KEY_ID" | base64 -w 0)
AWS_SECRET_ACCESS_KEY_B64=$(echo -n "$AWS_SECRET_ACCESS_KEY" | base64 -w 0)
AWS_SESSION_TOKEN_B64=$(echo -n "$AWS_SESSION_TOKEN" | base64 -w 0)

cat <<EOF > "$FICHEIRO_SECRET"
apiVersion: v1
kind: Secret
metadata:
  name: togglemaster-secrets
  namespace: togglemaster
type: Opaque
data:
  POSTGRES_USER: "$POSTGRES_USER_B64"
  POSTGRES_PASSWORD: "$POSTGRES_PASSWORD_B64"
  MASTER_KEY: "$MASTER_KEY_B64"
  SERVICE_API_KEY: "$SERVICE_API_KEY_B64"
  AWS_ACCESS_KEY_ID: "$AWS_ACCESS_KEY_ID_B64"
  AWS_SECRET_ACCESS_KEY: "$AWS_SECRET_ACCESS_KEY_B64"
  AWS_SESSION_TOKEN: "$AWS_SESSION_TOKEN_B64"
EOF

echo "Ficheiro $FICHEIRO_SECRET gerado com sucesso no formato base64."