locals {
  create_kms_key         = false
  create_s3_notification = var.integration_type == "S3" && ((var.s3_notification_type == "SNS" && !var.use_existing_sns_topic) || var.s3_notification_type == "SQS")
  create_sns_topic       = local.use_sns_topic ? !var.use_existing_sns_topic : false

  split_cloudtrail_bucket_arn = split(":", var.cloudtrail_bucket_arn)
  cloudtrail_bucket_name      = element(local.split_cloudtrail_bucket_arn, (length(local.split_cloudtrail_bucket_arn) - 1))

  sns_topic_arn     = local.use_sns_topic ? (length(var.sns_topic_arn) > 0 ? var.sns_topic_arn : aws_sns_topic.wiz-cloud-events[0].id) : ""
  sns_topic_key_arn = local.use_sns_topic ? (var.sns_topic_encryption_enabled ? (length(var.sns_topic_encryption_key_arn) > 0 ? var.sns_topic_encryption_key_arn : aws_kms_key.wiz_kms_key[0].arn) : "") : ""

  sqs_queue_key_arn = var.sqs_encryption_enabled ? (length(var.sqs_encryption_key_arn) > 0 ? var.sqs_encryption_key_arn : aws_kms_key.wiz_kms_key[0].arn) : ""
  sqs_source_arn    = var.integration_type == "S3" && var.s3_notification_type == "SQS" ? var.cloudtrail_bucket_arn : local.sns_topic_arn

  use_sns_topic = var.integration_type == "S3" && var.s3_notification_type == "SQS" ? false : true

  # Use explicit variable if provided, otherwise fall back to ARN parsing (may fail at plan time)
  wiz_access_via_user  = !var.wiz_access_is_role
  wiz_access_role_name = length(var.wiz_access_role_name) > 0 ? var.wiz_access_role_name : element(split("/", var.wiz_access_role_arn), length(split("/", var.wiz_access_role_arn)) - 1)
}

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

resource "aws_kms_key" "wiz_kms_key" {
  count = local.create_kms_key ? 1 : 0

  description             = "A KMS key used to encrypt CloudTrail log notifications which are monitored by Wiz"
  deletion_window_in_days = var.kms_key_deletion_days
  enable_key_rotation     = var.kms_key_rotation
  multi_region            = var.kms_key_multi_region
  policy                  = data.aws_iam_policy_document.kms_key_policy[0].json
}

data "aws_iam_policy_document" "kms_key_policy" {
  count = local.create_kms_key ? 1 : 0

  version = "2012-10-17"

  statement {
    sid       = "Enable IAM User Permissions"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }

  dynamic "statement" {
    for_each = var.integration_type == "CLOUDTRAIL" && local.create_sns_topic ? [1] : []
    content {
      sid = "Allow CloudTrail service to encrypt/decrypt"
      actions = [
        "kms:GenerateDataKey*",
        "kms:Decrypt"
      ]
      resources = ["*"]

      principals {
        type        = "Service"
        identifiers = ["cloudtrail.amazonaws.com"]
      }

      condition {
        test     = "ArnEquals"
        variable = "aws:SourceArn"
        values = [
          var.cloudtrail_arn
        ]
      }
    }
  }

  dynamic "statement" {
    for_each = var.integration_type == "S3" && local.create_sns_topic ? [1] : []
    content {
      sid = "Allow S3 bucket to encrypt/decrypt"
      actions = [
        "kms:GenerateDataKey*",
        "kms:Decrypt"
      ]
      resources = ["*"]

      principals {
        type        = "Service"
        identifiers = ["s3.amazonaws.com"]
      }

      condition {
        test     = "ArnEquals"
        variable = "aws:SourceArn"
        values = [
          var.cloudtrail_bucket_arn
        ]
      }
    }
  }

  dynamic "statement" {
    for_each = (local.use_sns_topic) ? [1] : []
    content {
      sid = "Allow SNS service to encrypt/decrypt"
      actions = [
        "kms:GenerateDataKey*",
        "kms:Decrypt"
      ]
      resources = ["*"]

      principals {
        type        = "Service"
        identifiers = ["sns.amazonaws.com"]
      }
    }
  }
}

# tflint-ignore: terraform_naming_convention
resource "aws_sns_topic" "wiz-cloud-events" {
  count = local.create_sns_topic ? 1 : 0

  name              = "${var.prefix}-wiz-cloudtrail-logs-notify"
  kms_master_key_id = local.sns_topic_key_arn
}

data "aws_iam_policy_document" "sns_topic_policy" {
  count = local.create_sns_topic ? 1 : 0

  version = "2012-10-17"

  dynamic "statement" {
    for_each = var.integration_type == "CLOUDTRAIL" ? [1] : []
    content {
      sid       = "AllowCloudTrailToPublishMessage"
      actions   = ["SNS:Publish"]
      resources = [local.sns_topic_arn]

      principals {
        type        = "Service"
        identifiers = ["cloudtrail.amazonaws.com"]
      }

      condition {
        test     = "ArnEquals"
        variable = "aws:SourceArn"
        values = [
          var.cloudtrail_arn
        ]
      }
    }
  }

  dynamic "statement" {
    for_each = (var.integration_type == "S3" && var.s3_notification_type == "SNS") ? [1] : []
    content {
      sid       = "AllowCloudTrailS3ToPublishMessage"
      actions   = ["SNS:Publish"]
      resources = [local.sns_topic_arn]

      principals {
        type        = "Service"
        identifiers = ["s3.amazonaws.com"]
      }

      condition {
        test     = "ArnEquals"
        variable = "aws:SourceArn"
        values = [
          var.cloudtrail_bucket_arn
        ]
      }
    }
  }
}

