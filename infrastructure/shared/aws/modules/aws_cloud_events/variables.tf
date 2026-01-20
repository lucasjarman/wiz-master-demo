variable "integration_type" {
  type        = string
  default     = "CLOUDTRAIL"
  description = "Specify the integration type. Can only be `CLOUDTRAIL` or `S3`. Defaults to `CLOUDTRAIL`"
  validation {
    condition     = contains(["CLOUDTRAIL", "S3"], var.integration_type)
    error_message = "The integration_type must be either CLOUDTRAIL or S3."
  }
}

variable "prefix" {
  type        = string
  description = "A prefix for resource names."
  default     = ""
}

variable "cloudtrail_arn" {
  type        = string
  description = "The ARN of the CloudTrail with which to integrate."
  default     = ""
}

variable "cloudtrail_bucket_arn" {
  type        = string
  description = "The ARN of the S3 bucket used to store CloudTrail logs."
}

variable "cloudtrail_kms_arn" {
  type        = string
  description = "The ARN of the KMS key used to encrypt CloudTrail logs."
  default     = ""
}

variable "kms_key_rotation" {
  type        = bool
  default     = false
  description = "A boolean representing whether to enable KMS automatic key rotation."
}

variable "kms_key_deletion_days" {
  type        = number
  default     = 30
  description = "The waiting period, specified in number of days, before deleting the KMS key."
}

variable "kms_key_multi_region" {
  type        = bool
  default     = true
  description = "A boolean representing whether the KMS key is a multi-region or regional key."
}

variable "s3_notification_log_prefix" {
  type        = string
  default     = ""
  description = "The object prefix for which to create S3 notifications."
}

variable "s3_notification_type" {
  type        = string
  default     = "SNS"
  description = "The destination type that should be used for S3 notifications: `SNS` or `SQS`. Defaults to `SNS`"

  validation {
    condition     = contains(["SNS", "SQS"], var.s3_notification_type)
    error_message = "Valid values for variable 's3_notification_type' are: ['SNS', 'SQS']."
  }
}

variable "sns_topic_arn" {
  type        = string
  default     = ""
  description = "The ARN of an existing SNS Topic to which SQS should be subscribed."
}

variable "sns_topic_encryption_enabled" {
  type        = bool
  default     = true
  description = "Set this to `false` to disable encryption on a sns topic. Defaults to true"
}

variable "sns_topic_encryption_key_arn" {
  type        = string
  default     = ""
  description = "The ARN of an existing KMS encryption key to be used for SNS"
}

variable "create_sns_topic_subscription" {
  type        = bool
  default     = true
  description = "A boolean representing whether the module should attempt to create an SNS Topic subscription."
}

variable "sqs_encryption_enabled" {
  type        = bool
  default     = true
  description = "Set this to `true` to enable server-side encryption on SQS."
}

variable "sqs_encryption_key_arn" {
  type        = string
  default     = ""
  description = "The ARN of the KMS encryption key to be used for SQS (Required when `sqs_encryption_enabled` is `true`)"
}

variable "use_existing_sns_topic" {
  type        = bool
  description = "A boolean representing whether the module should use an existing SNS Topic rather than creating one."
  default     = false
}

variable "wiz_access_role_arn" {
  description = "The ARN of the AWS role used by the Wiz cloud connector."
  type        = string
}
