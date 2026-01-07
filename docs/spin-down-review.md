# EKS Spin-Down Review

Review of `docs/eks-spin-down.md` runbook and supporting infrastructure.

## Verdict

**The spin-down plan will work** as long as you use `./Commands/cold-stop.sh` (or manually detach Terraform-managed Kubernetes/Helm resources from state first). The restoration process is also sound.

## What Works

- `enable_eks=false` properly gates all EKS resources (cluster, nodes, IRSA, NAT gateway, private subnets)
- Base infrastructure preserved (VPC, S3, CloudTrail, ECR)
- LoadBalancer cleanup is correctly documented before EKS teardown
- `up.sh` restores everything cleanly

## Potential Issue

**Provider configuration in `infra/aws/wiz-sensor.tf` (now fixed)**

The Kubernetes/Helm providers previously referenced `module.eks[0]`, which is invalid when `enable_eks=false`. This would prevent `terraform apply -var='enable_eks=false'` (cold stop) from running.

**Fix:** `infra/aws/wiz-sensor.tf` now wraps EKS-derived provider values with `try()` and uses safe placeholders when EKS is disabled, so cold stop can proceed.

## Important Behavior (Cold Stop)

Even with the provider indexing fixed, **cold stop can still fail** if Terraform tries to refresh/destroy Kubernetes resources that are currently in state while the cluster is being deleted (the Kubernetes provider can’t authenticate/reach the API server once EKS is down).

**Fix (implemented):** `./Commands/cold-stop.sh` now removes the Terraform-managed Kubernetes/Helm resources from state before applying `enable_eks=false`. This prevents provider refresh errors and lets the EKS teardown complete.

## Pre-Spin-Down Checklist

1. (Optional) Run `terraform -chdir=infra/aws plan -var='enable_eks=false'` to verify the change set
2. Delete the LoadBalancer Service (runbook step 3)
3. Run `./Commands/cold-stop.sh` (recommended; includes required state detach)

## Restoration

```bash
./Commands/up.sh
```

Then update kubeconfig and redeploy the app as documented.
