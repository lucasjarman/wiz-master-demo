# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with this codebase.

## Project Overview

This is a **Wiz security demo environment** showcasing the **React Server Components RCE vulnerability (React2Shell, CVE-2025-66478)** running on **AWS EKS**.

### Demo Purpose

Demonstrates Wiz platform capabilities:
- **Wiz Cloud**: Graph visualization of "Toxic Combinations" (Public Exposure + Vulnerability + Identity + Sensitive Data).
- **Wiz Defend (Sensor)**: Runtime detection of RCE behavior and lateral movement.
- **Wiz Code**: Detection of vulnerable dependencies (`next@16.0.6`) and risky IaC.

### Current Architecture (Golden State)

**Attack Path:**
`Internet (0.0.0.0/0)` → `NLB` → `EKS Service` → `Pod (RCE)` → `Service Account (IRSA)` → `IAM Role` → `S3 Bucket (Private)`

| Component | Configuration | Status |
|-----------|---------------|--------|
| **Cluster** | EKS 1.32 (`wiz-rsc-demo-eks-...`) | ✅ Active |
| **Workload** | Next.js 16.0.6 (Vulnerable) | ✅ Running |
| **Exposure** | Public NLB (`0.0.0.0/0`) | ✅ High Exposure |
| **Identity** | **IRSA** (IAM Roles for Service Accounts) | ✅ Linked |
| **Role** | `wiz-rsc-sa-role-...` | ✅ Admin + Inline `s3:*` |
| **Data** | S3 Bucket (Private, Sensitive Data) | ✅ Locked Down |

## Key Technical Details

### 1. Identity & Permissions (IRSA)
- **Service Account:** `wiz-rsc-sa` (Namespace: `wiz-demo`)
- **IAM Role:** `wiz-rsc-sa-role-wiz-2bb14abd`
- **Trust Policy:** Standard OIDC trust with strict conditions:
  - `sub`: `system:serviceaccount:wiz-demo:wiz-rsc-sa`
  - `aud`: `sts.amazonaws.com` (Critical for Wiz Graph validation)
- **Permissions:** Single **Inline Policy** (`wiz-demo-s3-full-access`) granting `s3:*` on `*`.
  - *Note:* Managed policies (`AdministratorAccess`) were removed to ensure clean graph edges.

### 2. Sensitive Data (S3)
- **Bucket:** `wiz-demo-sensitive-data-...-v2`
- **Access:** **PRIVATE**. Public Access Block is ENABLED.
- **Content:** Fake PII (SSNs, Credit Cards), API Keys, Medical Records.
- **Why Private?** To force Wiz Graph to calculate access *exclusively* via the IAM Role, ensuring the "Toxic Combination" alert fires (instead of a generic "Public Bucket" alert).

### 3. Vulnerability (React2Shell)
- **CVE:** CVE-2025-66478
- **Packages:** `next: 16.0.6`, `react: 19.2.0`
- **Exploit:** Deserialization RCE via `Next-Action` header.

## Directory Structure

```
app/nextjs/           # Vulnerable Application
infra/aws/            # Terraform (EKS, IAM, S3, VPC)
  ├── main.tf         # S3, VPC, Logging
  ├── eks.tf          # EKS Cluster, IRSA Role, Inline Policy
infra/k8s/            # Kubernetes Manifests
  ├── deployment.yaml # App Deployment (uses ServiceAccount)
  ├── service.yaml    # Service (LoadBalancer)
  ├── deploy.sh       # Build & Deploy script
wiz-demo-v2.sh        # Attack Scenario Script (The "Red Button")
```

## Key Commands

### Deployment (Clean Reset)
To rebuild the app and restart pods (wiping any runtime taint):
```bash
# Full Rebuild & Deploy
cd infra/k8s && ./deploy.sh

# Quick Pod Restart (Wipes /tmp files)
kubectl rollout restart deployment wiz-rsc-demo -n wiz-demo
```

To rotate to a **brand new EKS cluster identity** (new cluster name/ARN) while keeping the base environment (VPC/S3/etc.):
```bash
./Commands/rotate-eks.sh
cd infra/k8s && ./deploy.sh
```

Check whether Wiz Helm variables are present (without printing secrets):
```bash
./Commands/check-wiz-vars.sh
```

### Attack Demo
Executes the full exploit chain:
```bash
# Usage: ./wiz-demo-v2.sh <NLB_DNS> <PORT>
./wiz-demo-v2.sh $(kubectl get svc wiz-rsc-demo -n wiz-demo -o jsonpath='{.status.loadBalancer.ingress[0].hostname}') 80
```

### Verification
Check S3 access from within the pod (via IRSA):
```bash
kubectl exec -n wiz-demo -it deploy/wiz-rsc-demo -- aws s3 ls s3://$(cd infra/aws && terraform output -raw s3_bucket_name)
```

## Terraform Management

```bash
cd infra/aws
terraform apply -var "aws_profile=wiz-demo"
```
*Note: Legacy EC2 resources have been removed. The environment is EKS-only.*

## Security Warning

> **DO NOT DEPLOY TO PRODUCTION**
>
> This repository contains intentionally vulnerable code (`next@16.0.6`) and over-permissive IAM roles (`s3:*`).
