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

apply_args=()
if [[ "${AUTO_APPROVE:-}" == "1" ]]; then
  apply_args+=("-auto-approve")
fi

terraform -chdir="${TF_DIR}" init -input=false
terraform -chdir="${TF_DIR}" apply -var='enable_eks=false' "${apply_args[@]}"

echo "Cold stop complete: EKS disabled (other demo resources remain)."

