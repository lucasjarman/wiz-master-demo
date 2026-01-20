# develop

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 2.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.0 |
| <a name="requirement_wiz"></a> [wiz](#requirement\_wiz) | ~> 1.26 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |
| <a name="provider_wiz"></a> [wiz](#provider\_wiz) | ~> 1.26 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_k8s_services"></a> [k8s\_services](#module\_k8s\_services) | ../../../modules/k8s-services | n/a |
| <a name="module_wiz_aws_connector"></a> [wiz\_aws\_connector](#module\_wiz\_aws\_connector) | ../../../modules/wiz/aws-connector | n/a |

## Resources

| Name | Type |
|------|------|
| wiz_service_account.eks_cluster | resource |
| [terraform_remote_state.shared_resources](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/data-sources/remote_state) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_connector_config"></a> [aws\_connector\_config](#input\_aws\_connector\_config) | Configuration for the Wiz AWS Connector cloud events monitoring | <pre>object({<br/>    audit_log_enabled   = optional(bool, true)<br/>    network_log_enabled = optional(bool, true)<br/>    dns_log_enabled     = optional(bool, true)<br/>  })</pre> | `{}` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region | `string` | `"ap-southeast-2"` | no |
| <a name="input_backend_config_json_path"></a> [backend\_config\_json\_path](#input\_backend\_config\_json\_path) | Path to the backend configuration JSON file | `string` | n/a | yes |
| <a name="input_common_tags"></a> [common\_tags](#input\_common\_tags) | Common tags to apply to all resources | `map(string)` | <pre>{<br/>  "Environment": "Demo",<br/>  "ManagedBy": "Terraform",<br/>  "Project": "React2Shell"<br/>}</pre> | no |
| <a name="input_create_aws_connector"></a> [create\_aws\_connector](#input\_create\_aws\_connector) | Whether to create the Wiz AWS Cloud Connector. Requires wiz\_trusted\_arn to be set in shared/aws. | `bool` | `true` | no |
| <a name="input_create_eks_services_deployment"></a> [create\_eks\_services\_deployment](#input\_create\_eks\_services\_deployment) | Whether to create EKS services (ArgoCD, Wiz K8s connector, sensor). Set to false if EKS cluster doesn't exist yet. | `bool` | `true` | no |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | Prefix for resource naming | `string` | `"wiz-demo"` | no |
| <a name="input_tenant_image_pull_password"></a> [tenant\_image\_pull\_password](#input\_tenant\_image\_pull\_password) | Password for pulling Wiz sensor images (from 1Password wizautesting/Password) | `string` | n/a | yes |
| <a name="input_tenant_image_pull_username"></a> [tenant\_image\_pull\_username](#input\_tenant\_image\_pull\_username) | Username for pulling Wiz sensor images (from 1Password wizautesting/Username) | `string` | n/a | yes |
| <a name="input_wiz_admission_controller_enabled"></a> [wiz\_admission\_controller\_enabled](#input\_wiz\_admission\_controller\_enabled) | Whether to deploy Wiz admission controller | `bool` | `false` | no |
| <a name="input_wiz_client_environment"></a> [wiz\_client\_environment](#input\_wiz\_client\_environment) | Wiz client environment for the Kubernetes Connector. Options: prod, commercial, demo | `string` | `"prod"` | no |
| <a name="input_wiz_sensor_enabled"></a> [wiz\_sensor\_enabled](#input\_wiz\_sensor\_enabled) | Whether to deploy Wiz runtime sensor | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_argocd_namespace"></a> [argocd\_namespace](#output\_argocd\_namespace) | ArgoCD namespace |
| <a name="output_aws_connector_id"></a> [aws\_connector\_id](#output\_aws\_connector\_id) | ID of the Wiz AWS Cloud Connector |
| <a name="output_aws_connector_name"></a> [aws\_connector\_name](#output\_aws\_connector\_name) | Name of the Wiz AWS Cloud Connector |
| <a name="output_kubernetes_connector_name"></a> [kubernetes\_connector\_name](#output\_kubernetes\_connector\_name) | Wiz Kubernetes connector name |
| <a name="output_wiz_namespace"></a> [wiz\_namespace](#output\_wiz\_namespace) | Wiz namespace |
| <a name="output_wiz_service_account_id"></a> [wiz\_service\_account\_id](#output\_wiz\_service\_account\_id) | ID of the dynamically created Wiz service account |
| <a name="output_wiz_service_account_name"></a> [wiz\_service\_account\_name](#output\_wiz\_service\_account\_name) | Name of the dynamically created Wiz service account |
<!-- END_TF_DOCS -->
