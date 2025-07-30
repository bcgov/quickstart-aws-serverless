variable "api_cpu" {
  type     = number
  nullable = false
}

variable "api_image" {
  description = "The image for the API container"
  type        = string
  nullable    = false
}

variable "api_memory" {
  type     = number
  nullable = false
}

variable "app_env" {
  description = "The environment for the app, since multiple instances can be deployed to same dev environment of AWS, this represents whether it is PR or dev or test"
  type        = string
  nullable    = false
}

variable "app_name" {
  description = " The APP name with environment (app_env)"
  type        = string
  nullable    = false
}

variable "app_port" {
  description = "The port of the API container"
  type        = number
  nullable    = false
}

variable "aws_region" {
  type     = string
  nullable = false
}

variable "common_tags" {
  description = "Common tags to be applied to resources"
  type        = map(string)
  nullable    = false
}

variable "dynamodb_table_name" {
  description = "Name of the DynamoDB table"
  type        = string
  nullable    = false
}


variable "health_check_path" {
  description = "The path for the health check"
  type        = string
  nullable    = false
}

variable "is_public_api" {
  description = "Flag to indicate if the API is public or private"
  type        = bool
  nullable    = false
}

variable "max_capacity" {
  description = "The maximum tasks to run for the API."
  type        = number
  nullable    = false
}

variable "min_capacity" {
  description = "The minimum tasks to run for the API."
  type        = number
  nullable    = false
}


variable "repo_name" {
  description = "Name of the repository for resource descriptions and tags"
  type        = string
  nullable    = false
}


variable "target_env" {
  description = "AWS workload account env"
  type        = string
  nullable    = false
}

