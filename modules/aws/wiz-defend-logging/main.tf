data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  create_s3_bucket = var.create_s3_bucket
  create_sns_topic = var.create_sns_topic
  create_kms_key   = var.create_kms_key

  # Use provided ARNs or created resources
  bucket_arn    = local.create_s3_bucket ? aws_s3_bucket.route53_logs[0].arn : var.route53_logs_bucket_arn
  bucket_id     = local.create_s3_bucket ? aws_s3_bucket.route53_logs[0].id : split(":::", var.route53_logs_bucket_arn)[1]
  sns_topic_arn = local.create_sns_topic ? aws_sns_topic.route53_logs_fanout[0].arn : var.sns_topic_arn
  kms_key_arn   = local.create_kms_key ? aws_kms_key.wiz_route53_logs[0].arn : var.route53_logs_s3_kms_arn

  # Create list of Wiz role ARNs for bucket policy
  wiz_role_arns = [for role_name in values(var.wiz_role_names) : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${role_name}"]
  has_wiz_roles = length(var.wiz_role_names) > 0
}

# S3 Bucket for Route53 Logs
resource "aws_s3_bucket" "route53_logs" {
  count = local.create_s3_bucket ? 1 : 0

  bucket        = "${var.prefix}-route53-logs-${data.aws_region.current.name}"
  force_destroy = var.bucket_force_destroy
  tags = merge(
    { Name = "${var.prefix}-route53-logs-${data.aws_region.current.name}" },
    var.tags
  )
}

