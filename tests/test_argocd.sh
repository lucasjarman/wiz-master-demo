#!/bin/bash
# Test ArgoCD deployment and configuration
# Can be run standalone or via test_infrastructure.sh

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------
ARGOCD_NAMESPACE="${ARGOCD_NAMESPACE:-argocd}"

# -----------------------------------------------------------------------------
# Test Functions
# -----------------------------------------------------------------------------

test_argocd_namespace_exists() {
  info "Testing ArgoCD namespace exists..."

  if namespace_exists "$ARGOCD_NAMESPACE"; then
    pass "ArgoCD namespace '$ARGOCD_NAMESPACE' exists"
    ((TEST_PASSED++))
  else
    fail "ArgoCD namespace '$ARGOCD_NAMESPACE' not found"
    ((TEST_FAILED++))
    return 1
  fi
}

test_argocd_pods_running() {
  info "Testing ArgoCD pods are running..."

  # Check for essential ArgoCD components
  local components=(
    "app.kubernetes.io/name=argocd-server"
    "app.kubernetes.io/name=argocd-repo-server"
    "app.kubernetes.io/name=argocd-application-controller"
  )

  local all_running=true
  for selector in "${components[@]}"; do
    local pod_count
    pod_count=$(kubectl get pods -n "$ARGOCD_NAMESPACE" -l "$selector" --field-selector=status.phase=Running -o name 2>/dev/null | wc -l | tr -d ' ')

    local component_name="${selector#*=}"
    if [[ "$pod_count" -gt 0 ]]; then
      pass "$component_name is running ($pod_count pod(s))"
      ((TEST_PASSED++))
    else
      fail "$component_name is not running"
      ((TEST_FAILED++))
      all_running=false
    fi
  done

  if [[ "$all_running" == "false" ]]; then
    return 1
  fi
}

test_argocd_server_service() {
  info "Testing ArgoCD server service exists with LoadBalancer..."

  # Check if argocd-server service exists
  local service_type
  service_type=$(kubectl get svc -n "$ARGOCD_NAMESPACE" argocd-server -o jsonpath='{.spec.type}' 2>/dev/null || echo "")

  if [[ -z "$service_type" ]]; then
    fail "ArgoCD server service not found"
    ((TEST_FAILED++))
    return 1
  fi

  pass "ArgoCD server service exists"
  ((TEST_PASSED++))

  if [[ "$service_type" == "LoadBalancer" ]]; then
    pass "ArgoCD server service is type LoadBalancer"
    ((TEST_PASSED++))

    # Check if LoadBalancer has an external address
    local external_ip
    external_ip=$(kubectl get svc -n "$ARGOCD_NAMESPACE" argocd-server -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")

    if [[ -z "$external_ip" ]]; then
      external_ip=$(kubectl get svc -n "$ARGOCD_NAMESPACE" argocd-server -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
    fi

    if [[ -n "$external_ip" ]]; then
      pass "ArgoCD LoadBalancer has external address: $external_ip"
      ((TEST_PASSED++))
    else
      warn "ArgoCD LoadBalancer external address not yet assigned"
    fi
  else
    info "ArgoCD server service type is $service_type (not LoadBalancer)"
  fi
}

test_argocd_admin_password() {
  info "Testing ArgoCD initial admin password is available..."

  # Check if the initial admin secret exists
  local secret_exists
  secret_exists=$(kubectl get secret -n "$ARGOCD_NAMESPACE" argocd-initial-admin-secret -o name 2>/dev/null || echo "")

  if [[ -n "$secret_exists" ]]; then
    # Verify we can decode the password
    local password
    password=$(kubectl get secret -n "$ARGOCD_NAMESPACE" argocd-initial-admin-secret -o jsonpath='{.data.password}' 2>/dev/null | base64 -d 2>/dev/null || echo "")

    if [[ -n "$password" ]]; then
      pass "ArgoCD initial admin password is retrievable"
      ((TEST_PASSED++))
    else
      fail "ArgoCD initial admin password could not be decoded"
      ((TEST_FAILED++))
      return 1
    fi
  else
    warn "ArgoCD initial admin secret not found (may have been deleted after first login)"
  fi
}

test_argocd_api_accessible() {
  info "Testing ArgoCD API is accessible..."

  # Get ArgoCD server URL from LoadBalancer
  local argocd_url
  argocd_url=$(kubectl get svc argocd-server -n "$ARGOCD_NAMESPACE" \
    -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")

  if [[ -z "$argocd_url" ]]; then
    warn "ArgoCD LoadBalancer URL not available"
    return 0
  fi

  # Try HTTP (ArgoCD is configured with server.insecure=true)
  local response
  response=$(curl -s --connect-timeout 10 --max-time 15 "http://${argocd_url}/api/version" 2>/dev/null || echo "")

  if [[ -n "$response" ]] && echo "$response" | grep -qi "version"; then
    local version
    version=$(echo "$response" | grep -o '"Version":"[^"]*"' | cut -d'"' -f4)
    pass "ArgoCD API is accessible (version: $version)"
    ((TEST_PASSED++))
  else
    warn "Could not access ArgoCD API (LoadBalancer may still be provisioning)"
  fi
}

test_argocd_login_works() {
  info "Testing ArgoCD login authentication..."

  # Get ArgoCD server URL from LoadBalancer
  local argocd_url
  argocd_url=$(kubectl get svc argocd-server -n "$ARGOCD_NAMESPACE" \
    -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")

  if [[ -z "$argocd_url" ]]; then
    warn "ArgoCD LoadBalancer URL not available"
    return 0
  fi

  # Get admin password
  local password
  password=$(kubectl get secret -n "$ARGOCD_NAMESPACE" argocd-initial-admin-secret \
    -o jsonpath='{.data.password}' 2>/dev/null | base64 -d 2>/dev/null || echo "")

  if [[ -z "$password" ]]; then
    warn "Cannot test login - admin password not available"
    return 0
  fi

  # Try to login via API (using HTTP since server.insecure=true)
  local login_response
  login_response=$(curl -s --connect-timeout 10 --max-time 15 \
    -X POST "http://${argocd_url}/api/v1/session" \
    -H "Content-Type: application/json" \
    -d "{\"username\":\"admin\",\"password\":\"${password}\"}" 2>/dev/null || echo "")

  if echo "$login_response" | grep -q "token"; then
    pass "ArgoCD login successful - received auth token"
    ((TEST_PASSED++))
  elif [[ -n "$login_response" ]]; then
    warn "ArgoCD login response: $login_response"
  else
    warn "Could not complete ArgoCD login test"
  fi
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------
main() {
  echo ""
  echo "=========================================="
  echo "  ArgoCD Tests"
  echo "=========================================="
  echo ""

  test_argocd_namespace_exists || true
  test_argocd_pods_running || true
  test_argocd_server_service || true
  test_argocd_admin_password || true
  test_argocd_api_accessible || true
  test_argocd_login_works || true

  print_summary
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main
  exit $?
fi
