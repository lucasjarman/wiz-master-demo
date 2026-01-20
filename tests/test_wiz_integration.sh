#!/bin/bash
# Test Wiz integration configuration
# Can be run standalone or via test_infrastructure.sh

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------
WIZ_NAMESPACE="${WIZ_NAMESPACE:-wiz}"
ARGOCD_NAMESPACE="${ARGOCD_NAMESPACE:-argocd}"

# -----------------------------------------------------------------------------
# Test Functions
# -----------------------------------------------------------------------------

test_wiz_namespace_exists() {
  info "Testing Wiz namespace exists..."

  if namespace_exists "$WIZ_NAMESPACE"; then
    pass "Wiz namespace '$WIZ_NAMESPACE' exists"
    ((TEST_PASSED++))
  else
    fail "Wiz namespace '$WIZ_NAMESPACE' not found"
    ((TEST_FAILED++))
    return 1
  fi
}

test_wiz_argocd_application_exists() {
  info "Testing Wiz ArgoCD Application exists..."

  # Check for Wiz ArgoCD Application
  local wiz_apps
  wiz_apps=$(kubectl get applications -n "$ARGOCD_NAMESPACE" -o name 2>/dev/null | grep -i wiz || echo "")

  if [[ -n "$wiz_apps" ]]; then
    pass "Wiz ArgoCD Application found: ${wiz_apps}"
    ((TEST_PASSED++))

    # Check application sync status
    for app in $wiz_apps; do
      local app_name="${app#application.argoproj.io/}"
      local sync_status
      sync_status=$(kubectl get application -n "$ARGOCD_NAMESPACE" "$app_name" -o jsonpath='{.status.sync.status}' 2>/dev/null || echo "Unknown")
      local health_status
      health_status=$(kubectl get application -n "$ARGOCD_NAMESPACE" "$app_name" -o jsonpath='{.status.health.status}' 2>/dev/null || echo "Unknown")

      if [[ "$sync_status" == "Synced" ]]; then
        pass "Application $app_name is Synced"
        ((TEST_PASSED++))
      else
        warn "Application $app_name sync status: $sync_status"
      fi

      if [[ "$health_status" == "Healthy" ]]; then
        pass "Application $app_name is Healthy"
        ((TEST_PASSED++))
      else
        warn "Application $app_name health status: $health_status"
      fi
    done
  else
    fail "No Wiz ArgoCD Application found"
    ((TEST_FAILED++))
    return 1
  fi
}

test_wiz_connector_configured() {
  info "Testing Wiz connector is configured..."

  # Check for Wiz connector pods
  local connector_pods
  connector_pods=$(kubectl get pods -n "$WIZ_NAMESPACE" -l app.kubernetes.io/name=wiz-kubernetes-connector -o name 2>/dev/null || echo "")

  if [[ -z "$connector_pods" ]]; then
    # Try alternative label
    connector_pods=$(kubectl get pods -n "$WIZ_NAMESPACE" -o name 2>/dev/null | grep -i connector || echo "")
  fi

  if [[ -n "$connector_pods" ]]; then
    pass "Wiz connector pods found"
    ((TEST_PASSED++))

    # Check if connector pods are running
    local running_count
    running_count=$(kubectl get pods -n "$WIZ_NAMESPACE" --field-selector=status.phase=Running -o name 2>/dev/null | grep -i connector | wc -l | tr -d ' ' || echo "0")

    if [[ "$running_count" -gt 0 ]]; then
      pass "Wiz connector is running ($running_count pod(s))"
      ((TEST_PASSED++))
    else
      fail "Wiz connector pods are not running"
      ((TEST_FAILED++))
    fi
  else
    warn "Wiz connector pods not found - may still be deploying"
  fi

  # Check for Wiz sensor pods
  local sensor_pods
  sensor_pods=$(kubectl get pods -n "$WIZ_NAMESPACE" -l app.kubernetes.io/name=wiz-sensor -o name 2>/dev/null || echo "")

  if [[ -z "$sensor_pods" ]]; then
    sensor_pods=$(kubectl get pods -n "$WIZ_NAMESPACE" -o name 2>/dev/null | grep -i sensor || echo "")
  fi

  if [[ -n "$sensor_pods" ]]; then
    pass "Wiz sensor pods found"
    ((TEST_PASSED++))
  else
    info "Wiz sensor pods not found (may be disabled)"
  fi

  # Check for Wiz secrets (API token, pull secret)
  local secrets
  secrets=$(kubectl get secrets -n "$WIZ_NAMESPACE" -o name 2>/dev/null || echo "")

  if echo "$secrets" | grep -qi "wiz\|api\|token\|pull"; then
    pass "Wiz secrets are configured"
    ((TEST_PASSED++))
  else
    warn "No Wiz-related secrets found in $WIZ_NAMESPACE namespace"
  fi
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------
main() {
  echo ""
  echo "=========================================="
  echo "  Wiz Integration Tests"
  echo "=========================================="
  echo ""

  test_wiz_namespace_exists || true
  test_wiz_argocd_application_exists || true
  test_wiz_connector_configured || true

  print_summary
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main
  exit $?
fi
