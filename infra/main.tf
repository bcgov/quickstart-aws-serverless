# -------------------------------------------------------------------
# Database Module (First)
# -------------------------------------------------------------------
module "database" {
  source = "./modules/database"

  app_env             = var.app_env
  app_name            = var.app_name
  common_tags         = var.common_tags
  dynamodb_table_name = var.dynamodb_table_name
  repo_name           = var.repo_name
  target_env          = var.target_env
}

# -------------------------------------------------------------------
# API Module (Second)
# -------------------------------------------------------------------
module "api" {
  source = "./modules/api"

  api_cpu             = var.api_cpu
  api_image           = var.api_image
  api_memory          = var.api_memory
  app_env             = var.app_env
  app_name            = var.app_name
  app_port            = var.app_port
  aws_region          = var.aws_region
  common_tags         = var.common_tags
  dynamodb_table_name = var.dynamodb_table_name
  health_check_path   = var.health_check_path
  is_public_api       = var.is_public_api
  max_capacity        = var.api_max_capacity
  min_capacity        = var.api_min_capacity
  repo_name           = var.repo_name
  target_env          = var.target_env

  providers = {
    aws.us-east-1 = aws.us-east-1
  }

  depends_on = [module.database]
}

# -------------------------------------------------------------------
# Frontend Module (Third)
# -------------------------------------------------------------------
module "frontend" {
  source = "./modules/frontend"

  app_env     = var.app_env
  app_name    = var.app_name
  common_tags = var.common_tags
  repo_name   = var.repo_name
  target_env  = var.target_env

  providers = {
    aws.us-east-1 = aws.us-east-1
  }

  depends_on = [module.api]
}
