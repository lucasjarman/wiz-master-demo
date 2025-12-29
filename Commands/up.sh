#!/usr/bin/env bash
set -euo pipefail

# Brings the demo environment "up" (EKS enabled) and applies cost controls for EKS logging.
#
# Env overrides:
# - AWS_PROFILE (default: wiz-demo)
# - AWS_REGION  (default: ap-southeast-2)
# - AUTO_APPROVE=1 to pass -auto-approve to terraform apply
# - EKS_LOGGING_MODE=off|minimal|default (default: off)
# - LOG_RETENTION_DAYS (default: 1)

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF_DIR="${ROOT_DIR}/infra/aws"

AWS_PROFILE="${AWS_PROFILE:-wiz-demo}"
AWS_REGION="${AWS_REGION:-ap-southeast-2}"
EKS_LOGGING_MODE="${EKS_LOGGING_MODE:-off}"
LOG_RETENTION_DAYS="${LOG_RETENTION_DAYS:-1}"

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
terraform -chdir="${TF_DIR}" apply -var='enable_eks=true' ${apply_flag:+${apply_flag}}

cluster_name="$(terraform -chdir="${TF_DIR}" output -raw eks_cluster_name 2>/dev/null || true)"
if [[ -z "${cluster_name}" ]]; then
  echo "EKS cluster name output is empty; did enable_eks=true apply successfully?" >&2
  exit 1
fi

echo "EKS cluster: ${cluster_name}"

case "${EKS_LOGGING_MODE}" in
  off)
    AWS_PROFILE="${AWS_PROFILE}" aws eks update-cluster-config \
      --region "${AWS_REGION}" \
      --name "${cluster_name}" \
      --logging '{"clusterLogging":[{"types":["api","audit","authenticator","controllerManager","scheduler"],"enabled":false}]}' \
      >/dev/null
    echo "EKS control-plane logging: disabled"
    ;;
  minimal)
    AWS_PROFILE="${AWS_PROFILE}" aws eks update-cluster-config \
      --region "${AWS_REGION}" \
      --name "${cluster_name}" \
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

log_group="/aws/eks/${cluster_name}/cluster"
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
