# AWS S3 Module

This module manages S3 buckets with advanced configuration options including:

- Versioning support
- Server-side encryption
- Cross-region replication
- Public access blocking
- IAM role and policy management

## Features
- Multiple bucket creation and management
- KMS encryption integration
- Bucket policy and access control
- Replication configuration with KMS support
- Flexible bucket naming with prefix support

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.83 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.83 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy.s3_replication](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy_attachment.s3_replication](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy_attachment) | resource |
| [aws_iam_role.s3_replication](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_s3_bucket.s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_lifecycle_configuration.s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_public_access_block.s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_replication_configuration.s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_replication_configuration) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.kms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.versioning](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_iam_policy_document.s3_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.s3_replication](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_common_tags"></a> [common\_tags](#input\_common\_tags) | Map of common tags for all taggable AWS resources.# | `map(string)` | `{}` | no |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | Prefix used for tagging and naming AWS resources. | `string` | n/a | yes |
| <a name="input_s3_bucket_lifecycle_rules"></a> [s3\_bucket\_lifecycle\_rules](#input\_s3\_bucket\_lifecycle\_rules) | Map of S3 bucket lifecycle rules to apply to the S3 buckets. Key should match the bucket key used in s3\_buckets | <pre>map(list(object({<br/>    id                                          = string<br/>    enabled                                     = optional(bool)<br/>    prefix                                      = optional(string)<br/>    expiration_days                             = optional(number)<br/>    expired_object_delete_marker                = optional(bool)<br/>    noncurrent_version_expiration_days          = optional(number)<br/>    transition_days                             = optional(number)<br/>    transition_storage_class                    = optional(string)<br/>    noncurrent_version_transition_days          = optional(number)<br/>    noncurrent_version_transition_storage_class = optional(string)<br/>    abort_incomplete_multipart_upload_days      = optional(number)<br/>  })))</pre> | `{}` | no |
| <a name="input_s3_buckets"></a> [s3\_buckets](#input\_s3\_buckets) | Object Map that contains the configuration for the S3 bucket configurations. | <pre>object({<br/>    state = optional(object({<br/>      create        = optional(bool, true)<br/>      bucket_name   = optional(string, "state-bucket")<br/>      description   = optional(string, "Statefile bucket for demo environment")<br/>      versioning    = optional(bool, true)<br/>      force_destroy = optional(bool, false)<br/>      public_access = optional(bool, false)<br/>      replication_destinations = optional(list(object({<br/>        bucket_arn         = string<br/>        kms_key_arn        = optional(string)<br/>        destination_region = optional(string)<br/>      })), [])<br/>      encrypt             = optional(bool, true)<br/>      bucket_key_enabled  = optional(bool, true)<br/>      kms_key_arn         = optional(string)<br/>      sse_s3_managed_key  = optional(bool, false)<br/>      is_secondary_region = optional(bool, false)<br/>    }))<br/>    bootstrap_state = optional(object({<br/>      create        = optional(bool, true)<br/>      bucket_name   = optional(string, "bootstrap-bucket")<br/>      description   = optional(string, "Statefile bucket for demo state bootstrap")<br/>      versioning    = optional(bool, true)<br/>      force_destroy = optional(bool, true)<br/>      public_access = optional(bool, false)<br/>      replication_destinations = optional(list(object({<br/>        bucket_arn         = string<br/>        kms_key_arn        = optional(string)<br/>        destination_region = optional(string)<br/>      })), [])<br/>      encrypt             = optional(bool, true)<br/>      bucket_key_enabled  = optional(bool, true)<br/>      kms_key_arn         = optional(string)<br/>      sse_s3_managed_key  = optional(bool, true)<br/>      is_secondary_region = optional(bool, false)<br/>    }))<br/>    sensitiveDataBucket = optional(object({<br/>      create        = optional(bool, true)<br/>      bucket_name   = optional(string, "sensitive-bucket")<br/>      description   = optional(string, "bucket to demo sensitive data exposure")<br/>      versioning    = optional(bool, true)<br/>      force_destroy = optional(bool, true)<br/>      public_access = optional(bool, false)<br/>      replication_destinations = optional(list(object({<br/>        bucket_arn         = string<br/>        kms_key_arn        = optional(string)<br/>        destination_region = optional(string)<br/>      })), [])<br/>      encrypt             = optional(bool, true)<br/>      bucket_key_enabled  = optional(bool, true)<br/>      kms_key_arn         = optional(string)<br/>      sse_s3_managed_key  = optional(bool, true)<br/>      is_secondary_region = optional(bool, false)<br/>    }))<br/>    flowLogs = optional(object({<br/>      create        = optional(bool, true)<br/>      bucket_name   = optional(string, "flow-logs")<br/>      description   = optional(string, "bucket to hold VPC Flow Logs")<br/>      versioning    = optional(bool, true)<br/>      force_destroy = optional(bool, true)<br/>      public_access = optional(bool, false)<br/>      replication_destinations = optional(list(object({<br/>        bucket_arn         = string<br/>        kms_key_arn        = optional(string)<br/>        destination_region = optional(string)<br/>      })), [])<br/>      encrypt             = optional(bool, true)<br/>      bucket_key_enabled  = optional(bool, true)<br/>      kms_key_arn         = optional(string)<br/>      sse_s3_managed_key  = optional(bool, true)<br/>      is_secondary_region = optional(bool, false)<br/>    }))<br/>    route53Logs = optional(object({<br/>      create        = optional(bool, true)<br/>      bucket_name   = optional(string, "route53-logs")<br/>      description   = optional(string, "bucket to hold Route53 Logs")<br/>      versioning    = optional(bool, true)<br/>      force_destroy = optional(bool, true)<br/>      public_access = optional(bool, false)<br/>      replication_destinations = optional(list(object({<br/>        bucket_arn         = string<br/>        kms_key_arn        = optional(string)<br/>        destination_region = optional(string)<br/>      })), [])<br/>      encrypt             = optional(bool, true)<br/>      bucket_key_enabled  = optional(bool, true)<br/>      kms_key_arn         = optional(string)<br/>      sse_s3_managed_key  = optional(bool, true)<br/>      is_secondary_region = optional(bool, false)<br/>    }))<br/>  })</pre> | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_s3_backup_bucket_arn"></a> [s3\_backup\_bucket\_arn](#output\_s3\_backup\_bucket\_arn) | Arn of the 'backup' bucket |
| <a name="output_s3_backup_bucket_name"></a> [s3\_backup\_bucket\_name](#output\_s3\_backup\_bucket\_name) | Name of S3 'backup' bucket. |
| <a name="output_s3_buckets"></a> [s3\_buckets](#output\_s3\_buckets) | List of objects created by the module |
| <a name="output_s3_state_bucket_arn"></a> [s3\_state\_bucket\_arn](#output\_s3\_state\_bucket\_arn) | Arn of the 'state' bucket |
| <a name="output_s3_state_bucket_name"></a> [s3\_state\_bucket\_name](#output\_s3\_state\_bucket\_name) | Name of S3 'state' bucket. |
<!-- END_TF_DOCS -->
