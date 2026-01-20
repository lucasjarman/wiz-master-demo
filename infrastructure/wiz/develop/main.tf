################################################################################
# Wiz Tenant Configuration - Develop Environment
################################################################################

locals {
  backend_config_json = jsondecode(file(var.backend_config_json_path))
  environment         = local.backend_config_json.environment
  suffix              = local.backend_config_json.suffix
  name                = "${var.prefix}-${local.environment}"

  kubernetes_connector_name = "${var.prefix}-${local.suffix}-connector"
  aws_connector_name        = "${var.prefix}-${local.suffix}-aws-connector"
  tenant_short_name         = "develop" # Used for looking up tenant-specific resources

  # Get the customer role ARN from shared resources (created by wiz_aws_permissions module)
  customer_role_arn = try(
    data.terraform_remote_state.shared_resources.outputs.wiz_permission_object_map[local.tenant_short_name].role_arn,
    null
  )

  # CloudTrail and VPC Flow Logs bucket names from shared resources
  cloudtrail_bucket = try(
    data.terraform_remote_state.shared_resources.outputs.cloudtrail_bucket_name,
    null
  )
  vpc_flow_log_bucket = try(
    data.terraform_remote_state.shared_resources.outputs.flow_logs_bucket_name,
    null
  )

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
  count  = var.create_eks_services_deployment ? 1 : 0
  source = "../../../modules/k8s-services"

  prefix           = var.prefix
  random_prefix_id = local.suffix
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

################################################################################
# Wiz AWS Connector
################################################################################
# Creates the AWS Cloud Connector in Wiz using the IAM role from shared resources.
# This connector enables Wiz to scan the AWS account for security issues.

module "wiz_aws_connector" {
  count  = var.create_aws_connector ? 1 : 0
  source = "../../../modules/wiz/aws-connector"

  connector_name         = local.aws_connector_name
  customer_role_arn      = local.customer_role_arn
  skip_organization_scan = true

  # Enable cloud events for Wiz Defend
  audit_log_monitor_enabled   = var.aws_connector_config.audit_log_enabled
  network_log_monitor_enabled = var.aws_connector_config.network_log_enabled
  dns_log_monitor_enabled     = var.aws_connector_config.dns_log_enabled

  scheduled_scanning_settings = {
    enabled                         = true
    public_buckets_scanning_enabled = true
  }

  # CloudTrail configuration for Wiz Defend
  cloud_trail_config = local.cloudtrail_bucket != null ? {
    bucket_name = local.cloudtrail_bucket
    notifications_sqs_options = {
      region             = try(data.terraform_remote_state.shared_resources.outputs.cloudtrail_bucket_region, null)
      override_queue_url = try(data.terraform_remote_state.shared_resources.outputs.wiz_events_object_map[local.tenant_short_name].sqs_queue_url, null)
    }
  } : {}

  # VPC Flow Logs configuration for Wiz Defend
  vpc_flow_log_config = local.vpc_flow_log_bucket != null ? {
    bucket_name = local.vpc_flow_log_bucket
    notifications_sqs_options = {
      region             = try(data.terraform_remote_state.shared_resources.outputs.vpc_flow_logs_bucket_region, null)
      override_queue_url = try(data.terraform_remote_state.shared_resources.outputs.vpc_flow_logs_object_map[local.tenant_short_name].sqs_queue_url, null)
    }
  } : {}
}

