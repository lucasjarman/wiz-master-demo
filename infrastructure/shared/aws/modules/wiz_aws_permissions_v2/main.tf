locals {
  wiz_data = jsondecode(data.http.wiz_policies.response_body)

  policy_flags = {
    "WizCloudCostPolicy"         = var.enable_cloud_cost_scanning
    "WizDataScanningPolicy"      = var.enable_data_scanning
    "WizLightsailScanningPolicy" = var.enable_lightsail_scanning
    "WizDefendPolicy"            = var.enable_defend_scanning
    "WizEKSScanningPolicy"       = var.enable_eks_scanning
    "WizTerraformScanningPolicy" = var.enable_terraform_bucket_scanning
    "WizS3InventoryPolicy"       = var.enable_data_scanning
  }

  enabled_policies = {
    for policy_name, policy_data in local.wiz_data :
    policy_name => policy_data
    if !contains(["WizFullPolicy", "WizFullPolicy2"], policy_name) &&
    lookup(local.policy_flags, policy_name, false)
  }

  all_modification_dates = concat(
    [
      for policy_name, policy_data in local.enabled_policies :
      policy_data.wiz_last_modified_date
    ],
    [
      local.wiz_data["WizFullPolicy"].wiz_last_modified_date,
      local.wiz_data["WizFullPolicy2"].wiz_last_modified_date
    ]
  )

  latest_modified_date = length(local.all_modification_dates) > 0 ? reverse(sort(local.all_modification_dates))[0] : ""

  template_vars = {
    aws_partition          = data.aws_partition.current.partition
    aws_current_account_id = data.aws_caller_identity.current.account_id
    aws_dns_suffix         = data.aws_partition.current.dns_suffix
    WizRoleName            = aws_iam_role.user_role_tf.name
  }

  policy_templates = {
    for policy_name, policy_data in merge(local.enabled_policies, {
      "WizFullPolicy"  = local.wiz_data["WizFullPolicy"]
      "WizFullPolicy2" = local.wiz_data["WizFullPolicy2"]
    }) :
    policy_name => jsonencode(policy_data.wiz_policy_document)
  }
  processed_policies = {
    for policy_name, template in local.policy_templates :
    policy_name => templatestring(template, local.template_vars)
  }
}

data "http" "wiz_policies" {
  url = var.wiz_standard_connector_url

  request_headers = {
    Accept = "application/json"
  }
}

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
resource "aws_iam_policy" "wiz_merged_policy" {
  count = length(local.enabled_policies) > 0 ? 1 : 0

  name        = "${var.prefix}WizMergedPolicy"
  description = "Merged Wiz policy for enabled scanning types - Last Modified: ${local.latest_modified_date}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = flatten([
      for policy_name in keys(local.enabled_policies) :
      jsondecode(local.processed_policies[policy_name]).Statement
    ])
  })

  tags = merge(var.tags, {
    "wiz:last-modified" = local.latest_modified_date
    "managed-by"        = "terraform"
  })
}

resource "aws_iam_role_policy_attachment" "wiz_merged_policy_attachment" {
  count      = length(local.enabled_policies) > 0 ? 1 : 0
  role       = aws_iam_role.user_role_tf.name
  policy_arn = aws_iam_policy.wiz_merged_policy[0].arn
}

resource "aws_iam_role_policy" "wiz_full_policy" {
  name   = "${var.prefix}WizFullPolicy"
  role   = aws_iam_role.user_role_tf.id
  policy = local.processed_policies["WizFullPolicy"]
}

resource "aws_iam_policy" "wiz_full_policy2" {
  name        = "${var.prefix}WizFullPolicy2"
  description = "Wiz Full Policy 2 - Last Modified: ${local.wiz_data["WizFullPolicy2"].wiz_last_modified_date}"
  policy      = local.processed_policies["WizFullPolicy2"]

  tags = merge(var.tags, {
    "wiz:last-modified" = local.wiz_data["WizFullPolicy2"].wiz_last_modified_date
    "managed-by"        = "terraform"
  })
}

resource "aws_iam_role_policy_attachment" "wiz_full_policy2_attachment" {
  role       = aws_iam_role.user_role_tf.name
  policy_arn = aws_iam_policy.wiz_full_policy2.arn
}

resource "aws_iam_role" "user_role_tf" {
  name                 = var.role_name
  permissions_boundary = var.permission_boundary_arn

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : var.remote_arn
        },
        "Action" : "sts:AssumeRole",
        "Condition" : {
          "StringEquals" : {
            "sts:ExternalId" : var.external_id
          }
        }
      }
    ]
  })

  tags = merge(var.tags, {
    "wiz:last-modified" = local.latest_modified_date
    "managed-by"        = "terraform"
  })
}

resource "aws_iam_role_policy_attachment" "view_only_access_role_policy_attach" {
  role       = aws_iam_role.user_role_tf.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/job-function/ViewOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "security_audit_role_policy_attach" {
  role       = aws_iam_role.user_role_tf.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/SecurityAudit"
}
