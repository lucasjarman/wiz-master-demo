#!/usr/bin/env bash
set -euo pipefail

# Deep stop: additional cost reduction on top of cold stop.
#
# This script intentionally makes AWS-side changes that Terraform will later revert/recreate:
# - Stop CloudTrail logging for the demo trail
# - Delete VPC Flow Logs for the demo VPC
# - Disassociate Route53 Resolver query logging from the demo VPC
#
# Run order:
# 1) ./Commands/cold-stop.sh
# 2) ./Commands/deep-stop.sh
#
# Env overrides:
# - AWS_PROFILE (default: wiz-demo)
# - AWS_REGION  (default: ap-southeast-2)
# - AUTO_APPROVE=1 to skip confirmation prompt

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF_DIR="${ROOT_DIR}/infra/aws"

AWS_PROFILE="${AWS_PROFILE:-wiz-demo}"
AWS_REGION="${AWS_REGION:-ap-southeast-2}"

if ! command -v terraform >/dev/null 2>&1; then
  echo "terraform not found in PATH" >&2
  exit 1
fi
if ! command -v aws >/dev/null 2>&1; then
  echo "aws CLI not found in PATH" >&2
  exit 1
fi
if ! command -v jq >/dev/null 2>&1; then
  echo "jq not found in PATH (required)" >&2
  exit 1
fi

terraform -chdir="${TF_DIR}" init -input=false >/dev/null

suffix_hex="$(terraform -chdir="${TF_DIR}" state show -no-color random_id.suffix 2>/dev/null | awk '/^hex[[:space:]]+=/ {gsub(/\"/,"",$3); print $3; exit}')"
if [[ -z "${suffix_hex}" ]]; then
  echo "Could not read random_id.suffix from state; is the environment initialized?" >&2
  exit 1
fi

trail_name="wiz-demo-trail-${suffix_hex}"
vpc_id="$(terraform -chdir="${TF_DIR}" output -raw vpc_id 2>/dev/null || true)"

echo "Deep stop targets:"
echo "- CloudTrail trail: ${trail_name}"
echo "- VPC ID: ${vpc_id}"
echo "- Flow log tag Name=wiz-demo-vpc-flow-log"

if [[ "${AUTO_APPROVE:-}" != "1" ]]; then
  read -r -p "Proceed with deep stop actions (stop/delete/disassociate)? [y/N] " confirm
  if [[ "${confirm}" != "y" && "${confirm}" != "Y" ]]; then
    echo "Aborted."
    exit 0
  fi
fi

# 1) Stop CloudTrail logging (best-effort: the trail may not exist if previously removed)
if AWS_PROFILE="${AWS_PROFILE}" aws cloudtrail get-trail --region "${AWS_REGION}" --name "${trail_name}" >/dev/null 2>&1; then
  AWS_PROFILE="${AWS_PROFILE}" aws cloudtrail stop-logging --region "${AWS_REGION}" --name "${trail_name}" >/dev/null
  echo "Stopped CloudTrail logging: ${trail_name}"
else
  echo "CloudTrail trail not found (skipping): ${trail_name}"
fi

# 2) Delete VPC Flow Logs (by tag Name=wiz-demo-vpc-flow-log)
flow_log_ids="$(
  AWS_PROFILE="${AWS_PROFILE}" aws ec2 describe-flow-logs \
    --region "${AWS_REGION}" \
    --filter Name=tag:Name,Values=wiz-demo-vpc-flow-log \
    --query 'FlowLogs[].FlowLogId' \
    --output json | jq -r '.[]?'
)"
if [[ -n "${flow_log_ids}" ]]; then
  # shellcheck disable=SC2086
  AWS_PROFILE="${AWS_PROFILE}" aws ec2 delete-flow-logs --region "${AWS_REGION}" --flow-log-ids ${flow_log_ids} >/dev/null
  echo "Deleted VPC Flow Logs: ${flow_log_ids//$'\n'/ }"
else
  echo "No VPC Flow Logs found with tag Name=wiz-demo-vpc-flow-log (skipping)"
fi

# 3) Disassociate Route53 Resolver query logging from the VPC
if [[ -n "${vpc_id}" ]]; then
  assoc_ids="$(
    AWS_PROFILE="${AWS_PROFILE}" aws route53resolver list-resolver-query-log-config-associations \
      --region "${AWS_REGION}" \
      --filters Name=ResourceId,Values="${vpc_id}" \
      --query 'ResolverQueryLogConfigAssociations[].Id' \
      --output json | jq -r '.[]?'
  )"
  if [[ -n "${assoc_ids}" ]]; then
    while IFS= read -r assoc_id; do
      [[ -z "${assoc_id}" ]] && continue
      AWS_PROFILE="${AWS_PROFILE}" aws route53resolver disassociate-resolver-query-log-config \
        --region "${AWS_REGION}" \
        --resolver-query-log-config-association-id "${assoc_id}" \
        >/dev/null
      echo "Disassociated resolver query log config: ${assoc_id}"
    done <<< "${assoc_ids}"
  else
    echo "No resolver query log associations found for VPC ${vpc_id} (skipping)"
  fi
else
  echo "VPC ID is empty (skipping resolver query log disassociation)"
fi

echo "Deep stop complete. Next UP: run ./Commands/up.sh (Terraform will recreate/re-enable as needed)."

