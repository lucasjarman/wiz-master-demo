module "wiz_cloud_cost" {
  source = "../.."

  create_new_export = false

  cost_export_name    = "My-Manually-Created-Export"
  cost_export_bucket  = "my-cost-exports-bucket"
  cost_exports_prefix = "myExportsDir"

  wiz_access_role_arn = "arn:<AWS-PARTITION>:iam::<AWS-ACCOUNT-ID>:role/<ROLE-NAME>"
}
