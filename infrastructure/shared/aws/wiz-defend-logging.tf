# -----------------------------------------------------------------------------
# Wiz Defend Logging Infrastructure
# -----------------------------------------------------------------------------
# Creates logging resources for Wiz Defend ingestion:
# - S3 buckets (CloudTrail, VPC Flow Logs)
# - KMS keys for encryption
# - SNS topics for fanout
# - CloudTrail with advanced event selectors
# - VPC Flow Logs
# - Route53 DNS query logging

# NOTE: The following are defined in main.tf and shared across all files:
# - data "aws_partition" "current"
# - local.global_name
# - local.wiz_role_names (derived from wiz_tenant_trust_data)

# -----------------------------------------------------------------------------
# S3 Buckets Module (for CloudTrail and VPC Flow Logs)
# -----------------------------------------------------------------------------
module "aws_buckets" {
  source      = "../../../modules/aws/s3"
  count       = var.enabled_logs.cloudtrail || var.enabled_logs.vpc_flow_logs ? 1 : 0
  prefix      = local.global_name
  common_tags = local.tags
  s3_buckets = {
    sensitiveDataBucket = var.enabled_logs.cloudtrail ? merge(var.s3_buckets.sensitiveDataBucket, {
      create = true
    }) : null
    flowLogs = var.enabled_logs.vpc_flow_logs ? merge(var.s3_buckets.flowLogs, {
      create      = true
      kms_key_arn = aws_kms_key.flow_logs[0].arn
    }) : null
  }
  s3_bucket_lifecycle_rules = var.s3_bucket_lifecycle_rules
}

# -----------------------------------------------------------------------------
# KMS Keys
# -----------------------------------------------------------------------------
resource "aws_kms_key" "flow_logs" {
  count               = var.enabled_logs.vpc_flow_logs ? 1 : 0
  description         = "KMS key for VPC flow logs"
  key_usage           = "ENCRYPT_DECRYPT"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.flow_log_kms_key_policy[0].json
  tags                = local.tags
}

resource "aws_kms_alias" "flow_logs" {
  count         = var.enabled_logs.vpc_flow_logs ? 1 : 0
  name          = "alias/flow-logs-${local.suffix}"
  target_key_id = aws_kms_key.flow_logs[0].key_id
}

resource "aws_kms_key" "cloudtrail" {
  count               = var.enabled_logs.cloudtrail ? 1 : 0
  description         = "KMS key for cloudtrail"
  key_usage           = "ENCRYPT_DECRYPT"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.cloudtrail_kms_key_policy[0].json
  tags                = local.tags
}

resource "aws_kms_alias" "cloudtrail" {
  count         = var.enabled_logs.cloudtrail ? 1 : 0
  name          = "alias/cloudtrail-${local.suffix}"
  target_key_id = aws_kms_key.cloudtrail[0].key_id
}

# -----------------------------------------------------------------------------
# KMS Key Policies
# -----------------------------------------------------------------------------
data "aws_iam_policy_document" "flow_log_kms_key_policy" {
  count   = var.enabled_logs.vpc_flow_logs ? 1 : 0
  version = "2012-10-17"

  statement {
    sid       = "Default"
    actions   = ["kms:*"]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }

  statement {
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:Encrypt",
      "kms:GenerateDataKey*",
      "kms:ReEncrypt",
    ]
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
    resources = ["*"]
    sid       = "AllowFlowLogs"
  }

  statement {
    sid = "AllowS3PublishSNS"
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
    sid = "AllowSNSServiceAccess"
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
}

data "aws_iam_policy_document" "cloudtrail_kms_key_policy" {
  count   = var.enabled_logs.cloudtrail ? 1 : 0
  version = "2012-10-17"

  statement {
    sid       = "Default"
    actions   = ["kms:*"]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }

  statement {
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:Encrypt",
      "kms:GenerateDataKey",
      "kms:ReEncrypt",
    ]
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    resources = ["*"]
    sid       = "AllowCloudTrail"
  }

  statement {
    sid = "AllowSNSServiceAccess"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey*",
    ]
    resources = ["*"]
    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }
  }
}



