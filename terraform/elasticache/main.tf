provider "aws" {
  region = "us-east-1"
}

data "aws_vpc" "default" {
  default = true
}

resource "aws_security_group" "redis" {

  name = "togglemaster-redis-sg"

  description = "Redis SG"

  vpc_id = data.aws_vpc.default.id

  ingress {

    from_port = 6379
    to_port   = 6379
    protocol  = "tcp"

    cidr_blocks = []

  }

  egress {

    from_port = 0
    to_port   = 0
    protocol  = "-1"

    cidr_blocks = ["0.0.0.0/0"]

  }

}

resource "aws_elasticache_cluster" "redis_cache" {
  cluster_id           = "togglemaster-redis"
  engine               = "redis"
  node_type            = "cache.t3.micro"
  num_cache_nodes      = 1
  port                 = 6379
  apply_immediately    = true
  security_group_ids = [
    aws_security_group.redis.id
]
}

output "redis_endpoint" {
  value = aws_elasticache_cluster.redis_cache.cache_nodes[0].address
}