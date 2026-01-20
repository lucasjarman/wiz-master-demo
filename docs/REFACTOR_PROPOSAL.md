# Infrastructure Refactor Proposal

> Generated: 2026-01-20
> Last Updated: 2026-01-20
> Reference: `~/Code/wiz-demo-infra`
> Goals: Simplicity, Repeatability, Portability

## ✅ REFACTOR COMPLETE

**All tasks completed:** 2026-01-20

### Completed Tasks:
- [x] 1.1 Delete `infra/` directory (legacy terraform + state files)
- [x] 1.2 Delete `Commands/` directory (replaced by mise tasks)
- [x] 1.3 Delete sensitive/binary files (.pem, .zip, .pdf, kubeconfig)
- [x] 1.4 Delete unused root files (defend.md, values.yaml, Support/, ci/, wizcli/)
- [x] 1.5 Move exploit scripts to `scripts/exploit/`
- [x] 1.6 Clean outdated docs (kept only REFACTOR_PROPOSAL.md)
- [x] 2.1 Add multi-cloud module placeholders (`modules/azure/`, `modules/gcp/`)
- [x] 2.2 Update `.gitignore` for sensitive files
- [x] 3.1 Add `common.auto.tfvars` to terraform directories
- [x] 3.2 Enhance `mise.local.toml.template` with allowed_cidrs, toggles
- [x] 4.1 Add `mise run test` task
- [x] 4.2 Add `mise run init-scenarios` task

---

## Executive Summary

This document outlines proposed changes to align `wiz-master-demo` with patterns from the reference repository. The goal is a clean, repeatable infrastructure deployable from scratch with minimal commands.

---

## 🔴 Critical Issues (Must Fix)

### 1. Legacy `infra/` Directory - DELETE

| Path | Issue | Action |
|------|-------|--------|
| `infra/aws/` | Old monolithic terraform, hardcoded regions, local state | DELETE |
| `infra/bootstrap/` | Replaced by `infrastructure/backends/` | DELETE |
| `infra/k8s/` | K8s manifests now in scenario modules | DELETE |

**Problems:** Hardcoded `ap-southeast-2`, hardcoded SNS ARNs, `null_resource` with `local-exec`, committed state files.

### 2. Committed State Files - DELETE IMMEDIATELY

```
infra/aws/terraform.tfstate
infra/aws/terraform.tfstate.backup
infra/bootstrap/terraform.tfstate
infra/bootstrap/terraform.tfstate.backup
```

### 3. Sensitive/Binary Files - DELETE

| File | Issue |
|------|-------|
| `wiz-master-demo.pem` | Private key - NEVER commit |
| `kubeconfig` | Generated, not committed |
| `wiz-linux-attack-scenario.zip` | Binary file |
| `Install Runtime Sensor*.pdf` | Documentation |

### 4. Unused Scripts - DELETE or MIGRATE

| File | Action |
|------|--------|
| `Commands/*` | DELETE - replaced by mise tasks |
| `wiz-demo*.sh` | MOVE to `scripts/exploit/` |
| `trigger_*.sh` | MOVE to `scripts/exploit/` |
| `docs/*.md` (except this) | DELETE - outdated |
| `Support/`, `ci/`, `wizcli/` | DELETE |
| `defend.md`, `values.yaml` | DELETE |

---

## 🟡 Structural Improvements

### 1. Add `common.auto.tfvars` Pattern

Each terraform directory should have shared config:

```hcl
# infrastructure/shared/aws/common.auto.tfvars
prefix      = "wiz-demo"
common_tags = {
  Project     = "wiz-master-demo"
  Environment = "Demo"
  ManagedBy   = "Terraform"
}
```

### 2. Enhance `mise.local.toml.template`

Add network/scenario configuration:

```toml
# Network Access Control
TF_VAR_allowed_cidrs='["YOUR_IP/32"]'
TF_VAR_dynamic_scanner_ipv4s_develop=""

# Scenario toggles
TF_VAR_deploy_react2shell="true"
```

### 3. Add Missing Mise Tasks

| Task | Purpose |
|------|---------|
| `init-scenarios` | Scaffold new scenario directories |
| `build-image` | Build and push container to ECR |
| `test` | Run infrastructure tests |

### 4. Add Multi-Cloud Placeholders

```
modules/
├── aws/           # Existing
├── azure/         # NEW placeholder
├── gcp/           # NEW placeholder
├── k8s-services/  # Existing
└── wiz/           # Existing
```

---

## 🟢 What Works (Keep)

- `infrastructure/` layered structure
- `scenarios/react2shell/aws/` pattern
- `mise.toml` and templates
- `.mise-tasks/` structure
- `modules/` structure
- Auth pattern with fnox
- Test scripts (integrate with mise)

---

## Proposed Clean Structure

