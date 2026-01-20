variable "prefix" {
  type        = string
  description = "A string representing the prefix for all created resources"
}

variable "create_kms_key" {
  type        = bool
  description = "Whether to create a new KMS key for VPC Flow logs encryption"
  default     = true
}

variable "sqs_kms_encryption_enabled" {
  type        = bool
  description = "Whether to enable encryption for the SQS queue used for VPC Flow logs"
  default     = false
}

variable "flowlogs_s3_kms_arn" {
  type        = string
  description = "The KMS ARN to use for encrypting VPC Flow logs in S3"
  default     = ""
  validation {
    condition     = var.flowlogs_s3_kms_arn == "" || can(regex("^arn:aws(?:-(?:cn|us-gov))??:kms:[a-z0-9-]+:\\d{12}:key/[a-zA-Z0-9-]+$", var.flowlogs_s3_kms_arn))
    error_message = "If provided, the KMS ARN must match the pattern ^arn:aws(?:-(?:cn|us-gov))??:kms:[a-z0-9-]+:\\d{12}:key/[a-zA-Z0-9-]+$"
  }
}

variable "sqs_queue_key_arn" {
  type        = string
  description = "The KMS key ARN to use for encrypting the SQS queue"
  default     = ""
  validation {
    condition     = var.sqs_queue_key_arn == "" || can(regex("^arn:aws(?:-(?:cn|us-gov))??:kms:[a-z0-9-]+:\\d{12}:key/[a-zA-Z0-9-]+$", var.sqs_queue_key_arn))
    error_message = "If provided, the SQS queue KMS key ARN must match the pattern ^arn:aws(?:-(?:cn|us-gov))??:kms:[a-z0-9-]+:\\d{12}:key/[a-zA-Z0-9-]+$"
  }
}

variable "vpc_flow_logs_bucket_arn" {
  type        = string
  description = "The arn of the S3 bucket the VPC Flow logs are written to"
  default     = ""
  validation {
    condition     = var.vpc_flow_logs_bucket_arn == "" || can(regex("^arn:aws(?:-(?:cn|us-gov))??:s3:::[\\w-]+$", var.vpc_flow_logs_bucket_arn))
    error_message = "If provided, the VPC Flow logs bucket ARN must match the pattern ^arn:aws(?:-(?:cn|us-gov))??:s3:::[\\w-]+$"
  }
}

variable "sns_topic_arn" {
  description = "ARN of the SNS topic to subscribe to"
  type        = string
}

variable "wiz_access_role" {
  type        = string
  description = "The WizAccessRole ARN"
  validation {
    condition     = can(regex("^arn:aws(?:-(?:cn|us-gov))??:iam::\\d{12}:role/.+$", var.wiz_access_role))
    error_message = "Must be a valid IAM role ARN"
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

variable "tags" {
  type        = map(string)
  description = "A map of tags to apply to all resources created by this module"
  default     = {}
}
