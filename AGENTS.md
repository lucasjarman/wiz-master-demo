# Agent Instructions (Codex / Claude / Gemini)

> Canonical instructions live in `AGENTS.md`. This repo also keeps `CLAUDE.md` aligned for other CLIs that auto-load those files.

---

## ⚠️ ACTIVE REFACTOR - READ THIS FIRST

**A refactor is in progress.** See `docs/REFACTOR_PROPOSAL.md` for full details.

### Current Status: ✅ REFACTOR COMPLETE

**All tasks completed:**
- [x] 1.1 Deleted `infra/` directory (legacy terraform + state files)
- [x] 1.2 Deleted `Commands/` directory (replaced by mise tasks)
- [x] 1.3 Deleted sensitive files (.pem, .zip, .pdf, kubeconfig)
- [x] 1.4 Deleted unused root files (defend.md, values.yaml, Support/, ci/, wizcli/)
- [x] 1.5 Moved exploit scripts to `scripts/exploit/`
- [x] 1.6 Cleaned outdated docs (kept only REFACTOR_PROPOSAL.md)
- [x] 2.1 Added `modules/azure/` and `modules/gcp/` placeholders
- [x] 2.2 Updated `.gitignore` for sensitive files
- [x] 3.1 Added `common.auto.tfvars` files to terraform directories
- [x] 3.2 Enhanced `mise.local.toml.template` with network/scenario config
- [x] 4.1 Added `mise run test` task
- [x] 4.2 Added `mise run init-scenarios` task

**Reference repo:** `~/Code/wiz-demo-infra` (source of truth for patterns)

---

## Project Overview

This is a **Wiz security demo environment** showcasing the **React Server Components RCE vulnerability (React2Shell, CVE-2025-66478)** running on **AWS EKS**.

**DO NOT DEPLOY TO PRODUCTION.** The app and infrastructure are intentionally insecure for demonstration purposes.

### Demo Purpose

Demonstrates Wiz platform capabilities:
- **Wiz Cloud**: Graph visualization of "Toxic Combinations" (Public Exposure + Vulnerability + Identity + Sensitive Data).
- **Wiz Defend (Sensor)**: Runtime detection of RCE behavior and lateral movement.
- **Wiz Code**: Detection of vulnerable dependencies and risky IaC.

### Current Architecture (Golden State)

**Attack Path:**
`Internet (0.0.0.0/0)` → `NLB` → `EKS Service` → `Pod (RCE)` → `Service Account (IRSA)` → `IAM Role` → `S3 Bucket (Private)`

## Repository Structure

```
.
├── mise.toml                    # Tool version management (terraform, tflint, fnox, etc.)
├── .pre-commit-config.yaml      # Pre-commit hooks for validation
├── .terraform-docs.yml          # Terraform docs generation config
├── templates/
│   ├── mise.local.toml.template # Local environment config template
│   └── fnox.toml.template       # 1Password secrets template
├── infrastructure/
│   ├── backend-config.json      # State backend configuration (auto-generated)
│   ├── backends/                # Bootstrap terraform for S3 state bucket
│   ├── shared/aws/              # Shared infrastructure (VPC, EKS)
│   └── wiz/develop/             # Wiz tenant configuration (connectors, sensors)
├── scenarios/
│   └── react2shell/aws/         # React2Shell demo scenario
├── modules/
│   ├── aws/
│   │   ├── aws-cloud-events/    # CloudTrail → SQS for Wiz Defend
│   │   └── wiz-defend-logging/  # Route53 DNS logs for Wiz Defend
│   ├── k8s-services/            # ArgoCD + Wiz K8s integration module
│   ├── azure/                   # (TODO) Azure modules
│   └── gcp/                     # (TODO) GCP modules
├── app/nextjs/                  # Vulnerable Next.js application
├── scripts/exploit/             # (TODO) Demo exploit scripts
└── tests/                       # Infrastructure validation tests
```

## Development Setup

