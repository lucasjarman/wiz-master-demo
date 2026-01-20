# vpc-flow-logs

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
| [aws_iam_policy.wiz_allow_vpc_flow_logs_bucket_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role_policy_attachment.wiz_vpc_flow_logs_policy_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_kms_key.wiz_vpc_flow_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_sns_topic_subscription.wiz_vpc_flow_logs_notification_queue_subscription](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription) | resource |
| [aws_sqs_queue.wiz_vpc_flow_logs_queue](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue) | resource |
| [aws_sqs_queue_policy.wiz_vpc_flow_logs_queue_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue_policy) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.sqs_queue_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.wiz_access_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.wiz_kms_key_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_create_kms_key"></a> [create\_kms\_key](#input\_create\_kms\_key) | Whether to create a new KMS key for VPC Flow logs encryption | `bool` | `true` | no |
| <a name="input_flowlogs_s3_kms_arn"></a> [flowlogs\_s3\_kms\_arn](#input\_flowlogs\_s3\_kms\_arn) | The KMS ARN to use for encrypting VPC Flow logs in S3 | `string` | `""` | no |
| <a name="input_kms_deletion_window_in_days"></a> [kms\_deletion\_window\_in\_days](#input\_kms\_deletion\_window\_in\_days) | The number of days after which the KMS key will be deleted | `number` | `30` | no |
| <a name="input_kms_enable_key_rotation"></a> [kms\_enable\_key\_rotation](#input\_kms\_enable\_key\_rotation) | Whether to enable key rotation for the KMS key | `bool` | `true` | no |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | A string representing the prefix for all created resources | `string` | n/a | yes |
| <a name="input_sns_topic_arn"></a> [sns\_topic\_arn](#input\_sns\_topic\_arn) | ARN of the SNS topic to subscribe to | `string` | n/a | yes |
| <a name="input_sqs_kms_encryption_enabled"></a> [sqs\_kms\_encryption\_enabled](#input\_sqs\_kms\_encryption\_enabled) | Whether to enable encryption for the SQS queue used for VPC Flow logs | `bool` | `false` | no |
| <a name="input_sqs_queue_key_arn"></a> [sqs\_queue\_key\_arn](#input\_sqs\_queue\_key\_arn) | The KMS key ARN to use for encrypting the SQS queue | `string` | `""` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to apply to all resources created by this module | `map(string)` | `{}` | no |
| <a name="input_vpc_flow_logs_bucket_arn"></a> [vpc\_flow\_logs\_bucket\_arn](#input\_vpc\_flow\_logs\_bucket\_arn) | The arn of the S3 bucket the VPC Flow logs are written to | `string` | `""` | no |
| <a name="input_wiz_access_role"></a> [wiz\_access\_role](#input\_wiz\_access\_role) | The WizAccessRole ARN | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_sqs_queue_arn"></a> [sqs\_queue\_arn](#output\_sqs\_queue\_arn) | The ARN of the SQS queue for VPC Flow Logs |
| <a name="output_sqs_queue_url"></a> [sqs\_queue\_url](#output\_sqs\_queue\_url) | The URL of the SQS queue for VPC Flow Logs |
<!-- END_TF_DOCS -->
