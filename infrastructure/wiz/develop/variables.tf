################################################################################
# Wiz Tenant Configuration - Variables
################################################################################

variable "backend_config_json_path" {
  description = "Path to the backend configuration JSON file"
  type        = string
}

variable "prefix" {
  description = "Prefix for resource naming"
  type        = string
  default     = "wiz-demo"
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "React2Shell"
    Environment = "Demo"
    ManagedBy   = "Terraform"
  }
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-2"
}

# -----------------------------------------------------------------------------
# Wiz Client Environment (for clientEndpoint)
# -----------------------------------------------------------------------------
variable "wiz_client_environment" {
  description = "Wiz client environment for the Kubernetes Connector. Options: prod, commercial, demo"
  type        = string
  default     = "prod"
}

# -----------------------------------------------------------------------------
# Wiz Sensor Configuration
# -----------------------------------------------------------------------------
variable "wiz_sensor_enabled" {
  description = "Whether to deploy Wiz runtime sensor"
  type        = bool
  default     = true
}

variable "wiz_admission_controller_enabled" {
  description = "Whether to deploy Wiz admission controller"
  type        = bool
  default     = false
}

variable "tenant_image_pull_username" {
  description = "Username for pulling Wiz sensor images (from 1Password wizautesting/Username)"
  type        = string
  sensitive   = true
}

variable "tenant_image_pull_password" {
  description = "Password for pulling Wiz sensor images (from 1Password wizautesting/Password)"
  type        = string
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Deployment Toggles
# -----------------------------------------------------------------------------
variable "create_eks_services_deployment" {
  description = "Whether to create EKS services (ArgoCD, Wiz K8s connector, sensor). Set to false if EKS cluster doesn't exist yet."
  type        = bool
  default     = true
}

variable "create_aws_connector" {
  description = "Whether to create the Wiz AWS Cloud Connector. Requires wiz_trusted_arn to be set in shared/aws."
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# AWS Connector Configuration
# -----------------------------------------------------------------------------
variable "aws_connector_config" {
  type = object({
    audit_log_enabled   = optional(bool, true)
    network_log_enabled = optional(bool, true)
    dns_log_enabled     = optional(bool, true)
  })
  description = "Configuration for the Wiz AWS Connector cloud events monitoring"
  default     = {}
}

