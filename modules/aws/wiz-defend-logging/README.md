# Wiz Defend Logs Integration Module

Ignore this we will udpate it once we get the module done

This module creates a complete, self-contained infrastructure for Route53 query logs integration with Wiz.

**Supports both**:
- **Route53 Resolver Query Logs** (VPC DNS queries) - Primary use case
- **Route53 Hosted Zone Query Logs** (public DNS queries) - Future use case

## Features

- **S3 Bucket** (optional): Creates an S3 bucket for Route53 query logs with:
  - Versioning support
  - KMS encryption
  - Lifecycle rules
  - Bucket policies for Route53 Resolver and Route53 service access
  - Bucket policies for Wiz access
  - Public access blocking

- **SNS Topic** (optional): Creates an SNS topic for S3 event notifications with:
  - KMS encryption support
  - Topic policy allowing S3 to publish

- **SQS Queue**: Creates an SQS queue for Wiz to consume notifications with:
  - KMS encryption support
  - Queue policy allowing SNS and Wiz access
  - Raw message delivery

- **KMS Key** (optional): Creates a KMS key for encrypting:
  - S3 bucket contents
  - SNS topic messages
  - SQS queue messages

- **IAM Policies**: Creates IAM policies for Wiz role to:
  - Access S3 bucket (GetObject, ListBucket, GetBucketLocation)
  - Decrypt KMS-encrypted data
  - Receive and delete SQS messages

## Usage Examples

### Complete Infrastructure with Multiple Wiz Roles (Default)
Creates everything: S3 bucket, SNS topic, SQS queues (one per role), KMS key, and IAM policies (one per role).

```hcl
module "route53_logs" {
  source = "../../../modules/aws/wiz-defend-logging/"

  prefix = "my-prefix"
  wiz_role_names = {
    "adv" = "WizAccessRole"
    "ext" = "WizAccessRoleExternal"
  }

  # Optional: Configure lifecycle rules
  bucket_lifecycle_rules = [
    {
      id              = "expire_old_logs"
      enabled         = true
      expiration_days = 90
    }
  ]

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

This creates:
- 1 S3 bucket for Route53 logs
- 1 SNS topic for S3 notifications
- 1 KMS key for encryption
- 2 SQS queues: `my-prefix-adv-wiz-route53-logs-queue` and `my-prefix-ext-wiz-route53-logs-queue`
- 2 IAM policies attached to their respective roles

### Use Existing S3 Bucket and SNS Topic
Only creates SQS queues and IAM policies, uses existing bucket and topic.

```hcl
module "route53_logs" {
  source = "../../../modules/aws/wiz-defend-logging/"

  prefix = "my-prefix"
  wiz_role_names = {
    "adv" = "WizAccessRole"
  }

  # Use existing resources
  create_s3_bucket        = false
  create_sns_topic        = false
  create_kms_key          = false

  route53_logs_bucket_arn = "arn:aws:s3:::existing-route53-logs-bucket"
  sns_topic_arn           = "arn:aws:sns:us-east-1:123456789012:existing-topic"
  route53_logs_s3_kms_arn = "arn:aws:kms:us-east-1:123456789012:key/existing-key-id"

  sqs_kms_encryption_enabled = true
  sqs_queue_key_arn          = "arn:aws:kms:us-east-1:123456789012:key/existing-key-id"
}
```

### Create Bucket and SNS, Use Existing KMS Key
Creates S3 bucket, SNS topic, and SQS queues, but uses an existing KMS key.

```hcl
module "route53_logs" {
  source = "../../../modules/aws/wiz-defend-logging/"

  prefix = "my-prefix"
  wiz_role_names = {
    "adv" = "WizAccessRole"
    "ext" = "WizAccessRoleExternal"
  }

  create_kms_key          = false
  route53_logs_s3_kms_arn = aws_kms_key.existing.arn

