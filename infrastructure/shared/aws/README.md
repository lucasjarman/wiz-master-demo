# aws

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |
| <a name="requirement_time"></a> [time](#requirement\_time) | ~> 0.9 |
| <a name="requirement_tls"></a> [tls](#requirement\_tls) | ~> 4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_access_log_bucket"></a> [access\_log\_bucket](#module\_access\_log\_bucket) | ../../../modules/aws/s3 | n/a |
| <a name="module_aws_buckets"></a> [aws\_buckets](#module\_aws\_buckets) | ../../../modules/aws/s3 | n/a |
| <a name="module_aws_cloud_events"></a> [aws\_cloud\_events](#module\_aws\_cloud\_events) | ./modules/aws_cloud_events | n/a |
| <a name="module_eks"></a> [eks](#module\_eks) | terraform-aws-modules/eks/aws | ~> 20.0 |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | terraform-aws-modules/vpc/aws | ~> 5.0 |
| <a name="module_vpc_flow_logs_queue"></a> [vpc\_flow\_logs\_queue](#module\_vpc\_flow\_logs\_queue) | ../../../modules/wiz/vpc-flow-logs/ | n/a |
| <a name="module_wiz_aws_permissions"></a> [wiz\_aws\_permissions](#module\_wiz\_aws\_permissions) | ./modules/wiz_aws_permissions_v2 | n/a |
| <a name="module_wiz_defend_logs"></a> [wiz\_defend\_logs](#module\_wiz\_defend\_logs) | ../../../modules/aws/wiz-defend-logging/ | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_cloudtrail.demo_cloudtrail](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudtrail) | resource |
| [aws_ecr_repository.app](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository) | resource |
| [aws_flow_log.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/flow_log) | resource |
| [aws_kms_alias.cloudtrail](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_alias.flow_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.cloudtrail](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_kms_key.flow_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_s3_bucket_logging.s3_access_logging](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_logging) | resource |
| [aws_s3_bucket_notification.vpc_flow_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_notification) | resource |
| [aws_s3_bucket_policy.cloudtrail_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_policy.flow_logs_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_policy.s3_access_logging_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_sns_topic.cloudtrail_sns_fanout](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_sns_topic.vpc_flow_logs_fanout](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_sns_topic_policy.cloudtrail_fanout](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_policy) | resource |
| [aws_sns_topic_policy.vpc_flow_logs_fanout](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_policy) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.cloudtrail_kms_key_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.cloudtrail_sns_fanout_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.flow_log_kms_key_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.flow_logs_bucket_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.flow_logs_sns_fanout_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.logging_bucket_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.sensitive_bucket_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_profile"></a> [aws\_profile](#input\_aws\_profile) | AWS CLI profile to use | `string` | `"wiz-demo"` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region for resources | `string` | `"ap-southeast-2"` | no |
| <a name="input_backend_config_json_path"></a> [backend\_config\_json\_path](#input\_backend\_config\_json\_path) | Path to the backend configuration JSON file | `string` | n/a | yes |
| <a name="input_common_tags"></a> [common\_tags](#input\_common\_tags) | Common tags to apply to all resources | `map(string)` | <pre>{<br/>  "Environment": "Demo",<br/>  "ManagedBy": "Terraform",<br/>  "Project": "React2Shell"<br/>}</pre> | no |
| <a name="input_eks_cluster_version"></a> [eks\_cluster\_version](#input\_eks\_cluster\_version) | Kubernetes version for the EKS cluster | `string` | `"1.32"` | no |
| <a name="input_eks_node_instance_type"></a> [eks\_node\_instance\_type](#input\_eks\_node\_instance\_type) | Instance type for EKS managed node group | `string` | `"t3.medium"` | no |
| <a name="input_enabled_logs"></a> [enabled\_logs](#input\_enabled\_logs) | Object to signify building logging assets for Wiz Defend | <pre>object({<br/>    vpc_flow_logs     = optional(bool, true)<br/>    cloudtrail        = optional(bool, true)<br/>    s3_access_logging = optional(bool, true)<br/>    route53_logs      = optional(bool, true)<br/>  })</pre> | `{}` | no |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | Prefix for resource names | `string` | `"wiz-demo"` | no |
| <a name="input_s3_bucket_lifecycle_rules"></a> [s3\_bucket\_lifecycle\_rules](#input\_s3\_bucket\_lifecycle\_rules) | Map of S3 bucket lifecycle rules | <pre>map(list(object({<br/>    id                                     = string<br/>    enabled                                = optional(bool, true)<br/>    prefix                                 = optional(string)<br/>    expiration_days                        = optional(number)<br/>    expired_object_delete_marker           = optional(bool)<br/>    noncurrent_version_expiration_days     = optional(number)<br/>    abort_incomplete_multipart_upload_days = optional(number)<br/>  })))</pre> | `{}` | no |
| <a name="input_s3_buckets"></a> [s3\_buckets](#input\_s3\_buckets) | Object Map that contains the configuration for the S3 bucket configurations. | <pre>object({<br/>    sensitiveDataBucket = optional(object({<br/>      create        = optional(bool, true)<br/>      bucket_name   = optional(string, "cloudtrail")<br/>      description   = optional(string, "bucket to hold CloudTrail event data")<br/>      versioning    = optional(bool, true)<br/>      force_destroy = optional(bool, true)<br/>      public_access = optional(bool, false)<br/>      replication_destinations = optional(list(object({<br/>        bucket_arn         = string<br/>        kms_key_arn        = optional(string)<br/>        destination_region = optional(string)<br/>      })), [])<br/>      encrypt            = optional(bool, true)<br/>      bucket_key_enabled = optional(bool, true)<br/>      kms_key_arn        = optional(string, "")<br/>    }), {})<br/>    flowLogs = optional(object({<br/>      create        = optional(bool, true)<br/>      bucket_name   = optional(string, "flow-logs")<br/>      description   = optional(string, "bucket to hold VPC Flow Logs")<br/>      versioning    = optional(bool, true)<br/>      force_destroy = optional(bool, true)<br/>      public_access = optional(bool, false)<br/>      replication_destinations = optional(list(object({<br/>        bucket_arn         = string<br/>        kms_key_arn        = optional(string)<br/>        destination_region = optional(string)<br/>      })), [])<br/>      encrypt            = optional(bool, true)<br/>      bucket_key_enabled = optional(bool, true)<br/>      kms_key_arn        = optional(string, "")<br/>    }), {})<br/>  })</pre> | `{}` | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | CIDR block for the VPC | `string` | `"10.0.0.0/16"` | no |
| <a name="input_wiz_aws_connector_config"></a> [wiz\_aws\_connector\_config](#input\_wiz\_aws\_connector\_config) | Configuration for the Wiz AWS Connector scanning capabilities | <pre>object({<br/>    lightsail_scanning_enabled  = optional(bool, false)<br/>    data_scanning_enabled       = optional(bool, true)<br/>    eks_scanning_enabled        = optional(bool, true)<br/>    terraform_scanning_enabled  = optional(bool, true)<br/>    cloud_cost_scanning_enabled = optional(bool, true)<br/>    defend_scanning_enabled     = optional(bool, true)<br/>  })</pre> | `{}` | no |
| <a name="input_wiz_tenant_id"></a> [wiz\_tenant\_id](#input\_wiz\_tenant\_id) | External ID for Wiz tenant. Required for connector authentication. | `string` | `""` | no |
| <a name="input_wiz_trusted_arn"></a> [wiz\_trusted\_arn](#input\_wiz\_trusted\_arn) | Remote ARN for Wiz AWS Connector (AssumeRoleDelegator). Get this from Wiz portal or 1Password. | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_aws_account_id"></a> [aws\_account\_id](#output\_aws\_account\_id) | AWS account ID |
| <a name="output_aws_region"></a> [aws\_region](#output\_aws\_region) | AWS region |
| <a name="output_cloudtrail_arn"></a> [cloudtrail\_arn](#output\_cloudtrail\_arn) | ARN of the CloudTrail |
| <a name="output_cloudtrail_bucket_name"></a> [cloudtrail\_bucket\_name](#output\_cloudtrail\_bucket\_name) | Name of the CloudTrail S3 bucket |
| <a name="output_cloudtrail_bucket_region"></a> [cloudtrail\_bucket\_region](#output\_cloudtrail\_bucket\_region) | Region of the CloudTrail bucket |
| <a name="output_cloudtrail_name"></a> [cloudtrail\_name](#output\_cloudtrail\_name) | Name of the CloudTrail |
| <a name="output_cloudtrail_sns_topic_arn"></a> [cloudtrail\_sns\_topic\_arn](#output\_cloudtrail\_sns\_topic\_arn) | ARN of the CloudTrail SNS topic |
| <a name="output_cluster_oidc_provider"></a> [cluster\_oidc\_provider](#output\_cluster\_oidc\_provider) | OIDC provider URL (without https://) |
| <a name="output_cluster_oidc_provider_arn"></a> [cluster\_oidc\_provider\_arn](#output\_cluster\_oidc\_provider\_arn) | ARN of the OIDC provider for the EKS cluster |
| <a name="output_ecr_repository_arn"></a> [ecr\_repository\_arn](#output\_ecr\_repository\_arn) | ARN of the ECR repository |
| <a name="output_ecr_repository_url"></a> [ecr\_repository\_url](#output\_ecr\_repository\_url) | URL of the ECR repository |
| <a name="output_eks_cluster_arn"></a> [eks\_cluster\_arn](#output\_eks\_cluster\_arn) | ARN of the EKS cluster |
| <a name="output_eks_cluster_ca_certificate"></a> [eks\_cluster\_ca\_certificate](#output\_eks\_cluster\_ca\_certificate) | Base64 encoded CA certificate for the EKS cluster |
| <a name="output_eks_cluster_endpoint"></a> [eks\_cluster\_endpoint](#output\_eks\_cluster\_endpoint) | Endpoint for the EKS cluster API server |
| <a name="output_eks_cluster_name"></a> [eks\_cluster\_name](#output\_eks\_cluster\_name) | Name of the EKS cluster |
| <a name="output_flow_logs_bucket_name"></a> [flow\_logs\_bucket\_name](#output\_flow\_logs\_bucket\_name) | Name of the VPC Flow Logs S3 bucket |
| <a name="output_private_subnets"></a> [private\_subnets](#output\_private\_subnets) | List of private subnet IDs |
| <a name="output_public_subnets"></a> [public\_subnets](#output\_public\_subnets) | List of public subnet IDs |
| <a name="output_random_prefix_id"></a> [random\_prefix\_id](#output\_random\_prefix\_id) | Random prefix ID for this deployment |
| <a name="output_route53_logs_bucket_arn"></a> [route53\_logs\_bucket\_arn](#output\_route53\_logs\_bucket\_arn) | ARN of the Route53 logs bucket |
| <a name="output_route53_logs_bucket_name"></a> [route53\_logs\_bucket\_name](#output\_route53\_logs\_bucket\_name) | Name of the Route53 logs S3 bucket |
| <a name="output_route53_logs_bucket_region"></a> [route53\_logs\_bucket\_region](#output\_route53\_logs\_bucket\_region) | Region of the Route53 logs bucket |
| <a name="output_route53_logs_iam_policy_arns"></a> [route53\_logs\_iam\_policy\_arns](#output\_route53\_logs\_iam\_policy\_arns) | Map of IAM policy ARNs for Route53 logs by role prefix |
| <a name="output_route53_logs_kms_key_arn"></a> [route53\_logs\_kms\_key\_arn](#output\_route53\_logs\_kms\_key\_arn) | ARN of the Route53 logs KMS key |
| <a name="output_route53_logs_sns_topic_arn"></a> [route53\_logs\_sns\_topic\_arn](#output\_route53\_logs\_sns\_topic\_arn) | ARN of the Route53 logs SNS topic |
| <a name="output_route53_logs_sqs_queue_arns"></a> [route53\_logs\_sqs\_queue\_arns](#output\_route53\_logs\_sqs\_queue\_arns) | Map of SQS queue ARNs for Route53 logs by role prefix |
| <a name="output_route53_logs_sqs_queue_urls"></a> [route53\_logs\_sqs\_queue\_urls](#output\_route53\_logs\_sqs\_queue\_urls) | Map of SQS queue URLs for Route53 logs by role prefix |
| <a name="output_s3_access_logs_bucket_name"></a> [s3\_access\_logs\_bucket\_name](#output\_s3\_access\_logs\_bucket\_name) | Name of the S3 access logs bucket |
| <a name="output_vpc_cidr_block"></a> [vpc\_cidr\_block](#output\_vpc\_cidr\_block) | CIDR block of the VPC |
| <a name="output_vpc_flow_log_id"></a> [vpc\_flow\_log\_id](#output\_vpc\_flow\_log\_id) | ID of the VPC Flow Log |
| <a name="output_vpc_flow_logs_bucket_name"></a> [vpc\_flow\_logs\_bucket\_name](#output\_vpc\_flow\_logs\_bucket\_name) | Name of the VPC Flow Logs S3 bucket (alias for flow\_logs\_bucket\_name) |
| <a name="output_vpc_flow_logs_bucket_region"></a> [vpc\_flow\_logs\_bucket\_region](#output\_vpc\_flow\_logs\_bucket\_region) | Region of the VPC Flow Logs bucket |
| <a name="output_vpc_flow_logs_object_map"></a> [vpc\_flow\_logs\_object\_map](#output\_vpc\_flow\_logs\_object\_map) | Outputs from the VPC Flow Logs module (SQS queues per tenant) |
| <a name="output_vpc_flow_logs_sns_topic_arn"></a> [vpc\_flow\_logs\_sns\_topic\_arn](#output\_vpc\_flow\_logs\_sns\_topic\_arn) | ARN of the VPC Flow Logs SNS topic |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | ID of the VPC |
| <a name="output_wiz_events_object_map"></a> [wiz\_events\_object\_map](#output\_wiz\_events\_object\_map) | Outputs from the Wiz AWS Cloud Events module (CloudTrail SQS queues per tenant) |
| <a name="output_wiz_permission_object_map"></a> [wiz\_permission\_object\_map](#output\_wiz\_permission\_object\_map) | Outputs from the Wiz AWS Permissions module (role ARN for connector) |
<!-- END_TF_DOCS -->