### Prerequisites
- [mise](https://mise.jdx.dev/) - Polyglot runtime manager
- [1Password CLI](https://developer.1password.com/docs/cli/) - Secrets management
- AWS credentials with appropriate permissions

### Quick Start

```bash
# 1. Trust and install mise tools
mise trust
mise install

# 2. Setup local configuration
cp templates/mise.local.toml.template mise.local.toml
cp templates/fnox.toml.template fnox.toml
# Edit fnox.toml to point to your 1Password items

# 3. Install pre-commit hooks
pre-commit install

# 4. Bootstrap the backend (creates S3 state bucket)
mise run bootstrap-branch --directories infrastructure/shared/aws,scenarios/react2shell/aws,infrastructure/wiz/develop

# 5. Apply infrastructure
mise run apply-demo --path infrastructure/shared/aws
mise run apply-demo --path scenarios/react2shell/aws
mise run apply-demo --path infrastructure/wiz/develop
```

## Key Technical Details

### 1) AWS Authentication

**Two options for AWS credentials:**

**Option A: AWS Profile (Simple)**
- Configure `~/.aws/credentials` with a named profile (e.g., `wiz-demo`)
- Terraform providers use `profile = var.aws_profile` (default: `wiz-demo`)
- Run: `terraform apply -var="aws_profile=your-profile"`

**Option B: fnox + 1Password (Recommended for teams)**
- Configure `fnox.toml` with 1Password item mappings for `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`
- Run: `fnox run -- terraform apply`
- No profile needed in providers (uses environment variables)

### 2) Secrets Management (fnox + 1Password)

Secrets are fetched from 1Password at runtime via `fnox`. Configure `fnox.toml` with your 1Password item mappings:

```toml
[secrets]
[profiles.dev.secrets]
AWS_ACCESS_KEY_ID={provider="1pass", value="your-aws-item/username"}
AWS_SECRET_ACCESS_KEY={provider="1pass", value="your-aws-item/credential"}
WIZ_CLIENT_ID={provider="1pass", value="your-wiz-sa/username"}
WIZ_CLIENT_SECRET={provider="1pass", value="your-wiz-sa/credential"}
```

**IMPORTANT: Authenticate once per terminal session**

To avoid repeated 1Password touch prompts, export secrets to your shell once:

```bash
# Authenticate once - exports secrets to current shell
eval "$(mise run auth)"

# Now all commands work without re-prompting:
terraform plan
aws s3 ls
kubectl get pods
```

**DO NOT** wrap every command with `mise exec -- fnox run --profile dev --`. This causes a touch prompt for every single command.

### 3) State Management

State is stored in S3 with locking. `backend-config.json` is auto-generated by `mise run bootstrap-branch`.

### 4) Naming Convention

**All resources include a random suffix** to ensure no conflicts between deployments:

| Resource Type | Naming Pattern | Example |
|---------------|----------------|---------|
| EKS Cluster | `${prefix}-${suffix}-eks` | `wiz-demo-c215e2-eks` |
| ECR Repository | `${prefix}-${suffix}-app` | `wiz-demo-c215e2-app` |
| S3 Buckets | `react2shell-${suffix}-sensitive-data` | `react2shell-c215e2-sensitive-data` |
| IAM Roles | `${prefix}-${suffix}-*` | `wiz-demo-c215e2-aws-lb-controller` |
| KMS Aliases | `alias/eks/${prefix}-${suffix}-eks` | `alias/eks/wiz-demo-c215e2-eks` |

The suffix is generated by `random_id.this` in `infrastructure/demo/main.tf` and stored in terraform state.

**Why this matters:** Without the suffix, resources like ECR repositories and KMS aliases would conflict if a previous deployment wasn't fully cleaned up, blocking new deployments.

### 5) Identity & Permissions (IRSA)

Uses `terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks` with intentionally over-permissive policies.

### 6) Wiz Integration (ArgoCD)

ArgoCD + Wiz sensor/connector deployed via `modules/k8s-services/` as ArgoCD Application.

**Important: Wiz Connector Bucket Scanning**

By default, Wiz connectors only scan **public** S3 buckets. For the demo (where the sensitive data bucket is private), you must set:

```hcl
scheduled_scanning_settings = {
  enabled                         = true
  public_buckets_scanning_enabled = false  # Scan ALL buckets, not just public
}
```

This is already configured in `infrastructure/demo/main.tf`. Without this setting, the private `react2shell-<suffix>-sensitive-data` bucket won't be scanned and won't show up in Wiz's data security findings.

### 7) Vulnerability (React2Shell)

- CVE: **CVE-2025-66478**
- Packages: `next: 16.0.6`, `react: 19.2.0`
- Exploit: deserialization RCE via `Next-Action` header

### 8) Network Access & AUTO_DETECT_PUBLIC_IP

The demo app uses a NetworkPolicy that restricts ingress to specific CIDRs. To access the app from your machine, your public IP must be allowed.

**Option A: Auto-detect (Recommended)**

Set in `mise.local.toml`:
```toml
AUTO_DETECT_PUBLIC_IP="true"
```

Then run `eval "$(mise run auth)"` - this will:
1. Detect your public IP via `ifconfig.me`
2. Export `TF_VAR_allowed_cidrs='["<your-ip>/32"]'`
3. Print: `# Your public IP: x.x.x.x`

**Option B: Manual**

```bash
eval "$(mise run get-my-ip)"
# Then apply terraform to update the NetworkPolicy
```

**Option C: Direct Terraform Apply**

If you need to add your IP after deployment without using mise tasks:

```bash
# Get your public IP
MY_IP=$(curl -s ifconfig.me)
echo "Your IP: $MY_IP"

# Apply with your IP added to allowed_cidrs
cd infrastructure/demo
terraform apply -var="allowed_cidrs=[\"${MY_IP}/32\"]"
```

**Troubleshooting NLB Timeout:**
If the NLB times out, your IP is likely not in the NetworkPolicy. Check:
```bash
kubectl get networkpolicy -n react2shell -o yaml | grep -A20 "ingress:"
```

To fix, run the terraform apply with your IP as shown in Option C above.

### 9) ArgoCD Access

ArgoCD runs in **insecure mode** (HTTP, not HTTPS). To access:

```bash
# 1. Authenticate and get kubeconfig
eval "$(mise run auth)"
AWS_REGION=$(grep TF_VAR_aws_region mise.local.toml | cut -d'"' -f2)
aws eks update-kubeconfig --name wiz-demo-eks --region $AWS_REGION --kubeconfig /tmp/kubeconfig-wiz-demo
export KUBECONFIG=/tmp/kubeconfig-wiz-demo

# 2. Port-forward (use port 80, NOT 443)
kubectl port-forward svc/argocd-server -n argocd 8080:80

# 3. Open browser
# URL: http://localhost:8080
# Username: admin
# Password: (see below)
```

**Get ArgoCD password:**
```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo
```

**Note:** The ArgoCD CLI (`argocd login`) may crash the port-forward due to gRPC behavior. Use the web UI or curl with the REST API instead.

### 10) Wiz Defend Logging

Wiz Defend requires log ingestion from AWS services. The demo configures:

**Enabled Log Types:**
- **CloudTrail** (audit logs + S3 Data Events) - via `aws-cloud-events` module
- **Route53 DNS Query Logs** - via `wiz-defend-logging` module
- **VPC Flow Logs** - NOT enabled (simplified for demo)

**Architecture:**
```
CloudTrail → S3 Bucket (KMS encrypted) → SNS Topic → SQS Queue → Wiz Connector
Route53 DNS → S3 Bucket (KMS encrypted) → SNS Topic → SQS Queue → Wiz Connector
```

**Configuration in `infrastructure/demo/variables.tf`:**
```hcl
variable "enabled_logs" {
  type = object({
    cloudtrail   = bool
    route53_logs = bool
  })
  default = {
    cloudtrail   = true
    route53_logs = true
  }
}
```

**Key Resources Created:**
| Resource | Purpose |
|----------|---------|
| `aws_cloudtrail.demo` | Trail with S3 Data Event selectors |
| `aws_kms_key.cloudtrail` | KMS key for CloudTrail encryption |
| `aws_s3_bucket.cloudtrail_logs` | S3 bucket for CloudTrail logs |
| `aws_sns_topic.cloudtrail_fanout` | SNS topic for CloudTrail notifications |
| `module.aws_cloud_events` | Creates SQS queue for CloudTrail → Wiz |
| `module.wiz_defend_logs` | Route53 DNS logging (separate S3 bucket per Wiz requirement) |

**SQS Queue URL Flow:**
The SQS queue URLs are passed to the Wiz connector via:
- `cloud_trail_config.notifications_sqs_options.override_queue_url`
- `resolver_query_logs_config.notifications_sqs_options.override_queue_url`

**Important:** Route53 DNS logs **must** use a separate S3 bucket from CloudTrail (Wiz requirement).

**Outputs for Verification:**
```bash
terraform output cloudtrail_bucket_name
terraform output cloudtrail_sqs_queue_url
terraform output route53_logs_bucket_name
terraform output route53_sqs_queue_url
```

### 11) Wiz Code-to-Cloud Mapping

Wiz Code-to-Cloud has **two separate correlation paths**:

1. **IaC Mapping** - Links cloud resources (EKS, S3, IAM) to Terraform code
2. **Container Image Mapping** - Links container images to their Dockerfiles

---

#### 11a) IaC Code-to-Cloud (Terraform → Cloud Resources)

**How It Works:**
1. Wiz VCS Connector scans the repo and finds `backend.tf` files
2. Wiz Cloud Connector reads the Terraform state file from S3
3. Creates `IAC_BACKEND` → `IAC_DEPLOYMENT` → `IAC_RESOURCE` entities
4. Cloud resources show "Defined in Code" relationships

**IMPORTANT: Use Fully Defined `backend.tf`**

The `iac_config.wiz` approach (partial backends) **does not work reliably**. Instead, use fully defined `backend.tf` files with hardcoded bucket/key/region:

```hcl
# infrastructure/demo/backend.tf
terraform {
  backend "s3" {
    bucket       = "demo-dev-c1dfca-state-bucket-ap-southeast-2"  # Hardcoded
    key          = "infrastructure/demo/terraform.tfstate"         # Hardcoded
    region       = "ap-southeast-2"                                # Hardcoded
    encrypt      = true
    use_lockfile = true
  }
}
```

The `mise run init-backends` task generates these fully defined files automatically from `backend-config.json`.

**Verification:**
```bash
# Check IAC_BACKEND is not partial
# In Wiz Explorer, search for IAC_BACKEND and verify isPartial: false
```

**Troubleshooting:**
- If `IAC_BACKEND` shows `isPartial: true`, the backend.tf is missing bucket/key/region
- `IAC_DEPLOYMENT` is created when cloud scanner reads the state file (may take hours)
- Trigger VCS rescan: **Settings → Deployments → GitHub Connector → Trigger Scan**

---

#### 11b) Container Image Code-to-Cloud (Image → Dockerfile)

**Two Methods:**

| Method | How It Works | When to Use |
|--------|--------------|-------------|
| **CLI-based** | `wizcli docker scan` + `wizcli docker tag` in CI/CD | Deterministic 1:1 mapping |
| **Seamless VCS** | VCS Connector analyzes Dockerfiles automatically | Automatic but not always deterministic |

**CLI-based Workflow (Recommended):**

The scan must happen **BEFORE** pushing to registry:

```bash
# 1. Build image locally (don't push yet)
docker build -t $IMAGE_TAG -f app/nextjs/Dockerfile .

# 2. Scan BEFORE pushing (links to Dockerfile)
wizcli docker scan --image $IMAGE_TAG --dockerfile app/nextjs/Dockerfile

# 3. Push to registry
docker push $IMAGE_TAG

# 4. Tag AFTER pushing (uploads digest + metadata to Wiz)
wizcli docker tag --image $IMAGE_TAG
```

**CRITICAL: Order matters!**
- Scanning an already-pushed image does NOT establish code correlation
- The `--dockerfile` flag must point to the actual Dockerfile used to build

**Verification:**
```bash
# Check container image has code_detected = true
# In Wiz Explorer, search for the container image and check:
# - lifecycleStagesV2_code_detected: true
# - lifecycleStagesV2_build_detected: true
# - lifecycleStagesV2_store_detected: true
```

**GitHub Actions Example:**
```yaml
- name: Download Wiz CLI
  run: |
    curl -Lo wizcli https://downloads.wiz.io/v1/wizcli/latest/wizcli-linux-amd64
    chmod +x wizcli

- name: Build Docker image
  run: docker build -t $IMAGE_TAG -f app/nextjs/Dockerfile .

- name: Scan with Wiz CLI (BEFORE push)
  env:
    WIZ_CLIENT_ID: ${{ secrets.WIZ_CLIENT_ID }}
    WIZ_CLIENT_SECRET: ${{ secrets.WIZ_CLIENT_SECRET }}
  run: ./wizcli docker scan --image $IMAGE_TAG --dockerfile app/nextjs/Dockerfile

- name: Push to ECR
  run: docker push $IMAGE_TAG

- name: Tag for Code-to-Cloud (AFTER push)
  env:
    WIZ_CLIENT_ID: ${{ secrets.WIZ_CLIENT_ID }}
    WIZ_CLIENT_SECRET: ${{ secrets.WIZ_CLIENT_SECRET }}
  run: ./wizcli docker tag --image $IMAGE_TAG
```

---

**ECR Connector Error (Cosmetic):**
The ECR connector may show `CONNECTION_ERROR` but this is non-blocking. Container images are scanned via:
- AWS cloud connector (auto-connect feature)
- EKS connector (runtime detection)

### 12) Wiz Defend Demo (Attack Script)

The attack script `scripts/exploit/wiz-demo-v4.sh` creates a clean threat chain for Wiz Defend demonstration.

**Attack Chain:**
```
React2Shell (RCE) → Container Activity → Cloud Identity → S3 Exfil
```

**Usage:**
```bash
# Auto-detect S3 bucket from terraform:
./scripts/exploit/wiz-demo-v4.sh <nlb-hostname>

# With OAST/interact.sh callback:
./scripts/exploit/wiz-demo-v4.sh <nlb-hostname> --oast-domain abc123.oast.fun

# Manual bucket specification:
./scripts/exploit/wiz-demo-v4.sh <nlb-hostname> --bucket my-sensitive-bucket
```

**Expected Wiz Defend Detections:**

| Phase | Detection | Rule ID | Description |
|-------|-----------|---------|-------------|
| 1. Initial Access | Web service command | (signal) | `webServiceOrDescendantOf` context |
| 2. Container Activity | Reverse shell pattern | `cer-sen-id-458` | Bash reverse shell command line |
| 2. Container Activity | Cryptomining DNS | `cer-sen-id-10` | DNS query to mining pool |
| 2. Container Activity | Tunneling DNS | `cer-sen-id-323` | DNS query to ngrok/tunneling |
| 2. Container Activity | OAST callback | (optional) | C2 beacon if --oast-domain set |
| 2. Container Activity | Sensitive file access | `cer-sen-id-*` | K8s token, /etc/shadow |
| 2. Container Activity | Cron persistence | `cer-sen-id-6` | Crontab modification |
| 3. Cloud Identity | Unusual STS call | `cer-aws-identity-unusualGetCallerIdentity` | GetCallerIdentity from pod |
| 4. S3 Exfil | S3 Data Events | (CloudTrail) | ListBucket, GetObject (if enabled) |

**Threat Grouping:**
Wiz groups detections within 24 hours on the same entity into a single threat. The attack script should produce 1 grouped threat with multiple correlated detections.

**Verify Results:**
1. Navigate to **Defend → Threats** in Wiz Console
2. Filter by pod name (e.g., `react2shell`)
3. Expand the threat to see correlated detections
4. Check **Event Groups** tab for the attack timeline

## Mise Tasks

| Task | Description |
|------|-------------|
| `eval "$(mise run auth)"` | **Export secrets to shell** (includes public IP if `AUTO_DETECT_PUBLIC_IP=true`) |
| `mise run deploy-demo` | **One-command deploy** - bootstrap, apply, build image, verify |
| `mise run destroy-demo` | **One-command destroy** - dry-run by default, use `--no-dry-run` to execute |
| `eval "$(mise run get-my-ip)"` | Get your public IP and export `TF_VAR_allowed_cidrs` |
| `mise run bootstrap-branch` | Bootstrap S3 state backend and init terraform |
| `mise run build-image --push` | Build and push Docker image to ECR |

---

## Single-Root Module (Recommended)

The `infrastructure/demo/` directory contains a **single-root Terraform module** that deploys everything in one `terraform apply`. This is the recommended approach for demos.

### Quick Start

```bash
# 1. Authenticate (single 1Password prompt)
eval "$(mise run auth)"

# 2. Deploy everything
mise run deploy-demo

# 3. Destroy everything (when done)
mise run destroy-demo              # Dry-run (shows what would be destroyed)
mise run destroy-demo --no-dry-run # Actually destroys
```

### Why Single-Root?

The original multi-directory approach (`infrastructure/shared/aws`, `scenarios/react2shell/aws`, `infrastructure/wiz/develop`) had **cross-state dependencies** that caused:
- Ordering issues during apply/destroy
- Silent failures when dependencies weren't ready
- Manual intervention required during teardown

The single-root module eliminates these issues by managing everything in one state file with proper `depends_on` relationships.

---

## Graceful EKS Teardown (time_sleep Pattern)

The `infrastructure/demo/main.tf` uses the **`time_sleep` resource pattern** from the reference implementation to handle graceful EKS teardown.

### How It Works

```hcl
# infrastructure/demo/main.tf
resource "time_sleep" "wait_for_cluster" {
  count            = var.create_eks ? 1 : 0
  depends_on       = [module.eks]
  create_duration  = "10s"
  destroy_duration = "30s"  # Gives controllers time to clean up
}

# AWS LB Controller depends on time_sleep
resource "helm_release" "aws_load_balancer_controller" {
  depends_on = [time_sleep.wait_for_cluster, ...]
}
```

**On `terraform destroy`:**
1. Terraform destroys resources in reverse dependency order
2. App namespaces destroyed first (triggers NLB deletion)
3. AWS LB Controller destroyed (cleans up security groups)
4. `time_sleep` waits 30 seconds (`destroy_duration`)
5. EKS cluster destroyed
6. VPC destroyed (no orphaned resources blocking it)

### Why This Works

The `destroy_duration` gives the AWS Load Balancer Controller time to:
- Delete NLBs/ALBs it created
- Delete `k8s-*` prefixed security groups
- Release ENIs attached to subnets

This is the same pattern used in the reference implementation (`~/Code/wiz-demo-iac-reference/wiz-demo-infra`).

### Known Issue: Orphaned k8s-* Security Groups

**Problem:** The `time_sleep` pattern sometimes isn't enough. If the AWS Load Balancer Controller doesn't fully clean up before the EKS cluster is deleted, `k8s-*` prefixed security groups can be orphaned. These block VPC deletion with `DependencyViolation` errors.

**Symptoms:**
```
Error: deleting EC2 VPC (vpc-xxx): DependencyViolation: The vpc has dependencies and cannot be deleted.
```

**Manual cleanup (if destroy hangs on VPC):**
```bash
# 1. Find orphaned security groups
aws ec2 describe-security-groups --filters "Name=vpc-id,Values=vpc-xxx" --region ap-southeast-2 \
  --query 'SecurityGroups[?starts_with(GroupName, `k8s-`)].{ID:GroupId,Name:GroupName}' --output table

# 2. Delete them (may need to revoke cross-references first)
for SG in sg-xxx sg-yyy; do
  aws ec2 delete-security-group --group-id $SG --region ap-southeast-2
done

# 3. Re-run terraform destroy
terraform destroy -auto-approve
```

**Future improvement:** Add a pre-destroy cleanup step to the `mise run destroy-demo` task that waits for `k8s-*` security groups to be deleted before proceeding.

## Repo Hygiene

- **Never commit secrets** - Use `fnox.toml` (gitignored) for 1Password mappings
- **Never commit** - `.pem`, `.zip`, `kubeconfig`, `*.tfstate` files
- **State files** - `*.tfstate`, `backend.tf`, `backend.hcl` are gitignored
- **Pre-commit hooks** - Run `pre-commit run --all-files` before committing

---

## Deployment Verification

After deployment, verify all components are running:

```bash
export KUBECONFIG=/tmp/kubeconfig-wiz-demo

# 1. Check EKS nodes
kubectl get nodes

# 2. Check React2Shell app
kubectl get pods -n react2shell-<suffix>
kubectl get svc -n react2shell-<suffix>

# 3. Check Wiz integration
kubectl get pods -n wiz
kubectl get pods -n argocd

# 4. Test app connectivity
NLB=$(kubectl get svc -n react2shell-<suffix> -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" "http://$NLB"
```

**Expected State:**
- 2 EKS nodes (Ready)
- 1 react2shell pod (Running)
- 5 Wiz pods (Running): 1 agent, 2 admission controllers, 2 sensors
- 7 ArgoCD pods (Running)
- App returns HTTP 200

---

## Running Tests

The test suite requires environment variables that match your deployment's naming:

```bash
export KUBECONFIG=/tmp/kubeconfig-wiz-demo
export APP_NAMESPACE=react2shell-<suffix>    # e.g., react2shell-1a4a1e
export APP_NAME=react2shell-<suffix>
export S3_BUCKET_NAME=react2shell-<suffix>-sensitive-data

# Run tests
mise run test app s3
```

**Note:** The suffix comes from `backend-config.json` → `random_prefix_id`.

The test defaults (`react2shell-v1`) don't match deployments using random prefixes. Always set these variables explicitly.

---

## Lessons Learned & Troubleshooting

### CLI Wrapper Scripts in `.mise-tasks/scripts/`

**CRITICAL**: Mise automatically adds `.mise-tasks/scripts/` to PATH when you enter the directory. Any executable script here will shadow the real command.

**What works:**
- `terraform` wrapper - Adds `-backend-config=backend.hcl` to `init` commands. Required for bootstrap.

**What breaks:**
- `aws` wrapper that calls `aws sts get-caller-identity` to validate credentials → **Infinite loop** when you run `aws sts get-caller-identity`
- `kubectl` wrapper with similar validation → Same problem

**Rule**: Never create wrapper scripts that call themselves (even indirectly via validation).

### mise.local.toml Hooks

**Problem**: The `[hooks.enter]` section runs `fnox activate` when entering the directory. This conflicts with manual `eval "$(mise run auth)"` workflow.

**Solution**: Hooks are commented out in the template by default. Users can enable them after setup is working.

**Two valid workflows:**
1. **Manual auth** (default): Run `eval "$(mise run auth)"` each session
2. **Auto-activate** (advanced): Enable hooks in mise.local.toml after confirming everything works

### fnox Credential Issues

**Symptom**: Wrong AWS credentials being used.

**Debugging steps:**
1. `env | grep AWS` - Check what credentials are set
2. `op item get "item-name" --vault "Vault" --fields username` - Verify 1Password item contents
3. `fnox run --profile dev -- env | grep AWS` - Check what fnox is providing
4. Check if fnox.toml has correct 1Password item references

**Common causes:**
- fnox.toml copied from template still has placeholder item names
- fnox activated from another directory with different credentials
- 1Password item contents changed but session cached old values

### Fresh Clone Testing

When testing a fresh clone experience:

1. Always use `/tmp/` or another clean location
2. Copy **working** `fnox.toml` from reference repo, not the template
3. Start a fresh terminal to clear any cached fnox/mise state
4. Run `hash -r` to clear shell's command cache after removing wrapper scripts

### Environment Variable Inheritance

**Problem**: `TF_VAR_allowed_cidrs` (and other TF_VAR_* variables) must be set in the same shell session that runs terraform.

**What doesn't work:**
```bash
mise run auth              # Just PRINTS exports, doesn't set them
launch-process terraform   # New shell, doesn't inherit parent env
```

**What works:**
```bash
eval "$(mise run auth)"                           # Actually sets variables
mise run apply-demo --path scenarios/react2shell  # Inherits from current shell
```

**Key insight**: The `eval "$(...)"` wrapper is required - without it, the exports are just printed to stdout but never executed.

### Adding New Directories to Existing Backend

If you need to add a new terraform directory after initial bootstrap:

```bash
# DON'T re-run bootstrap-branch (it will error or overwrite config)
# Instead, use init-backends:
mise run init-backends --directories infrastructure/wiz/develop

# Then apply:
mise run apply-demo --path infrastructure/wiz/develop
```

### Container Image Architecture

The EKS nodes run `amd64` (x86_64) architecture. If you're building on Apple Silicon (M1/M2/M3), Docker will build `arm64` images by default, which won't run on EKS.

The `mise run build-image` task handles this automatically with `--platform linux/amd64`, but if you see `ImagePullBackOff` or `exec format error`, verify the image architecture:

```bash
docker inspect --format='{{.Architecture}}' <image>
# Should be: amd64
```

### ECR Image Must Be Built Before First Deploy

After `terraform apply`, the react2shell pod will be in `ImagePullBackOff` until you build and push the container image:

```bash
# Ensure Docker/OrbStack is running
mise run build-image --push

# Pod will automatically restart and pull the new image
# Or force restart:
kubectl rollout restart deployment/react2shell-<suffix> -n react2shell-<suffix>
```

### ArgoCD LoadBalancer Not Publicly Accessible

The ArgoCD server is deployed as a LoadBalancer type, but it's **not publicly accessible** due to missing AWS Load Balancer Controller annotations. This is intentional for security.

**Always use port-forward to access ArgoCD:**
```bash
export KUBECONFIG=/tmp/kubeconfig-wiz-demo
kubectl port-forward svc/argocd-server -n argocd 8080:80

# Then open: http://localhost:8080
# Username: admin
# Password: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

### Wiz Defend Logging KMS Key Policy

When creating CloudTrail with an encrypted SNS topic, the KMS key policy must explicitly allow CloudTrail to use the key for SNS publishing:

```hcl
{
  Sid    = "Allow CloudTrail to use key for SNS"
  Effect = "Allow"
  Principal = {
    Service = "cloudtrail.amazonaws.com"
  }
  Action = [
    "kms:GenerateDataKey*",
    "kms:Decrypt"
  ]
  Resource = "*"
}
```

Without this, `terraform apply` fails with `InsufficientSnsTopicPolicyException`.

### AWS Load Balancer Controller Cleanup During Destroy

**Problem**: `terraform destroy` gets stuck on VPC deletion because the AWS Load Balancer Controller creates resources (NLBs, security groups) that aren't managed by Terraform.

**Symptoms**:
- VPC deletion hangs for 10+ minutes
- Error: "DependencyViolation: The vpc has dependencies and cannot be deleted"
- Orphaned `k8s-*` prefixed security groups remain in the VPC
- NLBs created by the controller aren't deleted

**Root Cause**: The AWS Load Balancer Controller creates:
1. **NLBs/ALBs** for Kubernetes Services of type LoadBalancer
2. **Security Groups** with `k8s-` prefix for traffic routing
3. **TargetGroupBindings** custom resources with finalizers

These resources are created by the controller, not Terraform, so `terraform destroy` doesn't know to delete them.

**Manual Cleanup Required** (in order):
```bash
# 1. Delete NLBs first
aws elbv2 describe-load-balancers --region <region> \
  --query 'LoadBalancers[?starts_with(LoadBalancerName, `k8s-`)].[LoadBalancerArn]' --output text | \
  xargs -I {} aws elbv2 delete-load-balancer --load-balancer-arn {}

# 2. Wait for NLBs to fully delete (releases ENIs)
sleep 60

# 3. Delete orphaned k8s-* security groups
aws ec2 describe-security-groups --region <region> \
  --filters "Name=vpc-id,Values=<vpc-id>" \
  --query 'SecurityGroups[?starts_with(GroupName, `k8s-`)].[GroupId]' --output text | \
  xargs -I {} aws ec2 delete-security-group --group-id {}

# 4. Force-delete stuck Kubernetes namespaces (if cluster still exists)
kubectl get ns <namespace> -o json | jq '.spec.finalizers = []' | \
  kubectl replace --raw "/api/v1/namespaces/<namespace>/finalize" -f -
```

**Dependency Chain**:
```
NLBs → ENIs → Security Groups → Subnets → Internet Gateway → VPC
```

Each layer must be cleaned up before the next can be deleted.

**TODO**: Implement automated pre-destroy cleanup script or use the `time_sleep` pattern more effectively. See reference repo for potential solutions.
