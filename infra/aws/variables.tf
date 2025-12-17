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
# EKS Variables
# -----------------------------------------------------------------------------
variable "enable_eks" {
  description = "Enable EKS cluster deployment (adds NAT gateway cost)"
  type        = bool
  default     = false
}

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
