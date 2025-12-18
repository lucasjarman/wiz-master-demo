# -----------------------------------------------------------------------------
# WIZ KUBERNETES INTEGRATION (HELM)
# -----------------------------------------------------------------------------
# Automates the deployment of Wiz Sensor, Admission Controller, and Connector.
# Following the "Install all Kubernetes Deployments (Helm)" documentation.

provider "kubernetes" {
  host                   = module.eks[0].cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks[0].cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks[0].cluster_name, "--profile", var.aws_profile]
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks[0].cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks[0].cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks[0].cluster_name, "--profile", var.aws_profile]
    }
  }
}

# 1. Create Namespace
resource "kubernetes_namespace" "wiz" {
  count = var.enable_eks ? 1 : 0
  metadata {
    name = "wiz"
  }
}

# 2. Create Registry Pull Secret
resource "kubernetes_secret" "sensor_image_pull" {
  count = var.enable_eks && var.wiz_sensor_pull_user != "" ? 1 : 0
  metadata {
    name      = "sensor-image-pull"
    namespace = kubernetes_namespace.wiz[0].metadata[0].name
  }

  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "wizio.azurecr.io" = {
          auth = base64encode("${var.wiz_sensor_pull_user}:${var.wiz_sensor_pull_password}")
        }
      }
    })
  }
}

# 3. Create Wiz API Token Secret
resource "kubernetes_secret" "wiz_api_token" {
  count = var.enable_eks && var.wiz_client_id != "" ? 1 : 0
  metadata {
    name      = "wiz-api-token"
    namespace = kubernetes_namespace.wiz[0].metadata[0].name
  }

  data = {
    clientId    = var.wiz_client_id
    clientToken = var.wiz_client_secret
  }
}

# 4. Deploy Wiz Integration Helm Chart
resource "helm_release" "wiz_integration" {
  count      = var.enable_eks && var.wiz_client_id != "" ? 1 : 0
  name       = "wiz-integration"
  repository = "https://charts.wiz.io/"
  chart      = "wiz-kubernetes-integration"
  namespace  = kubernetes_namespace.wiz[0].metadata[0].name

  values = [
    yamlencode({
      global = {
        wizApiToken = {
          secret = {
            create = false
            name   = kubernetes_secret.wiz_api_token[0].metadata[0].name
          }
        }
      }
      wiz-kubernetes-connector = {
        enabled = true
        autoCreateConnector = {
          clusterFlavor = "EKS"
          connectorName = module.eks[0].cluster_name
        }
      }
      wiz-sensor = {
        enabled = true
        imagePullSecret = {
          create = false
          name   = kubernetes_secret.sensor_image_pull[0].metadata[0].name
        }
      }
      wiz-admission-controller = {
        enabled = true
        kubernetesAuditLogsWebhook = {
          enabled = true
        }
        opaWebhook = {
          enabled = true
        }
      }
    })
  ]

  depends_on = [
    kubernetes_secret.sensor_image_pull,
    kubernetes_secret.wiz_api_token
  ]
}
