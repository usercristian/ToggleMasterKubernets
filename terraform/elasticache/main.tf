provider "aws" {
  region = "us-east-1"
}

resource "aws_elasticache_cluster" "redis_cache" {
  cluster_id           = "togglemaster-redis"
  engine               = "redis"
  node_type            = "cache.t3.micro"
  num_cache_nodes      = 1
  port                 = 6379
  apply_immediately    = true
}

output "redis_endpoint" {
  value = aws_elasticache_cluster.redis_cache.cache_nodes[0].address
}