resource "aws_s3_bucket_versioning" "route53_logs" {
  count  = local.create_s3_bucket ? 1 : 0
  bucket = aws_s3_bucket.route53_logs[0].id

  versioning_configuration {
    status = var.bucket_versioning ? "Enabled" : "Disabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "route53_logs" {
  count  = local.create_s3_bucket && var.bucket_encryption_enabled ? 1 : 0
  bucket = aws_s3_bucket.route53_logs[0].id

  rule {
    bucket_key_enabled = var.bucket_key_enabled
    apply_server_side_encryption_by_default {
      kms_master_key_id = local.kms_key_arn
      sse_algorithm     = local.kms_key_arn != "" ? "aws:kms" : "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "route53_logs" {
  count  = local.create_s3_bucket ? 1 : 0
  bucket = aws_s3_bucket.route53_logs[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "route53_logs" {
  count  = local.create_s3_bucket && length(var.bucket_lifecycle_rules) > 0 ? 1 : 0
  bucket = aws_s3_bucket.route53_logs[0].id

  dynamic "rule" {
    for_each = var.bucket_lifecycle_rules
    content {
      id     = rule.value.id
      status = rule.value.enabled ? "Enabled" : "Disabled"

      filter {
        prefix = rule.value.prefix != null ? rule.value.prefix : ""
      }

      dynamic "expiration" {
        for_each = (rule.value.expiration_days != null || rule.value.expired_object_delete_marker == true) ? [1] : []
        content {
          days                         = rule.value.expiration_days
          expired_object_delete_marker = rule.value.expired_object_delete_marker == true ? true : null
        }
      }

      dynamic "noncurrent_version_expiration" {
        for_each = rule.value.noncurrent_version_expiration_days != null ? [1] : []
        content {
          noncurrent_days = rule.value.noncurrent_version_expiration_days
        }
      }

      dynamic "abort_incomplete_multipart_upload" {
        for_each = rule.value.abort_incomplete_multipart_upload_days != null ? [1] : []
        content {
          days_after_initiation = rule.value.abort_incomplete_multipart_upload_days
        }
      }
    }
  }

  depends_on = [aws_s3_bucket_versioning.route53_logs]
}

data "aws_iam_policy_document" "route53_logs_bucket_policy" {
  statement {
    sid       = "AWSLogDeliveryWrite"
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["${local.bucket_arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }

  statement {
    sid       = "AWSLogDeliveryAclCheck"
    effect    = "Allow"
    actions   = ["s3:GetBucketAcl"]
    resources = [local.bucket_arn]

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }

  # Only include Wiz access statement if Wiz roles are configured
  dynamic "statement" {
    for_each = local.has_wiz_roles ? [1] : []
    content {
      sid    = "AllowWizAccessRoute53LogsS3"
      effect = "Allow"
      actions = [
        "s3:GetObject",
        "s3:GetBucketLocation",
        "s3:ListBucket",
      ]
      resources = [
        local.bucket_arn,
        "${local.bucket_arn}/*"
      ]

      principals {
        type        = "AWS"
        identifiers = local.wiz_role_arns
      }

      condition {
        test     = "Bool"
        variable = "aws:SecureTransport"
        values   = ["true"]
      }
    }
  }
}

resource "aws_s3_bucket_policy" "route53_logs" {
  bucket = local.bucket_id
  policy = data.aws_iam_policy_document.route53_logs_bucket_policy.json
}

# KMS Key for encryption
data "aws_iam_policy_document" "wiz_kms_key_policy" {
  count   = local.create_kms_key ? 1 : 0
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
    sid = "Allow Log Delivery to use the key"
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:Encrypt",
      "kms:GenerateDataKey*",
      "kms:ReEncrypt",
    ]
    resources = ["*"]
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }

  statement {
    sid = "Allow S3 to use the key"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey*",
    ]
    resources = ["*"]
    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }

  statement {
    sid = "Allow SNS service to encrypt/decrypt"
    actions = [
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:GenerateDataKey*",
    ]
    resources = ["*"]
    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
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

resource "aws_kms_key" "wiz_route53_logs" {
  count = local.create_kms_key ? 1 : 0

  description             = "KMS key for Route53 Logs"
  deletion_window_in_days = var.kms_deletion_window_in_days
  enable_key_rotation     = var.kms_enable_key_rotation
  policy                  = data.aws_iam_policy_document.wiz_kms_key_policy[0].json
  tags = merge(
    { Name = "${var.prefix}-wiz-route53-logs-key" },
    var.tags
  )
}

resource "aws_kms_alias" "wiz_route53_logs" {
  count = local.create_kms_key ? 1 : 0

  name          = "alias/${var.prefix}-route53-logs"
  target_key_id = aws_kms_key.wiz_route53_logs[0].key_id
}

# SNS Topic for fanout
data "aws_iam_policy_document" "route53_logs_sns_fanout_policy" {
  count   = local.create_sns_topic ? 1 : 0
  version = "2012-10-17"

  statement {
    sid    = "AllowS3BucketToPublish"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
    actions   = ["SNS:Publish"]
    resources = [local.sns_topic_arn]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [local.bucket_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_sns_topic" "route53_logs_fanout" {
  count = local.create_sns_topic ? 1 : 0

  name              = "${var.prefix}-route53-logs-fanout"
  kms_master_key_id = var.sns_kms_encryption_enabled ? local.kms_key_arn : null
  tags              = var.tags
}

resource "aws_sns_topic_policy" "route53_logs_fanout" {
  count = local.create_sns_topic ? 1 : 0

  arn    = aws_sns_topic.route53_logs_fanout[0].arn
  policy = data.aws_iam_policy_document.route53_logs_sns_fanout_policy[0].json
}

# S3 Bucket Notification - works with module-created or external bucket
resource "aws_s3_bucket_notification" "route53_logs" {
  count  = local.create_sns_topic ? 1 : 0
  bucket = local.bucket_id

  topic {
    topic_arn = aws_sns_topic.route53_logs_fanout[0].arn
    events    = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_sns_topic_policy.route53_logs_fanout]
}

# SQS Queue for Wiz notifications (one per Wiz role)
data "aws_iam_policy_document" "sqs_queue_policy" {
  for_each = var.wiz_role_names
  version  = "2012-10-17"

  statement {
    sid    = "AllowSendMessage"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }
    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.wiz_route53_logs_queue[each.key].arn]
    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [local.sns_topic_arn]
    }
  }

  statement {
    sid    = "AllowWizRecvDeleteMsg"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${each.value}"]
    }
    actions = [
      "sqs:DeleteMessage",
      "sqs:ReceiveMessage",
      "sqs:GetQueueAttributes",
      "sqs:ChangeMessageVisibility",
      "sqs:GetQueueUrl"
    ]
    resources = [aws_sqs_queue.wiz_route53_logs_queue[each.key].arn]
  }
}

resource "aws_sqs_queue" "wiz_route53_logs_queue" {
  for_each = var.wiz_role_names

  name              = "${var.prefix}-${each.key}-wiz-route53-logs-queue"
  kms_master_key_id = var.sqs_kms_encryption_enabled ? (var.sqs_queue_key_arn != "" ? var.sqs_queue_key_arn : local.kms_key_arn) : null
  tags              = var.tags
}

resource "aws_sqs_queue_policy" "wiz_route53_logs_queue_policy" {
  for_each = var.wiz_role_names

  queue_url = aws_sqs_queue.wiz_route53_logs_queue[each.key].id
  policy    = data.aws_iam_policy_document.sqs_queue_policy[each.key].json
}

resource "aws_sns_topic_subscription" "wiz_route53_logs_notification_queue_subscription" {
  for_each = var.wiz_role_names

  topic_arn                       = local.sns_topic_arn
  protocol                        = "sqs"
  endpoint                        = aws_sqs_queue.wiz_route53_logs_queue[each.key].arn
  raw_message_delivery            = true
  endpoint_auto_confirms          = false
  confirmation_timeout_in_minutes = 1
}

# IAM Policy for Wiz Access (one per Wiz role)
data "aws_iam_policy_document" "wiz_access_role_policy" {
  for_each = var.wiz_role_names
  version  = "2012-10-17"

  statement {
    sid    = "AllowWizAccessRoute53LogsS3ListGetLocation"
    effect = "Allow"
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket"
    ]
    resources = [local.bucket_arn]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["true"]
    }
  }

  statement {
    sid       = "AllowWizAccessRoute53LogsS3Get"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${local.bucket_arn}/*"]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["true"]
    }
  }

  dynamic "statement" {
    for_each = local.kms_key_arn != "" ? [1] : []
    content {
      sid       = "AllowWizDecryptRoute53Logs"
      actions   = ["kms:Decrypt"]
      resources = [local.kms_key_arn]
    }
  }

  dynamic "statement" {
    for_each = var.sqs_kms_encryption_enabled ? [1] : []
    content {
      sid       = "AllowWizDecryptQueueFiles"
      actions   = ["kms:Decrypt"]
      resources = [var.sqs_queue_key_arn != "" ? var.sqs_queue_key_arn : local.kms_key_arn]
    }
  }
}

resource "aws_iam_policy" "wiz_allow_route53_logs_bucket_access" {
  for_each = var.wiz_role_names

  name        = "${var.prefix}-${each.key}-WizAllowRoute53LogsBucketAccess"
  description = "Allow Wiz access to Route53 logs buckets for ${each.value}"
  policy      = data.aws_iam_policy_document.wiz_access_role_policy[each.key].json
  tags        = var.tags
}

resource "aws_iam_role_policy_attachment" "wiz_route53_logs_policy_attachment" {
  for_each = var.wiz_role_names

  role       = each.value
  policy_arn = aws_iam_policy.wiz_allow_route53_logs_bucket_access[each.key].arn
}

# Route53 Resolver Query Logging Configuration
# This creates a single query log config and associates it with all provided VPCs
resource "aws_route53_resolver_query_log_config" "this" {
  count = length(var.vpc_ids) > 0 ? 1 : 0

  name            = "${var.prefix}-resolver-query-logs"
  destination_arn = local.bucket_arn

  tags = merge(
    { Name = "${var.prefix}-resolver-query-logs" },
    var.tags
  )

  depends_on = [
    aws_s3_bucket_policy.route53_logs,
    aws_kms_key.wiz_route53_logs
  ]
}

resource "aws_route53_resolver_query_log_config_association" "this" {
  for_each = var.vpc_ids

  resolver_query_log_config_id = aws_route53_resolver_query_log_config.this[0].id
  resource_id                  = each.value
}