resource "aws_sns_topic_policy" "default" {
  count = local.create_sns_topic ? 1 : 0

  arn    = local.sns_topic_arn
  policy = data.aws_iam_policy_document.sns_topic_policy[0].json
}

# tflint-ignore: terraform_naming_convention
resource "aws_sqs_queue" "wiz-cloud-events" {
  name              = "${var.prefix}-wiz-cloudtrail-logs-queue"
  kms_master_key_id = local.sqs_queue_key_arn
}

# tflint-ignore: terraform_naming_convention
resource "aws_sqs_queue_policy" "wiz-cloud-events" {
  queue_url = aws_sqs_queue.wiz-cloud-events.id
  policy    = data.aws_iam_policy_document.sqs_queue_policy.json
}

data "aws_iam_policy_document" "sqs_queue_policy" {
  version = "2012-10-17"

  statement {
    sid       = "AllowSendMessage"
    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.wiz-cloud-events.arn]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values = [
        local.sqs_source_arn
      ]
    }
  }

  statement {
    sid = "AllowWizRecvDeleteMsg"
    actions = [
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:ReceiveMessage"
    ]
    resources = [aws_sqs_queue.wiz-cloud-events.arn]

    principals {
      type        = "AWS"
      identifiers = [var.wiz_access_role_arn]
    }
  }
}

# tflint-ignore: terraform_naming_convention
resource "aws_sns_topic_subscription" "wiz-cloudtrail-logs" {
  count = local.use_sns_topic && var.create_sns_topic_subscription ? 1 : 0

  confirmation_timeout_in_minutes = 1
  endpoint_auto_confirms          = false
  topic_arn                       = local.sns_topic_arn
  protocol                        = "sqs"
  endpoint                        = aws_sqs_queue.wiz-cloud-events.arn
  raw_message_delivery            = true
}

resource "aws_iam_policy" "wiz_allow_cloudtrail_bucket_access" {
  name        = "${var.prefix}-WizAllowCloudTrailBucketAccessPolicy"
  description = "Allow Wiz access to CloudTrail bucket and logs"
  policy      = data.aws_iam_policy_document.wiz_access_role_policy.json
}

data "aws_iam_policy_document" "wiz_access_role_policy" {
  version = "2012-10-17"

  statement {
    sid = "AllowWizAccessCloudtrailS3ListGetLocation"
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket"
    ]
    resources = [var.cloudtrail_bucket_arn]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["true"]
    }
  }

  statement {
    sid       = "AllowWizAccessCloudtrailS3Get"
    actions   = ["s3:GetObject"]
    resources = ["${var.cloudtrail_bucket_arn}/*"]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["true"]
    }
  }

  dynamic "statement" {
    for_each = length(var.cloudtrail_kms_arn) > 0 ? [1] : []
    content {
      sid       = "AllowWizDecryptCloudTrailLogs"
      actions   = ["kms:Decrypt"]
      resources = [var.cloudtrail_kms_arn]
    }
  }

  dynamic "statement" {
    for_each = var.sqs_encryption_enabled ? [1] : []
    content {
      sid       = "AllowWizDecryptQueueFiles"
      actions   = ["kms:Decrypt"]
      resources = [local.sqs_queue_key_arn]
    }
  }
}

resource "aws_iam_user_policy_attachment" "wiz_access_user" {
  count = local.wiz_access_via_user ? 1 : 0

  user       = local.wiz_access_role_name
  policy_arn = aws_iam_policy.wiz_allow_cloudtrail_bucket_access.arn
}

resource "aws_iam_role_policy_attachment" "wiz_access_role" {
  count = local.wiz_access_via_user ? 0 : 1

  role       = local.wiz_access_role_name
  policy_arn = aws_iam_policy.wiz_allow_cloudtrail_bucket_access.arn
}

resource "aws_s3_bucket_notification" "cloudtrail_bucket_notification" {
  count = local.create_s3_notification ? 1 : 0

  bucket = local.cloudtrail_bucket_name

  dynamic "queue" {
    for_each = (var.s3_notification_type == "SQS") ? [1] : []
    content {
      queue_arn     = aws_sqs_queue.wiz-cloud-events.arn
      events        = ["s3:ObjectCreated:*"]
      filter_prefix = var.s3_notification_log_prefix
    }
  }

  dynamic "topic" {
    for_each = (var.s3_notification_type == "SNS") ? [1] : []
    content {
      topic_arn     = local.sns_topic_arn
      events        = ["s3:ObjectCreated:*"]
      filter_prefix = var.s3_notification_log_prefix
    }
  }

  depends_on = [
    aws_sns_topic_policy.default,
    aws_sqs_queue_policy.wiz-cloud-events,
  ]
}
