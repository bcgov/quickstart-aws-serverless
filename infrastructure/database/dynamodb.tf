# Import common configurations
module "common" {
  source = "../modules/common"
  
  target_env    = var.target_env
  app_env       = var.app_env
  app_name      = var.app_name
  repo_name     = var.repo_name
  common_tags   = var.common_tags
}

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
    enabled = module.common.is_production
  }

  # Server-side encryption
  server_side_encryption {
    enabled = true
  }

  # Deletion protection for production
  deletion_protection_enabled = module.common.is_production

  tags = module.common.common_tags
}
# DynamoDB initial data using the aws_dynamodb_table_item resource, remove if not needed
resource "aws_dynamodb_table_item" "user_items" {
    for_each = {
        "1" = { name = "John", email = "John.ipsum@test.com" }
        "2" = { name = "Jane", email = "Jane.ipsum@test.com" }
        "3" = { name = "Jack", email = "Jack.ipsum@test.com" }
        "4" = { name = "Jill", email = "Jill.ipsum@test.com" }
        "5"  = { name = "Joe",  email = "Joe.ipsum@test.com" }
    }

    table_name = aws_dynamodb_table.users_table.name
    hash_key   = aws_dynamodb_table.users_table.hash_key

    item = jsonencode({
        id    = { S = each.key }
        name  = { S = each.value.name }
        email = { S = each.value.email }
    })
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
