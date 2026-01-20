variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "branch" {
  description = "Git branch name for tagging resources"
  type        = string
  default     = "main"
}

variable "aws_region" {
  description = "AWS region for the state bucket"
  type        = string
  default     = "us-east-1"
}

