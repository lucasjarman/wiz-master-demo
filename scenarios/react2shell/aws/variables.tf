################################################################################
# React2Shell RCE Demo Scenario - Variables
################################################################################

variable "backend_config_json_path" {
  description = "Path to the backend configuration JSON file"
  type        = string
}

variable "prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "wiz-rsc-demo"
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
  description = "AWS region for resources"
  type        = string
  default     = "ap-southeast-2"
}

variable "kubernetes_namespace" {
  description = "Kubernetes namespace for the vulnerable application"
  type        = string
  default     = "wiz-demo"
}

variable "app_name" {
  description = "Name of the vulnerable application"
  type        = string
  default     = "react2shell"
}

variable "ecr_image" {
  description = "ECR image URL for the vulnerable Next.js app"
  type        = string
  # Update this with your actual ECR image
  default = ""
}

variable "app_replicas" {
  description = "Number of pod replicas"
  type        = number
  default     = 1
}

# -----------------------------------------------------------------------------
# NetworkPolicy Configuration
# -----------------------------------------------------------------------------
# SGs remain open (0.0.0.0/0) so Wiz evaluates "publicly exposed" risk
# NetworkPolicy at pod level restricts actual traffic

variable "dynamic_scanner_ipv4s_develop" {
  description = "Wiz Dynamic Scanner IPv4 CIDRs for development (comma-separated)"
  type        = string
  default     = "54.153.167.0/32,54.206.253.144/32,54.66.162.244/32,13.238.102.51/32,54.66.150.182/32,3.24.191.170/32"
}

variable "allowed_cidrs" {
  description = "Additional allowed CIDRs (e.g., your IP for demos)"
  type        = list(string)
  default     = []
}

variable "aws_profile" {
  description = "AWS CLI profile to use"
  type        = string
  default     = "wiz-demo"
}

