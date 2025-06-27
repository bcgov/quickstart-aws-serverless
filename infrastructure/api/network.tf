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
  app_subnet_names   = [for az in local.availability_zones : "${local.environment}-Data-${az}"]
  data_subnet_names  = [for az in local.availability_zones : "${local.environment}-App-${az}"]
  web_security_group_name  = "Web"
  app_security_group_name  = "App"
  data_security_group_name = "Data"
}

data "aws_vpc" "main" {
  filter {
    name = "tag:Name"
    values = [
    local.vpc_name]
  }
}

data "aws_subnets" "web" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }

  filter {
    name   = "tag:Name"
    values = local.web_subnet_names
  }
}

data "aws_subnets" "app" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }

  filter {
    name   = "tag:Name"
    values = local.app_subnet_names
  }
}

data "aws_subnets" "data" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }

  filter {
    name   = "tag:Name"
    values = local.data_subnet_names
  }
}

data "aws_subnet" "web" {
  for_each = toset(data.aws_subnets.web.ids)
  id       = each.value
}

data "aws_subnet" "app" {
  for_each = toset(data.aws_subnets.app.ids)
  id       = each.value
}

data "aws_subnet" "data" {
  for_each = toset(data.aws_subnets.data.ids)
  id       = each.value
}

data "aws_security_group" "web" {
  name = local.web_security_group_name
}

data "aws_security_group" "app" {
  name = local.app_security_group_name
}

data "aws_security_group" "data" {
  name = local.data_security_group_name
}
# Data source for route tables
data "aws_route_tables" "app_route_tables" {
  vpc_id = data.aws_vpc.main.id
}

# ECR API VPC Endpoint
resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = data.aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = data.aws_subnets.app.ids
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = "*"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name = "${var.app_name}-ecr-api-endpoint"
  })
}

# ECR Docker VPC Endpoint
resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = data.aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = data.aws_subnets.app.ids
  security_group_ids  = [aws_security_group.vpc_endpoints.id]

  tags = merge(var.common_tags, {
    Name = "${var.app_name}-ecr-dkr-endpoint"
  })
}


# CloudWatch Logs VPC Endpoint
resource "aws_vpc_endpoint" "logs" {
  vpc_id              = data.aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = data.aws_subnets.app.ids
  security_group_ids  = [aws_security_group.vpc_endpoints.id]

  tags = merge(var.common_tags, {
    Name = "${var.app_name}-logs-endpoint"
  })
}

# Security Group for VPC Endpoints
resource "aws_security_group" "vpc_endpoints" {
  name        = "${var.app_name}-vpc-endpoints-sg"
  description = "Security group for VPC endpoints"
  vpc_id      = data.aws_vpc.main.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.main.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name = "${var.app_name}-vpc-endpoints-sg"
  })
}

