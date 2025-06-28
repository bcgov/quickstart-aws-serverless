variable "target_env" {
  description = "AWS workload account env"
  type        = string
}

variable "app_name" {
  description = "Name for the application"
  type        = string
}

variable "app_env" {
  description = "The environment for the app, since multiple instances can be deployed to same dev environment of AWS, this represents whether it is PR or dev or test"
  type        = string
}

variable "common_tags" {
  description = "Common tags to be applied to resources"
  type        = map(string)
  default     = {}
}

variable "repo_name" {
  description = "Name of the repository for resource descriptions and tags"
  type        = string
}