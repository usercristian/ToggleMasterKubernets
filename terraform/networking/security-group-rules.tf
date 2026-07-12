#########################################
# AUTH RDS
#########################################

resource "aws_vpc_security_group_ingress_rule" "auth_postgres" {

  security_group_id = data.aws_db_instance.auth.vpc_security_groups[0]

  referenced_security_group_id = var.eks_node_security_group

  ip_protocol = "tcp"

  from_port = 5432
  to_port   = 5432
}

#########################################
# FLAG RDS
#########################################

resource "aws_vpc_security_group_ingress_rule" "flag_postgres" {

  security_group_id = data.aws_db_instance.flag.vpc_security_groups[0]

  referenced_security_group_id = var.eks_node_security_group

  ip_protocol = "tcp"

  from_port = 5432
  to_port   = 5432
}

#########################################
# TARGETING RDS
#########################################

resource "aws_vpc_security_group_ingress_rule" "targeting_postgres" {

  security_group_id = data.aws_db_instance.targeting.vpc_security_groups[0]

  referenced_security_group_id = var.eks_node_security_group

  ip_protocol = "tcp"

  from_port = 5432
  to_port   = 5432
}

#########################################
# REDIS
#########################################

resource "aws_vpc_security_group_ingress_rule" "redis" {

  security_group_id = tolist(data.aws_elasticache_cluster.redis.security_group_ids)[0]

  referenced_security_group_id = var.eks_node_security_group

  ip_protocol = "tcp"

  from_port = 6379
  to_port   = 6379
}