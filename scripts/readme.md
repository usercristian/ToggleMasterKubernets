# Documentacao dos Scripts de Automacao

Este diretorio contem os scripts auxiliares para provisionamento, teste e deploy do projeto ToggleMaster. A utilizacao destes scripts agiliza a operacao e garante a padronizacao das execucoes no ambiente AWS Academy.

## Pre-requisitos

Antes de executar qualquer script deste diretorio, certifique-se de que o seu ambiente local possui:
- AWS CLI configurado e autenticado com as credenciais ativas da sua sessao.
- Kubectl configurado apontando para o cluster EKS atualizado.
- Motor de conteineres (Podman ou Docker) instalado e em execucao.

## Arquivos e Responsabilidades

pushecr
Automatiza a construcao (build) das imagens dos microsservicos e realiza o envio (push) para o AWS Elastic Container Registry (ECR). Ele identifica automaticamente o motor de conteineres disponivel no sistema, extrai o ID da conta AWS ativa e autentica no registro da nuvem antes de iniciar o processo de envio.

gerar_secrets.sh
Gera as credenciais e os arquivos de variaveis sensiveis necessarios para o provisionamento do banco de dados relacional. Este script prepara o terreno para a execucao do Terraform no modulo do RDS.

testar_comunicacao.sh
Valida a conectividade de rede e a comunicacao entre os componentes da infraestrutura, garantindo que as regras de seguranca e os ingressos do Kubernetes estao respondendo adequadamente.

escalabilidade.sh
Executa rotinas de teste de carga contra os endpoints do cluster EKS. O objetivo e simular um pico de acesso para acionar e validar o comportamento do Horizontal Pod Autoscaler (HPA) e a alocacao de novos pods nos worker nodes.

carga.log
Arquivo de texto gerado dinamicamente que armazena os registros e metricas de saida durante a execucao do script de teste de escalabilidade.

sgnode.sh
Pega o security para criar o networking via terraform

## Como Utilizar

Navegue ate o diretorio scripts:
cd scripts/

Conceda permissao de execucao para os scripts:
chmod +x *.sh

Execute o script desejado:
./nomedoscript