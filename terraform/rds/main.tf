provider "aws" {
  region = "us-east-1"
}

variable "db_username" {
  description = "Credencial de utilizador da base de dados"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Palavra-passe da base de dados"
  type        = string
  sensitive   = true
}

resource "aws_db_instance" "rds_auth" {
  identifier             = "rds-postgres-auth"
  engine                 = "postgres"
  engine_version         = "15"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  db_name                = "auth_db"
  username = var.db_username
  password = var.db_password
  skip_final_snapshot    = true
  multi_az               = false
  publicly_accessible    = false
  monitoring_interval    = 0
}

resource "aws_db_instance" "rds_flag" {
  identifier             = "rds-postgres-flag"
  engine                 = "postgres"
  engine_version         = "15"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  db_name                = "flags_db"
  username = var.db_username
  password = var.db_password
  skip_final_snapshot    = true
  multi_az               = false
  publicly_accessible    = false
  monitoring_interval    = 0
}

resource "aws_db_instance" "rds_targeting" {
  identifier             = "rds-postgres-targeting"
  engine                 = "postgres"
  engine_version         = "15"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  db_name                = "targeting_db"
  username = var.db_username
  password = var.db_password
  skip_final_snapshot    = true
  multi_az               = false
  publicly_accessible    = false
  monitoring_interval    = 0
}

output "rds_auth_endpoint" {
  value = aws_db_instance.rds_auth.endpoint
}

output "rds_flag_endpoint" {
  value = aws_db_instance.rds_flag.endpoint
}

output "rds_targeting_endpoint" {
  value = aws_db_instance.rds_targeting.endpoint
}