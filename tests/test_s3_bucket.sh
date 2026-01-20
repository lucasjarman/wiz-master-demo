#!/usr/bin/env bash
# tests/test_s3_bucket.sh - Tests for S3 bucket configuration and sensitive data

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

# Helper to run AWS commands via fnox (local credentials)
run_aws() {
    cd "${REPO_ROOT}/infrastructure/shared/aws" && \
        mise exec -- fnox run --profile dev -- aws "$@" 2>/dev/null
}

# Get bucket name from Terraform output or environment
get_bucket_name() {
    if [[ -n "${S3_BUCKET_NAME:-}" ]]; then
        echo "$S3_BUCKET_NAME"
        return
    fi

    # Try to get from Terraform
    local bucket
    bucket=$(cd "${SCRIPT_DIR}/../scenarios/react2shell/aws" && \
        mise exec -- fnox run --profile dev -- terraform output -raw s3_bucket_name 2>/dev/null || echo "")

    if [[ -z "$bucket" ]]; then
        bucket="react2shell-v1-sensitive-data"
    fi
    echo "$bucket"
}

BUCKET_NAME=$(get_bucket_name)
APP_NAMESPACE="${APP_NAMESPACE:-react2shell-v1}"
APP_NAME="${APP_NAME:-react2shell-v1}"

# Helper to run AWS commands via pod (uses IRSA)
run_aws_in_pod() {
    kubectl exec -n "$APP_NAMESPACE" "deploy/$APP_NAME" -- "$@" 2>/dev/null
}

# -----------------------------------------------------------------------------
# Test Functions
# -----------------------------------------------------------------------------
test_bucket_exists() {
    info "Testing S3 bucket exists..."

    local result
    result=$(run_aws s3api head-bucket --bucket "${BUCKET_NAME}" 2>&1 || echo "ERROR")

    if [[ "$result" != *"ERROR"* ]] && [[ "$result" != *"Not Found"* ]] && [[ "$result" != *"Forbidden"* ]]; then
        pass "S3 bucket '$BUCKET_NAME' exists"
        ((TEST_PASSED++))
    else
        fail "S3 bucket '$BUCKET_NAME' does not exist: $result"
        ((TEST_FAILED++))
        return 1
    fi
}

test_bucket_public_access_blocked() {
    info "Testing S3 bucket has public access blocked..."

    local pab
    pab=$(run_aws s3api get-public-access-block --bucket "${BUCKET_NAME}" --output json 2>/dev/null || echo "{}")

    local all_blocked=true
    for setting in BlockPublicAcls IgnorePublicAcls BlockPublicPolicy RestrictPublicBuckets; do
        local value
        value=$(echo "$pab" | jq -r ".PublicAccessBlockConfiguration.$setting // false" 2>/dev/null || echo "false")
        if [[ "$value" != "true" ]]; then
            all_blocked=false
        fi
    done

    if [[ "$all_blocked" == "true" ]]; then
        pass "S3 bucket has all public access blocked"
        ((TEST_PASSED++))
    else
        warn "S3 bucket does not have all public access blocked (expected for Wiz toxic combination)"
    fi
}

test_bucket_versioning_enabled() {
    info "Testing S3 bucket has versioning enabled..."

    local versioning
    versioning=$(run_aws s3api get-bucket-versioning --bucket "${BUCKET_NAME}" --output json 2>/dev/null || echo "{}")
    local status
    status=$(echo "$versioning" | jq -r '.Status // "Disabled"' 2>/dev/null || echo "Disabled")

    if [[ "$status" == "Enabled" ]]; then
        pass "S3 bucket versioning is enabled"
        ((TEST_PASSED++))
    else
        warn "S3 bucket versioning is not enabled (Status: $status)"
    fi
}

test_bucket_has_sensitive_data() {
    info "Testing S3 bucket contains sensitive data files..."

    local objects
    objects=$(run_aws s3 ls "s3://${BUCKET_NAME}/" --recursive 2>/dev/null || echo "")

    if [[ -z "$objects" ]]; then
        fail "S3 bucket is empty"
        ((TEST_FAILED++))
        return 1
    fi

    local file_count
    file_count=$(echo "$objects" | wc -l | tr -d ' ')
    pass "S3 bucket contains $file_count file(s)"
    ((TEST_PASSED++))

    # Check for specific sensitive data patterns in filenames
    if echo "$objects" | grep -qi "pii\|customer\|employee\|patient\|payroll\|api_key"; then
        pass "Bucket contains PII-related files"
        ((TEST_PASSED++))
    else
        warn "No PII-related files found (expected for Wiz detection)"
    fi
}

test_sensitive_data_contains_pii_patterns() {
    info "Testing sensitive data contains PII patterns for Wiz detection..."

    # Try to download and check content of sensitive files
    local content=""
    local files=("pii/customer_data.txt" "customers/customer_database.csv" "employees.json")

    for file in "${files[@]}"; do
        content=$(run_aws s3 cp "s3://${BUCKET_NAME}/${file}" - 2>/dev/null || echo "")
        if [[ -n "$content" ]]; then
            break
        fi
    done

    if [[ -z "$content" ]]; then
        warn "Could not retrieve sensitive data file content"
        return 0
    fi

    local patterns_found=0

    # Check for SSN pattern
    if echo "$content" | grep -qE "[0-9]{3}-[0-9]{2}-[0-9]{4}"; then
        ((patterns_found++))
    fi

    # Check for credit card pattern
    if echo "$content" | grep -qE "[0-9]{4}[-]?[0-9]{4}[-]?[0-9]{4}[-]?[0-9]{4}"; then
        ((patterns_found++))
    fi

    # Check for AWS key pattern
    if echo "$content" | grep -qE "AKIA[A-Z0-9]{16}"; then
        ((patterns_found++))
    fi

    if [[ $patterns_found -gt 0 ]]; then
        pass "Sensitive data contains $patterns_found PII pattern type(s) (SSN, CC, AWS keys)"
        ((TEST_PASSED++))
    else
        warn "No standard PII patterns detected - Wiz may not flag as sensitive"
    fi
}

test_irsa_can_access_bucket() {
    info "Testing IRSA role can access bucket from pod..."

    local result
    result=$(kubectl exec -n "$APP_NAMESPACE" "deploy/$APP_NAME" -- \
        aws s3 ls "s3://${BUCKET_NAME}/" 2>&1 || echo "ERROR")

    if [[ "$result" != *"ERROR"* ]] && [[ "$result" != *"AccessDenied"* ]]; then
        pass "Pod can access S3 bucket via IRSA"
        ((TEST_PASSED++))
    else
        fail "Pod cannot access S3 bucket: $result"
        ((TEST_FAILED++))
        return 1
    fi
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------
main() {
    echo ""
    echo "=========================================="
    echo "  S3 Bucket Tests"
    echo "=========================================="
    echo ""

    test_bucket_exists || true
    test_bucket_public_access_blocked || true
    test_bucket_versioning_enabled || true
    test_bucket_has_sensitive_data || true
    test_sensitive_data_contains_pii_patterns || true
    test_irsa_can_access_bucket || true

    print_summary
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
    exit $?
fi

