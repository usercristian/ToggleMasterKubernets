# Construção local via docker

Ecossistema de microsservicos localmente, atraves da orquestracao de contentores, e o provisionamento da primeira camada de nuvem utilizando Terraform. A estrutura foi desenhada respeitando a separacao de responsabilidades e a modularidade da aplicacao.

## Requisitos e Configuracao de Credenciais

- Podman ou Docker com o plugin compose instalado nativamente.
- Terraform na versao 1.5 ou superior.
- AWS CLI instalado.
- Acesso ativo ao AWS Academy Learner Lab.
- kubectl (versão 1.31 ou superior)
- utilitários nativos de terminal Linux (bash, base64)
- Psql e jq para testes

Para que o Terraform consiga autenticar e criar os recursos na nuvem, e necessario carregar as credenciais temporarias do Learner Lab. No painel da AWS Academy, aceda aos detalhes da conta, copie o bloco de credenciais de terminal e exporte as variaveis na sua sessao de terminal antes de iniciar os comandos de infraestrutura.

```bash
export AWS_ACCESS_KEY_ID="<SUA_CHAVE_DE_ACESSO>"
export AWS_SECRET_ACCESS_KEY="<SEU_SEGREDO_DE_ACESSO>"
export AWS_SESSION_TOKEN="<SEU_TOKEN_DE_SESSAO>"

```

## Arquitetura Local

O ambiente local simula a topologia de microsservicos com bases de dados isoladas logicamente numa rede fechada, garantindo a facilidade de manutencao.

Crie um ficheiro chamado .env na raiz do repositorio com as configuracoes de acesso e chaves de seguranca partilhadas entre as aplicacoes.

```env
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
MASTER_KEY=admin-secreto-123
SERVICE_API_KEY=tm_key_local_dev_123
AWS_REGION=us-east-1
AWS_SQS_URL=https://sqs.us-east-1.amazonaws.com/<SEU_ACCOUNT_ID>/togglemaster-evaluation-events
AWS_DYNAMODB_TABLE=ToggleMasterAnalytics
AWS_ACCESS_KEY_ID=<SUA_CHAVE_DE_ACESSO>
AWS_SECRET_ACCESS_KEY=<SEU_SEGREDO_DE_ACESSO>
AWS_SESSION_TOKEN=<SEU_TOKEN_DE_SESSAO>

```

Na raiz do projeto, execute o comando de construcao. O orquestrador iniciara as instancias do PostgreSQL e do Redis, validara o estado de prontidao das bases de dados e, em seguida, iniciara a compilacao e o arranque das aplicacoes de forma sequencial.

# Principais Comandos

## Inicializacao
Subir a infraestrutura em segundo plano e construir imagens atualizadas:
podman-compose up -d --build

## Monitoramento
Listar os containers em execucao:
podman-compose ps

Acompanhar os logs da aplicacao em tempo real:
podman-compose logs -f

## Gerenciamento de Ciclo de Vida
Parar a execucao temporariamente:
podman-compose stop

Retomar os containers pausados:
podman-compose start

## Encerramento
Destruir os containers e manter os dados armazenados:
podman-compose down

Destruir os containers e apagar todos os volumes de dados:
podman-compose down -v

# Arquitetura de Nuvem

O projeto utiliza a **VPC padrão** disponibilizada pelo ambiente AWS Academy devido as limitações do ambiente. Dessa forma, não foi necessária a criação de uma infraestrutura de rede personalizada (VPC, Subnets, Route Tables ou Internet Gateway).

## Componentes

- Amazon EKS
- Amazon RDS PostgreSQL (3 instâncias)
- Amazon ElastiCache Redis
- Amazon DynamoDB
- Amazon SQS
- Amazon ECR

## Comunicação

O fluxo de comunicação da aplicação é realizado da seguinte forma:

```text
Internet
    │
    ▼
Ingress NGINX
    │
    ▼
Amazon EKS
    │
    ├────────► RDS Auth
    │
    ├────────► RDS Flag
    │
    ├────────► RDS Targeting
    │
    ├────────► ElastiCache Redis
    │
    ├────────► Amazon DynamoDB
    │
    ├────────► Amazon SQS
    │
    └────────► Amazon ECR (pull das imagens)
```

