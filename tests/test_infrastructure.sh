#!/bin/bash
# Main infrastructure test runner
# Runs all test suites and reports overall status

set -euo pipefail

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TESTS_TO_RUN=()
VERBOSE=${VERBOSE:-false}

# -----------------------------------------------------------------------------
# Colors
# -----------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

# -----------------------------------------------------------------------------
# Usage
# -----------------------------------------------------------------------------
usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS] [TEST_SUITE...]

Infrastructure Integration Test Runner

OPTIONS:
    -h, --help      Show this help message
    -v, --verbose   Show verbose output
    -l, --list      List available test suites

TEST SUITES:
    network-policy  Test NetworkPolicy enforcement
    argocd          Test ArgoCD deployment
    wiz             Test Wiz integration
    app             Test app accessibility and IRSA
    s3              Test S3 bucket config and sensitive data
    wiz-defend      Test Wiz Defend logging (CloudTrail, FlowLogs, EKS audit)
    all             Run all test suites (default)

EXAMPLES:
    $(basename "$0")                    # Run all tests
    $(basename "$0") argocd wiz         # Run specific test suites
    $(basename "$0") -v all             # Run all tests with verbose output

ENVIRONMENT VARIABLES:
    ARGOCD_NAMESPACE      ArgoCD namespace (default: argocd)
    WIZ_NAMESPACE         Wiz namespace (default: wiz)
    REACT2SHELL_NAMESPACE App namespace (default: react2shell)
    VERBOSE               Enable verbose output (default: false)

EXIT CODES:
    0   All tests passed
    1   One or more tests failed
    2   Invalid arguments
EOF
}

# -----------------------------------------------------------------------------
# Helper Functions
# -----------------------------------------------------------------------------
list_suites() {
  echo "Available test suites:"
  echo "  network-policy  - Tests for NetworkPolicy enforcement"
  echo "  argocd          - Tests for ArgoCD deployment"
  echo "  wiz             - Tests for Wiz integration"
  echo "  app             - Tests for app accessibility and IRSA"
  echo "  s3              - Tests for S3 bucket config and sensitive data"
  echo "  wiz-defend      - Tests for Wiz Defend logging infrastructure"
  echo ""
  echo "Use 'all' to run all test suites"
}

setup_environment() {
  echo -e "${BOLD}Setting up test environment...${NC}"

  # Check kubectl is available
  if ! command -v kubectl &>/dev/null; then
    echo -e "${RED}Error: kubectl not found in PATH${NC}"
    exit 2
  fi

  # Check cluster connectivity
  if ! kubectl cluster-info &>/dev/null; then
    echo -e "${RED}Error: Cannot connect to Kubernetes cluster${NC}"
    echo "Please ensure your kubeconfig is set correctly"
    exit 2
  fi

  local cluster_info
  cluster_info=$(kubectl config current-context 2>/dev/null || echo "unknown")
  echo -e "${BLUE}Connected to cluster: ${cluster_info}${NC}"
  echo ""
}

run_test_suite() {
  local suite="$1"
  local script=""
  local exit_code=0

  case "$suite" in
  network-policy)
    script="$SCRIPT_DIR/test_network_policy.sh"
    ;;
  argocd)
    script="$SCRIPT_DIR/test_argocd.sh"
    ;;
  wiz)
    script="$SCRIPT_DIR/test_wiz_integration.sh"
    ;;
  app)
    script="$SCRIPT_DIR/test_app_access.sh"
    ;;
  s3)
    script="$SCRIPT_DIR/test_s3_bucket.sh"
    ;;
  wiz-defend)
    script="$SCRIPT_DIR/test_wiz_defend_logging.sh"
    ;;
  *)
    echo -e "${RED}Unknown test suite: $suite${NC}"
    return 2
    ;;
  esac

  if [[ ! -x "$script" ]]; then
    echo -e "${RED}Test script not executable: $script${NC}"
    return 2
  fi

  # Run the test script
  if "$script"; then
    return 0
  else
    return 1
  fi
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------
main() {
  local total_passed=0
  local total_failed=0
  local suites_run=0

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
    -h | --help)
      usage
      exit 0
      ;;
    -v | --verbose)
      VERBOSE=true
      export VERBOSE
      shift
      ;;
    -l | --list)
      list_suites
      exit 0
      ;;
    all)
      TESTS_TO_RUN=(network-policy argocd wiz app s3 wiz-defend)
      shift
      ;;
    network-policy | argocd | wiz | app | s3 | wiz-defend)
      TESTS_TO_RUN+=("$1")
      shift
      ;;
    *)
      echo -e "${RED}Unknown option: $1${NC}"
      usage
      exit 2
      ;;
    esac
  done

  # Default to all tests if none specified
  if [[ ${#TESTS_TO_RUN[@]} -eq 0 ]]; then
    TESTS_TO_RUN=(network-policy argocd wiz app s3)
  fi

  # Header
  echo ""
  echo -e "${BOLD}=========================================="
  echo "  Infrastructure Integration Tests"
  echo "==========================================${NC}"
  echo ""

  # Setup
  setup_environment

  # Run test suites
  for suite in "${TESTS_TO_RUN[@]}"; do
    ((suites_run++))
    if run_test_suite "$suite"; then
      ((total_passed++))
    else
      ((total_failed++))
    fi
  done

  # Final summary
  echo ""
  echo -e "${BOLD}=========================================="
  echo "  Final Results"
  echo "==========================================${NC}"
  echo -e "Test Suites Run: $suites_run"
  echo -e "Suites Passed:   ${GREEN}$total_passed${NC}"
  echo -e "Suites Failed:   ${RED}$total_failed${NC}"
  echo ""

  if [[ $total_failed -gt 0 ]]; then
    echo -e "${RED}${BOLD}OVERALL: FAILED${NC}"
    exit 1
  else
    echo -e "${GREEN}${BOLD}OVERALL: PASSED${NC}"
    exit 0
  fi
}

main "$@"
