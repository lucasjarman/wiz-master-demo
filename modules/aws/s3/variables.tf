variable "prefix" {
  type        = string
  description = "Prefix used for tagging and naming AWS resources."
}

variable "common_tags" {
  type        = map(string)
  description = "Map of common tags for all taggable AWS resources.#"
  default     = {}
}

variable "s3_bucket_lifecycle_rules" {
  type = map(list(object({
    id                                          = string
    enabled                                     = optional(bool)
    prefix                                      = optional(string)
    expiration_days                             = optional(number)
    expired_object_delete_marker                = optional(bool)
    noncurrent_version_expiration_days          = optional(number)
    transition_days                             = optional(number)
    transition_storage_class                    = optional(string)
    noncurrent_version_transition_days          = optional(number)
    noncurrent_version_transition_storage_class = optional(string)
    abort_incomplete_multipart_upload_days      = optional(number)
  })))
  description = "Map of S3 bucket lifecycle rules to apply to the S3 buckets. Key should match the bucket key used in s3_buckets"
  default     = {}
  validation {
    condition = alltrue(flatten([
      for bucket, rules in var.s3_bucket_lifecycle_rules : [
        for rule_idx, rule in rules : (
          (rule.expiration_days != null ? 1 : 0) +
          (rule.expired_object_delete_marker != null ? 1 : 0)
        ) <= 1
      ]
    ]))
    error_message = "Each S3 lifecycle rule can only specify one of: expiration_days or expired_object_delete_marker."
  }
}

variable "s3_buckets" {
  type = object({
    state = optional(object({
      create        = optional(bool, true)
      bucket_name   = optional(string, "state-bucket")
      description   = optional(string, "Statefile bucket for demo environment")
      versioning    = optional(bool, true)
      force_destroy = optional(bool, false)
      public_access = optional(bool, false)
      replication_destinations = optional(list(object({
        bucket_arn         = string
        kms_key_arn        = optional(string)
        destination_region = optional(string)
      })), [])
      encrypt             = optional(bool, true)
      bucket_key_enabled  = optional(bool, true)
      kms_key_arn         = optional(string)
      sse_s3_managed_key  = optional(bool, false)
      is_secondary_region = optional(bool, false)
    }))
    bootstrap_state = optional(object({
      create        = optional(bool, true)
      bucket_name   = optional(string, "bootstrap-bucket")
      description   = optional(string, "Statefile bucket for demo state bootstrap")
      versioning    = optional(bool, true)
      force_destroy = optional(bool, true)
      public_access = optional(bool, false)
      replication_destinations = optional(list(object({
        bucket_arn         = string
        kms_key_arn        = optional(string)
        destination_region = optional(string)
      })), [])
      encrypt             = optional(bool, true)
      bucket_key_enabled  = optional(bool, true)
      kms_key_arn         = optional(string)
      sse_s3_managed_key  = optional(bool, true)
      is_secondary_region = optional(bool, false)
    }))
    sensitiveDataBucket = optional(object({
      create        = optional(bool, true)
      bucket_name   = optional(string, "sensitive-bucket")
      description   = optional(string, "bucket to demo sensitive data exposure")
      versioning    = optional(bool, true)
      force_destroy = optional(bool, true)
      public_access = optional(bool, false)
      replication_destinations = optional(list(object({
        bucket_arn         = string
        kms_key_arn        = optional(string)
        destination_region = optional(string)
      })), [])
      encrypt             = optional(bool, true)
      bucket_key_enabled  = optional(bool, true)
      kms_key_arn         = optional(string)
      sse_s3_managed_key  = optional(bool, true)
      is_secondary_region = optional(bool, false)
    }))
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
      encrypt             = optional(bool, true)
      bucket_key_enabled  = optional(bool, true)
      kms_key_arn         = optional(string)
      sse_s3_managed_key  = optional(bool, true)
      is_secondary_region = optional(bool, false)
    }))
    route53Logs = optional(object({
      create        = optional(bool, true)
      bucket_name   = optional(string, "route53-logs")
      description   = optional(string, "bucket to hold Route53 Logs")
      versioning    = optional(bool, true)
      force_destroy = optional(bool, true)
      public_access = optional(bool, false)
      replication_destinations = optional(list(object({
        bucket_arn         = string
        kms_key_arn        = optional(string)
        destination_region = optional(string)
      })), [])
      encrypt             = optional(bool, true)
      bucket_key_enabled  = optional(bool, true)
      kms_key_arn         = optional(string)
      sse_s3_managed_key  = optional(bool, true)
      is_secondary_region = optional(bool, false)
    }))
  })
  description = "Object Map that contains the configuration for the S3 bucket configurations."
  default     = {}
}
