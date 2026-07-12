output "auth_security_group" {
  value = data.aws_db_instance.auth.vpc_security_groups[0]
}

output "flag_security_group" {
  value = data.aws_db_instance.flag.vpc_security_groups[0]
}

output "targeting_security_group" {
  value = data.aws_db_instance.targeting.vpc_security_groups[0]
}

output "redis_security_group" {
  value = tolist(data.aws_elasticache_cluster.redis.security_group_ids)[0]
}