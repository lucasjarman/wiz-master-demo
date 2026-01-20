variable "name" {
  description = "Name prefix for resources"
  type        = string
}

variable "cluster_oidc_provider_arn" {
  description = "ARN of the EKS cluster OIDC provider"
  type        = string
}

variable "kubernetes_namespace" {
  description = "Kubernetes namespace to deploy into"
  type        = string
}

variable "ecr_image" {
  description = "ECR image URL for the vulnerable Next.js app"
  type        = string
}

variable "replicas" {
  description = "Number of pod replicas"
  type        = number
  default     = 1
}

variable "common_tags" {
  description = "Common tags for AWS resources"
  type        = map(string)
  default     = {}
}

variable "vpc_cidr" {
  description = "VPC CIDR block for NetworkPolicy (allows internal traffic)"
  type        = string
  default     = "10.0.0.0/16"
}

variable "allowed_cidrs" {
  description = "List of allowed external CIDRs (Wiz scanners + custom IPs)"
  type        = list(string)
  default     = []
}

variable "wiz_scanner_cidrs" {
  description = "Wiz Dynamic Scanner IPv4 CIDRs"
  type        = list(string)
  default     = []
}
