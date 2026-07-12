#!/bin/bash

set -e

REGION="us-east-1"
CLUSTER_NAME="togglemaster-cluster"

echo "========================================="
echo "Configurando Security Groups"
echo "Cluster: $CLUSTER_NAME"
echo "Região : $REGION"
echo "========================================="

############################################
# Descobrir Node Group
############################################

NODEGROUP=$(aws eks list-nodegroups \
    --cluster-name "$CLUSTER_NAME" \
    --region "$REGION" \
    --query "nodegroups[0]" \
    --output text)

if [ "$NODEGROUP" = "None" ] || [ -z "$NODEGROUP" ]; then
    echo "ERRO: Nenhum Node Group encontrado."
    exit 1
fi

echo "NodeGroup encontrado:"
echo "$NODEGROUP"

############################################
# Descobrir uma EC2 do Node Group
############################################

INSTANCE_ID=$(aws ec2 describe-instances \
    --region "$REGION" \
    --filters \
        "Name=tag:eks:cluster-name,Values=$CLUSTER_NAME" \
        "Name=instance-state-name,Values=running" \
    --query "Reservations[0].Instances[0].InstanceId" \
    --output text)

if [ "$INSTANCE_ID" = "None" ] || [ -z "$INSTANCE_ID" ]; then
    echo "ERRO: Nenhum Worker Node encontrado."
    exit 1
fi

echo
echo "Instância encontrada:"
echo "$INSTANCE_ID"

############################################
# Descobrir SG dos Workers
############################################

WORKER_SG=$(aws ec2 describe-instances \
    --region "$REGION" \
    --instance-ids "$INSTANCE_ID" \
    --query "Reservations[0].Instances[0].SecurityGroups[0].GroupId" \
    --output text)

echo
echo "Security Group dos Workers:"
echo "$WORKER_SG"

############################################
# Descobrir SG dos RDS
############################################

AUTH_SG=$(aws rds describe-db-instances \
    --region "$REGION" \
    --db-instance-identifier rds-postgres-auth \
    --query "DBInstances[0].VpcSecurityGroups[0].VpcSecurityGroupId" \
    --output text)

FLAG_SG=$(aws rds describe-db-instances \
    --region "$REGION" \
    --db-instance-identifier rds-postgres-flag \
    --query "DBInstances[0].VpcSecurityGroups[0].VpcSecurityGroupId" \
    --output text)

TARGETING_SG=$(aws rds describe-db-instances \
    --region "$REGION" \
    --db-instance-identifier rds-postgres-targeting \
    --query "DBInstances[0].VpcSecurityGroups[0].VpcSecurityGroupId" \
    --output text)

############################################
# Descobrir SG Redis
############################################

REDIS_SG=$(aws elasticache describe-cache-clusters \
    --region "$REGION" \
    --show-cache-node-info \
    --query "CacheClusters[?CacheClusterId=='togglemaster-redis'].SecurityGroups[0].SecurityGroupId" \
    --output text)

echo
echo "========================================="
echo "Liberando acesso aos bancos..."
echo "========================================="

add_rule () {

SG=$1
PORT=$2

aws ec2 authorize-security-group-ingress \
    --region "$REGION" \
    --group-id "$SG" \
    --protocol tcp \
    --port "$PORT" \
    --source-group "$WORKER_SG" \
    >/dev/null 2>&1 || true

}

add_rule "$AUTH_SG" 5432
add_rule "$FLAG_SG" 5432
add_rule "$TARGETING_SG" 5432
add_rule "$REDIS_SG" 6379

echo
echo "========================================="
echo "Rede configurada com sucesso!"
echo "========================================="

echo
echo "Worker SG:"
echo "$WORKER_SG"

echo
echo "RDS Auth SG:"
echo "$AUTH_SG"

echo
echo "RDS Flag SG:"
echo "$FLAG_SG"

echo
echo "RDS Targeting SG:"
echo "$TARGETING_SG"

echo
echo "Redis SG:"
echo "$REDIS_SG"