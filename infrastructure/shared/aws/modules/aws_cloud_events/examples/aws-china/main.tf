module "aws_cloud_events" {
  source = "../.."

  integration_type = "S3"

  cloudtrail_bucket_arn = "<CLOUDTRAIL_BUCKET_ARN>"
  cloudtrail_kms_arn    = "<CLOUDTRAIL_KMS_ARN>"

  wiz_access_role_arn = "arn:<AWS-PARTITION>:iam::<AWS-ACCOUNT-ID>:role/<ROLE-NAME>"

  kms_key_multi_region = false
}

terraform {
  required_version = ">= 1.10"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.83"
    }
  }
}
