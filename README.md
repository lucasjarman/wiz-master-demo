# Wiz React2Shell Demo

A deliberately vulnerable Next.js application demonstrating **CVE-2025-66478** - React Server Components Remote Code Execution.

## ⚠️ Security Warning

> **DO NOT DEPLOY TO PRODUCTION**
> 
> This repository contains intentionally vulnerable code for security demonstration purposes only.

## Vulnerability Details

| Component | Version | CVE |
|-----------|---------|-----|
| Next.js | 16.0.6 | CVE-2025-66478 |
| React | 19.2.0 | - |

This version of Next.js contains a critical vulnerability in how React Server Components deserialize flight data, allowing Remote Code Execution.

### Built From Template

This app was scaffolded using the official `create-next-app` template:

```bash
npx create-next-app@16.0.6 app/nextjs --typescript --tailwind --eslint --app --src-dir
```

The template itself is vulnerable out-of-the-box—no additional exploit code was added.

## Project Structure

```
├── app/nextjs/          # Vulnerable Next.js application
│   ├── src/app/         # App router pages
│   ├── Dockerfile       # Container build
│   └── package.json     # Dependencies (pinned to vulnerable versions)
├── infra/aws/           # Terraform infrastructure
│   ├── main.tf          # VPC, EKS, S3, ECR
│   └── variables.tf     # Configuration
└── infra/k8s/           # Kubernetes manifests (TODO)
```

## Quick Start

### Local Development

```bash
cd app/nextjs
npm install
npm run dev
```

### Docker

```bash
cd app/nextjs
docker build -t wiz-rsc-demo:latest .
docker run --rm -p 3000:3000 wiz-rsc-demo:latest
```

Access at: http://localhost:3000

## Demo Purpose

This environment is designed to demonstrate:

- **Wiz Code**: Detects vulnerable dependencies and hardcoded secrets in IaC
- **Wiz Cloud**: Discovers misconfigured S3 buckets and over-permissive IAM roles
- **Wiz Defend**: Detects runtime exploitation (RCE, file writes, AWS API calls)

## Attack Path

```
Internet → LoadBalancer → EKS Pod (RCE) → Node IAM Role → Sensitive S3 Bucket
```

## License

For educational and demonstration purposes only.
