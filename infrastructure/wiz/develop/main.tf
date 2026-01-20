################################################################################
# Wiz Tenant Configuration - Develop Environment
################################################################################

locals {
  backend_config_json = jsondecode(file(var.backend_config_json_path))
  environment         = local.backend_config_json.environment
  random_prefix_id    = local.backend_config_json.random_prefix_id
  name                = "${var.prefix}-${local.environment}"

  kubernetes_connector_name = "${var.prefix}-${local.random_prefix_id}-connector"

  tags = merge(var.common_tags, {
    environment = local.environment
  })
}

################################################################################
# Remote State - Shared Resources
################################################################################

data "terraform_remote_state" "shared_resources" {
  backend = "s3"
  config = {
    bucket = local.backend_config_json.state.bucket
    key    = "infrastructure/shared/aws/terraform.tfstate"
    region = local.backend_config_json.state.region
  }
}

################################################################################
# Wiz Service Account (Dynamically Created)
# This creates a FIRST_PARTY service account for the Kubernetes Connector
################################################################################

resource "wiz_service_account" "eks_cluster" {
  name   = "${local.name}-eks-cluster"
  type   = "FIRST_PARTY"
  scopes = ["read:all"]
}

################################################################################
# Wiz Kubernetes Services (ArgoCD + Wiz Integration)
################################################################################

module "k8s_services" {
  source = "../../../modules/k8s-services"

  prefix           = var.prefix
  random_prefix_id = local.random_prefix_id
  cluster_type     = "EKS"

  # Wiz credentials (dynamically created service account)
  wiz_k8s_integration_client_id       = wiz_service_account.eks_cluster.client_id
  wiz_k8s_integration_client_secret   = wiz_service_account.eks_cluster.client_secret
  wiz_k8s_integration_client_endpoint = var.wiz_client_environment

  # Wiz sensor configuration
  use_wiz_sensor           = var.wiz_sensor_enabled
  wiz_sensor_pull_username = var.tenant_image_pull_username
  wiz_sensor_pull_password = var.tenant_image_pull_password

  # Wiz admission controller
  use_wiz_admission_controller = var.wiz_admission_controller_enabled
}

