# Provisionamento do EKS Academy

Estrutura modular dos arquivos Terraform para provisionar o cluster EKS respeitando as limitacoes do ambiente AWS Academy, alem do fluxo de aplicacao.

## Arquivos e Responsabilidades

provider.tf: Configura o provedor da AWS, definindo a versao do modulo e a regiao de provisionamento (us-east-1).

data.tf: Realiza a busca dinamica da infraestrutura de rede e identidade. Localiza a VPC padrao da sessao, extrai as subnets associadas e captura o ARN da LabRole, eliminando a necessidade de atualizar IDs fixos a cada nova sessao.

cluster.tf: Cria o Control Plane do EKS na versao 1.36. Habilita o modo de acesso via EKS API, concedendo as permissoes de administrador de cluster para a sua sessao sem necessidade de editar o configmap legada aws-auth.

node_group.tf: Define o grupo de Worker Nodes. Estabelece a utilizacao de instancias t3.medium com 20GiB de disco para respeitar os limites do Academy, alem de configurar as politicas de escalabilidade e injetar as labels no Kubernetes.

addons.tf: Gerencia a instalacao dos complementos nativos (vpc-cni, kube-proxy, coredns, metrics-server e eks-node-monitoring-agent) nas versoes mapeadas. Possui dependencias explicitas para garantir que componentes como o coredns so sejam instalados apos a disponibilidade computacional dos nos.

## Execucao

Com o terminal ja autenticado na AWS Academy via AWS CLI, siga estes passos no diretorio onde os arquivos foram criados:

1. Inicialize o ambiente baixando os modulos requeridos
terraform init

2. Valide as alteracoes estruturais que serao realizadas na sua conta
terraform plan

3. Aplique o provisionamento da infraestrutura
terraform apply -auto-approve

4. Conecte o seu terminal local ao novo cluster
aws eks update-kubeconfig --region us-east-1 --name togglemaster-eks