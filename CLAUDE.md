# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with this codebase.

## Project Overview

This is a **Wiz security demo environment** showcasing the React Server Components RCE vulnerability (React2Shell, CVE-2025-66478). The demo runs on AWS EKS with Terraform IaC.

### Demo Purpose

Demonstrates Wiz platform capabilities:
- **Wiz Code**: IDE & repo scanning for vulnerable packages and risky IaC
- **Wiz Cloud**: Agentless CNAPP-style discovery and graph visualization
- **Wiz Defend / Wiz Sensor**: Runtime detection of RCE behavior
- **Wiz CLI**: Code-to-cloud context and CI scanning

### Attack Path Narrative

```
Internet → LoadBalancer → EKS Pod (RCE via RSC) → Node IAM Role → Sensitive S3 Bucket
```

## Repository Structure

```
app/nextjs/           # Vulnerable Next.js 16.0.6 application (React 19.2.0)
infra/aws/            # Terraform: VPC, EKS, S3, ECR, IAM
infra/k8s/            # Kubernetes manifests (TODO)
ci/                   # CI pipelines (TODO)
docs/                 # Documentation (TODO)
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
terraform apply
terraform destroy
```

## Key Technical Details

### Vulnerable Versions (Intentional)

| Package | Version | Notes |
|---------|---------|-------|
| Next.js | 16.0.6 | CVE-2025-66478 - RSC deserialization RCE |
| React | 19.2.0 | Paired with vulnerable Next.js |

### Infrastructure Design

- **No IRSA**: Pods inherit permissions from EKS node IAM role (intentionally over-permissive)
- **No TLS/ALB Ingress**: Simple Kubernetes LoadBalancer service (HTTP only)
- **Public S3 bucket**: Contains fake sensitive data (`employees.json`, `salaries.csv`, etc.)

### App Routes (Target Design)

- `/` – Landing page
- `/status` – Shows hostname and banner (reads `/tmp/banner.json` if present)
- `/data` – Reads fake sensitive data from S3

### RCE Demo Capabilities

When exploited, the app should allow:
1. Recon commands: `whoami`, `id`, `uname -a`, `cat /etc/passwd`
2. File writes: `/tmp/pwned.txt`, `/tmp/banner.json`
3. AWS access: `aws s3 ls`, `aws s3 cp` using node IAM role

## Working Style Rules

1. **One major thing at a time** – Focus on the current task only
2. **Keep complexity low** – Prefer simple, readable Terraform and YAML
3. **No real secrets** – Use fake/demo data only
4. **Full-file outputs** – Show complete files, not diffs
5. **Be explicit about assumptions** – Document version choices
6. **Respect user pace** – Don't ask "Ready for the next step?" – wait for explicit requests

## Current State

- ✅ Next.js app scaffolded with vulnerable versions
- ✅ Basic Terraform structure for AWS infra
- ⏳ Kubernetes manifests (TODO)
- ⏳ S3 bucket with fake sensitive data (TODO)
- ⏳ Full RCE exploit endpoint (TODO)
- ⏳ `/status` and `/data` routes (TODO)

## Security Warning

> **DO NOT DEPLOY TO PRODUCTION**
> 
> This repository contains intentionally vulnerable code for security demonstration purposes only.
