# Cost Control Runbook (AWS demo)

This repo uses Terraform with a remote S3 state backend. The environment’s names are derived from a `random_id` suffix stored in Terraform state, so avoid full `terraform destroy` if you want stable names/IDs across cycles.

## Prereqs

- `terraform` (run from `infra/aws`)
- `aws` CLI configured with profile `wiz-demo`
- `jq` (used by optional “deep stop” script)

## Two supported “down” modes

### 1) Cold stop (recommended default)

This deletes the EKS cluster (control plane + nodes) and removes NAT/private subnets from the VPC module (because they’re gated on `enable_eks`). It keeps the rest of the demo (S3 buckets, CloudTrail, VPC, etc.).

- Down: `./Commands/cold-stop.sh`
- Up: `./Commands/up.sh`

### 2) Deep stop (maximum savings)

Do **cold stop** first, then also pause the non-EKS log sources that can generate ongoing spend:

- Stop CloudTrail logging
- Delete VPC Flow Logs
- Disassociate Route 53 Resolver query logging from the VPC

Terraform will recreate/re-enable these on the next `./Commands/up.sh` (you’ll see the changes in the plan).

- Deep stop: `./Commands/deep-stop.sh`

## Rotate EKS (new cluster identity)

If you want a **fresh EKS cluster** (new cluster name/ARN) without recreating the base environment (VPC/S3/etc.), rotate the EKS suffix:

- Rotate: `./Commands/rotate-eks.sh`
- Redeploy app: `cd infra/k8s && ./deploy.sh`
- Check Wiz vars: `./Commands/check-wiz-vars.sh`

By default the rotate script deletes the demo app `LoadBalancer` service (`wiz-demo/wiz-rsc-demo`) on the old cluster first so the AWS NLB is cleaned up before the cluster is replaced.

## What still costs money when “down”

Even with cold stop, you still pay for:

- S3 storage (buckets + objects)
- CloudTrail / Route 53 resolver logs / VPC flow logs (unless you deep stop)
- Any remaining AWS resources not gated on `enable_eks`

## Notes on EKS logging volume

When you run `./Commands/up.sh`, it disables EKS control-plane log export by default and sets short retention on the log group (if present). You can override behavior via env vars described at the top of the scripts.
