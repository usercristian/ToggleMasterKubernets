data "aws_db_instance" "auth" {
  db_instance_identifier = "rds-postgres-auth"
}

data "aws_db_instance" "flag" {
  db_instance_identifier = "rds-postgres-flag"
}

data "aws_db_instance" "targeting" {
  db_instance_identifier = "rds-postgres-targeting"
}

data "aws_elasticache_cluster" "redis" {
  cluster_id = "togglemaster-redis"
}