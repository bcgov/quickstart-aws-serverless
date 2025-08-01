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
