#!/bin/bash
# Common test utilities for infrastructure tests
# Source this file in test scripts: source "$(dirname "$0")/lib/common.sh"

set -euo pipefail

# -----------------------------------------------------------------------------
# Color Output Functions
# -----------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

fail() {
    echo -e "${RED}[FAIL]${NC} $1"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# -----------------------------------------------------------------------------
# Test Assertion Functions
# -----------------------------------------------------------------------------
TEST_PASSED=0
TEST_FAILED=0

# Assert that a command succeeds
# Usage: assert_success "description" command args...
assert_success() {
    local description="$1"
    shift
    if "$@" &>/dev/null; then
        pass "$description"
        ((TEST_PASSED++))
        return 0
    else
        fail "$description"
        ((TEST_FAILED++))
        return 1
    fi
}

# Assert that a command fails
# Usage: assert_failure "description" command args...
assert_failure() {
    local description="$1"
    shift
    if ! "$@" &>/dev/null; then
        pass "$description"
        ((TEST_PASSED++))
        return 0
    else
        fail "$description"
        ((TEST_FAILED++))
        return 1
    fi
}

# Assert that output contains expected string
# Usage: assert_contains "description" "expected" "actual"
assert_contains() {
    local description="$1"
    local expected="$2"
    local actual="$3"
    if [[ "$actual" == *"$expected"* ]]; then
        pass "$description"
        ((TEST_PASSED++))
        return 0
    else
        fail "$description (expected '$expected' in output)"
        ((TEST_FAILED++))
        return 1
    fi
}

# Assert that a value equals expected
# Usage: assert_equals "description" "expected" "actual"
assert_equals() {
    local description="$1"
    local expected="$2"
    local actual="$3"
    if [[ "$actual" == "$expected" ]]; then
        pass "$description"
        ((TEST_PASSED++))
        return 0
    else
        fail "$description (expected '$expected', got '$actual')"
        ((TEST_FAILED++))
        return 1
    fi
}

# Assert that a value is not empty
# Usage: assert_not_empty "description" "value"
assert_not_empty() {
    local description="$1"
    local value="$2"
    if [[ -n "$value" ]]; then
        pass "$description"
        ((TEST_PASSED++))
        return 0
    else
        fail "$description (value was empty)"
        ((TEST_FAILED++))
        return 1
    fi
}

# -----------------------------------------------------------------------------
# Kubectl Wrapper with Error Handling
# -----------------------------------------------------------------------------
# Kubectl wrapper that provides better error messages
# Usage: kube_get resource [namespace] [name]
kube_get() {
    local resource="$1"
    local namespace="${2:-}"
    local name="${3:-}"
    
    local cmd="kubectl get $resource"
    [[ -n "$namespace" ]] && cmd="$cmd -n $namespace"
    [[ -n "$name" ]] && cmd="$cmd $name"
    
    if ! eval "$cmd" 2>/dev/null; then
        return 1
    fi
}

# Check if a namespace exists
# Usage: namespace_exists "namespace-name"
namespace_exists() {
    kubectl get namespace "$1" &>/dev/null
}

# Check if pods are running in a namespace
# Usage: pods_running "namespace" ["label-selector"]
pods_running() {
    local namespace="$1"
    local selector="${2:-}"
    
    local cmd="kubectl get pods -n $namespace -o jsonpath='{.items[*].status.phase}'"
    [[ -n "$selector" ]] && cmd="kubectl get pods -n $namespace -l $selector -o jsonpath='{.items[*].status.phase}'"
    
    local phases
    phases=$(eval "$cmd" 2>/dev/null) || return 1
    
    # Check all pods are Running
    for phase in $phases; do
        [[ "$phase" != "Running" ]] && return 1
    done
    [[ -n "$phases" ]] || return 1
    return 0
}

# Print test summary
print_summary() {
    echo ""
    echo "=========================================="
    echo -e "Test Summary: ${GREEN}$TEST_PASSED passed${NC}, ${RED}$TEST_FAILED failed${NC}"
    echo "=========================================="
    
    if [[ $TEST_FAILED -gt 0 ]]; then
        return 1
    fi
    return 0
}

