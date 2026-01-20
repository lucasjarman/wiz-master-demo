variable "prefix" {
  description = "Prefix for naming"
  type        = string
}

variable "random_prefix_id" {
  description = "Random ID to use in resource names (matches reference repo pattern)"
  type        = string
}

variable "cluster_type" {
  description = "Cluster type for Wiz config"
  type        = string
  default     = "EKS"
  validation {
    condition     = contains(["EKS", "AKS", "GKE", "OKE", "OpenShift", "ACK", "Kubernetes"], var.cluster_type)
    error_message = "Cluster type must be one of EKS, AKS, GKE, OKE, OpenShift, ACK, Kubernetes"
  }
}

variable "wiz_k8s_integration_client_id" {
  description = "Wiz Kubernetes integration client ID"
  type        = string
  sensitive   = true
  default     = ""
}

variable "wiz_k8s_integration_client_secret" {
  description = "Wiz Kubernetes integration client secret"
  type        = string
  sensitive   = true
  default     = ""
}

variable "wiz_k8s_integration_client_endpoint" {
  description = "Wiz Kubernetes integration client endpoint (e.g., prod, commercial, demo)"
  type        = string
  default     = ""
}

variable "use_wiz_sensor" {
  description = "Whether to use Wiz sensor"
  type        = bool
  default     = false
}

variable "wiz_sensor_pull_username" {
  description = "Wiz sensor image pull username"
  type        = string
  sensitive   = true
  default     = ""
}

variable "wiz_sensor_pull_password" {
  description = "Wiz sensor image pull password"
  type        = string
  sensitive   = true
  default     = ""
}

variable "use_wiz_admission_controller" {
  description = "Whether to use Wiz admission controller"
  type        = bool
  default     = false
}

