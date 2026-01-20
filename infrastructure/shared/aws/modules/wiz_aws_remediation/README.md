# wiz_aws_remediation

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.0 |

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy.AssumeWorkerRolePolicy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.RemediationWorkerPolicy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.WizAccessPolicyToSns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.LambdaRole](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.RemediationWorkerRole](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.WizAccessRoleToSns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.AssumeWorkerRolePolicyAttachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.ManagedPolicyArns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.RemediationWorkerRolePolicyAttachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.WizAccessPolicyToSnsAttachement](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_lambda_event_source_mapping.WizLambdaTrigger](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_event_source_mapping) | resource |
| [aws_lambda_function.LambdaFunction](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_s3_bucket.WizRemediationCustomFunctionsBucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_ownership_controls.WizRemediationCustomFunctionsBucketOwnership](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls) | resource |
| [aws_s3_bucket_policy.WizRemediationCustomFunctionsBucketPolicy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.WizRemediationCustomFunctionsBucketPublicBlock](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.WizRemediationCustomFunctionsBucketSSEConfiguration](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_object.WizRemediationCustomFunctionsBucketFolders](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |
| [aws_s3_object.WizRemediationCustomFunctionsBucketJson](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |
| [aws_sns_topic.WizIssuesToRemediateSNSTopic](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_sns_topic_policy.WizIssuesToRemediateSNSTopicPolicy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_policy) | resource |
| [aws_sns_topic_subscription.SNSSubscription](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription) | resource |
| [aws_sqs_queue.IssuesDeadLetterQueue](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue) | resource |
| [aws_sqs_queue.WizIssuesToRemediateQueue](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue) | resource |
| [aws_sqs_queue_policy.MyQueuePolicy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue_policy) | resource |
| [aws_sqs_queue_policy.MyQueuePolicyDLQ](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue_policy) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.AssumeWorkerRolePolicyDocument](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.LambdaAssumeRoleDocument](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.MyQueuePolicy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.MyQueuePolicyDLQ](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.RemediationWorkerPolicy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.RemediationWorkerRoleAssumeDocument](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.SnsAssumeRoleFromWizPolicyDocument](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.WizAccessPolicyToSns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.WizIssuesToRemediateSNSTopicPolicyDocument](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.WizRemediationBucketPolicyDocument](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ExternalId"></a> [ExternalId](#input\_ExternalId) | The External ID of the Wiz connector. This is a nonce that will be used by our service to assume the role in your account | `string` | n/a | yes |
| <a name="input_AdditionalTag"></a> [AdditionalTag](#input\_AdditionalTag) | (Optional) An additional tag that will be added to all stack resources | `map(string)` | `{}` | no |
| <a name="input_ImageAccountID"></a> [ImageAccountID](#input\_ImageAccountID) | The AWS account ID of the Wiz Remediation container image | `string` | `"417748291193"` | no |
| <a name="input_ImageNameTag"></a> [ImageNameTag](#input\_ImageNameTag) | The URI of Wiz remediation Lambda container image | `string` | `"wiz-remediation-aws:2"` | no |
| <a name="input_IncludeDestructivePermissions"></a> [IncludeDestructivePermissions](#input\_IncludeDestructivePermissions) | Should the remediation worker role policy include destructive permissions such as Delete/Terminate | `bool` | `true` | no |
| <a name="input_RoleARN"></a> [RoleARN](#input\_RoleARN) | Enter the AWS Trust Policy Role ARN for your Wiz data center. You can retrieve it from User Settings, Tenant in the Wiz portal | `string` | `""` | no |
| <a name="input_WizFailoverSTSEndpointRegion"></a> [WizFailoverSTSEndpointRegion](#input\_WizFailoverSTSEndpointRegion) | The region used for STS authentication tokens when global resources are being remediated | `string` | `"us-east-1"` | no |
| <a name="input_WizRemediationAutoTagDateFormat"></a> [WizRemediationAutoTagDateFormat](#input\_WizRemediationAutoTagDateFormat) | The date format used for Wiz Remediation AutoTag values. Accepted values are DDMMYY and MMDDYY | `string` | `"DDMMYY"` | no |
| <a name="input_WizRemediationAutoTagKey"></a> [WizRemediationAutoTagKey](#input\_WizRemediationAutoTagKey) | The Wiz AutoTag key applied to cloud resources updated by Wiz Auto Remediation | `string` | `"wizRemediationLastUpdatedUTC"` | no |
| <a name="input_WizRemediationCustomFunctionsBucketEnabled"></a> [WizRemediationCustomFunctionsBucketEnabled](#input\_WizRemediationCustomFunctionsBucketEnabled) | Enable the creation and use of an S3 bucket for custom remediation response functions | `bool` | `true` | no |
| <a name="input_WizRemediationCustomFunctionsBucketName"></a> [WizRemediationCustomFunctionsBucketName](#input\_WizRemediationCustomFunctionsBucketName) | The naming prefix of the S3 bucket created for storing custom remediation response functions. The account id is added to the end of this name to make sure it is unique across aws | `string` | `"wiz-remediation-custom-functions"` | no |
| <a name="input_WizRemediationEnabledAutoTagOnUpdate"></a> [WizRemediationEnabledAutoTagOnUpdate](#input\_WizRemediationEnabledAutoTagOnUpdate) | Enable Wiz Remediation AutoTag when a cloud resource is updated by a response function | `bool` | `true` | no |
| <a name="input_WizRemediationResourcesPrefix"></a> [WizRemediationResourcesPrefix](#input\_WizRemediationResourcesPrefix) | Enter the prefix string that will be prepended to all Wiz Remediation resources on your account. The default is Wiz, which will as an example, create a role named Wiz-Remediation-Lambda-Role | `string` | `"Wiz"` | no |
| <a name="input_WizRemediationTagValue"></a> [WizRemediationTagValue](#input\_WizRemediationTagValue) | The remediation tag value uuid | `map(string)` | <pre>{<br/>  "wiz-remediation": ""<br/>}</pre> | no |
| <a name="input_WizRemediationWorkerRole"></a> [WizRemediationWorkerRole](#input\_WizRemediationWorkerRole) | The Role name to be assumed by Lambda for remediation on another account | `string` | `"Remediation-Worker-Role"` | no |
| <a name="input_region"></a> [region](#input\_region) | n/a | `string` | `"us-east-2"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_AccessRoleToSNS"></a> [AccessRoleToSNS](#output\_AccessRoleToSNS) | ARN of the role that Wiz will assume to publish messages to the queue |
| <a name="output_SNSTopicArn"></a> [SNSTopicArn](#output\_SNSTopicArn) | ARN of the SNS topic where Wiz will publish Response Actions |
| <a name="output_WizCustomResponseFunctionsBucketNameOutput"></a> [WizCustomResponseFunctionsBucketNameOutput](#output\_WizCustomResponseFunctionsBucketNameOutput) | The name of the S3 bucket where custom response functions are stored |
| <a name="output_WizRemediationLambda"></a> [WizRemediationLambda](#output\_WizRemediationLambda) | The Lambda function that will run the remediation functions |
| <a name="output_WizRemediationQueue"></a> [WizRemediationQueue](#output\_WizRemediationQueue) | Remediation SQS Queue URL |
| <a name="output_WizRemediationWorkerIAMRole"></a> [WizRemediationWorkerIAMRole](#output\_WizRemediationWorkerIAMRole) | Remediation Worker IAM Role |
| <a name="output_WizRemediationWorkerId"></a> [WizRemediationWorkerId](#output\_WizRemediationWorkerId) | Worker AWS Account ID |
<!-- END_TF_DOCS -->
