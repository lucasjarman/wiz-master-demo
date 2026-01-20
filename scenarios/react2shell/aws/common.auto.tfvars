# Common configuration for React2Shell scenario
# This file is auto-loaded by Terraform

backend_config_json_path = "../../../infrastructure/backend-config.json"

prefix = "react2shell"

common_tags = {
  Project     = "wiz-master-demo"
  Environment = "Demo"
  ManagedBy   = "Terraform"
  Component   = "react2shell-scenario"
  Scenario    = "React2Shell-RCE"
}

# Application settings
app_name             = "react2shell"
kubernetes_namespace = "react2shell"
