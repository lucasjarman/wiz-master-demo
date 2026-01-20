#!/bin/bash
# Test NetworkPolicy enforcement
# Can be run standalone or via test_infrastructure.sh

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------
REACT2SHELL_NAMESPACE="${REACT2SHELL_NAMESPACE:-react2shell}"

# Wiz Scanner CIDRs (from scenarios/react2shell/aws/variables.tf)
WIZ_SCANNER_CIDRS=(
  "54.78.133.42/32"
  "54.220.121.66/32"
  "18.202.52.49/32"
  "52.209.199.63/32"
  "54.220.187.83/32"
  "99.80.118.149/32"
)

# -----------------------------------------------------------------------------
# Test Functions
# -----------------------------------------------------------------------------

test_vpc_cni_network_policy_enabled() {
  info "Testing VPC CNI NetworkPolicy support..."

  # Check if vpc-cni addon is installed
  local addon_status
  addon_status=$(kubectl get daemonset aws-node -n kube-system -o jsonpath='{.status.numberReady}' 2>/dev/null || echo "0")

  if [[ "$addon_status" -gt 0 ]]; then
    pass "VPC CNI is running with $addon_status ready nodes"
    ((TEST_PASSED++))
  else
    fail "VPC CNI aws-node daemonset not found or not ready"
    ((TEST_FAILED++))
    return 1
  fi

  # Check for network policy controller (vpc-cni with network policy enabled runs this)
  local np_controller
  np_controller=$(kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-network-policy-agent -o name 2>/dev/null || echo "")

  if [[ -n "$np_controller" ]]; then
    pass "AWS Network Policy Agent is deployed"
    ((TEST_PASSED++))
  else
    warn "AWS Network Policy Agent not found - NetworkPolicy may not be enforced"
    # Don't fail - might be using different network policy implementation
  fi
}

test_network_policy_exists() {
  info "Testing NetworkPolicy resources exist..."

  # Try to find namespaces matching react2shell pattern
  local namespaces
  namespaces=$(kubectl get namespaces -o name 2>/dev/null | grep -E "(react2shell|wiz-demo)" || echo "")

  if [[ -z "$namespaces" ]]; then
    warn "No react2shell or wiz-demo namespaces found - skipping NetworkPolicy check"
    return 0
  fi

  local found_policy=false
  for ns in $namespaces; do
    ns_name="${ns#namespace/}"
    local policies
    policies=$(kubectl get networkpolicies -n "$ns_name" -o name 2>/dev/null || echo "")
    if [[ -n "$policies" ]]; then
      pass "NetworkPolicy found in namespace $ns_name"
      ((TEST_PASSED++))
      found_policy=true
    fi
  done

  if [[ "$found_policy" == "false" ]]; then
    fail "No NetworkPolicy resources found in any app namespace"
    ((TEST_FAILED++))
    return 1
  fi
}

test_network_policy_allows_wiz_scanner() {
  info "Testing NetworkPolicy allows Wiz scanner IPs..."

  # Find app namespaces
  local namespaces
  namespaces=$(kubectl get namespaces -o name 2>/dev/null | grep -E "(react2shell|wiz-demo)" || echo "")

  if [[ -z "$namespaces" ]]; then
    warn "No app namespaces found - skipping Wiz scanner IP check"
    return 0
  fi

  for ns in $namespaces; do
    ns_name="${ns#namespace/}"
    local policy_yaml
    policy_yaml=$(kubectl get networkpolicies -n "$ns_name" -o yaml 2>/dev/null || echo "")

    if [[ -z "$policy_yaml" ]]; then
      continue
    fi

    # Check if any Wiz scanner CIDR is in the policy
    local found_wiz_cidr=false
    for cidr in "${WIZ_SCANNER_CIDRS[@]}"; do
      if echo "$policy_yaml" | grep -q "$cidr"; then
        found_wiz_cidr=true
        break
      fi
    done

    if [[ "$found_wiz_cidr" == "true" ]]; then
      pass "NetworkPolicy in $ns_name includes Wiz scanner CIDRs"
      ((TEST_PASSED++))
    else
      fail "NetworkPolicy in $ns_name does not include Wiz scanner CIDRs"
      ((TEST_FAILED++))
    fi
  done
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------
main() {
  echo ""
  echo "=========================================="
  echo "  NetworkPolicy Tests"
  echo "=========================================="
  echo ""

  test_vpc_cni_network_policy_enabled || true
  test_network_policy_exists || true
  test_network_policy_allows_wiz_scanner || true

  print_summary
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main
  exit $?
fi
