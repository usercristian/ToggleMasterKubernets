#!/bin/bash

set -e

CLUSTER="togglemaster-cluster"
REGION="us-east-1"

echo "Procurando Security Group do cluster ${CLUSTER}..."

SG=$(aws ec2 describe-instances \
    --region ${REGION} \
    --filters "Name=tag:aws:eks:cluster-name,Values=${CLUSTER}" \
    --query "Reservations[*].Instances[*].SecurityGroups[0].GroupId" \
    --output text | head -n1)

if [ -z "$SG" ]; then
    echo "Nenhum Security Group encontrado."
    exit 1
fi

echo ""
echo "======================================"
echo "Security Group encontrado:"
echo ""
echo "$SG"
echo ""
echo "Execute:"
echo ""
echo "terraform apply -var=\"eks_node_security_group=$SG\""
echo "======================================"