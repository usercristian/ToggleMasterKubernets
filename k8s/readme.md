# Kubernetes

Esta pasta contém todos os manifestos Kubernetes necessários para executar o ToggleMaster no Amazon EKS.

## Estrutura

```text
k8s/
├── namespace.yaml       # Namespace do projeto
├── db-init/             # Jobs para inicialização das bases de dados
├── services/            # Deployments, Services, HPA e Ingress
├── configmap.yaml       # Configurações da aplicação
├── secret.yaml          # Secrets gerados automaticamente
└── README.md
```

## Pré-requisitos

Antes de realizar o deploy:

- Cluster EKS criado e configurado.
- Recursos da AWS (RDS, ElastiCache, DynamoDB, SQS e ECR) já provisionados.
- `kubectl` configurado para o cluster.
- Arquivo `secret.yaml` gerado através do script:

```bash
./scripts/gerar_secret.sh
```

## Deploy

* Atualize seu acesso ao cluster: `aws eks update-kubeconfig --region us-east-1 --name [nome-do-cluster]`.

### 1. Criar o namespace

Dentro do diretório aplique os comandos a seguir

```bash
kubectl apply -f namespace.yaml
```

### 2. Inicializar as bases de dados



Cria automaticamente as tabelas necessárias em cada instância PostgreSQL.

```bash
kubectl apply -k db-init

```


Verificar a execução:

```bash
kubectl get jobs -n togglemaster
```

Todos os Jobs devem estar com o estado **Complete**.

Agora só limpar os jobs

```bash
kubectl delete jobs \
auth-db-init \
flag-db-init \
targeting-db-init \
-n togglemaster

```

### 3. Implantar os serviços

```bash
kubectl apply -k services
```

## Verificação

Pods:

```bash
kubectl get pods -n togglemaster
```

Services:

```bash
kubectl get svc -n togglemaster
```

Ingress:

```bash
kubectl get ingress -n togglemaster
```

## Observações

- O `secret.yaml` **não deve ser editado manualmente**. Utilize sempre o script `gerar_secret.sh`.
- Os Jobs presentes em `db-init` podem ser executados novamente sem problemas, pois os scripts SQL utilizam `CREATE TABLE IF NOT EXISTS`.
- O deploy da aplicação deve ser realizado somente após a conclusão dos Jobs de inicialização do banco de dados.


#### Observações Arquiteturais Importantes:

* **`authenticationMode: EKS_API`**: Substitui o antigo ConfigMap `aws-auth` pelo recurso nativo da AWS chamado *Access Entries*. O próprio EKS gerencia o registro e a autorização do Node Group na API do Kubernetes, eliminando erros manuais de mapeamento interno. O arquivo `aws-auth.yaml` torna-se obsoleto e foi descartado.
* **`remoteAccess: false`**: O acesso remoto (SSH) deve ser desativado. Caso seja ativado, o EKS tentará criar um Security Group dedicado para a porta 22 por meio de chamadas de API externas, o que é imediatamente bloqueado pelo perfil de privilégios da `LabRole`.

##  Gestão de Segredos e Variáveis (`_template`)

Seguindo as boas práticas do pilar de Segurança, o repositório remoto armazena apenas os esqueletos de configuração (`configmap_template.yaml` e `secret_template.yaml`) para evitar a exposição inadvertida de credenciais.

Para o deploy local:

1. Duplique os arquivos removendo o sufixo `_template` para obter os nomes finais: `configmap.yaml` e `secret.yaml`.
2. No `configmap.yaml`, preencha os endpoints reais do RDS, ElastiCache Redis e SQS gerados na sua sessão ativa.
3. No endpoint do RDS, insira estritamente a string de conexão DNS pública (ex: `rds-postgres-auth.xxxxx.us-east-1.rds.amazonaws.com`). **Não inclua a porta `:5432` no final do endereço do endpoint**, pois o código Go está programado para concatenar a porta padrão automaticamente. Adicionar a porta manualmente causará falha de sintaxe (`too many colons in address`) e jogará os pods no estado `CrashLoopBackOff`.
4. No `secret.yaml`, insira os segredos e credenciais base. Caso prefira inserir os valores textuais em formato limpo (texto claro), altere a chave principal de `data:` para `stringData:`, permitindo que o Kubernetes faça a codificação Base64 interna automaticamente.

### 3. Colocar a variável do kube dentro do terminal

Com o contexto local configurado para apontar para o novo cluster (`aws-eks update-kubeconfig`), execute as etapas na sequência correta:

1. **Compilação e Envio de Imagens:** Garanta que as imagens dos cinco microsserviços foram geradas e enviadas ao ECR com o novo Account ID da sessão do lab.
2. **Criação do Namespace:**
```bash
kubectl create namespace togglemaster

```


3. **Implantação via Kustomize:** O arquivo `kustomization.yaml` local deve listar os arquivos reais modificados (sem o sufixo `_template`) e declarar a instrução `namespace: togglemaster` no topo para centralizar e injetar o escopo lógico em todos os recursos de maneira automatizada.
```bash
kubectl apply -k k8s/

```


4. **Monitoramento:**
```bash
kubectl get pods -n togglemaster -w

```