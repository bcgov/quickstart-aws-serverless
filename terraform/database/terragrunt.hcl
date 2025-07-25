terraform {
  source = "../../..//infrastructure//database"
}



locals {
  region       = "ca-central-1"
  stack_prefix = get_env("stack_prefix")
  # Terraform remote S3 config
  tf_remote_state_prefix = "terraform-remote-state" # Do not change this, given by cloud.pathfinder.
  target_env             = get_env("target_env")    # this is the target environment of AWS, like dev, test, prod
  aws_license_plate      = get_env("aws_license_plate")
  app_env                = get_env("app_env") # this is the environment for the app, like PR, dev, test, since same AWS dev can be reused for both dev and test
  statefile_bucket_name  = "${local.tf_remote_state_prefix}-${local.aws_license_plate}-${local.target_env}"
  statefile_key          = "${local.stack_prefix}/${local.app_env}/database/dynamodb/terraform.tfstate"
  statelock_table_name   = "${local.tf_remote_state_prefix}-lock-${local.aws_license_plate}"
  repo_name              = get_env("repo_name")
}

# Remote S3 state for Terraform.
generate "remote_state" {
  path      = "backend.tf"
  if_exists = "overwrite"
  contents  = <<EOF
terraform {
  backend "s3" {
    bucket         = "${local.statefile_bucket_name}"
    key            = "${local.statefile_key}"            # Path and name of the state file within the bucket
    region         = "${local.region}"                    # AWS region where the bucket is located
    dynamodb_table = "${local.statelock_table_name}"
    encrypt        = true
    use_lockfile   = true  # Enable native S3 locking
  }
}
EOF
}


generate "tfvars" {
  path              = "terragrunt.auto.tfvars"
  if_exists         = "overwrite"
  disable_signature = true
  contents          = <<-EOF
    app_name = "${local.stack_prefix}"
    app_env = "${local.app_env}"
    common_tags = {
      "Environment" = "${local.target_env}"
      "AppEnv"      = "${local.app_env}"
      "AppName"     = "${local.stack_prefix}"
      "RepoName"    = "${local.repo_name}"
      "ManagedBy"   = "Terraform"
    }
    repo_name="${local.repo_name}"
EOF
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite"
  contents  = <<EOF
provider "aws" {
  region  = "${local.region}"
}
EOF
}