# Terraform

# Fluxo Geral de Provisionamento

```text
Pré-requisitos
        │
        ▼
gerar_secret.sh
        │
        ▼
terraform/serverless
        │
        ▼
Build e Push das imagens
        │
        ▼
terraform/rds
        │
        ▼
terraform/elasticache
        │
        ▼
terraform/security
        │
        ▼
Configurar kubectl
        │
        ▼
Deploy Kubernetes
```

 A infraestrutura foi dividida em camadas independentes para facilitar a manutenção, reduzir custos e permitir a destruição seletiva dos recursos durante o desenvolvimento.

---

# Pré-requisitos

Antes de iniciar o provisionamento, certifique-se de possuir:

- Terraform instalado;
- AWS CLI instalada e autenticada;
- Podman ou Docker instalado;
- kubectl instalado;
- Cluster Amazon EKS criado (AWS Academy);
- Arquivo `.env` configurado na raiz do projeto.

Em seguida, gere automaticamente os arquivos necessários para o Terraform e Kubernetes:

```bash
./scripts/gerar_secret.sh
```

Este script cria automaticamente:

- `terraform/rds/secrets.auto.tfvars`
- `k8s/secret.yaml`

---

# Ordem Recomendada de Provisionamento

Para evitar inconsistências entre os serviços, recomenda-se executar os módulos na seguinte ordem:

```text
1. terraform/serverless
2. Construção e envio das imagens para o Amazon ECR
3. terraform/rds
4. terraform/elasticache
5. terraform/security
6. Deploy do Kubernetes
```

---

# Provisionamento da Camada Serverless

Esta camada engloba:

- 5 repositórios Amazon ECR;
- 1 fila Amazon SQS;
- 1 tabela Amazon DynamoDB.

Estes serviços utilizam faturação baseada em utilização (pay-per-use), não gerando custos fixos por hora de inatividade.

Navegue até ao diretório do módulo e aplique a configuração.

```bash
cd terraform/serverless
terraform init
terraform apply
```

Ao final da execução serão apresentados:

- URLs dos repositórios Amazon ECR;
- URL da fila Amazon SQS;
- Nome da tabela DynamoDB.

Estes valores serão utilizados posteriormente na configuração do Kubernetes.

---

# Construção e Envio das Imagens para o Amazon ECR

Após o provisionamento da camada serverless, os repositórios Amazon ECR estarão disponíveis para receber as imagens dos microsserviços.

Autentique o cliente de contentores no registo da AWS.

Substitua `<SEU_ACCOUNT_ID>` pelo identificador da sua conta AWS.

```bash
aws ecr get-login-password --region us-east-1 | podman login --username AWS --password-stdin <SEU_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com
```

Em seguida execute o script abaixo na raiz do projeto.

```bash
REGISTO="<SEU_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com"

SERVICOS="auth-service flag-service targeting-service evaluation-service analytics-service"

for SERVICO in $SERVICOS; do
    echo "Construindo e enviando $SERVICO..."

    podman build -t $SERVICO ./$SERVICO
    podman tag $SERVICO:latest $REGISTO/$SERVICO:latest
    podman push $REGISTO/$SERVICO:latest
done
```

---

# Provisionamento da Camada Relacional

Esta camada é responsável pela criação de três instâncias independentes do Amazon RDS PostgreSQL:

- Auth Service
- Flag Service
- Targeting Service

Cada microsserviço possui a sua própria base de dados, garantindo isolamento e independência entre os domínios da aplicação.

A configuração foi adaptada às restrições do AWS Academy utilizando:

- PostgreSQL 15;
- Instâncias `db.t3.micro`;
- Single-AZ;
- Backup final desativado;
- Enhanced Monitoring desativado;
- Storage encriptado.

Execute:

```bash
cd terraform/rds
terraform init
terraform apply
```

Posteriormente você vai realizar as instruções descritas no README do diretório `k8s` para criar as tabelas das bases de dados através dos Jobs Kubernetes.

---

# Provisionamento da Camada de Cache

O Amazon ElastiCache Redis foi isolado num módulo próprio para permitir um ciclo de vida independente da restante infraestrutura.

A configuração utiliza:

- Redis;
- cache.t3.micro;
- 1 nó;
- VPC padrão da AWS Academy.

Execute:

```bash
cd terraform/elasticache
terraform init
terraform apply
```

Ao final da execução será apresentado o endpoint do Redis, utilizado posteriormente pelo Kubernetes.

---

# Configuração Automática dos Security Groups

Após a criação do Amazon RDS, ElastiCache e do cluster Amazon EKS, execute o módulo responsável por configurar automaticamente a comunicação entre os serviços.

Este módulo identifica automaticamente:

- Security Group do cluster EKS;
- Security Groups das instâncias RDS;
- Security Group do ElastiCache.

Em seguida cria as regras necessárias para permitir:

- EKS → PostgreSQL (5432)
- EKS → Redis (6379)

Execute primeiramente o script *confignetwork.sh* para encontrar o security groups e colocar em uma variavel, sem ele o aws academy não permite criar via terraform devido as restrições do labrole.


```bash
cd terraform/security
terraform init
terraform apply
```

---

# Deploy da Aplicação

Após toda a infraestrutura estar provisionada, prossiga para o diretório Kubernetes e siga as instruções do respetivo README.

```text
k8s/README.md
```

---

# Rotina de Otimização de Custos

Para evitar o consumo desnecessário dos créditos disponibilizados pelo AWS Academy, recomenda-se destruir diariamente apenas os recursos que possuem faturação contínua.

## Destruir ElastiCache

```bash
cd terraform/elasticache
terraform destroy
```

## Destruir Amazon RDS

```bash
cd terraform/rds
terraform destroy
```

Os recursos da camada Serverless (Amazon ECR, Amazon DynamoDB e Amazon SQS) podem permanecer ativos, uma vez que utilizam faturação baseada em utilização e normalmente não geram custos significativos quando não estão a ser utilizados.

---

