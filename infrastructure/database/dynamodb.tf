# DynamoDB Table for Users
resource "aws_dynamodb_table" "users_table" {
  name           = "${var.app_name}-users-${var.app_env}"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }

  attribute {
    name = "email"
    type = "S"
  }

  # Global Secondary Index for email lookups
  global_secondary_index {
    name            = "EmailIndex"
    hash_key        = "email"
    projection_type = "ALL"
  }

  # Enable point-in-time recovery for production environments
  point_in_time_recovery {
    enabled = contains(["prod"], var.app_env) ? true : false
  }

  # Server-side encryption
  server_side_encryption {
    enabled = true
  }

  # Deletion protection for production
  deletion_protection_enabled = contains(["prod"], var.app_env) ? true : false

  tags = {
    managed-by = "terraform"
    Name       = "${var.app_name}-users-${var.app_env}"
    Environment = var.app_env
  }
}

# Output the DynamoDB table name and ARN for use in other modules
output "dynamodb_table_name" {
  description = "Name of the DynamoDB table"
  value       = aws_dynamodb_table.users_table.name
}

output "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table"
  value       = aws_dynamodb_table.users_table.arn
}

output "dynamodb_endpoint" {
  description = "DynamoDB endpoint URL"
  value       = aws_dynamodb_table.users_table.end
  
}
