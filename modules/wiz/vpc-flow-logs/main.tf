locals {
  role_name = split("/", var.wiz_access_role)[1]
}

data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "wiz_access_role_policy" {
  version = "2012-10-17"

  statement {
    sid    = "AllowWizAccessVPCFlowLogsS3ListGetLocation"
    effect = "Allow"
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket"
    ]
    resources = [var.vpc_flow_logs_bucket_arn]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["true"]
    }
  }
  statement {
    sid       = "AllowWizAccessVPCFlowLogsS3Get"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${var.vpc_flow_logs_bucket_arn}/*"]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["true"]
    }
  }
  dynamic "statement" {
    for_each = length(var.flowlogs_s3_kms_arn) > 0 ? [1] : []
    content {
      sid       = "AllowWizDecryptFlowLogs"
      actions   = ["kms:Decrypt"]
      resources = [var.flowlogs_s3_kms_arn]
    }
  }

  dynamic "statement" {
    for_each = var.sqs_kms_encryption_enabled ? [1] : []
    content {
      sid       = "AllowWizDecryptQueueFiles"
      actions   = ["kms:Decrypt"]
      resources = [var.sqs_queue_key_arn != "" ? var.sqs_queue_key_arn : (var.create_kms_key ? aws_kms_key.wiz_vpc_flow_logs[0].arn : "")]
    }
  }
}

data "aws_iam_policy_document" "sqs_queue_policy" {
  version = "2012-10-17"

  statement {
    sid    = "AllowSendMessage"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }
    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.wiz_vpc_flow_logs_queue.arn]
    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [var.sns_topic_arn]
    }
  }

  statement {
    sid    = "AllowWizRecvDeleteMsg"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [var.wiz_access_role]
    }
    actions = [
      "sqs:DeleteMessage",
      "sqs:ReceiveMessage",
      "sqs:GetQueueAttributes",
      "sqs:ChangeMessageVisibility"
    ]
    resources = [aws_sqs_queue.wiz_vpc_flow_logs_queue.arn]
  }
}

data "aws_iam_policy_document" "wiz_kms_key_policy" {
  count   = var.create_kms_key ? 1 : 0
  version = "2012-10-17"

  statement {
    sid       = "Enable IAM User Permissions"
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }

  statement {
    sid = "Allow SQS service to encrypt/decrypt"
    actions = [
      "kms:GenerateDataKey*",
      "kms:Decrypt"
    ]
    resources = ["*"]
    principals {
      type        = "Service"
      identifiers = ["sqs.amazonaws.com"]
    }
  }
}

resource "aws_kms_key" "wiz_vpc_flow_logs" {
  count = var.create_kms_key ? 1 : 0

  description             = "KMS key for VPC Flow Logs"
  deletion_window_in_days = var.kms_deletion_window_in_days
  enable_key_rotation     = var.kms_enable_key_rotation
  policy                  = data.aws_iam_policy_document.wiz_kms_key_policy[0].json
  tags = merge(
    { Name = "${var.prefix}-wiz-vpc-flow-logs-key" },
    var.tags
  )
}

resource "aws_sqs_queue" "wiz_vpc_flow_logs_queue" {
  name              = "${var.prefix}-wiz-vpcflow-logs-queue"
  kms_master_key_id = var.sqs_kms_encryption_enabled ? (var.sqs_queue_key_arn != "" ? var.sqs_queue_key_arn : (var.create_kms_key ? aws_kms_key.wiz_vpc_flow_logs[0].arn : null)) : null
  tags              = var.tags
}

resource "aws_sqs_queue_policy" "wiz_vpc_flow_logs_queue_policy" {
  queue_url = aws_sqs_queue.wiz_vpc_flow_logs_queue.id
  policy    = data.aws_iam_policy_document.sqs_queue_policy.json
}

resource "aws_sns_topic_subscription" "wiz_vpc_flow_logs_notification_queue_subscription" {
  topic_arn                       = var.sns_topic_arn
  protocol                        = "sqs"
  endpoint                        = aws_sqs_queue.wiz_vpc_flow_logs_queue.arn
  raw_message_delivery            = true
  endpoint_auto_confirms          = false
  confirmation_timeout_in_minutes = 1
}

resource "aws_iam_policy" "wiz_allow_vpc_flow_logs_bucket_access" {
  name        = "${var.prefix}-WizAllowVPCFlowLogsBucketAccess"
  description = "Allow Wiz access to vpcflow buckets"
  policy      = data.aws_iam_policy_document.wiz_access_role_policy.json
  tags        = var.tags
}

resource "aws_iam_role_policy_attachment" "wiz_vpc_flow_logs_policy_attachment" {
  role       = local.role_name
  policy_arn = aws_iam_policy.wiz_allow_vpc_flow_logs_bucket_access.arn
}
