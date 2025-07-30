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

variable "target_env" {
  description = "AWS workload account env"
  type        = string
  nullable    = false
}
