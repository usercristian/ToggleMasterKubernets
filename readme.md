# Documentacao de Infraestrutura e Execucao

O presente documento consolida as instrucoes para a replicacao do ecossistema de microsservicos localmente, atraves da orquestracao de contentores, e o provisionamento da primeira camada de nuvem utilizando Terraform. A estrutura foi desenhada respeitando a separacao de responsabilidades e a modularidade da aplicacao, alinhada aos principios de arquitetura em nuvem.

## Requisitos e Configuracao de Credenciais

- Podman ou Docker com o plugin compose instalado nativamente.
- Terraform na versao 1.5 ou superior.
- AWS CLI instalado.
- Acesso ativo ao AWS Academy Learner Lab.
- kubectl (versão 1.31 ou superior)
- utilitários nativos de terminal Linux (bash, base64)

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

```bash
podman-compose up --build -d

```

## Estrutura de Nuvem Modular

Para contornar as limitacoes rigorosas de permissoes do perfil LabRole do AWS Academy e proteger o orcamento, o provisionamento de infraestrutura como codigo foi dividido em dois dominios isolados: serveless e rds.

Esta divisao assegura a modularidade operacional. Os ficheiros de estado do Terraform operam de forma independente, impedindo que atualizacoes na fila de mensageria causem interrupcoes ou reinicios acidentais nas bases de dados relacionais.

## Provisionamento da Camada Serveless

Esta camada engloba os 5 repositorios do ECR, a fila do SQS e a tabela do DynamoDB. Estes servicos operam com faturacao por pedido, nao gerando custos fixos por hora de inatividade.

Navegue ate a pasta do modulo e aplique a configuracao.

```bash
cd terraform/serveless
terraform init
terraform apply

```

No final da execucao, o terminal exibira os enderecos dos repositorios ECR, a URL da fila SQS e o nome da tabela DynamoDB. Registe estes valores para configurar os manifestos do Kubernetes na proxima fase.

## Construcao e Envio de Imagens para o ECR

Apos o provisionamento da camada serveless, os repositorios do Amazon ECR estarao disponiveis para receber os artefatos das aplicacoes. O envio garante a integridade dos pacotes de software na nuvem e prepara o ambiente para o orquestrador.

Autentique o cliente local de conteineres no registro da AWS. Substitua o `<SEU_ACCOUNT_ID>` pelo identificador da sua conta AWS.

```bash
aws ecr get-login-password --region us-east-1 | podman login --username AWS --password-stdin <SEU_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com

```

Com a sessao autenticada, execute o script de repeticao na raiz do projeto para compilar e enviar as imagens dos cinco microsservicos automaticamente, mantendo a excelencia operacional e reduzindo o esforco manual.

```bash
REGISTO="<SEU_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com"
SERVICOS="auth-service flag-service targeting-service evaluation-service analytics-service"

for SERVICO in $SERVICOS; do
  echo "A construir e enviar $SERVICO..."
  podman build -t $SERVICO ./$SERVICO
  podman tag $SERVICO:latest $REGISTO/$SERVICO:latest
  podman push $REGISTO/$SERVICO:latest
done

```

## Provisionamento da Camada Relacional

Esta camada encarrega-se do provisionamento de 3 instancias independentes do AWS RDS PostgreSQL, garantindo que o servico de autenticacao, o servico de flags e o servico de segmentacao operem nas suas proprias bases de dados fisicas.

O codigo Terraform inclui parametros estritos para respeitar a seguranca do Learner Lab. A classe computacional foi fixada em db.t3.micro, a execucao ocorre numa unica zona de disponibilidade, o monitoramento aprimorado foi desativado com um intervalo de zero, e a captura do backup final foi anulada.

Navegue ate a pasta do modulo de bases de dados e aplique a configuracao.

```bash
cd terraform/rds
terraform init
terraform apply

```

Os endpoints DNS de cada uma das 3 instancias serao impressos no terminal para integracao no ecossistema.

## Rotina de Otimizacao de Custos

