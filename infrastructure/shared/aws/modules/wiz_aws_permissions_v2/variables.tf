variable "prefix" {
  description = "Prefix for the policy name"
  type        = string
  default     = "standard-connector"
}

variable "wiz_standard_connector_url" {
  description = "URL for the Wiz standard connector policies"
  type        = string
  default     = "https://downloads.wiz.io/customer-files/aws/standard_connector_tf.json"
}

variable "enable_lightsail_scanning" {
  type        = bool
  default     = false
  description = "Enable Lightsail scanning"
}

variable "enable_data_scanning" {
  type        = bool
  default     = false
  description = "Enable DSPM data scanning"
}

variable "enable_eks_scanning" {
  type        = bool
  default     = false
  description = "Enable EKS scanning"
}

variable "enable_terraform_bucket_scanning" {
  type        = bool
  default     = true
  description = "Enable Terraform Bucket scanning"
}

variable "enable_cloud_cost_scanning" {
  type        = bool
  default     = true
  description = "Enable Cloud Cost scanning"
}

variable "enable_defend_scanning" {
  type        = bool
  default     = false
  description = "Enable Defend scanning"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags to apply to resources"
}

variable "role_name" {
  type        = string
  description = "Name to give the Wiz role"
}

variable "permission_boundary_arn" {
  type        = string
  default     = null
  description = "Optional - ARN of the policy that is used to set the permissions boundary for the role."
}

variable "remote_arn" {
  type        = string
  default     = ""
  description = "Enter the AWS Trust Policy Role ARN for your Wiz data center. You can retrieve it from User Settings, Tenant in the Wiz portal"
}

variable "external_id" {
  type        = string
  description = "Connector External ID"
  validation {
    condition     = can(regex("\\S{8}-\\S{4}-\\S{4}-\\S{4}-\\S{12}", var.external_id))
    error_message = "The external_id must match the pattern XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX (UUID format)."
  }
}
