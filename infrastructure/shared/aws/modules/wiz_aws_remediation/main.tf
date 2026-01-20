resource "aws_s3_bucket" "WizRemediationCustomFunctionsBucket" {
  count         = var.WizRemediationCustomFunctionsBucketEnabled ? 1 : 0
  bucket        = "${var.WizRemediationResourcesPrefix}-${var.WizRemediationCustomFunctionsBucketName}-${data.aws_caller_identity.current.account_id}"
  force_destroy = true

  tags = local.tags
}

resource "aws_s3_object" "WizRemediationCustomFunctionsBucketFolders" {
  count      = var.WizRemediationCustomFunctionsBucketEnabled ? 1 : 0
  depends_on = [aws_s3_bucket.WizRemediationCustomFunctionsBucket]
  bucket     = aws_s3_bucket.WizRemediationCustomFunctionsBucket[0].bucket
  key        = "wiz/response_functions/CUSTOM_001.py"
  source     = "${path.module}/CUSTOM_001.py"
  tags       = local.tags
}

resource "aws_s3_object" "WizRemediationCustomFunctionsBucketJson" {
  count      = var.WizRemediationCustomFunctionsBucketEnabled ? 1 : 0
  depends_on = [aws_s3_bucket.WizRemediationCustomFunctionsBucket]
  bucket     = aws_s3_bucket.WizRemediationCustomFunctionsBucket[0].bucket
  key        = "wiz/response_functions/CUSTOM_001.json"
  source     = "${path.module}/CUSTOM_001.json"
  tags       = local.tags
}

resource "aws_s3_bucket_ownership_controls" "WizRemediationCustomFunctionsBucketOwnership" {
  count      = var.WizRemediationCustomFunctionsBucketEnabled ? 1 : 0
  depends_on = [aws_s3_bucket.WizRemediationCustomFunctionsBucket]
  bucket     = aws_s3_bucket.WizRemediationCustomFunctionsBucket[0].bucket
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "WizRemediationCustomFunctionsBucketPublicBlock" {
  count      = var.WizRemediationCustomFunctionsBucketEnabled ? 1 : 0
  depends_on = [aws_s3_bucket.WizRemediationCustomFunctionsBucket]
  bucket     = aws_s3_bucket.WizRemediationCustomFunctionsBucket[0].bucket

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "WizRemediationCustomFunctionsBucketPolicy" {
  count      = var.WizRemediationCustomFunctionsBucketEnabled ? 1 : 0
  depends_on = [aws_s3_bucket.WizRemediationCustomFunctionsBucket]
  bucket     = aws_s3_bucket.WizRemediationCustomFunctionsBucket[0].bucket
  policy     = data.aws_iam_policy_document.WizRemediationBucketPolicyDocument.json
}

resource "aws_s3_bucket_server_side_encryption_configuration" "WizRemediationCustomFunctionsBucketSSEConfiguration" {
  count      = var.WizRemediationCustomFunctionsBucketEnabled ? 1 : 0
  depends_on = [aws_s3_bucket.WizRemediationCustomFunctionsBucket]
  bucket     = aws_s3_bucket.WizRemediationCustomFunctionsBucket[0].bucket
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}
resource "aws_sns_topic" "WizIssuesToRemediateSNSTopic" {
  name              = "${var.WizRemediationResourcesPrefix}-Remediation-Issues-Topic"
  kms_master_key_id = "alias/aws/sns"
  tags              = local.tags
}

resource "aws_sns_topic_subscription" "SNSSubscription" {
  topic_arn            = aws_sns_topic.WizIssuesToRemediateSNSTopic.arn
  protocol             = "sqs"
  endpoint             = aws_sqs_queue.WizIssuesToRemediateQueue.arn
  raw_message_delivery = true
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.IssuesDeadLetterQueue.arn
  })
}
resource "aws_sns_topic_policy" "WizIssuesToRemediateSNSTopicPolicy" {
  arn    = aws_sns_topic.WizIssuesToRemediateSNSTopic.arn
  policy = data.aws_iam_policy_document.WizIssuesToRemediateSNSTopicPolicyDocument.json
}

resource "aws_iam_role" "WizAccessRoleToSns" {
  name               = "${var.WizRemediationResourcesPrefix}-Remediation-Access-Role-To-Sns"
  assume_role_policy = data.aws_iam_policy_document.SnsAssumeRoleFromWizPolicyDocument.json
  tags               = local.tags
}

resource "aws_iam_policy" "WizAccessPolicyToSns" {
  name   = "${var.WizRemediationResourcesPrefix}-Remediation-Access-Policy-To-Sns"
  policy = data.aws_iam_policy_document.WizAccessPolicyToSns.json
  tags   = local.tags
}

