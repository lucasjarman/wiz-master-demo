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

