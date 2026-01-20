# k8s-services

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 2.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | ~> 2.0 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | ~> 2.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [helm_release.argocd](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.wiz_argocd_application](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_namespace.argocd](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_namespace.wiz](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_secret.argocd_initial_admin_secret](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/secret) | data source |
| [kubernetes_service.argocd_server](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/service) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cluster_type"></a> [cluster\_type](#input\_cluster\_type) | Cluster type for Wiz config | `string` | `"EKS"` | no |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | Prefix for naming | `string` | n/a | yes |
| <a name="input_random_prefix_id"></a> [random\_prefix\_id](#input\_random\_prefix\_id) | Random ID to use in resource names (matches reference repo pattern) | `string` | n/a | yes |
| <a name="input_use_wiz_admission_controller"></a> [use\_wiz\_admission\_controller](#input\_use\_wiz\_admission\_controller) | Whether to use Wiz admission controller | `bool` | `false` | no |
| <a name="input_use_wiz_sensor"></a> [use\_wiz\_sensor](#input\_use\_wiz\_sensor) | Whether to use Wiz sensor | `bool` | `false` | no |
| <a name="input_wiz_k8s_integration_client_endpoint"></a> [wiz\_k8s\_integration\_client\_endpoint](#input\_wiz\_k8s\_integration\_client\_endpoint) | Wiz Kubernetes integration client endpoint (e.g., prod, commercial, demo) | `string` | `""` | no |
| <a name="input_wiz_k8s_integration_client_id"></a> [wiz\_k8s\_integration\_client\_id](#input\_wiz\_k8s\_integration\_client\_id) | Wiz Kubernetes integration client ID | `string` | `""` | no |
| <a name="input_wiz_k8s_integration_client_secret"></a> [wiz\_k8s\_integration\_client\_secret](#input\_wiz\_k8s\_integration\_client\_secret) | Wiz Kubernetes integration client secret | `string` | `""` | no |
| <a name="input_wiz_sensor_pull_password"></a> [wiz\_sensor\_pull\_password](#input\_wiz\_sensor\_pull\_password) | Wiz sensor image pull password | `string` | `""` | no |
| <a name="input_wiz_sensor_pull_username"></a> [wiz\_sensor\_pull\_username](#input\_wiz\_sensor\_pull\_username) | Wiz sensor image pull username | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_argocd_namespace"></a> [argocd\_namespace](#output\_argocd\_namespace) | The ArgoCD namespace |
| <a name="output_argocd_password"></a> [argocd\_password](#output\_argocd\_password) | The ArgoCD admin password |
| <a name="output_argocd_url"></a> [argocd\_url](#output\_argocd\_url) | The ArgoCD LoadBalancer hostname |
| <a name="output_kubernetes_connector_name"></a> [kubernetes\_connector\_name](#output\_kubernetes\_connector\_name) | The Wiz Kubernetes connector name |
| <a name="output_wiz_namespace"></a> [wiz\_namespace](#output\_wiz\_namespace) | The Wiz namespace |
<!-- END_TF_DOCS -->
