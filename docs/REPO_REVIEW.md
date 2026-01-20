# Repo Review: `wiz-master-demo`
_Reviewed: 2026-01-20 • Branch: `iac-refactor`_

## What I evaluated

Source-of-truth for goals and intent:
- `README.md`
- `AGENTS.md` / `CLAUDE.md`
- `docs/REFACTOR_PROPOSAL.md`

I also skimmed the implementation in:
- `.mise-tasks/` (auth/bootstrap/apply/test/init-scenarios + wrappers)
- `infrastructure/` (backends/shared/aws/wiz/develop)
- `scenarios/react2shell/aws/` (+ module manifests)
- `modules/` (aws + k8s-services + wiz + cloud placeholders)
- `app/nextjs/` (vulnerable Next.js app)
- `tests/` (integration test runner + suites)
- `scripts/exploit/` (demo exploit scripts)

This is a static review (I did not run `terraform apply`, deploy, or run tests against AWS).

---

## Stated goals vs. repo reality

Stated goals in `README.md`: **Repeatable**, **Simple**, **Portable**, **Extensible**.

### Repeatable (mostly there, with a few blockers)
What’s working well:
- Layered Terraform structure (`infrastructure/backends` → `infrastructure/shared/aws` → `infrastructure/wiz/develop` → `scenarios/...`) is a good repeatability pattern.
- `backend-config.json` + remote state usage makes dependencies explicit.
- `common.auto.tfvars` pattern exists (at least for shared + react2shell) and keeps those layers consistent.

Blockers / gaps:
- **Working tree is not “clone-and-run” right now.** `git status` shows a large refactor is present but not fully committed/staged (new directories are untracked; legacy paths are deleted). Until this is committed, other users cannot reproduce the intended structure from a fresh clone.
- **`mise run bootstrap-branch` appears inconsistent with the current repo layout + config schema.**
  - The task declares `#MISE dir="infra/bootstrap"` even though `infra/` is deleted.
  - It writes `backend-config.json` with `random_prefix_id`, but **Terraform reads `suffix`** in `infrastructure/shared/aws` and `scenarios/react2shell/aws`. A fresh bootstrap for a new branch risks generating a config file that Terraform can’t read.

### Simple (good direction, but some “sharp edges”)
What’s working well:
- Using `mise` to define “golden path” tasks (`auth`, `bootstrap-branch`, `apply-demo`, `test`, `init-scenarios`) is exactly the right idea for minimal commands.
- Scenario module uses templated manifests (`kubectl_manifest` + YAML) instead of complicated Helm charts for the app, which keeps it understandable.

Sharp edges / complexity that may surprise users:
- **Credential model is effectively “env-var auth only”** in practice:
  - `.mise-tasks/scripts/aws`, `kubectl`, and `terraform` wrappers require `AWS_ACCESS_KEY_ID` to be set.
  - This conflicts with the “AWS profile” option described in `AGENTS.md` and can make tasks fail in otherwise-valid AWS credential setups (e.g., `AWS_PROFILE`, SSO, IMDS, or `credential_process`).
- There is no first-class “build and push the app image” step in `mise` tasks (even though `docs/REFACTOR_PROPOSAL.md` mentions a `build-image` task). For a true “from scratch” deploy in a new account, you need an image in ECR (or a documented alternative).

### Portable (partially achieved)
What’s working well:
- Region and naming are parameterized in Terraform; `templates/mise.local.toml.template` sets `AWS_REGION`/`TF_VAR_aws_region`.
- `init-scenarios` scaffolding supports multi-cloud directory creation.

Portability gaps:
- `scripts/exploit/` contains hard-coded targets (NLB DNS names, bucket names, region-specific assumptions). This will not work across accounts/regions/environments without edits.
- Defaults vary by layer (`ap-southeast-2` defaults in Terraform vs `us-east-2` in the template), which is fine if intentional, but should be consistently documented as “override via mise.local.toml”.

### Extensible (good foundation)
What’s working well:
- `templates/terraform/init_scenarios/*.template` + `mise run init-scenarios` is a solid extensibility mechanism.
- `modules/azure/` and `modules/gcp/` placeholders exist and keep the repo future-facing.

What would make it stronger:
- A lightweight convention for “what every scenario must include” (e.g., required outputs, test suite hooks, and a scenario README template) to keep new scenarios consistent.

---

## Does it achieve the demo goal?

The “golden state” attack path described in the docs is clearly represented in the implementation:
- Public exposure via `Service` type `LoadBalancer` (NLB annotations).
- Vulnerable Next.js app pinned to `next@16.0.6` / `react@19.2.0`.
- IRSA role intentionally over-permissive (`s3:*` on `*`).
- Sensitive data bucket populated with explicitly fake “PII-like” content.

So, conceptually: **yes**—the repo contains the right moving parts for the Wiz demo story.

Practically: **it will likely fail for a new user unless the bootstrap/config/task mismatches are addressed and the refactor is committed**.

---

## Simplicity review (where complexity feels justified vs. avoidable)

### Justified complexity (good trade-offs)
- Using upstream Terraform modules for VPC/EKS is a net reduction in custom code.
- Wiz Defend logging plumbing (CloudTrail, Flow Logs, KMS policies) is inherently verbose in AWS and is reasonable to keep as isolated files/modules behind toggles.
- Test suite split by “capability” is a good way to keep checks understandable.

### Avoidable / accidental complexity (worth tightening)
- **Schema drift:** `suffix` vs `random_prefix_id` appears in multiple places; one canonical field should exist, with compatibility handled in one spot.
- **Task drift:** `bootstrap-branch` still references deleted paths and does not clearly align with the current Terraform layout.
- **Hard-coded demo artifacts:** exploit scripts include environment-specific DNS/bucket names; for portability, they should accept inputs and/or auto-discover from Terraform outputs.
- **Brittle wrappers:** requiring `AWS_ACCESS_KEY_ID` is a fragile proxy for “auth is configured”.
- **Unused variables:** e.g., `aws_profile` variables exist in Terraform but aren’t used (and the wrapper approach discourages profile-based auth anyway).

---

## High-impact recommendations (prioritized)

1. **Commit the refactor state** (or explicitly document that this branch is WIP). Until new directories are tracked, the repo cannot meet “repeatable/portable”.
2. **Fix `bootstrap-branch` to match reality**:
   - Run in `infrastructure/backends/`.
   - Write a `backend-config.json` schema that matches Terraform (`suffix` and `random_prefix_id` or a single canonical field).
   - Prefer absolute paths rooted at `$GIT_ROOT` over brittle `../` paths.
3. **Add (or document) an image build/push step**:
   - Implement the missing `mise run build-image`, or
   - Document a minimal manual flow (`docker build` → `ecr login` → `docker push`) and how to set `TF_VAR_ecr_image`.
4. **Make auth truly flexible**:
   - Wrappers should validate auth by calling `aws sts get-caller-identity`, not by checking `AWS_ACCESS_KEY_ID`.
   - Update docs to reflect the supported credential methods (env, profile, SSO).
5. **Make tests and exploit scripts environment-aware**:
   - Derive namespaces/targets from Terraform outputs (or `backend-config.json`) instead of assuming `*-v1`.
   - Keep hard-coded Wiz scanner CIDRs in one place (or avoid hard-coding them in tests).