```
.
├── AGENTS.md
├── CLAUDE.md
├── README.md
├── mise.toml
├── .mise-tasks/
│   ├── auth
│   ├── bootstrap-branch
│   ├── apply-demo
│   ├── init-scenarios      # NEW
│   ├── build-image         # NEW
│   ├── test                # NEW
│   └── local-dev/
├── templates/
│   ├── fnox.toml.template
│   ├── mise.local.toml.template
│   └── terraform/          # NEW - scaffolding
├── infrastructure/
│   ├── backends/
│   ├── shared/aws/
│   └── wiz/develop/
├── scenarios/
│   └── react2shell/aws/
├── modules/
│   ├── aws/
│   ├── azure/              # NEW
│   ├── gcp/                # NEW
│   ├── k8s-services/
│   └── wiz/
├── app/nextjs/
├── scripts/                # NEW - exploit scripts
│   └── exploit/
└── tests/
```

---

## Files to DELETE

```
infra/                          # Entire legacy directory
Commands/                       # Replaced by mise tasks
docs/cost-control-runbook.md    # Outdated
docs/eks-spin-down.md           # Outdated
docs/iac-refactor-progress.md   # Outdated
docs/spin-down-review.md        # Outdated
wiz-demo.sh                     # Move to scripts/
wiz-demo-v2.sh                  # Consolidate
wiz-demo-v3.sh                  # Consolidate
trigger_banner.sh               # Move to scripts/
trigger_recon.sh                # Move to scripts/
wiz-master-demo.pem             # Never commit keys
wiz-linux-attack-scenario.zip   # Binary
Install Runtime Sensor*.pdf     # Not source code
defend.md                       # Outdated
values.yaml                     # Unused
Support/                        # Unused
ci/                             # Unused
wizcli/                         # Unused
kubeconfig                      # Should be generated
```

---

## Implementation Phases

### Phase 1: Cleanup
- Delete legacy `infra/` directory
- Delete unused scripts and docs
- Remove sensitive files from repo
- Move exploit scripts to `scripts/exploit/`

### Phase 2: Structure
- Add `modules/azure/` and `modules/gcp/` placeholders
- Add `scripts/exploit/` directory
- Add `templates/terraform/` for scaffolding

### Phase 3: Configuration
- Add `common.auto.tfvars` to each terraform directory
- Enhance `mise.local.toml.template` with more toggles
- Update `.gitignore` to exclude generated files

### Phase 4: Mise Tasks
- Add `mise run init-scenarios` for new scenario creation
- Add `mise run build-image` for container builds
- Add `mise run test` to wrap test scripts

### Phase 5: Validation
- Deploy from scratch on clean AWS account
- Verify all Wiz integrations work
- Run full test suite
- Document any issues

---

## Quick Deploy Target

After refactor, deploying from scratch should be:

```bash
# 1. Setup (one-time)
mise trust && mise install
cp templates/fnox.toml.template fnox.toml
cp templates/mise.local.toml.template mise.local.toml
# Edit both files with your 1Password items

# 2. Deploy
eval "$(mise run auth)"
mise run bootstrap-branch --directories infrastructure/shared/aws,infrastructure/wiz/develop,scenarios/react2shell/aws
mise run build-image                    # Build and push to ECR
mise run apply-demo --all               # Deploy everything
mise run test                           # Validate

# 3. Get app URL
kubectl get svc -n react2shell
```

---

## Container Image Strategy

Two options:

### Option A: Build Locally → Push to ECR (Current)
- Requires Docker on local machine
- Full control over image
- `mise run build-image` task needed

### Option B: Shared Registry (Reference Pattern)
- Use pre-built images from GAR or shared ECR
- Requires 1Password access to registry credentials
- No local Docker needed
- Add to `fnox.toml`:
  ```toml
  TF_VAR_registry_url={provider="1pass", value="registry-item/url"}
  TF_VAR_registry_pull_secret={provider="1pass", value="registry-item/pullSecret"}
  ```

**Recommendation:** Start with Option A for simplicity, migrate to Option B when sharing across team.

---

## Testing Strategy

Current tests in `tests/`:
- `test_infrastructure.sh` - Main runner
- `test_network_policy.sh` - NetworkPolicy validation
- `test_argocd.sh` - ArgoCD deployment
- `test_wiz_integration.sh` - Wiz sensor/connector
- `test_app_access.sh` - App accessibility
- `test_s3_bucket.sh` - S3 configuration
- `test_wiz_defend_logging.sh` - CloudTrail/FlowLogs

**Improvement:** Wrap with `mise run test` for consistency:
```bash
mise run test              # Run all tests
mise run test argocd wiz   # Run specific suites
```

---

## Questions to Resolve

1. **Container images:** Build locally or use shared registry?
2. **Wiz tenant:** Use existing tenant or create new?
3. **Exploit scripts:** Keep in repo or separate?
4. **Multi-cloud:** Add Azure/GCP now or later?

---

## Next Steps

When ready to proceed:
1. Review this proposal
2. Decide on container image strategy
3. Run cleanup (Phase 1)
4. Deploy and validate
