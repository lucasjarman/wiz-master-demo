# Integrate AWS CloudTrail with Wiz Cloud Events (existing SNS)

The following Terraform provides an example of integrating an AWS CloudTrail, with notifications to an existing SNS Topic, to Wiz Cloud Events. The bucket name and bucket account will be provided as outputs.

```hcl
provider "aws" {}

module "aws_cloud_events" {
  source = "https://s3-us-east-2.amazonaws.com/wizio-public/deployment-v2/aws/wiz-aws-cloud-events-terraform-module.zip"

  cloudtrail_arn        = "<CLOUDTRAIL_ARN>"
  cloudtrail_bucket_arn = "<CLOUDTRAIL_BUCKET_ARN>"
  cloudtrail_kms_arn    = "<CLOUDTRAIL_KMS_ARN>"

  use_existing_sns_topic       = true
  sns_topic_arn                = "<EXISTING_SNS_TOPIC_ARN>"
  sns_topic_encryption_enabled = false

  wiz_access_role_arn = "<WIZ_ACCESS_ROLE_ARN>"
}

output "bucket_name" {
    value = module.aws_cloud_events.bucket_name
}

output "bucket_account" {
    value = module.aws_cloud_events.bucket_account
}
```

The existing SNS Topic will need to allow subscriptions from the new SQS Queue. By default, the module will attempt to automatically create the SNS Topic subscription, but this behavior can be modified with the `create_sns_topic_subscription` boolean variable. An example SNS access policy statement to allow subscriptions is shown below.

```json
{
  "Sid": "AllowSubscribeFromAccount",
  "Effect": "Allow",
  "Principal": {
    "AWS": "arn:aws:iam::<AWS_ACCOUNT_ID>:root"
  },
  "Action": "sns:Subscribe",
  "Resource": "<SNS_TOPIC_ARN>"
}
```
