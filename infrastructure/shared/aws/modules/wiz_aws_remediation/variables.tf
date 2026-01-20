variable "region" {
  type    = string
  default = "us-east-2"
}

variable "WizRemediationWorkerRole" {
  type        = string
  default     = "Remediation-Worker-Role"
  description = "The Role name to be assumed by Lambda for remediation on another account"
}

variable "RoleARN" {
  type        = string
  default     = ""
  description = "Enter the AWS Trust Policy Role ARN for your Wiz data center. You can retrieve it from User Settings, Tenant in the Wiz portal"
}

variable "ExternalId" {
  type = string
  validation {
    condition     = can(regex("\\S{8}-\\S{4}-\\S{4}-\\S{4}-\\S{12}", var.ExternalId))
    error_message = "Invalid UUID4 pattern."
  }
  description = "The External ID of the Wiz connector. This is a nonce that will be used by our service to assume the role in your account"
}

variable "WizRemediationResourcesPrefix" {
  type        = string
  default     = "Wiz"
  description = "Enter the prefix string that will be prepended to all Wiz Remediation resources on your account. The default is Wiz, which will as an example, create a role named Wiz-Remediation-Lambda-Role"
}

variable "WizRemediationEnabledAutoTagOnUpdate" {
  type        = bool
  default     = true
  description = "Enable Wiz Remediation AutoTag when a cloud resource is updated by a response function"
}

variable "WizRemediationTagValue" {
  type        = map(string)
  default     = { wiz-remediation = "" }
  description = "The remediation tag value uuid"
}

variable "WizRemediationAutoTagKey" {
  type        = string
  default     = "wizRemediationLastUpdatedUTC"
  description = "The Wiz AutoTag key applied to cloud resources updated by Wiz Auto Remediation"
}

variable "WizRemediationAutoTagDateFormat" {
  type        = string
  default     = "DDMMYY"
  description = "The date format used for Wiz Remediation AutoTag values. Accepted values are DDMMYY and MMDDYY"
}

variable "WizRemediationCustomFunctionsBucketEnabled" {
  type        = bool
  default     = true
  description = "Enable the creation and use of an S3 bucket for custom remediation response functions"
}

variable "WizRemediationCustomFunctionsBucketName" {
  type        = string
  default     = "wiz-remediation-custom-functions"
  description = "The naming prefix of the S3 bucket created for storing custom remediation response functions. The account id is added to the end of this name to make sure it is unique across aws"
  validation {
    condition     = length(var.WizRemediationCustomFunctionsBucketName) < 51
    error_message = "The bucket name must be shorter than 51 characters."
  }
}

variable "WizFailoverSTSEndpointRegion" {
  type        = string
  default     = "us-east-1"
  description = "The region used for STS authentication tokens when global resources are being remediated"
}

variable "AdditionalTag" {
  type        = map(string)
  default     = {}
  description = "(Optional) An additional tag that will be added to all stack resources"
}

variable "IncludeDestructivePermissions" {
  type        = bool
  default     = true
  description = "Should the remediation worker role policy include destructive permissions such as Delete/Terminate"
}

variable "ImageNameTag" {
  type        = string
  default     = "wiz-remediation-aws:2"
  description = "The URI of Wiz remediation Lambda container image"
}

variable "ImageAccountID" {
  type        = string
  default     = "417748291193"
  description = "The AWS account ID of the Wiz Remediation container image"
}
