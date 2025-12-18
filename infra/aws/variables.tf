# -----------------------------------------------------------------------------
# Demo Feature Flags
# -----------------------------------------------------------------------------
variable "enable_ec2_demo" {
  description = "Enable legacy EC2 demo instances"
  type        = bool
  default     = false
}

variable "enable_eks" {
  description = "Enable EKS cluster deployment (adds NAT gateway cost)"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Wiz Integration Variables (Required for Helm deployment)
# -----------------------------------------------------------------------------
variable "wiz_client_id" {
  description = "Wiz Service Account Client ID"
  type        = string
  default     = ""
}

variable "wiz_client_secret" {
  description = "Wiz Service Account Client Token"
  type        = string
  default     = ""
  sensitive   = true
}

variable "wiz_sensor_pull_user" {
  description = "Wiz Registry Username (Tenant ID)"
  type        = string
  default     = ""
}

variable "wiz_sensor_pull_password" {
  description = "Wiz Registry Password (Pull Key)"
  type        = string
  default     = ""
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Infrastructure Settings
# -----------------------------------------------------------------------------
variable "aws_region" {
  description = "AWS Region to deploy resources"
  type        = string
  default     = "ap-southeast-2"
}

variable "aws_profile" {
  description = "AWS CLI Profile to use"
  type        = string
  default     = "wiz-demo"
}

variable "ec2_instance_type" {
  description = "Instance type for the demo EC2 instance"
  type        = string
  default     = "t3.small"
}

variable "ssh_key_name" {
  description = "Name of existing EC2 key pair for SSH access"
  type        = string
}

# -----------------------------------------------------------------------------
# EKS Configuration
# -----------------------------------------------------------------------------
variable "eks_cluster_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
  default     = "1.32"
}

variable "eks_node_instance_type" {
  description = "Instance type for EKS node group"
  type        = string
  default     = "t3.medium"
}