# -----------------------------------------------------------------------------
# SNS Topics for Log Fanout
# -----------------------------------------------------------------------------
resource "aws_sns_topic" "vpc_flow_logs_fanout" {
  count             = var.enabled_logs.vpc_flow_logs ? 1 : 0
  name              = "${local.global_name}-vpc-flow-logs-fanout"
  kms_master_key_id = aws_kms_key.flow_logs[0].arn
  tags              = local.tags
}

resource "aws_sns_topic_policy" "vpc_flow_logs_fanout" {
  count  = var.enabled_logs.vpc_flow_logs ? 1 : 0
  arn    = aws_sns_topic.vpc_flow_logs_fanout[0].arn
  policy = data.aws_iam_policy_document.flow_logs_sns_fanout_policy[0].json
}

resource "aws_sns_topic" "cloudtrail_sns_fanout" {
  count             = var.enabled_logs.cloudtrail ? 1 : 0
  name              = "${local.global_name}-cloudtrail-logs-fanout"
  kms_master_key_id = aws_kms_key.cloudtrail[0].arn
  tags              = local.tags
}

resource "aws_sns_topic_policy" "cloudtrail_fanout" {
  count  = var.enabled_logs.cloudtrail ? 1 : 0
  arn    = aws_sns_topic.cloudtrail_sns_fanout[0].arn
  policy = data.aws_iam_policy_document.cloudtrail_sns_fanout_policy[0].json
}

