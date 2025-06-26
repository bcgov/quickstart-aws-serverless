# Use the common networking module instead of duplicating all networking code
# This module is already imported in api-gateway.tf as module.networking
# So this file can be empty or removed as networking is handled by the module

# If you need to reference networking data sources directly in this file,
# you can access them through the module outputs:
# module.networking.vpc.id
# module.networking.subnets.web.ids
# module.networking.security_groups.web.id
# etc.

# For compatibility with existing ALB and ECS resources that reference data sources,
# create aliases to the module outputs. The networking module is imported in api-gateway.tf
# Note: Some resources may need to be updated to reference module.networking directly

# Import networking module here for this file to use
module "networking_local" {
  source = "../modules/networking"
  
  target_env = var.target_env
}

# Compatibility data sources for existing resource references
data "aws_vpc" "main" {
  id = module.networking_local.vpc.id
}

data "aws_subnets" "web" {
  filter {
    name   = "subnet-id"
    values = module.networking_local.subnets.web.ids
  }
}

data "aws_subnets" "app" {
  filter {
    name   = "subnet-id"
    values = module.networking_local.subnets.app.ids
  }
}

data "aws_subnets" "data" {
  filter {
    name   = "subnet-id"
    values = module.networking_local.subnets.data.ids
  }
}

data "aws_security_group" "web" {
  id = module.networking_local.security_groups.web.id
}

data "aws_security_group" "app" {
  id = module.networking_local.security_groups.app.id
}

data "aws_security_group" "data" {
  id = module.networking_local.security_groups.data.id
}
