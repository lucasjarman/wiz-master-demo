# Common configuration for Wiz tenant (develop environment)
# This file is auto-loaded by Terraform

backend_config_json_path = "../../../infrastructure/backend-config.json"

prefix = "wiz-demo"

common_tags = {
  Project     = "wiz-master-demo"
  Environment = "Demo"
  ManagedBy   = "Terraform"
  Component   = "wiz-tenant"
}

# Wiz client environment (prod, commercial, demo)
wiz_client_environment = "prod"

# Wiz sensor configuration
wiz_sensor_enabled               = true
wiz_admission_controller_enabled = false

# Deployment toggles
# Set to false if EKS cluster doesn't exist yet
create_eks_services_deployment = true

# Set to true to create the AWS Cloud Connector
# Requires wiz_trusted_arn and wiz_tenant_id to be set via environment variables
create_aws_connector = true
