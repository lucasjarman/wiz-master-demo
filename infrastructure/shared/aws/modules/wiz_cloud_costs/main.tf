locals {
  create_new_export = var.create_new_export

  account_id       = data.aws_caller_identity.current.account_id
  cost_bucket_name = var.cost_export_bucket != "" ? var.cost_export_bucket : "wiz-cloud-cost-exports-${local.account_id}"

  cost_export_prefix = var.cost_exports_prefix
  cost_export_name   = var.cost_export_name

  wiz_access_role = var.wiz_access_role_arn != "" ? element(split("/", var.wiz_access_role_arn), -1) : null

  wiz_access_role_names = [
    for item in var.wiz_access_role_arns :
    element(split("/", item), length(split("/", item)) - 1)
  ]
}

data "aws_caller_identity" "current" {}

# salt used to avoid policy name conflicts
resource "random_id" "uniq" {
  byte_length = 6
}

# Create S3 bucket for the cost export
resource "aws_s3_bucket" "wiz_cost_export_bucket" {
  count = local.create_new_export ? 1 : 0

  bucket = local.cost_bucket_name
}

data "aws_iam_policy_document" "cost_and_usage_export_s3_bucket_policy" {
  count = local.create_new_export ? 1 : 0

  statement {
    sid    = "EnableAWSDataExportsToWriteToS3AndCheckPolicy"
    effect = "Allow"

    principals {
      type = "Service"
      identifiers = [
        "billingreports.amazonaws.com",
        "bcm-data-exports.amazonaws.com"
      ]
    }

    actions = [
      "s3:PutObject",
      "s3:GetBucketPolicy"
    ]

    resources = [
      aws_s3_bucket.wiz_cost_export_bucket[0].arn,
      "${aws_s3_bucket.wiz_cost_export_bucket[0].arn}/*"
    ]

    condition {
      test = "StringLike"
      values = [
        "arn:aws:cur:us-east-1:${local.account_id}:definition/*",
        "arn:aws:bcm-data-exports:us-east-1:${local.account_id}:export/*"
      ]
      variable = "aws:SourceArn"
    }

    condition {
      test     = "StringLike"
      variable = "aws:SourceAccount"
      values   = [local.account_id]
    }
  }
}

resource "aws_s3_bucket_policy" "cost_and_usage_export_s3_bucket_policy" {
  count = local.create_new_export ? 1 : 0

  bucket = aws_s3_bucket.wiz_cost_export_bucket[0].bucket

  policy = data.aws_iam_policy_document.cost_and_usage_export_s3_bucket_policy[0].json
}

