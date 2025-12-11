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

variable "eks_node_instance_type" {
  description = "Instance type for the EKS managed node group"
  type        = string
  default     = "t3.medium" # Recommended minimum for K8s system pods
}
