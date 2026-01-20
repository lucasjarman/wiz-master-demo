module "aws_cloud_events" {
  source = "../.."

  cloudtrail_arn        = "<CLOUDTRAIL_ARN>"
  cloudtrail_bucket_arn = "<CLOUDTRAIL_BUCKET_ARN>"
  cloudtrail_kms_arn    = "<CLOUDTRAIL_KMS_ARN>"

  use_existing_sns_topic       = true
  sns_topic_arn                = "<EXISTING_SNS_TOPIC_ARN>"
  sns_topic_encryption_enabled = false

  wiz_access_role_arn = "arn:<AWS-PARTITION>:iam::<AWS-ACCOUNT-ID>:role/<ROLE-NAME>"
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