# Create Cost and Usage Report (CUR 2.0)
resource "aws_bcmdataexports_export" "wiz_cost_export" {
  count = local.create_new_export ? 1 : 0

  depends_on = [aws_s3_bucket.wiz_cost_export_bucket, aws_s3_bucket_policy.cost_and_usage_export_s3_bucket_policy]

  export {
    name = local.cost_export_name
    data_query {
      query_statement = "SELECT bill_bill_type, bill_billing_entity, bill_billing_period_end_date, bill_billing_period_start_date, bill_invoice_id, bill_invoicing_entity, bill_payer_account_id, bill_payer_account_name, cost_category, discount, discount_bundled_discount, discount_total_discount, identity_line_item_id, identity_time_interval, line_item_availability_zone, line_item_blended_cost, line_item_blended_rate, line_item_currency_code, line_item_legal_entity, line_item_line_item_description, line_item_line_item_type, line_item_net_unblended_cost, line_item_net_unblended_rate, line_item_normalization_factor, line_item_normalized_usage_amount, line_item_operation, line_item_product_code, line_item_resource_id, line_item_tax_type, line_item_unblended_cost, line_item_unblended_rate, line_item_usage_account_id, line_item_usage_account_name, line_item_usage_amount, line_item_usage_end_date, line_item_usage_start_date, line_item_usage_type, pricing_currency, pricing_lease_contract_length, pricing_offering_class, pricing_public_on_demand_cost, pricing_public_on_demand_rate, pricing_purchase_option, pricing_rate_code, pricing_rate_id, pricing_term, pricing_unit, product, product_comment, product_fee_code, product_fee_description, product_from_location, product_from_location_type, product_from_region_code, product_instance_family, product_instance_type, product_instancesku, product_location, product_location_type, product_operation, product_pricing_unit, product_product_family, product_region_code, product_servicecode, product_sku, product_to_location, product_to_location_type, product_to_region_code, product_usagetype, reservation_amortized_upfront_cost_for_usage, reservation_amortized_upfront_fee_for_billing_period, reservation_availability_zone, reservation_effective_cost, reservation_end_time, reservation_modification_status, reservation_net_amortized_upfront_cost_for_usage, reservation_net_amortized_upfront_fee_for_billing_period, reservation_net_effective_cost, reservation_net_recurring_fee_for_usage, reservation_net_unused_amortized_upfront_fee_for_billing_period, reservation_net_unused_recurring_fee, reservation_net_upfront_value, reservation_normalized_units_per_reservation, reservation_number_of_reservations, reservation_recurring_fee_for_usage, reservation_reservation_a_r_n, reservation_start_time, reservation_subscription_id, reservation_total_reserved_normalized_units, reservation_total_reserved_units, reservation_units_per_reservation, reservation_unused_amortized_upfront_fee_for_billing_period, reservation_unused_normalized_unit_quantity, reservation_unused_quantity, reservation_unused_recurring_fee, reservation_upfront_value, resource_tags, savings_plan_amortized_upfront_commitment_for_billing_period, savings_plan_end_time, savings_plan_instance_type_family, savings_plan_net_amortized_upfront_commitment_for_billing_period, savings_plan_net_recurring_commitment_for_billing_period, savings_plan_net_savings_plan_effective_cost, savings_plan_offering_type, savings_plan_payment_option, savings_plan_purchase_term, savings_plan_recurring_commitment_for_billing_period, savings_plan_region, savings_plan_savings_plan_a_r_n, savings_plan_savings_plan_effective_cost, savings_plan_savings_plan_rate, savings_plan_start_time, savings_plan_total_commitment_to_date, savings_plan_used_commitment FROM COST_AND_USAGE_REPORT"
      table_configurations = {
        COST_AND_USAGE_REPORT = {
          TIME_GRANULARITY                      = "DAILY",
          INCLUDE_RESOURCES                     = "TRUE",
          INCLUDE_SPLIT_COST_ALLOCATION_DATA    = "FALSE",
          INCLUDE_MANUAL_DISCOUNT_COMPATIBILITY = "FALSE",
          BILLING_VIEW_ARN                      = "arn:aws:billing::${local.account_id}:billingview/primary",
        }
      }
    }
    destination_configurations {
      s3_destination {
        s3_bucket = aws_s3_bucket.wiz_cost_export_bucket[0].bucket
        s3_prefix = local.cost_export_prefix
        s3_region = aws_s3_bucket.wiz_cost_export_bucket[0].region
        s3_output_configurations {
          overwrite   = "CREATE_NEW_REPORT"
          format      = "PARQUET"
          compression = "PARQUET"
          output_type = "CUSTOM"
        }
      }
    }

    refresh_cadence {
      frequency = "SYNCHRONOUS"
    }
  }
}

# Policy for report and bucket access
data "aws_iam_policy_document" "wiz_cost_and_usage_report_policy" {
  version = "2012-10-17"

  statement {
    sid       = "AllowWizToListCURBucket"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${local.cost_bucket_name}"]
  }

  statement {
    sid       = "AllowWizToReadCURFiles"
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::${local.cost_bucket_name}/${local.cost_export_prefix}/*"]
  }

  statement {
    sid       = "AllowWizToListDataExports"
    actions   = ["bcm-data-exports:ListExports"]
    resources = ["*"]
  }

  statement {
    sid       = "AllowWizToViewDataExportConfig"
    actions   = ["bcm-data-exports:GetExport"]
    resources = local.create_new_export ? [aws_bcmdataexports_export.wiz_cost_export[0].id] : ["*"]
  }

  dynamic "statement" {
    for_each = local.create_new_export ? [] : [1]
    content {
      sid       = "AllowWizToViewLegacyCURConfig"
      actions   = ["cur:DescribeReportDefinitions"]
      resources = ["*"]
    }
  }
}

resource "aws_iam_policy" "wiz_allow_cost_export_bucket_access" {
  name        = "WizAllowCostExportAccess-${random_id.uniq.hex}"
  description = "Allow Wiz access to cost export properties and S3 bucket"
  policy      = data.aws_iam_policy_document.wiz_cost_and_usage_report_policy.json
}

resource "aws_iam_role_policy_attachment" "wiz_access_role_exports_by_arn" {
  count      = local.wiz_access_role != null ? 1 : 0
  role       = local.wiz_access_role
  policy_arn = aws_iam_policy.wiz_allow_cost_export_bucket_access.arn
}

resource "aws_iam_role_policy_attachment" "wiz_access_role_exports_by_name" {
  for_each   = toset(local.wiz_access_role_names)
  role       = each.value
  policy_arn = aws_iam_policy.wiz_allow_cost_export_bucket_access.arn
}
