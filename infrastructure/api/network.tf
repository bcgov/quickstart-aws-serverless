locals {
  env_map = {
    dev     = "Dev"
    test    = "Test"
    prod    = "Prod"
    tools   = "Tools"
    unclass = "UnClass"
  }
  environment        = local.env_map[lower(var.target_env)]
  vpc_name           = "${local.environment}"
  availability_zones = ["A", "B"]
  web_subnet_names   = [for az in local.availability_zones : "${local.environment}-Web-MainTgwAttach-${az}"]
  app_subnet_names   = [for az in local.availability_zones : "${local.environment}-App-${az}"]
  data_subnet_names  = [for az in local.availability_zones : "${local.environment}-Data-${az}"]
  web_security_group_name  = "Web"
  app_security_group_name  = "App"
  data_security_group_name = "Data"
}

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