  sqs_kms_encryption_enabled = true
  sqs_queue_key_arn          = aws_kms_key.existing.arn
}
```

## Integration with Route53 Query Logging

After deploying this module, configure Route53 query logging:

```hcl
resource "aws_route53_query_log" "example" {
  depends_on = [module.route53_logs]

  cloudwatch_log_group_arn = module.route53_logs.bucket_arn
  zone_id                  = aws_route53_zone.example.zone_id
}
```

## Module Behavior

The module uses conditional resource creation based on the following variables:
- `create_s3_bucket`: When `true`, creates S3 bucket and related resources
- `create_sns_topic`: When `true`, creates SNS topic and topic policy
- `create_kms_key`: When `true`, creates KMS key for encryption

When set to `false`, you must provide the corresponding ARN variables:
- `route53_logs_bucket_arn` (if `create_s3_bucket = false`)
- `sns_topic_arn` (if `create_sns_topic = false`)
- `route53_logs_s3_kms_arn` (if `create_kms_key = false`)

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | 1.13.5 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.83 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.83 |

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy.wiz_allow_route53_logs_bucket_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role_policy_attachment.wiz_route53_logs_policy_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_kms_alias.wiz_route53_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.wiz_route53_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_route53_resolver_query_log_config.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_resolver_query_log_config) | resource |
| [aws_route53_resolver_query_log_config_association.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_resolver_query_log_config_association) | resource |
| [aws_s3_bucket.route53_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_lifecycle_configuration.route53_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_notification.route53_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_notification) | resource |
| [aws_s3_bucket_policy.route53_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.route53_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.route53_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.route53_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_sns_topic.route53_logs_fanout](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_sns_topic_policy.route53_logs_fanout](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_policy) | resource |
| [aws_sns_topic_subscription.wiz_route53_logs_notification_queue_subscription](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription) | resource |
| [aws_sqs_queue.wiz_route53_logs_queue](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue) | resource |
| [aws_sqs_queue_policy.wiz_route53_logs_queue_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue_policy) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.route53_logs_bucket_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.route53_logs_sns_fanout_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.sqs_queue_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.wiz_access_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.wiz_kms_key_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_prefix"></a> [prefix](#input\_prefix) | A string representing the prefix for all created resources | `string` | n/a | yes |
| <a name="input_wiz_role_names"></a> [wiz\_role\_names](#input\_wiz\_role\_names) | Map of Wiz role prefixes to role names (e.g., {"adv" = "WizAccessRole", "ext" = "WizAccessRoleExternal"}) | `map(string)` | n/a | yes |
| <a name="input_bucket_encryption_enabled"></a> [bucket\_encryption\_enabled](#input\_bucket\_encryption\_enabled) | Whether to enable encryption on the S3 bucket | `bool` | `true` | no |
| <a name="input_bucket_force_destroy"></a> [bucket\_force\_destroy](#input\_bucket\_force\_destroy) | Whether to allow force destroy of the S3 bucket | `bool` | `true` | no |
| <a name="input_bucket_key_enabled"></a> [bucket\_key\_enabled](#input\_bucket\_key\_enabled) | Whether to enable S3 bucket key for SSE-KMS | `bool` | `true` | no |
| <a name="input_bucket_lifecycle_rules"></a> [bucket\_lifecycle\_rules](#input\_bucket\_lifecycle\_rules) | List of lifecycle rules to apply to the S3 bucket | <pre>list(object({<br/>    id                                     = string<br/>    enabled                                = optional(bool, true)<br/>    prefix                                 = optional(string)<br/>    expiration_days                        = optional(number)<br/>    expired_object_delete_marker           = optional(bool)<br/>    noncurrent_version_expiration_days     = optional(number)<br/>    abort_incomplete_multipart_upload_days = optional(number)<br/>  }))</pre> | `[]` | no |
| <a name="input_bucket_versioning"></a> [bucket\_versioning](#input\_bucket\_versioning) | Whether to enable versioning on the S3 bucket | `bool` | `true` | no |
| <a name="input_create_kms_key"></a> [create\_kms\_key](#input\_create\_kms\_key) | Whether to create a new KMS key for Route53 logs encryption | `bool` | `true` | no |
| <a name="input_create_s3_bucket"></a> [create\_s3\_bucket](#input\_create\_s3\_bucket) | Whether to create a new S3 bucket for Route53 logs | `bool` | `true` | no |
| <a name="input_create_sns_topic"></a> [create\_sns\_topic](#input\_create\_sns\_topic) | Whether to create a new SNS topic for S3 notifications | `bool` | `true` | no |
| <a name="input_kms_deletion_window_in_days"></a> [kms\_deletion\_window\_in\_days](#input\_kms\_deletion\_window\_in\_days) | The number of days after which the KMS key will be deleted | `number` | `30` | no |
| <a name="input_kms_enable_key_rotation"></a> [kms\_enable\_key\_rotation](#input\_kms\_enable\_key\_rotation) | Whether to enable key rotation for the KMS key | `bool` | `true` | no |
| <a name="input_route53_logs_bucket_arn"></a> [route53\_logs\_bucket\_arn](#input\_route53\_logs\_bucket\_arn) | The ARN of an existing S3 bucket for Route53 logs (required if create\_s3\_bucket is false) | `string` | `""` | no |
| <a name="input_route53_logs_s3_kms_arn"></a> [route53\_logs\_s3\_kms\_arn](#input\_route53\_logs\_s3\_kms\_arn) | The KMS ARN to use for encrypting Route53 logs in S3 (used if create\_kms\_key is false) | `string` | `""` | no |
| <a name="input_sns_kms_encryption_enabled"></a> [sns\_kms\_encryption\_enabled](#input\_sns\_kms\_encryption\_enabled) | Whether to enable KMS encryption for the SNS topic | `bool` | `true` | no |
| <a name="input_sns_topic_arn"></a> [sns\_topic\_arn](#input\_sns\_topic\_arn) | ARN of an existing SNS topic to subscribe to (required if create\_sns\_topic is false) | `string` | `""` | no |
| <a name="input_sqs_kms_encryption_enabled"></a> [sqs\_kms\_encryption\_enabled](#input\_sqs\_kms\_encryption\_enabled) | Whether to enable encryption for the SQS queue used for Route53 logs | `bool` | `true` | no |
| <a name="input_sqs_queue_key_arn"></a> [sqs\_queue\_key\_arn](#input\_sqs\_queue\_key\_arn) | The KMS key ARN to use for encrypting the SQS queue (if different from route53\_logs\_s3\_kms\_arn) | `string` | `""` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to apply to all resources created by this module | `map(string)` | `{}` | no |
| <a name="input_vpc_ids"></a> [vpc\_ids](#input\_vpc\_ids) | Map of VPC names to VPC IDs to enable Route53 Resolver query logging for (e.g., {"main" = vpc-xxx}) | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_bucket_arn"></a> [bucket\_arn](#output\_bucket\_arn) | ARN of the Route53 logs S3 bucket |
| <a name="output_bucket_id"></a> [bucket\_id](#output\_bucket\_id) | ID of the Route53 logs S3 bucket |
| <a name="output_bucket_region"></a> [bucket\_region](#output\_bucket\_region) | Region of the Route53 logs S3 bucket |
| <a name="output_iam_policy_arns"></a> [iam\_policy\_arns](#output\_iam\_policy\_arns) | Map of IAM policy ARNs for Wiz access to Route53 logs by role prefix |
| <a name="output_iam_policy_names"></a> [iam\_policy\_names](#output\_iam\_policy\_names) | Map of IAM policy names for Wiz access to Route53 logs by role prefix |
| <a name="output_kms_key_arn"></a> [kms\_key\_arn](#output\_kms\_key\_arn) | ARN of the KMS key for Route53 logs (if created) |
| <a name="output_kms_key_id"></a> [kms\_key\_id](#output\_kms\_key\_id) | ID of the KMS key for Route53 logs (if created) |
| <a name="output_resolver_query_log_association_ids"></a> [resolver\_query\_log\_association\_ids](#output\_resolver\_query\_log\_association\_ids) | Map of VPC IDs to their Route53 Resolver query log association IDs |
| <a name="output_resolver_query_log_config_arn"></a> [resolver\_query\_log\_config\_arn](#output\_resolver\_query\_log\_config\_arn) | ARN of the Route53 Resolver query log configuration |
| <a name="output_resolver_query_log_config_id"></a> [resolver\_query\_log\_config\_id](#output\_resolver\_query\_log\_config\_id) | ID of the Route53 Resolver query log configuration |
| <a name="output_sns_topic_arn"></a> [sns\_topic\_arn](#output\_sns\_topic\_arn) | ARN of the SNS topic for Route53 logs notifications |
| <a name="output_sns_topic_name"></a> [sns\_topic\_name](#output\_sns\_topic\_name) | Name of the SNS topic for Route53 logs notifications |
| <a name="output_sqs_queue_arns"></a> [sqs\_queue\_arns](#output\_sqs\_queue\_arns) | Map of SQS queue ARNs for Route53 logs by role prefix |
| <a name="output_sqs_queue_names"></a> [sqs\_queue\_names](#output\_sqs\_queue\_names) | Map of SQS queue names for Route53 logs by role prefix |
| <a name="output_sqs_queue_urls"></a> [sqs\_queue\_urls](#output\_sqs\_queue\_urls) | Map of SQS queue URLs for Route53 logs by role prefix |
<!-- END_TF_DOCS -->
