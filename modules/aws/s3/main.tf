locals {
  s3_buckets_enabled = {
    for bucket, values in var.s3_buckets :
    bucket => values
    if values != null && try(values.create, false) == true
  }
  s3_buckets_encrypted = {
    for bucket, values in local.s3_buckets_enabled :
    bucket => values
    if try(values.encrypt, false) == true
  }
  s3_buckets_replicated = {
    for bucket, values in local.s3_buckets_enabled :
    bucket => values
    if length(values.replication_destinations) > 0 && try(values.is_secondary_region, false) != true
  }
  s3_bucket_lifecycle_rules = {
    for bucket, rules in var.s3_bucket_lifecycle_rules :
    bucket => rules
    if contains(keys(local.s3_buckets_enabled), bucket) && length(rules) > 0
  }

}

data "aws_region" "current" {}

resource "aws_s3_bucket" "s3" {
  for_each      = local.s3_buckets_enabled
  bucket        = "${var.prefix}-${each.value.bucket_name}-${data.aws_region.current.name}"
  force_destroy = each.value.force_destroy
  tags = merge({
    Name = "${var.prefix}-${each.value.bucket_name}-${data.aws_region.current.name}" },
    var.common_tags
  )
}

resource "aws_s3_bucket_lifecycle_configuration" "s3" {
  for_each = local.s3_bucket_lifecycle_rules
  bucket   = aws_s3_bucket.s3[each.key].id
  dynamic "rule" {
    for_each = each.value
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
      dynamic "transition" {
        for_each = rule.value.transition_days != null ? [1] : []
        content {
          days          = rule.value.transition_days
          storage_class = rule.value.transition_storage_class
        }
      }
      dynamic "noncurrent_version_transition" {
        for_each = rule.value.noncurrent_version_transition_days != null ? [1] : []
        content {
          noncurrent_days = rule.value.noncurrent_version_transition_days
          storage_class   = rule.value.noncurrent_version_transition_storage_class
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
  depends_on = [aws_s3_bucket_versioning.versioning]
}

resource "aws_s3_bucket_versioning" "versioning" {
  for_each = local.s3_buckets_enabled
  bucket   = aws_s3_bucket.s3[each.key].id
  versioning_configuration {
    status = each.value.versioning ? "Enabled" : "Disabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "kms" {
  for_each = local.s3_buckets_encrypted
  bucket   = aws_s3_bucket.s3[each.key].id
  rule {
    bucket_key_enabled = each.value.bucket_key_enabled
    apply_server_side_encryption_by_default {
      kms_master_key_id = each.value.kms_key_arn != "" ? each.value.kms_key_arn : null
      sse_algorithm     = each.value.kms_key_arn != "" ? "aws:kms" : "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "s3" {
  for_each                = local.s3_buckets_enabled
  bucket                  = aws_s3_bucket.s3[each.key].id
  block_public_acls       = each.value.public_access ? false : true
  block_public_policy     = each.value.public_access ? false : true
  restrict_public_buckets = each.value.public_access ? false : true
  ignore_public_acls      = each.value.public_access ? false : true
}

resource "aws_s3_bucket_replication_configuration" "s3" {
  for_each   = local.s3_buckets_replicated
  role       = aws_iam_role.s3_replication[0].arn
  bucket     = aws_s3_bucket.s3[each.key].id
  depends_on = [aws_s3_bucket_versioning.versioning]
  dynamic "rule" {
    for_each = each.value.replication_destinations
    content {
      id       = "replicate-${each.key}-${rule.key}"
      priority = rule.key + 1
      status   = "Enabled"
      filter { prefix = "" }
      dynamic "source_selection_criteria" {
        for_each = rule.value.kms_key_arn == "" ? [] : [1]
        content {
          sse_kms_encrypted_objects { status = "Enabled" }
        }
      }
      destination {
        bucket        = rule.value.bucket_arn
        storage_class = "STANDARD"
        dynamic "encryption_configuration" {
          for_each = rule.value.kms_key_arn == "" ? [] : [1]
          content {
            replica_kms_key_id = rule.value.kms_key_arn
          }
        }
      }
      delete_marker_replication {
        status = "Enabled"
      }
    }
  }
}

data "aws_iam_policy_document" "s3_assume_role" {
  count = length(local.s3_buckets_replicated) >= 1 ? 1 : 0
  statement {
    sid     = "S3CRRRole"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "s3_replication" {
  for_each = local.s3_buckets_replicated
  statement {
    sid    = "S3GetList"
    effect = "Allow"
    actions = [
      "s3:GetReplicationConfiguration",
      "s3:ListBucket"
    ]
    resources = [aws_s3_bucket.s3[each.key].arn]
  }
  statement {
    sid    = "S3GetStatement"
    effect = "Allow"
    actions = [
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging"
    ]
    resources = ["${aws_s3_bucket.s3[each.key].arn}/*"]
  }
  dynamic "statement" {
    for_each = each.value.replication_destinations
    content {
      sid    = "S3ReplicationStatement${statement.key}"
      effect = "Allow"
      actions = [
        "s3:ReplicateObject",
        "s3:ReplicateDelete",
        "s3:ReplicateTags"
      ]
      resources = ["${statement.value.bucket_arn}/*"]
    }
  }
  dynamic "statement" {
    for_each = each.value.kms_key_arn == "" ? [] : [1]
    content {
      sid    = "DecryptSourceObject"
      effect = "Allow"
      actions = [
        "kms:Decrypt",
        "kms:GenerateDataKey"
      ]
      resources = [each.value.kms_key_arn]
      condition {
        test     = "StringEquals"
        variable = "kms:ViaService"
        values   = ["s3.${data.aws_region.current.name}.amazonaws.com"]
      }
    }
  }
  dynamic "statement" {
    for_each = [
      for dest in each.value.replication_destinations : dest
      if dest.kms_key_arn != ""
    ]
    content {
      sid    = "EncryptDestObject${statement.key}"
      effect = "Allow"
      actions = [
        "kms:Encrypt",
        "kms:GenerateDataKey"
      ]
      resources = [statement.value.kms_key_arn]
      condition {
        test     = "StringEquals"
        variable = "kms:ViaService"
        values   = ["s3.${statement.value.destination_region}.amazonaws.com"]
      }
    }
  }
}

resource "aws_iam_role" "s3_replication" {
  count              = length(local.s3_buckets_replicated) >= 1 ? 1 : 0
  name               = "${var.prefix}-s3-crr-iam-role-${data.aws_region.current.name}"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.s3_assume_role[0].json
  tags = merge(
    { Name = "${var.prefix}-s3-crr-iam-role-${data.aws_region.current.name}" },
    var.common_tags
  )
}

resource "aws_iam_policy" "s3_replication" {
  for_each = local.s3_buckets_replicated
  name     = "${var.prefix}-s3-crr-iam-policy-${each.value.bucket_name}-${data.aws_region.current.name}"
  policy   = data.aws_iam_policy_document.s3_replication[each.key].json
  tags = merge(
    { Name = "${var.prefix}-s3-crr-iam-policy-${each.value.bucket_name}-${data.aws_region.current.name}" },
    var.common_tags
  )
}

resource "aws_iam_policy_attachment" "s3_replication" {
  for_each   = local.s3_buckets_replicated
  name       = "${var.prefix}-s3-crr-iam-policy-attachment-${each.value.bucket_name}-${data.aws_region.current.name}"
  roles      = [aws_iam_role.s3_replication[0].name]
  policy_arn = aws_iam_policy.s3_replication[each.key].arn
}
