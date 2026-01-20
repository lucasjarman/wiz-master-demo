# Common configuration for shared AWS infrastructure
# This file is auto-loaded by Terraform

backend_config_json_path = "../../../infrastructure/backend-config.json"

prefix = "wiz-demo"

common_tags = {
  Project     = "wiz-master-demo"
  Environment = "Demo"
  ManagedBy   = "Terraform"
  Component   = "shared-infrastructure"
}
