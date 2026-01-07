#!/usr/bin/env bash
set -euo pipefail

# Cold stop: disables EKS via Terraform without destroying the whole environment.
#
# Env overrides:
# - AUTO_APPROVE=1 to pass -auto-approve to terraform apply

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF_DIR="${ROOT_DIR}/infra/aws"

if ! command -v terraform >/dev/null 2>&1; then
  echo "terraform not found in PATH" >&2
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

echo "Detaching Terraform-managed Kubernetes resources from state (cold stop)..."
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

terraform -chdir="${TF_DIR}" apply -var='enable_eks=false' ${apply_flag:+${apply_flag}}

echo "Cold stop complete: EKS disabled (other demo resources remain)."