## Security Groups

Para permitir a comunicação entre os componentes foram configuradas regras de Security Group.

### Amazon EKS

O Security Group associado aos Worker Nodes deve possuir acesso de saída para:

- Amazon RDS (TCP 5432)
- Amazon ElastiCache Redis (TCP 6379)
- Amazon DynamoDB (HTTPS 443)
- Amazon SQS (HTTPS 443)
- Amazon ECR (HTTPS 443)

### Amazon RDS

Cada instância PostgreSQL permite conexões apenas provenientes do Security Group do cluster EKS.

Porta utilizada:

- TCP 5432

### Amazon ElastiCache

O Redis permite conexões apenas provenientes do Security Group do cluster EKS.

Porta utilizada:

- TCP 6379

## Subnets

Foram utilizadas as **Subnets padrão da VPC** disponibilizadas pela AWS Academy.

Os Worker Nodes do Amazon EKS, bem como as instâncias RDS e o ElastiCache, encontram-se nessas subnets privadas/padrão, permitindo comunicação interna dentro da VPC.

## Acesso Externo

O acesso dos clientes ocorre através do **NGINX Ingress Controller**, publicado como **NodePort**, que encaminha as requisições HTTP para os serviços internos do cluster.

## Observações

- Não há acesso público direto às instâncias RDS.
- Não há acesso público direto ao ElastiCache Redis.
- DynamoDB, SQS e ECR são acessados através das APIs da AWS utilizando HTTPS.
- Toda comunicação entre os microserviços ocorre internamente dentro do cluster Kubernetes.

# Guia de Provisionamento: Do Zero à Nuvem

Para implementar a infraestrutura no ambiente academy:
(não esta muito detalhado para não ficar longo, mais infos no readme da pasta docs)

### 1. Preparação do Ambiente

* Instale as ferramentas necessárias: Docker, AWS CLI, Terraform, kubectl e Go.
* Configure suas credenciais na AWS: `aws configure`.
* Clone o repositório do projeto e entre na pasta raiz.

### 2. Provisionamento de Banco de Dados (RDS)

A forma mais segura é automatizar com Terraform.

* Entre na pasta: `cd terraform/rds`.
* Gere as credenciais: `./scripts/gerar_secrets.sh` (cria o `secrets.auto.tfvars`).
* Inicialize o Terraform: `terraform init`.
* Valide o plano: `terraform plan`.
* Aplique o provisionamento: `terraform apply -auto-approve`.
* Anote o `db_endpoint` gerado na saída do terminal.

### 3. Containerização e Registro

* Compile o código dos serviços (FastAPI/Python).
* Construa a imagem: `docker build -t [nome-da-imagem] .`.
* Faça o login no ECR (Elastic Container Registry): `aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin [ID_DA_CONTA].dkr.ecr.us-east-1.amazonaws.com`.
* Envie a imagem: `docker push [ID_DA_CONTA][.dkr.ecr.us-east-1.amazonaws.com/](https://.dkr.ecr.us-east-1.amazonaws.com/)[nome-da-imagem]:latest`.

### 4. Orquestração no Kubernetes (EKS)

* Atualize seu acesso ao cluster: `aws eks update-kubeconfig --region us-east-1 --name [nome-do-cluster]`.
* Aplique os manifestos de infraestrutura: `kubectl apply -k k8s/`.
* Verifique se todos os pods estão em execução: `kubectl get pods -n togglemaster`.

### 5. Configuração de Rede e Testes

* Identifique a porta do serviço: `kubectl get svc ingress-nginx-controller -n togglemaster`.
* Libere o tráfego no Security Group dos nós:
`aws ec2 authorize-security-group-ingress --region us-east-1 --group-id [ID_DO_SG] --protocol tcp --port [PORTA_IDENTIFICADA] --cidr 0.0.0.0/0`.
* Valide a comunicação: `./scripts/testar_comunicacao.sh`.
* Teste a escalabilidade: `./scripts/escalabilidade.sh`.

---

*Lembrete: Em sessões novas na AWS Academy, o RDS persiste, mas o EKS e os Security Groups exigem revalidação da porta de rede e atualização do kubeconfig.*