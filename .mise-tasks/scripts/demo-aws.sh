#!/usr/bin/env bash
#
# Source this file from mise tasks to run all AWS/Terraform actions against a
# dedicated "throwaway demo" AWS account without touching the user's normal
# AWS profile/credentials.
#
# Usage in a mise task:
#   # shellcheck source=/dev/null
#   source "$(command -v demo-aws.sh)"
#   demo_aws_activate
#

set -euo pipefail

demo_aws__pick_secret() {
  # Support a few historical/mistyped env var names to reduce friction.
  if [[ -n "${DEMO_AWS_SECRET_ACCESS_KEY:-}" ]]; then
    printf '%s' "$DEMO_AWS_SECRET_ACCESS_KEY"
    return 0
  fi
  if [[ -n "${DEMO_SECRET_ACCESS_KEY_ID:-}" ]]; then
    printf '%s' "$DEMO_SECRET_ACCESS_KEY_ID"
    return 0
  fi
  if [[ -n "${DEMO_AWS_SECRET_ACCESS_KEY_ID:-}" ]]; then
    printf '%s' "$DEMO_AWS_SECRET_ACCESS_KEY_ID"
    return 0
  fi
  return 1
}

demo_aws_activate() {
  if [[ -z "${DEMO_AWS_ACCESS_KEY_ID:-}" ]]; then
    echo "ERROR: DEMO_AWS_ACCESS_KEY_ID is not set." >&2
    echo "Set demo-only credentials for this repo, e.g.:" >&2
    echo "  export DEMO_AWS_ACCESS_KEY_ID='...'" >&2
    echo "  export DEMO_AWS_SECRET_ACCESS_KEY='...'" >&2
    echo "  export DEMO_AWS_ACCOUNT_ID='123456789012'  # safety guardrail" >&2
    echo "  export DEMO_AWS_REGION='ap-southeast-2'     # optional" >&2
    return 1
  fi

  local secret=""
  if ! secret="$(demo_aws__pick_secret)"; then
    echo "ERROR: Demo secret key env var not set." >&2
    echo "Set one of:" >&2
    echo "  DEMO_AWS_SECRET_ACCESS_KEY (preferred)" >&2
    echo "  DEMO_SECRET_ACCESS_KEY_ID (accepted for backwards-compat)" >&2
    echo "  DEMO_AWS_SECRET_ACCESS_KEY_ID (accepted for backwards-compat)" >&2
    return 1
  fi

  # Do not allow an ambient profile to accidentally override credentials.
  unset AWS_PROFILE

  export AWS_ACCESS_KEY_ID="$DEMO_AWS_ACCESS_KEY_ID"
  export AWS_SECRET_ACCESS_KEY="$secret"

  if [[ -n "${DEMO_AWS_SESSION_TOKEN:-}" ]]; then
    export AWS_SESSION_TOKEN="$DEMO_AWS_SESSION_TOKEN"
  fi

  local region="${DEMO_AWS_REGION:-${AWS_DEFAULT_REGION:-${AWS_REGION:-ap-southeast-2}}}"
  export AWS_REGION="$region"
  export AWS_DEFAULT_REGION="$region"
  export TF_VAR_aws_region="${TF_VAR_aws_region:-$region}"

  if [[ -z "${DEMO_AWS_ACCOUNT_ID:-}" ]] && [[ "${DEMO_SKIP_ACCOUNT_CHECK:-}" != "true" ]]; then
    echo "ERROR: DEMO_AWS_ACCOUNT_ID is not set (required safety guardrail)." >&2
    echo "Run once:" >&2
    echo "  export DEMO_AWS_ACCOUNT_ID='123456789012'" >&2
    echo "" >&2
    echo "If you really need to bypass this check (not recommended):" >&2
    echo "  export DEMO_SKIP_ACCOUNT_CHECK=true" >&2
    return 1
  fi

  # Confirm we are in the intended AWS account before doing anything destructive.
  local actual_account=""
  actual_account="$(aws sts get-caller-identity --query Account --output text 2>/dev/null || true)"
  if [[ -z "$actual_account" || "$actual_account" == "None" ]]; then
    echo "ERROR: AWS authentication failed for demo credentials." >&2
    return 1
  fi

  if [[ -n "${DEMO_AWS_ACCOUNT_ID:-}" && "${DEMO_SKIP_ACCOUNT_CHECK:-}" != "true" ]]; then
    if [[ "$actual_account" != "$DEMO_AWS_ACCOUNT_ID" ]]; then
      echo "ERROR: Refusing to run against unexpected AWS account." >&2
      echo "  Expected: $DEMO_AWS_ACCOUNT_ID" >&2
      echo "  Actual:   $actual_account" >&2
      echo "Fix DEMO_* env vars before proceeding." >&2
      return 1
    fi
  fi
}