# -----------------------------------------------------------------------------
# SNS Topic Policies
# -----------------------------------------------------------------------------
data "aws_iam_policy_document" "flow_logs_sns_fanout_policy" {
  count   = var.enabled_logs.vpc_flow_logs ? 1 : 0
  version = "2012-10-17"

  statement {
    sid    = "AllowS3BucketToPublish"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
    actions   = ["SNS:Publish"]
    resources = [aws_sns_topic.vpc_flow_logs_fanout[0].arn]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [module.aws_buckets[0].s3_buckets["flowLogs"].arn]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

data "aws_iam_policy_document" "cloudtrail_sns_fanout_policy" {
  count   = var.enabled_logs.cloudtrail ? 1 : 0
  version = "2012-10-17"

  statement {
    sid    = "AllowCloudTrailToPublishMessage"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions   = ["SNS:Publish"]
    resources = [aws_sns_topic.cloudtrail_sns_fanout[0].arn]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

# -----------------------------------------------------------------------------
# S3 Bucket Notifications
# -----------------------------------------------------------------------------
resource "aws_s3_bucket_notification" "vpc_flow_logs" {
  count  = var.enabled_logs.vpc_flow_logs ? 1 : 0
  bucket = module.aws_buckets[0].s3_buckets["flowLogs"].id

  topic {
    topic_arn = aws_sns_topic.vpc_flow_logs_fanout[0].arn
    events    = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_sns_topic_policy.vpc_flow_logs_fanout]
}

# -----------------------------------------------------------------------------
# S3 Bucket Policies
# -----------------------------------------------------------------------------
data "aws_iam_policy_document" "sensitive_bucket_policy" {
  count = var.enabled_logs.cloudtrail ? 1 : 0
  statement {
    sid       = "AWSCloudTrailWrite"
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["${module.aws_buckets[0].s3_buckets["sensitiveDataBucket"].arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }

  statement {
    sid       = "AWSCloudTrailAclCheck"
    effect    = "Allow"
    actions   = ["s3:GetBucketAcl"]
    resources = [module.aws_buckets[0].s3_buckets["sensitiveDataBucket"].arn]

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "flow_logs_bucket_policy" {
  count = var.enabled_logs.vpc_flow_logs ? 1 : 0
  statement {
    sid       = "AWSVPCFlowLogsDelivery"
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["${module.aws_buckets[0].s3_buckets["flowLogs"].arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"]
    }
  }

  statement {
    sid       = "AWSVPCFlowLogsAclCheck"
    effect    = "Allow"
    actions   = ["s3:GetBucketAcl"]
    resources = [module.aws_buckets[0].s3_buckets["flowLogs"].arn]

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"]
    }
  }

  dynamic "statement" {
    for_each = local.wiz_role_names
    content {
      effect = "Allow"
      actions = [
        "s3:GetObject",
      ]
      resources = ["${module.aws_buckets[0].s3_buckets["flowLogs"].arn}/*"]
      principals {
        type        = "AWS"
        identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${statement.value}"]
      }
    }
  }
}

resource "aws_s3_bucket_policy" "cloudtrail_policy" {
  count = var.enabled_logs.cloudtrail ? 1 : 0

  bucket = module.aws_buckets[0].s3_buckets["sensitiveDataBucket"].id
  policy = data.aws_iam_policy_document.sensitive_bucket_policy[0].json
}

resource "aws_s3_bucket_policy" "flow_logs_policy" {
  count = var.enabled_logs.vpc_flow_logs ? 1 : 0

  bucket = module.aws_buckets[0].s3_buckets["flowLogs"].id
  policy = data.aws_iam_policy_document.flow_logs_bucket_policy[0].json
}

# -----------------------------------------------------------------------------
# CloudTrail
# -----------------------------------------------------------------------------
resource "aws_cloudtrail" "demo_cloudtrail" {
  count = var.enabled_logs.cloudtrail ? 1 : 0

  name                          = "${local.global_name}-cloudtrail"
  s3_bucket_name                = module.aws_buckets[0].s3_buckets["sensitiveDataBucket"].id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  tags                          = local.tags
  sns_topic_name                = aws_sns_topic.cloudtrail_sns_fanout[0].name

  advanced_event_selector {
    name = "Data Events for Demo Deployment"
    field_selector {
      field  = "eventCategory"
      equals = ["Data"]
    }
    field_selector {
      field  = "resources.type"
      equals = ["AWS::S3::Object"]
    }
  }

  advanced_event_selector {
    name = "DynamoDB Data Events for Demo Deployment"
    field_selector {
      field  = "resources.type"
      equals = ["AWS::DynamoDB::Table"]
    }
    field_selector {
      field  = "eventCategory"
      equals = ["Data"]
    }
  }

  advanced_event_selector {
    name = "Management Events for Demo Deployment"
    field_selector {
      field  = "eventCategory"
      equals = ["Management"]
    }
    field_selector {
      field      = "eventSource"
      not_equals = ["kms.amazonaws.com", "rdsdata.amazonaws.com"]
    }
  }

  depends_on = [
    aws_s3_bucket_policy.cloudtrail_policy,
    module.aws_buckets,
    aws_sns_topic_policy.cloudtrail_fanout
  ]
}

# -----------------------------------------------------------------------------
# VPC Flow Logs (enable on existing VPC)
# -----------------------------------------------------------------------------
resource "aws_flow_log" "main" {
  count = var.enabled_logs.vpc_flow_logs ? 1 : 0

  log_destination      = module.aws_buckets[0].s3_buckets["flowLogs"].arn
  log_destination_type = "s3"
  traffic_type         = "ALL"
  vpc_id               = module.vpc.vpc_id

  tags = merge(local.tags, {
    Name = "${local.global_name}-flow-logs"
  })

  depends_on = [aws_s3_bucket_policy.flow_logs_policy]
}

# -----------------------------------------------------------------------------
# Route53 Resolver Query Logging (Wiz Defend Logging Module)
# -----------------------------------------------------------------------------
module "wiz_defend_logs" {
  count  = var.enabled_logs.route53_logs ? 1 : 0
  source = "../../../modules/aws/wiz-defend-logging/"

  prefix         = local.global_name
  wiz_role_names = local.wiz_role_names

  create_s3_bucket            = true
  create_sns_topic            = true
  create_kms_key              = true
  sqs_kms_encryption_enabled  = true
  sns_kms_encryption_enabled  = true
  kms_deletion_window_in_days = 7

  vpc_ids = { "main" = module.vpc.vpc_id }

  tags = local.tags
}

# -----------------------------------------------------------------------------
# Wiz CloudTrail Ingestion (aws_cloud_events module)
# -----------------------------------------------------------------------------
module "aws_cloud_events" {
  for_each = var.enabled_logs.cloudtrail ? local.wiz_role_names : {}
  source   = "./modules/aws_cloud_events"

  integration_type = "CLOUDTRAIL"

  cloudtrail_arn        = try(aws_cloudtrail.demo_cloudtrail[0].arn, null)
  cloudtrail_bucket_arn = try(module.aws_buckets[0].s3_buckets["sensitiveDataBucket"].arn, null)
  cloudtrail_kms_arn    = try(aws_kms_key.cloudtrail[0].arn, null)

  use_existing_sns_topic       = true
  sns_topic_arn                = aws_sns_topic.cloudtrail_sns_fanout[0].arn
  sns_topic_encryption_enabled = true
  sns_topic_encryption_key_arn = try(aws_kms_key.cloudtrail[0].arn, null)
  sqs_encryption_key_arn       = try(aws_kms_key.cloudtrail[0].arn, null)

  prefix              = each.key
  wiz_access_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${each.value}"
}

# -----------------------------------------------------------------------------
# Wiz VPC Flow Logs Ingestion (vpc-flow-logs module)
# -----------------------------------------------------------------------------
module "vpc_flow_logs_queue" {
  for_each = var.enabled_logs.vpc_flow_logs ? local.wiz_role_names : {}
  source   = "../../../modules/wiz/vpc-flow-logs/"

  prefix                      = each.key
  create_kms_key              = false
  sns_topic_arn               = aws_sns_topic.vpc_flow_logs_fanout[0].arn
  vpc_flow_logs_bucket_arn    = module.aws_buckets[0].s3_buckets["flowLogs"].arn
  sqs_kms_encryption_enabled  = true
  kms_deletion_window_in_days = 7
  flowlogs_s3_kms_arn         = aws_kms_key.flow_logs[0].arn
  sqs_queue_key_arn           = aws_kms_key.flow_logs[0].arn
  wiz_access_role             = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${each.value}"
}

# -----------------------------------------------------------------------------
# S3 Access Logging
# -----------------------------------------------------------------------------
module "access_log_bucket" {
  source      = "../../../modules/aws/s3"
  count       = var.enabled_logs.s3_access_logging ? 1 : 0
  prefix      = local.global_name
  common_tags = local.tags

  s3_buckets = {
    sensitiveDataBucket = merge(var.s3_buckets.sensitiveDataBucket, {
      create      = true
      bucket_name = "access-logs"
      description = "Bucket to hold access logs for S3 buckets in Demo"
    })
  }

  s3_bucket_lifecycle_rules = var.s3_bucket_lifecycle_rules
}

data "aws_iam_policy_document" "logging_bucket_policy" {
  count   = var.enabled_logs.s3_access_logging ? 1 : 0
  version = "2012-10-17"

  statement {
    sid    = "S3ServerAccessLogsPolicy"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["logging.s3.amazonaws.com"]
    }

    actions = ["s3:PutObject"]

    resources = ["arn:aws:s3:::${module.access_log_bucket[0].s3_buckets["sensitiveDataBucket"].id}/*"]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }

  statement {
    sid    = "S3ServerAccessLogsDeliveryRootAccess"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["logging.s3.amazonaws.com"]
    }

    actions = [
      "s3:GetBucketAcl",
      "s3:ListBucket",
    ]

    resources = ["arn:aws:s3:::${module.access_log_bucket[0].s3_buckets["sensitiveDataBucket"].id}"]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_s3_bucket_logging" "s3_access_logging" {
  for_each = var.enabled_logs.s3_access_logging && length(module.aws_buckets) > 0 ? module.aws_buckets[0].s3_buckets : {}

  bucket        = each.value.id
  target_bucket = module.access_log_bucket[0].s3_buckets["sensitiveDataBucket"].id
  target_prefix = "${data.aws_caller_identity.current.account_id}/access-logs/${each.value.id}/"
}

resource "aws_s3_bucket_policy" "s3_access_logging_policy" {
  count = var.enabled_logs.s3_access_logging ? 1 : 0

  bucket = module.access_log_bucket[0].s3_buckets["sensitiveDataBucket"].id
  policy = data.aws_iam_policy_document.logging_bucket_policy[0].json
}
