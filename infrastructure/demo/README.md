# demo

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 2.12 |
| <a name="requirement_kubectl"></a> [kubectl](#requirement\_kubectl) | ~> 2.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.25 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.0 |
| <a name="requirement_time"></a> [time](#requirement\_time) | ~> 0.9 |
| <a name="requirement_wiz"></a> [wiz](#requirement\_wiz) | ~> 1.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.0 |
| <a name="provider_helm"></a> [helm](#provider\_helm) | ~> 2.12 |
| <a name="provider_random"></a> [random](#provider\_random) | ~> 3.0 |
| <a name="provider_time"></a> [time](#provider\_time) | ~> 0.9 |
| <a name="provider_wiz"></a> [wiz](#provider\_wiz) | ~> 1.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_aws_cloud_events"></a> [aws\_cloud\_events](#module\_aws\_cloud\_events) | ../../modules/aws/aws-cloud-events | n/a |
| <a name="module_aws_lb_controller_irsa_role"></a> [aws\_lb\_controller\_irsa\_role](#module\_aws\_lb\_controller\_irsa\_role) | terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks | ~> 5.0 |
| <a name="module_eks"></a> [eks](#module\_eks) | terraform-aws-modules/eks/aws | ~> 20.0 |
| <a name="module_k8s_services"></a> [k8s\_services](#module\_k8s\_services) | ../../modules/k8s-services | n/a |
| <a name="module_react2shell_app"></a> [react2shell\_app](#module\_react2shell\_app) | ../../scenarios/react2shell/aws/modules/react2shell-app | n/a |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | terraform-aws-modules/vpc/aws | ~> 5.0 |
| <a name="module_wiz_aws_connector"></a> [wiz\_aws\_connector](#module\_wiz\_aws\_connector) | ../../modules/wiz/aws-connector | n/a |
| <a name="module_wiz_aws_permissions"></a> [wiz\_aws\_permissions](#module\_wiz\_aws\_permissions) | ../shared/aws/modules/wiz_aws_permissions_v2 | n/a |
| <a name="module_wiz_defend_logs"></a> [wiz\_defend\_logs](#module\_wiz\_defend\_logs) | ../../modules/aws/wiz-defend-logging | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_cloudtrail.demo](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudtrail) | resource |
| [aws_ecr_repository.app](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository) | resource |
| [aws_kms_alias.cloudtrail](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.cloudtrail](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_s3_bucket.cloudtrail_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket.sensitive_data](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_notification.cloudtrail_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_notification) | resource |
| [aws_s3_bucket_policy.cloudtrail_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.cloudtrail_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_public_access_block.sensitive_data](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.cloudtrail_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.sensitive_data](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_s3_object.api_keys](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |
| [aws_s3_object.aws_credentials](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |
| [aws_s3_object.client_keys](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |
| [aws_s3_object.customer_conversations](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |
| [aws_s3_object.customer_data](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |
| [aws_sns_topic.cloudtrail_fanout](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_sns_topic_policy.cloudtrail_fanout](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_policy) | resource |
| [helm_release.aws_load_balancer_controller](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [random_id.this](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |
| [time_sleep.wait_for_cluster](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| wiz_service_account.eks_cluster | resource |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_eks_cluster.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster) | data source |
| [aws_eks_cluster_auth.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster_auth) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_allowed_cidrs"></a> [allowed\_cidrs](#input\_allowed\_cidrs) | CIDRs allowed to access the app (your IP) | `list(string)` | <pre>[<br/>  "119.17.156.157/32"<br/>]</pre> | no |
| <a name="input_app_name"></a> [app\_name](#input\_app\_name) | Name of the demo application | `string` | `"react2shell"` | no |
| <a name="input_app_replicas"></a> [app\_replicas](#input\_app\_replicas) | Number of app replicas | `number` | `1` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region for all resources | `string` | `"ap-southeast-2"` | no |
| <a name="input_common_tags"></a> [common\_tags](#input\_common\_tags) | Common tags for all resources | `map(string)` | <pre>{<br/>  "Environment": "Demo",<br/>  "ManagedBy": "Terraform",<br/>  "Project": "WizDemo"<br/>}</pre> | no |
| <a name="input_create_eks"></a> [create\_eks](#input\_create\_eks) | Whether to create the EKS cluster | `bool` | `true` | no |
| <a name="input_create_react2shell"></a> [create\_react2shell](#input\_create\_react2shell) | Whether to deploy the React2Shell demo scenario | `bool` | `true` | no |
| <a name="input_create_wiz_connector"></a> [create\_wiz\_connector](#input\_create\_wiz\_connector) | Whether to create the Wiz AWS connector | `bool` | `true` | no |
| <a name="input_create_wiz_k8s_integration"></a> [create\_wiz\_k8s\_integration](#input\_create\_wiz\_k8s\_integration) | Whether to deploy Wiz K8s integration (sensor, admission controller) | `bool` | `true` | no |
| <a name="input_dynamic_scanner_ipv4s_develop"></a> [dynamic\_scanner\_ipv4s\_develop](#input\_dynamic\_scanner\_ipv4s\_develop) | Wiz scanner IPs for develop tenant | `string` | `""` | no |
| <a name="input_ecr_image"></a> [ecr\_image](#input\_ecr\_image) | ECR image URL (leave empty to use default) | `string` | `""` | no |
| <a name="input_eks_cluster_version"></a> [eks\_cluster\_version](#input\_eks\_cluster\_version) | Kubernetes version for EKS cluster | `string` | `"1.31"` | no |
| <a name="input_eks_node_instance_type"></a> [eks\_node\_instance\_type](#input\_eks\_node\_instance\_type) | Instance type for EKS worker nodes | `string` | `"t3.medium"` | no |
| <a name="input_enabled_logs"></a> [enabled\_logs](#input\_enabled\_logs) | Toggle for Wiz Defend log types. CloudTrail includes S3 Data Events. | <pre>object({<br/>    cloudtrail   = bool<br/>    route53_logs = bool<br/>  })</pre> | <pre>{<br/>  "cloudtrail": true,<br/>  "route53_logs": true<br/>}</pre> | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev, staging, prod) | `string` | `"dev"` | no |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | Prefix for all resource names | `string` | `"wiz-demo"` | no |
| <a name="input_tenant_image_pull_password"></a> [tenant\_image\_pull\_password](#input\_tenant\_image\_pull\_password) | Password for pulling Wiz images | `string` | `""` | no |
| <a name="input_tenant_image_pull_username"></a> [tenant\_image\_pull\_username](#input\_tenant\_image\_pull\_username) | Username for pulling Wiz images | `string` | `""` | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | CIDR block for VPC | `string` | `"10.0.0.0/16"` | no |
| <a name="input_wiz_admission_controller_enabled"></a> [wiz\_admission\_controller\_enabled](#input\_wiz\_admission\_controller\_enabled) | Enable Wiz admission controller | `bool` | `true` | no |
| <a name="input_wiz_client_environment"></a> [wiz\_client\_environment](#input\_wiz\_client\_environment) | Wiz API endpoint environment | `string` | `"app.wiz.io"` | no |
| <a name="input_wiz_sensor_enabled"></a> [wiz\_sensor\_enabled](#input\_wiz\_sensor\_enabled) | Enable Wiz runtime sensor | `bool` | `true` | no |
| <a name="input_wiz_tenant_id"></a> [wiz\_tenant\_id](#input\_wiz\_tenant\_id) | Wiz tenant ID for AWS connector trust | `string` | `""` | no |
| <a name="input_wiz_trusted_arn"></a> [wiz\_trusted\_arn](#input\_wiz\_trusted\_arn) | Wiz AssumeRoleDelegator ARN for AWS connector | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_aws_region"></a> [aws\_region](#output\_aws\_region) | AWS region |
| <a name="output_cloudtrail_bucket_name"></a> [cloudtrail\_bucket\_name](#output\_cloudtrail\_bucket\_name) | CloudTrail logs S3 bucket name |
| <a name="output_cloudtrail_sqs_queue_url"></a> [cloudtrail\_sqs\_queue\_url](#output\_cloudtrail\_sqs\_queue\_url) | CloudTrail SQS queue URL for Wiz integration |
| <a name="output_cluster_endpoint"></a> [cluster\_endpoint](#output\_cluster\_endpoint) | EKS cluster endpoint |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | EKS cluster name |
| <a name="output_cluster_oidc_provider_arn"></a> [cluster\_oidc\_provider\_arn](#output\_cluster\_oidc\_provider\_arn) | EKS OIDC provider ARN |
| <a name="output_ecr_repository_url"></a> [ecr\_repository\_url](#output\_ecr\_repository\_url) | ECR repository URL |
| <a name="output_kubeconfig_command"></a> [kubeconfig\_command](#output\_kubeconfig\_command) | Command to update kubeconfig |
| <a name="output_next_steps"></a> [next\_steps](#output\_next\_steps) | Commands to run after deployment |
| <a name="output_private_subnet_ids"></a> [private\_subnet\_ids](#output\_private\_subnet\_ids) | Private subnet IDs |
| <a name="output_public_subnet_ids"></a> [public\_subnet\_ids](#output\_public\_subnet\_ids) | Public subnet IDs |
| <a name="output_react2shell_namespace"></a> [react2shell\_namespace](#output\_react2shell\_namespace) | Kubernetes namespace for React2Shell app |
| <a name="output_react2shell_s3_bucket"></a> [react2shell\_s3\_bucket](#output\_react2shell\_s3\_bucket) | S3 bucket with sensitive data |
| <a name="output_route53_logs_bucket_name"></a> [route53\_logs\_bucket\_name](#output\_route53\_logs\_bucket\_name) | Route53 DNS logs S3 bucket name |
| <a name="output_route53_sqs_queue_url"></a> [route53\_sqs\_queue\_url](#output\_route53\_sqs\_queue\_url) | Route53 DNS logs SQS queue URL for Wiz integration |
| <a name="output_suffix"></a> [suffix](#output\_suffix) | Random suffix used for resource naming |
| <a name="output_vpc_cidr_block"></a> [vpc\_cidr\_block](#output\_vpc\_cidr\_block) | VPC CIDR block |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | VPC ID |
| <a name="output_wiz_connector_role_arn"></a> [wiz\_connector\_role\_arn](#output\_wiz\_connector\_role\_arn) | IAM role ARN for Wiz connector |
<!-- END_TF_DOCS -->
