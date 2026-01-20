data "aws_partition" "current" {}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "MyQueuePolicy" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }
    actions   = ["sqs:SendMessage"]
    resources = ["*"]
    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"

      values = [
        aws_sns_topic.WizIssuesToRemediateSNSTopic.arn
      ]
    }
  }
}

data "aws_iam_policy_document" "MyQueuePolicyDLQ" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["sqs.amazonaws.com"]
    }
    actions   = ["sqs:SendMessage"]
    resources = ["*"]
    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"

      values = [
        aws_sqs_queue.WizIssuesToRemediateQueue.arn
      ]
    }
  }

  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }
    actions   = ["sqs:SendMessage"]
    resources = ["*"]
    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"

      values = [
        aws_sns_topic.WizIssuesToRemediateSNSTopic.arn
      ]
    }
  }
}

data "aws_iam_policy_document" "WizAccessPolicyToSns" {
  statement {
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.WizIssuesToRemediateSNSTopic.arn]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["true"]
    }
  }
}

data "aws_iam_policy_document" "SnsAssumeRoleFromWizPolicyDocument" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    condition {
      test     = "StringEquals"
      values   = [var.ExternalId]
      variable = "sts:ExternalId"
    }

    principals {
      type        = "AWS"
      identifiers = [var.RoleARN]
    }
  }
}

data "aws_iam_policy_document" "WizIssuesToRemediateSNSTopicPolicyDocument" {
  statement {
    effect    = "Deny"
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.WizIssuesToRemediateSNSTopic.arn]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

data "aws_iam_policy_document" "LambdaAssumeRoleDocument" {
  version = "2012-10-17"
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}
data "aws_iam_policy_document" "AssumeWorkerRolePolicyDocument" {
  version = "2012-10-17"
  statement {
    effect    = "Allow"
    actions   = ["sts:AssumeRole"]
    resources = ["arn:aws:iam::*:role/${var.WizRemediationResourcesPrefix}-${var.WizRemediationWorkerRole}"]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/${keys(var.WizRemediationTagValue)[0]}"
      values   = [var.WizRemediationTagValue[keys(var.WizRemediationTagValue)[0]]]
    }
  }
}

data "aws_iam_policy_document" "WizRemediationBucketPolicyDocument" {
  depends_on = [aws_s3_bucket.WizRemediationCustomFunctionsBucket]
  statement {
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.LambdaRole.arn]
    }

    effect  = "Allow"
    actions = ["s3:ListBucket"]

    resources = length(aws_s3_bucket.WizRemediationCustomFunctionsBucket) > 0 ? ["arn:aws:s3:::${aws_s3_bucket.WizRemediationCustomFunctionsBucket[0].bucket}"] : null
    sid       = "CustomWizFunctionsListBucket"
  }

  statement {
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.LambdaRole.arn]
    }

    effect  = "Allow"
    actions = ["s3:GetObject"]

    resources = length(aws_s3_bucket.WizRemediationCustomFunctionsBucket) > 0 ? ["arn:aws:s3:::${aws_s3_bucket.WizRemediationCustomFunctionsBucket[0].bucket}/*"] : null
    sid       = "CustomWizFunctionsGetObject"
  }

  statement {
    principals {
      type        = "*"
      identifiers = ["*"]
    }

    effect  = "Deny"
    actions = ["s3:*"]

    resources = length(aws_s3_bucket.WizRemediationCustomFunctionsBucket) > 0 ? ["arn:aws:s3:::${aws_s3_bucket.WizRemediationCustomFunctionsBucket[0].bucket}/*"] : null

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  statement {
    principals {
      type        = "*"
      identifiers = ["*"]
    }

    effect  = "Deny"
    actions = ["s3:*"]

    resources = length(aws_s3_bucket.WizRemediationCustomFunctionsBucket) > 0 ? ["arn:aws:s3:::${aws_s3_bucket.WizRemediationCustomFunctionsBucket[0].bucket}/*"] : null

    condition {
      test     = "NumericLessThan"
      variable = "s3:TlsVersion"
      values   = ["1.2"]
    }
  }
}

data "aws_iam_policy_document" "RemediationWorkerRoleAssumeDocument" {
  version = "2012-10-17"
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.LambdaRole.arn]
    }
  }
}


data "aws_iam_policy_document" "RemediationWorkerPolicy" {
  statement {
    effect  = "Allow"
    actions = var.IncludeDestructivePermissions ? concat(local.base_actions, local.desructive_actions) : local.base_actions

    resources = ["*"]
    sid       = "WizRemediation20240601"
  }
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:CreateSecret",
      "secretsmanager:TagResource"
    ]
    resources = ["arn:aws:secretsmanager:*:*:secret:wiz-*"]
    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/${keys(var.WizRemediationTagValue)[0]}"
      values   = [var.WizRemediationTagValue[keys(var.WizRemediationTagValue)[0]]]
    }
    sid = "WizRemediationSecrets20240601"
  }
}
