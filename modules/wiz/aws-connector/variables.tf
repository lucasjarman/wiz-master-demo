variable "connector_name" {
  description = "Name that will be used for the connector"
  type        = string
}

variable "customer_role_arn" {
  description = "The ARN of the role that will be assumed by the connector"
  type        = string
}

variable "connector_state" {
  description = "Boolean that controls whether the connector is enabled or disabled"
  type        = bool
  default     = true
}

variable "outpost_id" {
  description = "The ID of the that will be used by the connector."
  type        = string
  default     = null
}

variable "disk_analyzer_scanner_arn" {
  description = "The scanner role that will be used by the Wiz Outpost to perform workload scanning."
  type        = string
  default     = null
}

variable "audit_log_monitor_enabled" {
  description = "Boolean that controls whether the audit log monitor is enabled or disabled"
  type        = bool
  default     = false
}

variable "network_log_monitor_enabled" {
  description = "Boolean that controls whether the network log monitor is enabled or disabled"
  type        = bool
  default     = false
}

variable "dns_log_monitor_enabled" {
  description = "Boolean that controls whether the DNS log monitor is enabled or disabled"
  type        = bool
  default     = false
}

variable "excluded_accounts" {
  description = "List of AWS account IDs that will be excluded from workload scanning"
  type        = set(string)
  default     = []
}

variable "excluded_organization_units" {
  description = "List of organization unit IDs that will be excluded from workload scanning"
  type        = set(string)
  default     = []
}

variable "scan_regions" {
  description = "List of regions that will be opted into workload scanning. If empty, all regions will be opted in"
  type        = set(string)
  default     = []
}

variable "skip_organization_scan" {
  description = "Boolean that controls whether the connector is scoped to a single account or an organization"
  type        = bool
  default     = false
}

variable "scheduled_scanning_settings" {
  description = <<EOF
    Map that contains the settings for scheduled security tool scanning.
    enabled: Boolean that controls whether the scheduled security tool scanning is enabled or disabled
    public_buckets_scanning_enabled: Boolean that controls whether public buckets scanning is enabled or disabled
  EOF
  type = object({
    enabled                         = optional(bool, true)
    public_buckets_scanning_enabled = optional(bool, true)
  })
  default = {}
}

variable "cloud_trail_config" {
  description = <<EOF
    Map that contains the settings for scheduled security tool scanning.
    bucket_name: Name of the bucket where the CloudTrail logs are stored
    bucket_sub_account: Account ID of the sub-account where the bucket is located
    trail_org: Organization associated with the trail
  EOF
  type = object({
    bucket_name        = optional(string, null)
    bucket_sub_account = optional(string, null)
    trail_org          = optional(string, null)
    notifications_sqs_options = optional(object({
      region             = string
      override_queue_url = string
    }))
  })
  default = {}
}

variable "vpc_flow_log_config" {
  description = <<EOF
    Map that contains the settings for VPC Flow Logs.
    bucket_name: Name of the bucket where the VPC Flow Logs are stored
    notifications_sqs_options: Map that contains the settings for SQS notifications
    region: AWS region where the SQS queue is located
    override_queue_url: Optional URL to override the default SQS queue URL
  EOF
  type = object({
    bucket_name = optional(string, null)
    notifications_sqs_options = optional(object({
      region             = string
      override_queue_url = string
    }))
  })
  default = {}
}

variable "resolver_query_logs_config" {
  description = <<EOF
    Map that contains the settings for DNS Resolver Query Logs.
    bucket_name: Name of the bucket where the DNS Resolver Query Logs are stored
    notifications_sqs_options: Map that contains the settings for SQS notifications
    region: AWS region where the SQS queue is located
    override_queue_url: Optional URL to override the default SQS queue URL
  EOF
  type = object({
    bucket_name = optional(string, null)
    notifications_sqs_options = optional(object({
      region             = string
      override_queue_url = string
    }))
  })
  default = {}
}
