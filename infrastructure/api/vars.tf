variable "target_env" {
  description = "AWS workload account env"
  type        = string
}
variable "app_env" {
  description = "The environment for the app, since multiple instances can be deployed to same dev environment of AWS, this represents whether it is PR or dev or test"
  type        = string
}

variable "stack_prefix" {
  description = "The stack prefix for resource naming"
  type        = string
}

variable "aws_license_plate" {
  description = "The AWS license plate identifier"
  type        = string
}

# DynamoDB configuration (replacing PostgreSQL variables)
variable "dynamodb_table_name" {
  description = "Name of the DynamoDB table"
  type        = string
  default     = ""
}

variable "subnet_app_a" {
  description = "Value of the name tag for a subnet in the APP security group"
  type = string
  default = "App_Dev_aza_net"
}

variable "subnet_app_b" {
  description = "Value of the name tag for a subnet in the APP security group"
  type = string
  default = "App_Dev_azb_net"
}
variable "subnet_web_a" {
  description = "Value of the name tag for a subnet in the APP security group"
  type = string
  default = "Web_Dev_aza_net"
}

variable "subnet_web_b" {
  description = "Value of the name tag for a subnet in the APP security group"
  type = string
  default = "Web_Dev_azb_net"
}


# Networking Variables
variable "subnet_data_a" {
  description = "Value of the name tag for a subnet in the DATA security group"
  type = string
  default = "Data_Dev_aza_net"
}

variable "subnet_data_b" {
  description = "Value of the name tag for a subnet in the DATA security group"
  type = string
  default = "Data_Dev_azb_net"
}

variable "app_port" {
  description = "The port of the API container"
  type        = number
  default     = 3000
}
variable "app_name" {
  description  = " The APP name with environment (app_env)"
  type        = string
}
variable "common_tags" {
  description = "Common tags to be applied to resources"
  type        = map(string)
  default     = {}
}
# Note: Flyway variables removed as DynamoDB doesn't require migrations
variable "api_image" {
  description = "The image for the API container"
  type        = string
}
variable "health_check_path" {
  description = "The path for the health check"
  type        = string
  default     = "/api/health"
  
}

variable "api_cpu" {
  type = number
  default     = "256"
}
variable "api_memory" {
  type = number
  default     = "512"
}
variable "aws_region" {
  type = string
  default = "ca-central-1"
}


variable "is_public_api" {
  description = "Flag to indicate if the API is public or private"
  type        = bool
  default     = true
}

variable "dynamodb_table_name" {
  description = "The name of the DynamoDB table"
  type        = string
}

variable "dynamodb_read_capacity" {
  description = "The read capacity units for the DynamoDB table"
  type        = number
  default     = 5
}

variable "dynamodb_write_capacity" {
  description = "The write capacity units for the DynamoDB table"
  type        = number
  default     = 5
}

variable "dynamodb_partition_key" {
  description = "The partition key for the DynamoDB table"
  type        = string
}

variable "dynamodb_sort_key" {
  description = "The sort key for the DynamoDB table (optional)"
  type        = string
  default     = ""
}

variable "dynamodb_billing_mode" {
  description = "The billing mode for the DynamoDB table. Can be PROVISIONED or PAY_PER_REQUEST."
  type        = string
  default     = "PROVISIONED"
}

variable "dynamodb_stream_enabled" {
  description = "Flag to enable DynamoDB Streams"
  type        = bool
  default     = false
}

variable "dynamodb_stream_view_type" {
  description = "The view type for the DynamoDB stream. Can be NEW_IMAGE, OLD_IMAGE, NEW_AND_OLD_IMAGES, or KEYS_ONLY."
  type        = string
  default     = "NEW_IMAGE"
}