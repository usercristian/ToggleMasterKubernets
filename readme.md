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