resource "aws_iam_role_policy_attachment" "WizAccessPolicyToSnsAttachement" {
  role       = aws_iam_role.WizAccessRoleToSns.name
  policy_arn = aws_iam_policy.WizAccessPolicyToSns.arn
}

resource "aws_sqs_queue" "WizIssuesToRemediateQueue" {
  name                       = "${var.WizRemediationResourcesPrefix}-Remediation-Queue"
  visibility_timeout_seconds = 600
  message_retention_seconds  = 900
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.IssuesDeadLetterQueue.arn
    maxReceiveCount     = 3
  })
  tags = local.tags
}

resource "aws_sqs_queue" "IssuesDeadLetterQueue" {
  name                      = "${var.WizRemediationResourcesPrefix}-Remediation-DeadLetter-Queue"
  message_retention_seconds = 604800
  tags                      = local.tags
}

resource "aws_sqs_queue_policy" "MyQueuePolicy" {
  queue_url = aws_sqs_queue.WizIssuesToRemediateQueue.id
  policy    = data.aws_iam_policy_document.MyQueuePolicy.json
}

resource "aws_sqs_queue_policy" "MyQueuePolicyDLQ" {
  queue_url = aws_sqs_queue.IssuesDeadLetterQueue.id
  policy    = data.aws_iam_policy_document.MyQueuePolicyDLQ.json
}

resource "aws_iam_role" "RemediationWorkerRole" {
  name               = "${var.WizRemediationResourcesPrefix}-${var.WizRemediationWorkerRole}"
  assume_role_policy = data.aws_iam_policy_document.RemediationWorkerRoleAssumeDocument.json
  tags               = local.tags
}

resource "aws_iam_policy" "RemediationWorkerPolicy" {
  name   = "${var.WizRemediationResourcesPrefix}-Remediation-Worker-Policy"
  policy = data.aws_iam_policy_document.RemediationWorkerPolicy.json
  tags   = local.tags
}

resource "aws_iam_role_policy_attachment" "RemediationWorkerRolePolicyAttachment" {
  role       = aws_iam_role.RemediationWorkerRole.name
  policy_arn = aws_iam_policy.RemediationWorkerPolicy.arn
}

resource "aws_iam_role" "LambdaRole" {
  name               = "${var.WizRemediationResourcesPrefix}-Remediation-Lambda-Role"
  assume_role_policy = data.aws_iam_policy_document.LambdaAssumeRoleDocument.json
  tags               = local.tags
}

resource "aws_iam_role_policy_attachment" "ManagedPolicyArns" {
  role       = aws_iam_role.LambdaRole.name
  policy_arn = "arn:${data.aws_partition.current.id}:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole"
}

resource "aws_iam_policy" "AssumeWorkerRolePolicy" {
  name   = "${var.WizRemediationResourcesPrefix}-Assume-Worker-Role-Policy"
  policy = data.aws_iam_policy_document.AssumeWorkerRolePolicyDocument.json
  tags   = local.tags
}

resource "aws_iam_role_policy_attachment" "AssumeWorkerRolePolicyAttachment" {
  role       = aws_iam_role.LambdaRole.name
  policy_arn = aws_iam_policy.AssumeWorkerRolePolicy.arn
}

resource "aws_lambda_function" "LambdaFunction" {
  function_name = "${var.WizRemediationResourcesPrefix}-Remediation-Lambda-Function"
  role          = aws_iam_role.LambdaRole.arn

  image_uri    = local.ecr_url
  package_type = "Image"
  memory_size  = 256
  timeout      = 300

  environment {
    variables = {
      WIZ_REMEDIATION_WORKER_ROLE          = "${var.WizRemediationResourcesPrefix}-${var.WizRemediationWorkerRole}"
      WIZ_AUTO_TAG_ON_UPDATE               = var.WizRemediationEnabledAutoTagOnUpdate
      WIZ_AUTO_TAG_KEY                     = var.WizRemediationAutoTagKey
      WIZ_AUTO_TAG_DATE_FORMAT             = var.WizRemediationAutoTagDateFormat
      WIZ_ENABLE_CUSTOM_RESPONSE_FUNCTIONS = var.WizRemediationCustomFunctionsBucketEnabled
      WIZ_CUSTOM_RESPONSE_FUNCTIONS_BUCKET = var.WizRemediationCustomFunctionsBucketEnabled ? aws_s3_bucket.WizRemediationCustomFunctionsBucket[0].bucket : ""
      WIZ_FAILOVER_STS_ENDPOINT_REGION     = var.WizFailoverSTSEndpointRegion
    }
  }
  tags = local.tags
}

resource "aws_lambda_event_source_mapping" "WizLambdaTrigger" {
  enabled          = true
  batch_size       = 10
  event_source_arn = aws_sqs_queue.WizIssuesToRemediateQueue.arn
  function_name    = aws_lambda_function.LambdaFunction.arn
  tags             = local.tags
}
