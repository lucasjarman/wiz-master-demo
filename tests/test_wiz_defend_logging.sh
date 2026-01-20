#!/usr/bin/env bash
# tests/test_wiz_defend_logging.sh - Tests for Wiz Defend logging infrastructure

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

# Helper to run AWS commands via fnox (local credentials)
run_aws() {
    cd "${REPO_ROOT}/infrastructure/shared/aws" && \
        mise exec -- fnox run --profile dev -- aws "$@" 2>/dev/null
}

# Get region from AWS config
AWS_REGION=$(run_aws configure get region 2>/dev/null || echo "ap-southeast-2")

# -----------------------------------------------------------------------------
# Test Functions
# -----------------------------------------------------------------------------

test_cloudtrail_exists() {
    info "Testing CloudTrail trail exists..."
    
    local trails
    trails=$(run_aws cloudtrail describe-trails --output json 2>/dev/null || echo '{"trailList":[]}')
    local trail_count
    trail_count=$(echo "$trails" | jq '.trailList | length' 2>/dev/null || echo "0")
    
    if [[ "$trail_count" -gt 0 ]]; then
        local trail_name
        trail_name=$(echo "$trails" | jq -r '.trailList[0].Name' 2>/dev/null)
        pass "CloudTrail trail exists: $trail_name"
        ((TEST_PASSED++))
    else
        fail "No CloudTrail trail found (required for Wiz Defend)"
        ((TEST_FAILED++))
    fi
}

test_cloudtrail_s3_data_events() {
    info "Testing CloudTrail has S3 data events enabled..."
    
    local trails
    trails=$(run_aws cloudtrail describe-trails --output json 2>/dev/null || echo '{"trailList":[]}')
    local trail_arn
    trail_arn=$(echo "$trails" | jq -r '.trailList[0].TrailARN // empty' 2>/dev/null)
    
    if [[ -z "$trail_arn" ]]; then
        warn "No CloudTrail trail - cannot check S3 data events"
        return 0
    fi
    
    local event_selectors
    event_selectors=$(run_aws cloudtrail get-event-selectors --trail-name "$trail_arn" --output json 2>/dev/null || echo '{}')
    
    if echo "$event_selectors" | grep -q "AWS::S3::Object"; then
        pass "CloudTrail has S3 data events enabled"
        ((TEST_PASSED++))
    else
        fail "CloudTrail does not have S3 data events (required for Wiz Defend)"
        ((TEST_FAILED++))
    fi
}

test_vpc_flow_logs_enabled() {
    info "Testing VPC Flow Logs are enabled..."
    
    local flow_logs
    flow_logs=$(run_aws ec2 describe-flow-logs --output json 2>/dev/null || echo '{"FlowLogs":[]}')
    local flow_log_count
    flow_log_count=$(echo "$flow_logs" | jq '.FlowLogs | length' 2>/dev/null || echo "0")
    
    if [[ "$flow_log_count" -gt 0 ]]; then
        local destination
        destination=$(echo "$flow_logs" | jq -r '.FlowLogs[0].LogDestinationType // "unknown"' 2>/dev/null)
        pass "VPC Flow Logs enabled ($flow_log_count flow log(s), destination: $destination)"
        ((TEST_PASSED++))
    else
        fail "No VPC Flow Logs found (required for Wiz Defend)"
        ((TEST_FAILED++))
    fi
}

test_eks_audit_logs_enabled() {
    info "Testing EKS audit logs are enabled..."
    
    local cluster_name
    cluster_name=$(run_aws eks list-clusters --output json 2>/dev/null | jq -r '.clusters[0] // empty')
    
    if [[ -z "$cluster_name" ]]; then
        warn "No EKS cluster found"
        return 0
    fi
    
    local cluster_info
    cluster_info=$(run_aws eks describe-cluster --name "$cluster_name" --output json 2>/dev/null || echo '{}')
    
    local audit_enabled
    audit_enabled=$(echo "$cluster_info" | jq -r '.cluster.logging.clusterLogging[] | select(.types[] == "audit") | .enabled' 2>/dev/null || echo "false")
    
    if [[ "$audit_enabled" == "true" ]]; then
        pass "EKS audit logs are enabled for cluster: $cluster_name"
        ((TEST_PASSED++))
    else
        fail "EKS audit logs not enabled for cluster: $cluster_name"
        ((TEST_FAILED++))
    fi
}

