include {
  path = find_in_parent_folders()
}
locals {
  app_env    = get_env("app_env")
  api_image  = get_env("api_image")
  target_env = get_env("target_env")
}

# Include the common terragrunt configuration for all modules
generate "test_tfvars" {
  path              = "test.auto.tfvars"
  if_exists         = "overwrite"
  disable_signature = true
  contents          = <<-EOF
  target_env = "test"
  api_image="${local.api_image}"
  app_env="${local.app_env}"
EOF
}