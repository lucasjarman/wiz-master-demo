variable "create_new_export" {
  description = "Whether to create a new cost export or use an existing one."
  type        = bool
}

variable "cost_exports_prefix" {
  description = "The S3 prefix for the cost export files."
  type        = string
  default     = "Wiz"
}

variable "cost_export_name" {
  description = "The name of the cost export."
  type        = string
  default     = "Wiz-Cloud-Cost-Export"

  validation {
    condition     = var.cost_export_name != ""
    error_message = "Cost export name cannot be empty."
  }
}

variable "cost_export_bucket" {
  description = "The name bucket to which the cost export will be saved. Don't fill if you want to create a new bucket."
  type        = string
  default     = ""
}

variable "wiz_access_role_arn" {
  description = "The ARN of the AWS role used by the Wiz cloud connector."
  type        = string
  default     = ""
}

variable "wiz_access_role_arns" {
  description = "List of the arns of the AWS roles used by the Wiz cloud connector."
  type        = list(string)
  default     = []
}
