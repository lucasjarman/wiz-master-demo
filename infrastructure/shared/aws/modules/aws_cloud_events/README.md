<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13.7 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy.wiz_allow_cloudtrail_bucket_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role_policy_attachment.wiz_access_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_user_policy_attachment.wiz_access_user](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_user_policy_attachment) | resource |
| [aws_kms_key.wiz_kms_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_s3_bucket_notification.cloudtrail_bucket_notification](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_notification) | resource |
| [aws_sns_topic.wiz-cloud-events](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_sns_topic_policy.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_policy) | resource |
| [aws_sns_topic_subscription.wiz-cloudtrail-logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription) | resource |
| [aws_sqs_queue.wiz-cloud-events](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue) | resource |
| [aws_sqs_queue_policy.wiz-cloud-events](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue_policy) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.kms_key_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.sns_topic_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.sqs_queue_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.wiz_access_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cloudtrail_arn"></a> [cloudtrail\_arn](#input\_cloudtrail\_arn) | The ARN of the CloudTrail with which to integrate. | `string` | `""` | no |
| <a name="input_cloudtrail_bucket_arn"></a> [cloudtrail\_bucket\_arn](#input\_cloudtrail\_bucket\_arn) | The ARN of the S3 bucket used to store CloudTrail logs. | `string` | n/a | yes |
| <a name="input_cloudtrail_kms_arn"></a> [cloudtrail\_kms\_arn](#input\_cloudtrail\_kms\_arn) | The ARN of the KMS key used to encrypt CloudTrail logs. | `string` | `""` | no |
| <a name="input_create_sns_topic_subscription"></a> [create\_sns\_topic\_subscription](#input\_create\_sns\_topic\_subscription) | A boolean representing whether the module should attempt to create an SNS Topic subscription. | `bool` | `true` | no |
| <a name="input_integration_type"></a> [integration\_type](#input\_integration\_type) | Specify the integration type. Can only be `CLOUDTRAIL` or `S3`. Defaults to `CLOUDTRAIL` | `string` | `"CLOUDTRAIL"` | no |
| <a name="input_kms_key_deletion_days"></a> [kms\_key\_deletion\_days](#input\_kms\_key\_deletion\_days) | The waiting period, specified in number of days, before deleting the KMS key. | `number` | `30` | no |
| <a name="input_kms_key_multi_region"></a> [kms\_key\_multi\_region](#input\_kms\_key\_multi\_region) | A boolean representing whether the KMS key is a multi-region or regional key. | `bool` | `true` | no |
| <a name="input_kms_key_rotation"></a> [kms\_key\_rotation](#input\_kms\_key\_rotation) | A boolean representing whether to enable KMS automatic key rotation. | `bool` | `false` | no |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | A prefix for resource names. | `string` | `""` | no |
| <a name="input_s3_notification_log_prefix"></a> [s3\_notification\_log\_prefix](#input\_s3\_notification\_log\_prefix) | The object prefix for which to create S3 notifications. | `string` | `""` | no |
| <a name="input_s3_notification_type"></a> [s3\_notification\_type](#input\_s3\_notification\_type) | The destination type that should be used for S3 notifications: `SNS` or `SQS`. Defaults to `SNS` | `string` | `"SNS"` | no |
| <a name="input_sns_topic_arn"></a> [sns\_topic\_arn](#input\_sns\_topic\_arn) | The ARN of an existing SNS Topic to which SQS should be subscribed. | `string` | `""` | no |
| <a name="input_sns_topic_encryption_enabled"></a> [sns\_topic\_encryption\_enabled](#input\_sns\_topic\_encryption\_enabled) | Set this to `false` to disable encryption on a sns topic. Defaults to true | `bool` | `true` | no |
| <a name="input_sns_topic_encryption_key_arn"></a> [sns\_topic\_encryption\_key\_arn](#input\_sns\_topic\_encryption\_key\_arn) | The ARN of an existing KMS encryption key to be used for SNS | `string` | `""` | no |
| <a name="input_sqs_encryption_enabled"></a> [sqs\_encryption\_enabled](#input\_sqs\_encryption\_enabled) | Set this to `true` to enable server-side encryption on SQS. | `bool` | `true` | no |
| <a name="input_sqs_encryption_key_arn"></a> [sqs\_encryption\_key\_arn](#input\_sqs\_encryption\_key\_arn) | The ARN of the KMS encryption key to be used for SQS (Required when `sqs_encryption_enabled` is `true`) | `string` | `""` | no |
| <a name="input_use_existing_sns_topic"></a> [use\_existing\_sns\_topic](#input\_use\_existing\_sns\_topic) | A boolean representing whether the module should use an existing SNS Topic rather than creating one. | `bool` | `false` | no |
| <a name="input_wiz_access_role_arn"></a> [wiz\_access\_role\_arn](#input\_wiz\_access\_role\_arn) | The ARN of the AWS role used by the Wiz cloud connector. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_bucket_account"></a> [bucket\_account](#output\_bucket\_account) | Account ID of the AWS account where the S3 bucket is located |
| <a name="output_bucket_name"></a> [bucket\_name](#output\_bucket\_name) | Name of the S3 bucket where CloudTrail logs are stored |
| <a name="output_sns_topic_arn"></a> [sns\_topic\_arn](#output\_sns\_topic\_arn) | ARN of the SNS topic used for notifications |
| <a name="output_sns_topic_key_arn"></a> [sns\_topic\_key\_arn](#output\_sns\_topic\_key\_arn) | KMS Key ARN used for SNS topic encryption |
| <a name="output_sqs_queue_arn"></a> [sqs\_queue\_arn](#output\_sqs\_queue\_arn) | ARN of the SQS queue used for notifications |
| <a name="output_sqs_queue_key_arn"></a> [sqs\_queue\_key\_arn](#output\_sqs\_queue\_key\_arn) | KMS Key ARN used for SQS queue encryption |
| <a name="output_sqs_queue_url"></a> [sqs\_queue\_url](#output\_sqs\_queue\_url) | URL of the SQS queue used for notifications |
<!-- END_TF_DOCS -->
