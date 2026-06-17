Primeiro Criar um arquivo .env com as variaveis


POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
MASTER_KEY=admin-secreto-123
SERVICE_API_KEY=tm_key_inserir_chave_aqui
AWS_REGION=us-east-1
AWS_SQS_URL=https://sqs.us-east-1.amazonaws.com/123456789012/sua-fila
AWS_DYNAMODB_TABLE=ToggleMasterAnalytics
AWS_ACCESS_KEY_ID=sua_access_key
AWS_SECRET_ACCESS_KEY=sua_secret_key
AWS_SESSION_TOKEN=seu_token



podman-compose up --build