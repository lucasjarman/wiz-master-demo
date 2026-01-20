resource "wiz_aws_connector" "connector" {
  name    = var.connector_name
  enabled = var.connector_state
  auth_params {
    customer_role_arn = var.customer_role_arn
    outpost_id        = var.outpost_id
    dynamic "disk_analyzer" {
      for_each = var.disk_analyzer_scanner_arn != null ? [var.disk_analyzer_scanner_arn] : []
      content {
        scanner {
          role_arn = var.disk_analyzer_scanner_arn
        }
      }
    }
  }
  extra_config {
    audit_log_monitor_enabled   = var.audit_log_monitor_enabled
    network_log_monitor_enabled = var.network_log_monitor_enabled
    dns_log_monitor_enabled     = var.dns_log_monitor_enabled
    excluded_accounts           = var.excluded_accounts
    excluded_organization_units = var.excluded_organization_units
    opted_in_regions            = var.scan_regions
    skip_organization_scan      = var.skip_organization_scan
    scheduled_security_tool_scanning_settings {
      enabled                         = var.scheduled_scanning_settings.enabled
      public_buckets_scanning_enabled = var.scheduled_scanning_settings.public_buckets_scanning_enabled
    }
    dynamic "cloud_trail_config" {
      for_each = var.cloud_trail_config.bucket_name != null ? [var.cloud_trail_config] : []
      content {
        bucket_name        = var.cloud_trail_config.bucket_name
        bucket_sub_account = var.cloud_trail_config.bucket_sub_account
        trail_org          = var.cloud_trail_config.trail_org
        notifications_sqs_options {
          region             = var.cloud_trail_config.notifications_sqs_options.region
          override_queue_url = var.cloud_trail_config.notifications_sqs_options.override_queue_url
        }
      }
    }
    dynamic "vpc_flow_log_config" {
      for_each = var.vpc_flow_log_config.bucket_name != null ? [var.vpc_flow_log_config] : []
      content {
        bucket_name = var.vpc_flow_log_config.bucket_name
        notifications_sqs_options {
          region             = var.vpc_flow_log_config.notifications_sqs_options.region
          override_queue_url = var.vpc_flow_log_config.notifications_sqs_options.override_queue_url
        }
      }
    }
    dynamic "resolver_query_logs_config" {
      for_each = var.resolver_query_logs_config.bucket_name != null ? [var.resolver_query_logs_config] : []
      content {
        bucket_name = var.resolver_query_logs_config.bucket_name
        notifications_sqs_options {
          region             = var.resolver_query_logs_config.notifications_sqs_options.region
          override_queue_url = var.resolver_query_logs_config.notifications_sqs_options.override_queue_url
        }
      }
    }
  }
}