Para evitar o esgotamento dos creditos, e mandatorio destruir a camada relacional ao final de cada sessao de desenvolvimento, uma vez que as instancias RDS geram custos continuos de computacao enquanto estiverem ativas.

Navegue ate o diretorio rds e elimine a infraestrutura relacional.

```bash
cd terraform/rds
terraform destroy

```

A camada serveless e os repositorios de imagens podem permanecer intactos, permitindo que a infraestrutura fundacional seja preservada para os dias seguintes sem perdas financeiras.

```

## Provisionamento da Camada de Cache em Memoria

Para alinhar a arquitetura aos pilares de Modularidade e Otimizacao de Custos, o Amazon ElastiCache foi isolado num diretorio exclusivo. Este isolamento assegura que o ciclo de vida do cache nao interfira com a camada serveless, permitindo a sua destruicao diaria sem afetar os repositorios de imagens.

A configuracao utiliza a classe computacional cache.t3.micro com um unico no, alocada na VPC padrao. Estes parametros sao estritos para respeitar as restricoes do perfil LabRole e evitar o consumo excessivo dos creditos da conta estudantil.

Navegue ate a pasta do modulo de cache e aplique a configuracao.

```bash
cd terraform/elasticache
terraform init
terraform apply

```

O endpoint de conexao do Redis sera impresso no terminal no final da execucao e devera ser registado para a configuracao do Kubernetes.

## Atualizacao da Rotina de Otimizacao de Custos

Como o ElastiCache tambem gera faturacao continua por hora de execucao, tal como as bases de dados RDS, e imperativo adicionar a sua destruicao a rotina de encerramento da sessao de desenvolvimento.

Para destruir o cache em memoria e evitar o esgotamento dos creditos, execute o comando de destruicao na pasta respetiva:

```bash
cd terraform/elasticache
terraform destroy

```

Para refletir as dependências necessárias para a equipa, adicione os seguintes itens à lista de pré-requisitos já existente no início do seu ficheiro readme.md:

* kubectl (versão 1.31 ou superior)
* utilitários nativos de terminal Linux (bash, base64)

Em seguida, adicione o bloco de texto abaixo no final do seu ficheiro readme.md.

## Orquestração no Kubernetes (Amazon EKS)

Para manter a separação de responsabilidades, os manifestos de implantação estão isolados no diretório kubernetes. A arquitetura utiliza o Kustomize para gerir a substituição dinâmica das imagens dos contentores e a criação da infraestrutura declarativa.

### Geração de Credenciais Seguras

O projeto centraliza as variáveis sensíveis num ficheiro .env na raiz do repositório. O script de automação lê este ficheiro para provisionar as credenciais do Terraform para os bancos de dados RDS e os Secrets do Kubernetes em base64, impedindo a exposição de dados no controlo de versões.

Certifique-se de que o ficheiro .env está preenchido e que os valores não contêm aspas. Conceda permissão de execução e inicie o script:

```bash
chmod +x gerar_secrets.sh
./gerar_secrets.sh

```

O script criará o ficheiro terraform/rds/secrets.auto.tfvars e o manifesto kubernetes/secret.yaml.

### Conexão e Implantação no Cluster

Após a infraestrutura estar ativa, atualize a configuração do cliente local para estabelecer comunicação com o plano de controlo do EKS:

```bash
aws eks update-kubeconfig --region us-east-1 --name togglemaster-cluster

```

Edite o ficheiro kubernetes/kustomization.yaml para inserir o Account ID correto na secção de imagens. Em seguida, aplique todos os recursos simultaneamente utilizando a flag do Kustomize:

```bash
kubectl apply -k kubernetes/

```

Caso os pods já estejam em execução e seja necessário forçar o recarregamento de novas variáveis provenientes do ConfigMap ou do Secret, execute um reinício controlado para substituir os contentores sem tempo de inatividade:

```bash
kubectl rollout restart deployment auth-service flag-service targeting-service evaluation-service analytics-service

```