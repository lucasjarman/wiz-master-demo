#!/usr/bin/env bash
# tests/test_app_access.sh - Tests for React2Shell app accessibility

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

# Get app details from Terraform or kubectl
APP_NAMESPACE="${APP_NAMESPACE:-react2shell-v1}"
APP_NAME="${APP_NAME:-react2shell-v1}"

get_app_url() {
  kubectl get svc "$APP_NAME" -n "$APP_NAMESPACE" \
    -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo ""
}

# -----------------------------------------------------------------------------
# Test Functions
# -----------------------------------------------------------------------------
test_app_service_exists() {
  info "Testing app service exists..."

  if kubectl get svc "$APP_NAME" -n "$APP_NAMESPACE" &>/dev/null; then
    pass "App service '$APP_NAME' exists in namespace '$APP_NAMESPACE'"
    ((TEST_PASSED++))
  else
    fail "App service '$APP_NAME' not found in namespace '$APP_NAMESPACE'"
    ((TEST_FAILED++))
    return 1
  fi
}

test_app_service_is_loadbalancer() {
  info "Testing app service is LoadBalancer type..."

  local svc_type
  svc_type=$(kubectl get svc "$APP_NAME" -n "$APP_NAMESPACE" \
    -o jsonpath='{.spec.type}' 2>/dev/null || echo "")

  if [[ "$svc_type" == "LoadBalancer" ]]; then
    pass "App service is type LoadBalancer (publicly exposed)"
    ((TEST_PASSED++))
  else
    fail "App service is type '$svc_type', expected 'LoadBalancer'"
    ((TEST_FAILED++))
    return 1
  fi
}

test_app_has_external_ip() {
  info "Testing app has external IP/hostname..."

  local app_url
  app_url=$(get_app_url)

  if [[ -n "$app_url" ]]; then
    pass "App LoadBalancer has external address: $app_url"
    ((TEST_PASSED++))
  else
    fail "App LoadBalancer has no external address"
    ((TEST_FAILED++))
    return 1
  fi
}

test_app_pods_running() {
  info "Testing app pods are running..."

  local ready_pods
  ready_pods=$(kubectl get pods -n "$APP_NAMESPACE" -l "app=$APP_NAME" \
    -o jsonpath='{.items[*].status.containerStatuses[*].ready}' 2>/dev/null || echo "")

  if [[ "$ready_pods" == *"true"* ]]; then
    local pod_count
    pod_count=$(kubectl get pods -n "$APP_NAMESPACE" -l "app=$APP_NAME" \
      --field-selector=status.phase=Running -o name 2>/dev/null | wc -l | tr -d ' ')
    pass "App has $pod_count running pod(s)"
    ((TEST_PASSED++))
  else
    fail "App pods are not ready"
    ((TEST_FAILED++))
    return 1
  fi
}

test_app_responds_http() {
  info "Testing app responds to HTTP requests..."

  local app_url
  app_url=$(get_app_url)

  if [[ -z "$app_url" ]]; then
    warn "Skipping HTTP test - no external address available"
    return 0
  fi

  # Try to reach the app with timeout
  local http_code
  http_code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 10 \
    "http://${app_url}/" 2>/dev/null || echo "000")

  if [[ "$http_code" =~ ^(200|302|301|404|500)$ ]]; then
    pass "App responds to HTTP (status: $http_code)"
    ((TEST_PASSED++))
  else
    warn "App not responding to HTTP (status: $http_code) - NLB may still be provisioning"
  fi
}

test_app_uses_irsa_service_account() {
  info "Testing app uses IRSA service account..."

  local sa_name
  sa_name=$(kubectl get deployment "$APP_NAME" -n "$APP_NAMESPACE" \
    -o jsonpath='{.spec.template.spec.serviceAccountName}' 2>/dev/null || echo "")

  if [[ -n "$sa_name" ]]; then
    # Check if the SA has an IAM role annotation
    local role_arn
    role_arn=$(kubectl get sa "$sa_name" -n "$APP_NAMESPACE" \
      -o jsonpath='{.metadata.annotations.eks\.amazonaws\.com/role-arn}' 2>/dev/null || echo "")

    if [[ -n "$role_arn" ]]; then
      pass "App uses service account '$sa_name' with IRSA role: $role_arn"
      ((TEST_PASSED++))
    else
      fail "Service account '$sa_name' has no IRSA role annotation"
      ((TEST_FAILED++))
      return 1
    fi
  else
    fail "Deployment does not specify a service account"
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
  echo "  App Access Tests"
  echo "=========================================="
  echo ""

  test_app_service_exists || true
  test_app_service_is_loadbalancer || true
  test_app_has_external_ip || true
  test_app_pods_running || true
  test_app_responds_http || true
  test_app_uses_irsa_service_account || true

  print_summary
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main
  exit $?
fi
