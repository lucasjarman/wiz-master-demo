#!/usr/bin/env bash
set -euo pipefail

# Reports whether Wiz Helm/Terraform variables are present without printing secrets.
#
# Looks in (1) TF_VAR_* environment variables and (2) infra/aws/terraform.tfvars.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TFVARS_PATH="${ROOT_DIR}/infra/aws/terraform.tfvars"

read_tfvars_value() {
  local key="$1"
  [[ -f "${TFVARS_PATH}" ]] || return 0

  awk -v k="${key}" '
    BEGIN { FS="=" }
    $0 ~ "^[[:space:]]*" k "[[:space:]]*=" {
      val=$2
      sub(/^[[:space:]]*/, "", val)
      sub(/[[:space:]]*$/, "", val)
      if (val ~ /^".*"$/) { sub(/^"/, "", val); sub(/"$/, "", val) }
      print val
      exit
    }
  ' "${TFVARS_PATH}" 2>/dev/null || true
}

var_status() {
  local key="$1"
  local env_key="TF_VAR_${key}"
  local env_val="${!env_key:-}"
  local file_val
  file_val="$(read_tfvars_value "${key}")"

  if [[ -n "${env_val}" ]]; then
    echo "set (env: ${env_key})"
    return 0
  fi
  if [[ -n "${file_val}" ]]; then
    echo "set (${TFVARS_PATH##*/})"
    return 0
  fi
  echo "missing/empty"
}

wiz_client_id_status="$(var_status wiz_client_id)"
wiz_client_secret_status="$(var_status wiz_client_secret)"
wiz_sensor_pull_user_status="$(var_status wiz_sensor_pull_user)"
wiz_sensor_pull_password_status="$(var_status wiz_sensor_pull_password)"

printf "%-24s %s\n" "wiz_client_id:" "${wiz_client_id_status}"
printf "%-24s %s\n" "wiz_client_secret:" "${wiz_client_secret_status}"
printf "%-24s %s\n" "wiz_sensor_pull_user:" "${wiz_sensor_pull_user_status}"
printf "%-24s %s\n" "wiz_sensor_pull_password:" "${wiz_sensor_pull_password_status}"

all_set=1
for key in wiz_client_id wiz_client_secret wiz_sensor_pull_user wiz_sensor_pull_password; do
  if [[ "$(var_status "${key}")" == "missing/empty" ]]; then
    all_set=0
  fi
done

if [[ "${all_set}" == "1" ]]; then
  echo "Wiz integration variables look set (Terraform Helm deploy should work)."
else
  echo "Wiz integration variables are missing/empty (Terraform Helm deploy will be disabled or fail)."
fi

