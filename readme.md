# ToggleMaster

![Diagrama da Arquitetura](./docs/diagrama.jpg)

O ToggleMaster e um sistema de gerenciamento de feature flags baseado em microsservicos. O projeto possibilita o controle dinamico da liberacao de funcionalidades em aplicacoes, gerenciando regras de segmentacao de usuarios e a avaliacao de flags.

Tecnologias presentes no projeto:
- Python
- Go
- Kubernetes
- Docker
- Terraform
- PostgreSQL
- AWS DynamoDB
- AWS ElastiCache
- AWS SQS

Estrutura de diretorios e referencias:
- [Analytics Service](./analytics-service/)
- [Auth Service](./auth-service/)
- [Evaluation Service](./evaluation-service/)
- [Flag Service](./flag-service/)
- [Targeting Service](./targeting-service/)
- [Kubernetes](./k8s/)
- [Terraform](./terraform/)
- [Scripts Auxiliares](./scripts/)
- [Documentacao](./docs/)

# Construção local via docker

Ecossistema de microsservicos localmente, atraves da orquestracao de contentores, e o provisionamento da primeira camada de nuvem utilizando Terraform. A estrutura foi desenhada respeitando a separacao de responsabilidades e a modularidade da aplicacao.

- Podman ou Docker com o plugin compose instalado nativamente.
- Terraform na versao 1.5 ou superior.
- AWS CLI instalado.
- Acesso ativo ao AWS Academy Learner Lab.
- kubectl (versão 1.31 ou superior)
- utilitários nativos de terminal Linux (bash, base64)
- Psql e jq para testes



# Arquitetura de Nuvem


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


## Acesso Externo

O acesso dos clientes ocorre através do **NGINX Ingress Controller**, publicado como **NodePort**, que encaminha as requisições HTTP para os serviços internos do cluster.

## Observações

- Não há acesso público direto às instâncias RDS.
- Não há acesso público direto ao ElastiCache Redis.
- DynamoDB, SQS e ECR são acessados através das APIs da AWS utilizando HTTPS.
- Toda comunicação entre os microserviços ocorre internamente dentro do cluster Kubernetes.

# Fluxo completo

```text
                    Internet
                        │
                        ▼
               Security Group EKS
                 TCP 32594/31079
                        │
                        ▼
             NGINX Ingress Controller
                        │
        ┌───────────────┼───────────────┐
        ▼               ▼               ▼
   auth-service    flag-service   targeting...
        │               │
        ├───────────────┼───────────────┐
        ▼               ▼               ▼
      RDS           ElastiCache     DynamoDB/SQS
     (5432)           (6379)        (HTTPS 443)
```

