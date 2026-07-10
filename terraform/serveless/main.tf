provider "aws" {
  region = "us-east-1"
}

locals {
  repositories = [
    "auth-service",
    "flag-service",
    "targeting-service",
    "evaluation-service",
    "analytics-service"
  ]
}

resource "aws_ecr_repository" "togglemaster_repos" {
  for_each             = toset(local.repositories)
  name                 = each.key
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = false
  }
}

resource "aws_sqs_queue" "evaluation_queue" {
  name                      = "togglemaster-evaluation-events"
  message_retention_seconds = 86400
}

resource "aws_dynamodb_table" "analytics_table" {
  name           = "ToggleMasterAnalytics"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "event_id"

  attribute {
    name = "event_id"
    type = "S"
  }
}

output "ecr_repository_urls" {
  value       = { for k, v in aws_ecr_repository.togglemaster_repos : k => v.repository_url }
}

output "sqs_queue_url" {
  value       = aws_sqs_queue.evaluation_queue.url
}

output "dynamodb_table_name" {
  value       = aws_dynamodb_table.analytics_table.name
}