test_route53_dns_logs() {
    info "Testing Route53 DNS query logging..."
    
    # Check for query logging configs
    local query_logs
    query_logs=$(run_aws route53resolver list-resolver-query-log-configs --output json 2>/dev/null || echo '{"ResolverQueryLogConfigs":[]}')
    local config_count
    config_count=$(echo "$query_logs" | jq '.ResolverQueryLogConfigs | length' 2>/dev/null || echo "0")
    
    if [[ "$config_count" -gt 0 ]]; then
        pass "Route53 DNS query logging enabled ($config_count config(s))"
        ((TEST_PASSED++))
    else
        warn "No Route53 DNS query logging configs found (optional for Wiz Defend)"
    fi
}

test_sns_topics_exist() {
    info "Testing SNS topics for log fanout..."

    local topics
    topics=$(run_aws sns list-topics --output json 2>/dev/null || echo '{"Topics":[]}')

    local cloudtrail_topic
    cloudtrail_topic=$(echo "$topics" | jq -r '.Topics[].TopicArn | select(. | contains("cloudtrail"))' 2>/dev/null || echo "")
    local flowlogs_topic
    flowlogs_topic=$(echo "$topics" | jq -r '.Topics[].TopicArn | select(. | contains("flow-logs"))' 2>/dev/null || echo "")

    if [[ -n "$cloudtrail_topic" || -n "$flowlogs_topic" ]]; then
        pass "SNS topics found for log fanout"
        ((TEST_PASSED++))
    else
        fail "No SNS topics for CloudTrail/FlowLogs (required for Wiz Defend ingestion)"
        ((TEST_FAILED++))
    fi
}

test_s3_access_logging_enabled() {
    info "Testing S3 access logging is enabled..."

    # Check for access logs bucket
    local access_logs_bucket
    access_logs_bucket=$(run_aws s3api list-buckets --output json 2>/dev/null | jq -r '.Buckets[].Name | select(. | contains("access-logs"))' 2>/dev/null | head -1)

    if [[ -n "$access_logs_bucket" ]]; then
        pass "S3 access logs bucket exists: $access_logs_bucket"
        ((TEST_PASSED++))

        # Check if CloudTrail bucket has logging enabled
        local cloudtrail_bucket
        cloudtrail_bucket=$(run_aws s3api list-buckets --output json 2>/dev/null | jq -r '.Buckets[].Name | select(. | contains("cloudtrail") and (. | contains("access-logs") | not))' 2>/dev/null | head -1)

        if [[ -n "$cloudtrail_bucket" ]]; then
            local logging_config
            logging_config=$(run_aws s3api get-bucket-logging --bucket "$cloudtrail_bucket" --output json 2>/dev/null || echo '{}')

            if echo "$logging_config" | jq -e '.LoggingEnabled' >/dev/null 2>&1; then
                pass "S3 access logging enabled on CloudTrail bucket"
                ((TEST_PASSED++))
            else
                fail "S3 access logging not enabled on CloudTrail bucket"
                ((TEST_FAILED++))
            fi
        fi
    else
        fail "S3 access logs bucket not found"
        ((TEST_FAILED++))
    fi
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------
main() {
    echo ""
    echo "=========================================="
    echo "  Wiz Defend Logging Tests"
    echo "=========================================="
    echo ""

    test_cloudtrail_exists || true
    test_cloudtrail_s3_data_events || true
    test_vpc_flow_logs_enabled || true
    test_eks_audit_logs_enabled || true
    test_route53_dns_logs || true
    test_sns_topics_exist || true
    test_s3_access_logging_enabled || true

    print_summary
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
    exit $?
fi

