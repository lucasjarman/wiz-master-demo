#!/usr/bin/env bash
set -euo pipefail

# Rotates the EKS cluster identity (new cluster name/ARN) without recreating the
# base environment (VPC/S3/etc.).
#
# This works by forcing Terraform to replace `random_id.eks_suffix`, which is
# used to derive the EKS cluster name and subnet discovery tags.
#
# It also deletes the demo app Service (type LoadBalancer) from the *current*
# cluster before rotation so the AWS NLB is cleaned up by Kubernetes.
#
# Env overrides:
# - AWS_PROFILE (default: wiz-demo)
# - AWS_REGION  (default: ap-southeast-2)
# - AUTO_APPROVE=1 to pass -auto-approve to terraform apply
# - SKIP_LB_CLEANUP=1 to skip deleting the LoadBalancer Service
# - DELETE_NAMESPACE=1 to also delete the demo app namespace (default: 0)
# - EKS_LOGGING_MODE=off|minimal|default (default: preserve current, else off)
# - LOG_RETENTION_DAYS (default: preserve current, else 1)

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF_DIR="${ROOT_DIR}/infra/aws"

AWS_PROFILE="${AWS_PROFILE:-wiz-demo}"
AWS_REGION="${AWS_REGION:-ap-southeast-2}"
EKS_LOGGING_MODE="${EKS_LOGGING_MODE:-}"
LOG_RETENTION_DAYS="${LOG_RETENTION_DAYS:-}"
DELETE_NAMESPACE="${DELETE_NAMESPACE:-0}"

if ! command -v terraform >/dev/null 2>&1; then
  echo "terraform not found in PATH" >&2
  exit 1
fi
if ! command -v aws >/dev/null 2>&1; then
  echo "aws CLI not found in PATH" >&2
  exit 1
fi

apply_flag=""
if [[ "${AUTO_APPROVE:-}" == "1" ]]; then
  apply_flag="-auto-approve"
fi

terraform -chdir="${TF_DIR}" init -input=false

if ! state_list="$(terraform -chdir="${TF_DIR}" state list 2>/dev/null)"; then
  echo "Failed to read Terraform state. Ensure your backend/profile are configured and try again." >&2
  exit 1
fi

current_cluster_name="$(terraform -chdir="${TF_DIR}" output -raw eks_cluster_name 2>/dev/null || true)"
current_app_namespace="$(terraform -chdir="${TF_DIR}" output -raw app_namespace 2>/dev/null || true)"
current_app_workload_name="$(terraform -chdir="${TF_DIR}" output -raw app_workload_name 2>/dev/null || true)"
current_app_namespace="${current_app_namespace:-wiz-demo}"
current_app_workload_name="${current_app_workload_name:-wiz-rsc-demo}"
if [[ -z "${LOG_RETENTION_DAYS}" && -n "${current_cluster_name}" ]]; then
  current_log_group="/aws/eks/${current_cluster_name}/cluster"
  LOG_RETENTION_DAYS="$(
    AWS_PROFILE="${AWS_PROFILE}" aws logs describe-log-groups \
      --region "${AWS_REGION}" \
      --log-group-name-prefix "${current_log_group}" \
      --query "logGroups[?logGroupName=='${current_log_group}']|[0].retentionInDays" \
      --output text 2>/dev/null || true
  )"
fi
LOG_RETENTION_DAYS="${LOG_RETENTION_DAYS:-1}"
if [[ -z "${EKS_LOGGING_MODE}" && -n "${current_cluster_name}" ]]; then
  enabled_types="$(
    AWS_PROFILE="${AWS_PROFILE}" aws eks describe-cluster \
      --region "${AWS_REGION}" \
      --name "${current_cluster_name}" \
      --query 'cluster.logging.clusterLogging[?enabled==`true`].types[]' \
      --output text 2>/dev/null || true
  )"
  if [[ " ${enabled_types} " == *" audit "* ]]; then
    EKS_LOGGING_MODE="default"
  elif [[ " ${enabled_types} " == *" api "* && " ${enabled_types} " == *" authenticator "* ]]; then
    EKS_LOGGING_MODE="minimal"
  elif [[ -n "${enabled_types}" ]]; then
    EKS_LOGGING_MODE="default"
  else
    EKS_LOGGING_MODE="off"
  fi
fi
EKS_LOGGING_MODE="${EKS_LOGGING_MODE:-off}"

