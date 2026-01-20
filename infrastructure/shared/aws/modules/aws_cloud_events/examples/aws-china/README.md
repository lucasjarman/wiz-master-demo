# Integrate CloudTrail S3 Bucket Notifications with Wiz Cloud Events (new SNS) - AWS China

The following Terraform provides an example of integrating CloudTrail S3 Bucket Notifications to Wiz Cloud Events for AWS China. The bucket name and bucket account will be provided as outputs.

**AWS China does not support multi-region KMS keys**

```hcl
provider "aws" {}

module "aws_cloud_events" {
  source = "https://s3-us-east-2.amazonaws.com/wizio-public/deployment-v2/aws/wiz-aws-cloud-events-terraform-module.zip"

  integration_type = "S3"

  cloudtrail_bucket_arn = "<CLOUDTRAIL_BUCKET_ARN>"
  cloudtrail_kms_arn    = "<CLOUDTRAIL_KMS_ARN>"

  wiz_access_role_arn = "<WIZ_ACCESS_USER_ARN>"

  kms_key_multi_region = false
}

output "bucket_name" {
    value = module.aws_cloud_events.bucket_name
}

output "bucket_account" {
    value = module.aws_cloud_events.bucket_account
}
```
