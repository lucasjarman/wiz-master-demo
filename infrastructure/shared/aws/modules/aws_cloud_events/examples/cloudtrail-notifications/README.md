# Integrate AWS CloudTrail with Wiz Cloud Events

The following Terraform provides an example of integrating an AWS CloudTrail to Wiz Cloud Events. The bucket name and bucket account, and SNS topic will be provided as outputs.

```hcl
provider "aws" {}

module "aws_cloud_events" {
  source = "https://s3-us-east-2.amazonaws.com/wizio-public/deployment-v2/aws/wiz-aws-cloud-events-terraform-module.zip"

  cloudtrail_arn        = "<CLOUDTRAIL_ARN>"
  cloudtrail_bucket_arn = "<CLOUDTRAIL_BUCKET_ARN>"
  cloudtrail_kms_arn    = "<CLOUDTRAIL_KMS_ARN>"

  wiz_access_role_arn = "<WIZ_ACCESS_ROLE_ARN>"
}

output "bucket_name" {
    value = module.aws_cloud_events.bucket_name
}

output "bucket_account" {
    value = module.aws_cloud_events.bucket_account
}

output "sns_topic" {
    value = module.aws_cloud_events.sns_topic_arn
}
```

Once deployment of the module is complete, CloudTrail must be configured to notify the SNS Topic that is created.
