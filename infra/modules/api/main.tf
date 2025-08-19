terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 6.0"
      configuration_aliases = [aws.us-east-1]
    }
  }
}

# -------------------------
# DATA SOURCES (alphabetical)
# -------------------------


data "aws_iam_policy" "appDynamoDB" {
  name = "AmazonDynamoDBFullAccess"
}

data "aws_iam_policy_document" "ecs_task_execution_role" {
  version = "2012-10-17"
  statement {
    sid     = ""
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}


# -------------------------
# LOCALS (alphabetical)
# -------------------------
locals {
  container_name = var.app_name
}

# -------------------------
# MODULES (alphabetical)
# -------------------------
module "api_gateway" {
  source             = "git::https://github.com/bcgov/quickstart-aws-helpers.git//terraform/modules/api-gateway?ref=v0.2.0"
  api_name           = var.app_name
  protocol_type      = "HTTP"
  subnet_ids         = module.networking.subnets.web.ids
  security_group_ids = [module.networking.security_groups.web.id]
  integration_uri    = aws_alb_listener.internal.arn
  route_key          = "ANY /{proxy+}"
  stage_name         = "$default"
  auto_deploy        = true
  tags               = module.common.common_tags
}

module "cloudfront_api" {
  count                              = var.is_public_api ? 1 : 0
  source                             = "git::https://github.com/bcgov/quickstart-aws-helpers.git//terraform/modules/cloudfront?ref=v0.2.0"
  app_name                           = var.app_name
  repo_name                          = var.repo_name
  distribution_type                  = "api"
  enabled                            = true
  api_origin_domain_name             = "${module.api_gateway.api_id}.execute-api.${var.aws_region}.amazonaws.com"
  api_origin_id                      = "http-api-origin"
  api_origin_protocol_policy         = "https-only"
  api_origin_ssl_protocols           = ["TLSv1.2"]
  web_acl_arn                        = module.waf_api[0].web_acl_arn
  enable_logging                     = true
  log_bucket_domain_name             = "${module.cloudfront_api_logs[0].bucket_name}.s3.amazonaws.com"
  log_prefix                         = "cf/api/"
  log_include_cookies                = true
  cache_allowed_methods              = ["GET", "HEAD", "OPTIONS", "POST", "PUT", "DELETE", "PATCH"]
  cache_cached_methods               = ["GET", "HEAD"]
  cache_viewer_protocol_policy       = "https-only"
  cache_min_ttl                      = 0
  cache_default_ttl                  = 60
  cache_max_ttl                      = 60
  cache_forward_query_string         = true
  cache_forward_cookies              = "all"
  geo_restriction_type               = "none"
  use_cloudfront_default_certificate = true
  tags                               = module.common.common_tags
}

module "cloudfront_api_logs" {
  count       = var.is_public_api ? 1 : 0
  source      = "git::https://github.com/bcgov/quickstart-aws-helpers.git//terraform/modules/s3-cloudfront-logs?ref=v0.2.0"
  bucket_name = "cf-api-logs-${var.app_name}"
  log_prefix  = "cf/api/"
  tags        = module.common.common_tags
}

module "common" {
  source      = "git::https://github.com/bcgov/quickstart-aws-helpers.git//terraform/modules/common?ref=v0.2.0"
  target_env  = var.target_env
  app_env     = var.app_env
  app_name    = var.app_name
  repo_name   = var.repo_name
  common_tags = var.common_tags
}

module "networking" {
  source     = "git::https://github.com/bcgov/quickstart-aws-helpers.git//terraform/modules/networking?ref=v0.2.0"
  target_env = var.target_env
}

module "waf_api" {
  count                = var.is_public_api ? 1 : 0
  source               = "git::https://github.com/bcgov/quickstart-aws-helpers.git//terraform/modules/waf?ref=v0.2.0"
  name                 = "${var.app_name}-api-cf-waf"
  description          = "API CloudFront WAF Rules"
  scope                = "CLOUDFRONT"
  enable_rate_limiting = true
  rate_limit           = 50
  enable_ip_reputation = true
  enable_common_rules  = true
  enable_bad_inputs    = true
  enable_linux_rules   = true
  enable_sqli_rules    = true
  tags                 = module.common.common_tags

  providers = {
    aws = aws.us-east-1
  }
}


# -------------------------
# RESOURCES (alphabetical)
# -------------------------
resource "aws_alb" "app-alb" {
  name                             = var.app_name
  internal                         = true
  subnets                          = module.networking.subnets.web.ids
  security_groups                  = [module.networking.security_groups.web.id]
  enable_cross_zone_load_balancing = true
  tags                             = module.common.common_tags

  lifecycle {
    ignore_changes = [access_logs]
  }
  drop_invalid_header_fields = true
}

resource "aws_alb_listener" "internal" {
  load_balancer_arn = aws_alb.app-alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.app.arn
  }
}

resource "aws_alb_target_group" "app" {
  name                 = "${var.app_name}-tg"
  port                 = var.app_port
  protocol             = "HTTP"
  vpc_id               = module.networking.vpc.id
  target_type          = "ip"
  deregistration_delay = 30

  health_check {
    healthy_threshold   = "2"
    interval            = "30"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "3"
    path                = var.health_check_path
    unhealthy_threshold = "2"
  }

  tags = module.common.common_tags
}

