variable "prefix" {
  type        = string
  description = "A string representing the prefix for all created resources"
}

variable "wiz_role_names" {
  type        = map(string)
  description = "Map of Wiz role prefixes to role names (e.g., {\"adv\" = \"WizAccessRole\", \"ext\" = \"WizAccessRoleExternal\"}). Can be empty if Wiz integration is not configured."
  default     = {}
}

# S3 Bucket Configuration
variable "create_s3_bucket" {
  type        = bool
  description = "Whether to create a new S3 bucket for Route53 logs"
  default     = true
}

variable "route53_logs_bucket_arn" {
  type        = string
  description = "The ARN of an existing S3 bucket for Route53 logs (required if create_s3_bucket is false)"
  default     = ""
  validation {
    condition     = var.route53_logs_bucket_arn == "" || can(regex("^arn:aws(?:-(?:cn|us-gov))??:s3:::[\\w-]+$", var.route53_logs_bucket_arn))
    error_message = "If provided, the Route53 logs bucket ARN must match the pattern ^arn:aws(?:-(?:cn|us-gov))??:s3:::[\\w-]+$"
  }
}

variable "bucket_versioning" {
  type        = bool
  description = "Whether to enable versioning on the S3 bucket"
  default     = true
}

variable "bucket_force_destroy" {
  type        = bool
  description = "Whether to allow force destroy of the S3 bucket"
  default     = true
}

variable "bucket_encryption_enabled" {
  type        = bool
  description = "Whether to enable encryption on the S3 bucket"
  default     = true
}

variable "bucket_key_enabled" {
  type        = bool
  description = "Whether to enable S3 bucket key for SSE-KMS"
  default     = true
}

variable "bucket_lifecycle_rules" {
  type = list(object({
    id                                     = string
    enabled                                = optional(bool, true)
    prefix                                 = optional(string)
    expiration_days                        = optional(number)
    expired_object_delete_marker           = optional(bool)
    noncurrent_version_expiration_days     = optional(number)
    abort_incomplete_multipart_upload_days = optional(number)
  }))
  description = "List of lifecycle rules to apply to the S3 bucket"
  default     = []
}

# SNS Topic Configuration
variable "create_sns_topic" {
  type        = bool
  description = "Whether to create a new SNS topic for S3 notifications"
  default     = true
}

variable "sns_topic_arn" {
  type        = string
  description = "ARN of an existing SNS topic to subscribe to (required if create_sns_topic is false)"
  default     = ""
  validation {
    condition     = var.sns_topic_arn == "" || can(regex("^arn:aws(?:-(?:cn|us-gov))??:sns:[a-z0-9-]+:\\d{12}:[\\w-]+$", var.sns_topic_arn))
    error_message = "If provided, the SNS topic ARN must be valid"
  }
}

variable "sns_kms_encryption_enabled" {
  type        = bool
  description = "Whether to enable KMS encryption for the SNS topic"
  default     = true
}

# KMS Configuration
variable "create_kms_key" {
  type        = bool
  description = "Whether to create a new KMS key for Route53 logs encryption"
  default     = true
}

variable "route53_logs_s3_kms_arn" {
  type        = string
  description = "The KMS ARN to use for encrypting Route53 logs in S3 (used if create_kms_key is false)"
  default     = ""
  validation {
    condition     = var.route53_logs_s3_kms_arn == "" || can(regex("^arn:aws(?:-(?:cn|us-gov))??:kms:[a-z0-9-]+:\\d{12}:key/[a-zA-Z0-9-]+$", var.route53_logs_s3_kms_arn))
    error_message = "If provided, the KMS ARN must match the pattern ^arn:aws(?:-(?:cn|us-gov))??:kms:[a-z0-9-]+:\\d{12}:key/[a-zA-Z0-9-]+$"
  }
}

variable "kms_deletion_window_in_days" {
  type        = number
  description = "The number of days after which the KMS key will be deleted"
  default     = 30
  validation {
    condition     = var.kms_deletion_window_in_days >= 7 && var.kms_deletion_window_in_days <= 30
    error_message = "KMS deletion window must be between 7 and 30 days"
  }
}

variable "kms_enable_key_rotation" {
  type        = bool
  description = "Whether to enable key rotation for the KMS key"
  default     = true
}

# SQS Configuration
variable "sqs_kms_encryption_enabled" {
  type        = bool
  description = "Whether to enable encryption for the SQS queue used for Route53 logs"
  default     = true
}

variable "sqs_queue_key_arn" {
  type        = string
  description = "The KMS key ARN to use for encrypting the SQS queue (if different from route53_logs_s3_kms_arn)"
  default     = ""
  validation {
    condition     = var.sqs_queue_key_arn == "" || can(regex("^arn:aws(?:-(?:cn|us-gov))??:kms:[a-z0-9-]+:\\d{12}:key/[a-zA-Z0-9-]+$", var.sqs_queue_key_arn))
    error_message = "If provided, the SQS queue KMS key ARN must match the pattern ^arn:aws(?:-(?:cn|us-gov))??:kms:[a-z0-9-]+:\\d{12}:key/[a-zA-Z0-9-]+$"
  }
}

# Route53 Resolver Query Logging Configuration
variable "vpc_ids" {
  type        = map(string)
  description = "Map of VPC names to VPC IDs to enable Route53 Resolver query logging for (e.g., {\"main\" = vpc-xxx})"
  default     = {}
}

# Tags
variable "tags" {
  type        = map(string)
  description = "A map of tags to apply to all resources created by this module"
  default     = {}
}
