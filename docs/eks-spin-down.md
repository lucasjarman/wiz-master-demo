# EKS Spin-Down Runbook (Cold Stop / Deep Stop)

This repo supports “spin down” (cost control) without destroying the entire demo. The recommended approach is **Cold Stop**, which **deletes the EKS cluster + node group** and removes EKS-specific VPC components, while keeping the rest of the demo (S3 buckets, CloudTrail, etc.).

This document is written to be easy for humans *and* LLMs to reason about (inputs, steps, expected outcomes, verification).

## Key Context (Inputs)

**Defaults used by this repo**

- AWS profile: `wiz-demo`
  - Terraform backend (`infra/aws/backend.tf`) is pinned to `profile = "wiz-demo"`.
  - Terraform AWS provider defaults to `aws_profile = "wiz-demo"` via `infra/aws/terraform.tfvars`.
- AWS region: `ap-southeast-2` (via `infra/aws/terraform.tfvars`)
- Terraform directory: `infra/aws`
- EKS cluster name is derived from Terraform output `eks_cluster_name`.
- Demo Kubernetes identifiers are derived from Terraform outputs:
  - Namespace: `app_namespace`
  - Service/Deployment base name: `app_workload_name`

**Kubernetes auth model**

- `kubectl` access is typically configured via:
  - `aws eks update-kubeconfig --profile wiz-demo --region ap-southeast-2 --name <eks_cluster_name>`
- After a cold stop, any existing kubeconfig context pointing at the deleted cluster will remain in your local config, but requests will fail (cluster no longer exists).

## What “Cold Stop” Does (Mechanics)

Cold stop is implemented as:

- `terraform -chdir=infra/aws apply -var='enable_eks=false'`

At a high level, that:

- Destroys the EKS control plane and managed node group (because the EKS module is gated on `var.enable_eks`).
- Removes EKS-only VPC components (NAT gateway + private subnets) because they are also gated on `var.enable_eks`.
- Leaves non-EKS demo resources in place (S3 buckets, CloudTrail, etc.).

## Why Delete The LoadBalancer Service First

The demo app Service is `type: LoadBalancer`, which creates an AWS Network Load Balancer (NLB).

If you destroy the EKS cluster **before** deleting that Service, Kubernetes cannot clean up the NLB, and you may leave an orphaned (billable) load balancer behind.

## Step-by-Step: Spin Down Safely (Recommended)

### 0) Sanity check you’re in the right AWS account

```bash
aws sts get-caller-identity --profile wiz-demo
```

### 1) Read Terraform outputs (source of truth for names)

Run from repo root:

```bash
CLUSTER_NAME="$(terraform -chdir=infra/aws output -raw eks_cluster_name)"
APP_NS="$(terraform -chdir=infra/aws output -raw app_namespace)"
APP_SVC="$(terraform -chdir=infra/aws output -raw app_workload_name)"

echo "CLUSTER_NAME=${CLUSTER_NAME}"
echo "APP_NS=${APP_NS}"
echo "APP_SVC=${APP_SVC}"
```

Expected (example):

- `eks_cluster_name`: `wiz-rsc-demo-eks-<suffix>`
- `app_namespace`: `wiz-demo-<suffix>`
- `app_workload_name`: `wiz-rsc-demo-<suffix>`

### 2) Ensure your kubectl context points at the demo cluster

```bash
aws eks update-kubeconfig --profile wiz-demo --region ap-southeast-2 --name "${CLUSTER_NAME}"
kubectl config current-context
```

### 3) Delete the demo LoadBalancer Service (to clean up the NLB)

```bash
kubectl delete svc "$APP_SVC" -n "$APP_NS" --ignore-not-found
kubectl wait --for=delete "svc/$APP_SVC" -n "$APP_NS" --timeout=120s || true
```

Optional verification (Service should be gone):

```bash
kubectl get svc "$APP_SVC" -n "$APP_NS"
```

### 4) Run Cold Stop (delete EKS)

Use the helper script:

```bash
./Commands/cold-stop.sh
```

Note: `cold-stop.sh` detaches Terraform-managed Kubernetes/Helm resources from state before disabling EKS. This avoids Kubernetes provider refresh errors during teardown.

If you want to preview the Terraform diff *without* touching state, use:

```bash
terraform -chdir=infra/aws plan -var='enable_eks=false' -refresh=false
```

Non-interactive:

```bash
AUTO_APPROVE=1 ./Commands/cold-stop.sh
```

### 5) Verify EKS is down

```bash
aws eks list-clusters --profile wiz-demo --region ap-southeast-2
```

You should no longer see the demo cluster in the list.

If you want to be strict:

```bash
aws eks describe-cluster --profile wiz-demo --region ap-southeast-2 --name "${CLUSTER_NAME}"
```

Expected: an error like “ResourceNotFoundException” (because the cluster was deleted).

## Optional: Deep Stop (Maximum Cost Reduction)

Deep stop is for when you want to reduce spend from log sources too (CloudTrail, VPC flow logs, Route 53 resolver query logging). It intentionally makes AWS-side changes that Terraform will recreate when you bring the environment back up.

Run order:

1. `./Commands/cold-stop.sh`
2. `./Commands/deep-stop.sh`

## Bringing EKS Back Up

To recreate EKS and re-enable the demo:

```bash
./Commands/up.sh
```

Then set kubeconfig again:

```bash
aws eks update-kubeconfig --profile wiz-demo --region ap-southeast-2 --name "$(terraform -chdir=infra/aws output -raw eks_cluster_name)"
```

## Troubleshooting Notes (Common Failure Modes)

- **Terraform init fails (remote state backend):** confirm the `wiz-demo` AWS profile exists locally and has access to the S3 backend bucket/DynamoDB lock table.
- **LoadBalancer Service delete hangs:** check for finalizers on the Service; if you already deleted the cluster, you may need to manually delete the orphaned NLB in AWS.
- **kubectl can’t reach the cluster:** re-run `aws eks update-kubeconfig ...` and confirm you’re using the expected context with `kubectl config current-context`.

## LLM Audit Checklist (Reasoning Aids)

- Inputs are explicit (`AWS_PROFILE`, `AWS_REGION`, `TF_DIR`, cluster/name outputs).
- All Kubernetes deletions happen **before** EKS deletion (prevents orphaned NLB).
- Terraform action is narrowly scoped (`enable_eks=false`), not a full destroy.
- Verification steps are included (AWS CLI + kubectl checks).
