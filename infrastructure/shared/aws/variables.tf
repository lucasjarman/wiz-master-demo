# Variables for Shared AWS Infrastructure

variable "backend_config_json_path" {
  description = "Path to the backend configuration JSON file"
  type        = string
}

variable "prefix" {
  description = "Prefix for resource names"
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
  description = "AWS region for resources"
  type        = string
  default     = "ap-southeast-2"
}

variable "aws_profile" {
  description = "AWS CLI profile to use"
  type        = string
  default     = "wiz-demo"
}

# -----------------------------------------------------------------------------
# VPC Variables
# -----------------------------------------------------------------------------
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# -----------------------------------------------------------------------------
# EKS Variables
# -----------------------------------------------------------------------------
variable "eks_cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.32"
}

variable "eks_node_instance_type" {
  description = "Instance type for EKS managed node group"
  type        = string
  default     = "t3.medium"
}

# NOTE: Wiz Integration Variables have been moved to infrastructure/wiz/develop layer
# to match wiz-demo-infra reference pattern. The wiz layer creates service accounts
# dynamically via the Wiz Terraform provider.




# -----------------------------------------------------------------------------
# Wiz Defend Logging Variables
# -----------------------------------------------------------------------------
variable "enabled_logs" {
  type = object({
    vpc_flow_logs     = optional(bool, true)
    cloudtrail        = optional(bool, true)
    s3_access_logging = optional(bool, true)
    route53_logs      = optional(bool, true)
  })
  description = "Object to signify building logging assets for Wiz Defend"
  default     = {}
}

variable "s3_buckets" {
  type = object({
    sensitiveDataBucket = optional(object({
      create        = optional(bool, true)
      bucket_name   = optional(string, "cloudtrail")
      description   = optional(string, "bucket to hold CloudTrail event data")
      versioning    = optional(bool, true)
      force_destroy = optional(bool, true)
      public_access = optional(bool, false)
      replication_destinations = optional(list(object({
        bucket_arn         = string
        kms_key_arn        = optional(string)
        destination_region = optional(string)
      })), [])
      encrypt            = optional(bool, true)
      bucket_key_enabled = optional(bool, true)
      kms_key_arn        = optional(string, "")
    }), {})
    flowLogs = optional(object({
      create        = optional(bool, true)
      bucket_name   = optional(string, "flow-logs")
      description   = optional(string, "bucket to hold VPC Flow Logs")
      versioning    = optional(bool, true)
      force_destroy = optional(bool, true)
      public_access = optional(bool, false)
      replication_destinations = optional(list(object({
        bucket_arn         = string
        kms_key_arn        = optional(string)
        destination_region = optional(string)
      })), [])
      encrypt            = optional(bool, true)
      bucket_key_enabled = optional(bool, true)
      kms_key_arn        = optional(string, "")
    }), {})
  })
  description = "Object Map that contains the configuration for the S3 bucket configurations."
  default     = {}
}

variable "s3_bucket_lifecycle_rules" {
  type = map(list(object({
    id                                 = string
    enabled                            = optional(bool, true)
    prefix                             = optional(string)
    expiration_days                    = optional(number)
    expired_object_delete_marker       = optional(bool)
    noncurrent_version_expiration_days = optional(number)
    abort_incomplete_multipart_upload_days = optional(number)
  })))
  description = "Map of S3 bucket lifecycle rules"
  default     = {}
}

variable "wiz_access_role_name" {
  description = "Name of the Wiz access role for bucket policy permissions"
  type        = string
  default     = ""
}