echo "EKS_LOGGING_MODE=${EKS_LOGGING_MODE}"
if [[ -n "${current_cluster_name}" && "${SKIP_LB_CLEANUP:-}" != "1" ]]; then
  if command -v kubectl >/dev/null 2>&1; then
    echo "Cleaning up demo LoadBalancer service on cluster: ${current_cluster_name}"
    if AWS_PROFILE="${AWS_PROFILE}" aws eks update-kubeconfig \
      --region "${AWS_REGION}" \
      --name "${current_cluster_name}" \
      >/dev/null; then
      kubectl delete svc "${current_app_workload_name}" -n "${current_app_namespace}" --ignore-not-found >/dev/null 2>&1 || true
      kubectl wait --for=delete "svc/${current_app_workload_name}" -n "${current_app_namespace}" --timeout=120s >/dev/null 2>&1 || true

      if [[ "${DELETE_NAMESPACE}" == "1" ]]; then
        kubectl delete ns "${current_app_namespace}" --ignore-not-found >/dev/null 2>&1 || true
        kubectl wait --for=delete "ns/${current_app_namespace}" --timeout=180s >/dev/null 2>&1 || true
      fi
    else
      echo "Warning: failed to update kubeconfig for ${current_cluster_name}; skipping LoadBalancer cleanup" >&2
    fi
  else
    echo "kubectl not found; skipping LoadBalancer cleanup (set SKIP_LB_CLEANUP=1 to silence)" >&2
  fi
fi

replace_flag=""
echo "Detaching Terraform-managed Kubernetes resources from state (rotation-safe)..."
for addr in \
  "kubernetes_namespace.app_ns[0]" \
  "kubernetes_service_account.app_sa[0]" \
  "kubernetes_namespace.wiz[0]" \
  "kubernetes_secret.sensor_image_pull[0]" \
  "kubernetes_secret.wiz_api_token[0]" \
  "helm_release.wiz_integration[0]"; do
  if printf '%s\n' "${state_list}" | grep -Fxq "${addr}"; then
    terraform -chdir="${TF_DIR}" state rm "${addr}" >/dev/null
    echo "State removed: ${addr}"
  fi
done

if printf '%s\n' "${state_list}" | grep -Fxq 'random_id.eks_suffix'; then
  replace_flag="-replace=random_id.eks_suffix"
fi

echo "Rotating EKS cluster..."
terraform -chdir="${TF_DIR}" apply \
  -var='enable_eks=true' \
  -var='enable_k8s_resources=false' \
  ${replace_flag:+${replace_flag}} \
  ${apply_flag:+${apply_flag}}

new_cluster_name="$(terraform -chdir="${TF_DIR}" output -raw eks_cluster_name 2>/dev/null || true)"
if [[ -z "${new_cluster_name}" ]]; then
  echo "EKS cluster name output is empty; did the apply succeed?" >&2
  exit 1
fi

echo "New EKS cluster: ${new_cluster_name}"

case "${EKS_LOGGING_MODE}" in
  off)
    AWS_PROFILE="${AWS_PROFILE}" aws eks update-cluster-config \
      --region "${AWS_REGION}" \
      --name "${new_cluster_name}" \
      --logging '{"clusterLogging":[{"types":["api","audit","authenticator","controllerManager","scheduler"],"enabled":false}]}' \
      >/dev/null
    echo "EKS control-plane logging: disabled"
    ;;
  minimal)
    AWS_PROFILE="${AWS_PROFILE}" aws eks update-cluster-config \
      --region "${AWS_REGION}" \
      --name "${new_cluster_name}" \
      --logging '{"clusterLogging":[{"types":["api","authenticator"],"enabled":true},{"types":["audit","controllerManager","scheduler"],"enabled":false}]}' \
      >/dev/null
    echo "EKS control-plane logging: minimal (api, authenticator)"
    ;;
  default)
    echo "EKS control-plane logging: leaving as-is (Terraform defaults)"
    ;;
  *)
    echo "Unknown EKS_LOGGING_MODE='${EKS_LOGGING_MODE}' (expected: off|minimal|default)" >&2
    exit 1
    ;;
esac

log_group="/aws/eks/${new_cluster_name}/cluster"
if AWS_PROFILE="${AWS_PROFILE}" aws logs describe-log-groups \
  --region "${AWS_REGION}" \
  --log-group-name-prefix "${log_group}" \
  --query 'logGroups[?logGroupName==`'"${log_group}"'`].logGroupName' \
  --output text | grep -q "${log_group}"; then
  AWS_PROFILE="${AWS_PROFILE}" aws logs put-retention-policy \
    --region "${AWS_REGION}" \
    --log-group-name "${log_group}" \
    --retention-in-days "${LOG_RETENTION_DAYS}" \
    >/dev/null
  echo "CloudWatch retention: ${LOG_RETENTION_DAYS} day(s) on ${log_group}"
else
  echo "CloudWatch log group not found yet: ${log_group} (skipping retention)"
fi

echo "Re-enabling Terraform-managed Kubernetes resources on new cluster..."
terraform -chdir="${TF_DIR}" apply \
  -var='enable_eks=true' \
  -var='enable_k8s_resources=true' \
  ${apply_flag:+${apply_flag}}

echo "Rotate complete. Next: cd infra/k8s && ./deploy.sh"
