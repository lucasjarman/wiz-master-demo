module "wiz_cloud_cost" {
  source = "../.."

  create_new_export   = true
  wiz_access_role_arn = "arn:<AWS-PARTITION>:iam::<AWS-ACCOUNT-ID>:role/<ROLE-NAME>"
}