resource "aws_appautoscaling_policy" "api_down" {
  name               = "${var.app_name}-scale-down"
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.ecs_cluster.name}/${aws_ecs_service.node_api_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Maximum"

    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = -1
    }
  }

  depends_on = [aws_appautoscaling_target.api_target]
}

resource "aws_appautoscaling_policy" "api_up" {
  name               = "${var.app_name}-scale-up"
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.ecs_cluster.name}/${aws_ecs_service.node_api_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Maximum"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 2
    }
  }

  depends_on = [aws_appautoscaling_target.api_target]
}

resource "aws_appautoscaling_target" "api_target" {
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.ecs_cluster.name}/${aws_ecs_service.node_api_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = var.min_capacity
  max_capacity       = var.max_capacity
}

resource "aws_cloudwatch_metric_alarm" "node_api_service_cpu_high" {
  alarm_name          = "${var.app_name}_cpu_utilization_high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "3"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "10"
  statistic           = "Maximum"
  threshold           = "60"

  dimensions = {
    ClusterName = aws_ecs_cluster.ecs_cluster.name
    ServiceName = aws_ecs_service.node_api_service.name
  }

  alarm_actions = [aws_appautoscaling_policy.api_up.arn]
  tags          = module.common.common_tags
}

resource "aws_cloudwatch_metric_alarm" "node_api_service_cpu_low" {
  alarm_name          = "${var.app_name}_cpu_utilization_low"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "30"
  statistic           = "Maximum"
  threshold           = "25"

  dimensions = {
    ClusterName = aws_ecs_cluster.ecs_cluster.name
    ServiceName = aws_ecs_service.node_api_service.name
  }

  alarm_actions = [aws_appautoscaling_policy.api_down.arn]
  tags          = module.common.common_tags
}

resource "aws_ecs_cluster" "ecs_cluster" {
  name = var.app_name
  tags = module.common.common_tags
}

resource "aws_ecs_cluster_capacity_providers" "ecs_cluster_capacity_providers" {
  cluster_name = aws_ecs_cluster.ecs_cluster.name

  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE_SPOT"
  }
}

resource "aws_ecs_service" "node_api_service" {
  name                              = var.app_name
  cluster                           = aws_ecs_cluster.ecs_cluster.id
  task_definition                   = aws_ecs_task_definition.node_api_task.arn
  desired_count                     = 1
  health_check_grace_period_seconds = 60

  capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 80
  }
  capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 20
    base              = 1
  }

  network_configuration {
    security_groups  = [module.networking.security_groups.app.id]
    subnets          = module.networking.subnets.app.ids
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.app.id
    container_name   = local.container_name
    container_port   = var.app_port
  }
  wait_for_steady_state = true
  depends_on            = [aws_iam_role_policy_attachment.ecs_task_execution_role]
  tags                  = module.common.common_tags
}


resource "aws_ecs_task_definition" "node_api_task" {
  family                   = var.app_name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.api_cpu
  memory                   = var.api_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.app_container_role.arn
  container_definitions = jsonencode([{
    name      = local.container_name
    image     = var.api_image
    essential = true
    environment = [
      {
        name  = "DYNAMODB_TABLE_NAME"
        value = var.dynamodb_table_name
      },
      {
        name  = "AWS_REGION"
        value = var.aws_region
      },
      {
        name  = "NODE_ENV"
        value = "production"
      },
      {
        name  = "PORT"
        value = "3000"
      }
    ]
    portMappings = [{
      protocol      = "tcp"
      containerPort = var.app_port
      hostPort      = var.app_port
    }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-create-group  = "true"
        awslogs-group         = "/ecs/${var.app_name}/api"
        awslogs-region        = var.aws_region
        awslogs-stream-prefix = "ecs"
      }
    }
    mountPoints = []
    volumesFrom = []
  }])
  lifecycle {
    create_before_destroy = true
  }
  tags = module.common.common_tags
}

resource "aws_iam_role" "app_container_role" {
  name = "${var.app_name}_container_role"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
                "Service": "ecs-tasks.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF

  tags = module.common.common_tags
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "${var.app_name}_ecs_role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_execution_role.json
  tags               = module.common.common_tags
}

resource "aws_iam_role_policy" "app_container_cwlogs" {
  name = "${var.app_name}_container_cwlogs"
  role = aws_iam_role.app_container_role.id

  policy = <<-EOF
    {
            "Version": "2012-10-17",
            "Statement": [
                    {
                            "Effect": "Allow",
                            "Action": [
                                    "logs:CreateLogGroup",
                                    "logs:CreateLogStream",
                                    "logs:PutLogEvents",
                                    "logs:DescribeLogStreams"
                            ],
                            "Resource": [
                                    "arn:aws:logs:*:*:*"
                            ]
                    }
            ]
    }
EOF
}

resource "aws_iam_role_policy" "ecs_task_execution_cwlogs" {
  name = "${var.app_name}-ecs_cwlogs"
  role = aws_iam_role.ecs_task_execution_role.id

  policy = <<-EOF
    {
            "Version": "2012-10-17",
            "Statement": [
                    {
                            "Effect": "Allow",
                            "Action": [
                                    "logs:CreateLogGroup"
                            ],
                            "Resource": [
                                    "arn:aws:logs:*:*:*"
                            ]
                    }
            ]
    }
EOF
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "dynamodbAttach" {
  role       = aws_iam_role.app_container_role.name
  policy_arn = data.aws_iam_policy.appDynamoDB.arn
}
