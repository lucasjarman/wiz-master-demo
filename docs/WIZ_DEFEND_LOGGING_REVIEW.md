# Wiz Defend Logging Infra Review (vs `~/Code/wiz-demo-infra`)
_Reviewed: 2026-01-20_

## Where it lives (this repo vs reference)

- In `wiz-master-demo`, Wiz Defend logging infrastructure is primarily in:
  - `infrastructure/shared/aws/wiz-defend-logging.tf`
  - Consumed by the Wiz AWS connector config in `infrastructure/wiz/develop/main.tf`
- In `wiz-demo-infra`, the equivalent logic is embedded in:
  - `infrastructure/shared/aws/main.tf`
  - Consumed from `infrastructure/wiz/develop/main.tf`

## What matches the reference repo

- Core building blocks and modules line up with the reference patterns:
  - CloudTrail/S3/SNS/SQS wiring for cloud events: `infrastructure/shared/aws/modules/aws_cloud_events/`
  - VPC Flow Logs ingestion queue plumbing: `modules/wiz/vpc-flow-logs/`
  - Wiz AWS connector config schema: `modules/wiz/aws-connector/`
  - Shared S3 bucket module: `modules/aws/s3/`
- Shared-layer composition is the same shape as the reference:
  - S3 buckets + KMS keys + SNS fanout topics
  - Bucket policies for CloudTrail + VPC Flow Logs delivery
  - `aws_cloudtrail` with advanced selectors
  - `aws_flow_log` targeting S3
  - Route53 Resolver query logging via `modules/aws/wiz-defend-logging`
  - Per-tenant SQS queues wired into Wiz via connector config

## Key diffs introduced here

- **Route53 logging module contract relaxed**:
  - `modules/aws/wiz-defend-logging/variables.tf` now allows `wiz_role_names = {}` (default), whereas the reference required at least one role.
  - `modules/aws/wiz-defend-logging/main.tf` now conditionally emits the “AllowWizAccessRoute53LogsS3” bucket-policy statement only when roles are present.
- **Docs drift**:
  - `modules/aws/wiz-defend-logging/README.md` still documents `wiz_role_names` as required, but code now treats it as optional.
- **Output naming divergence**:
  - `wiz-master-demo` exports `flow_logs_bucket_name` in `infrastructure/shared/aws/outputs.tf`.
  - `wiz-demo-infra` exports `vpc_flow_logs_bucket_name` in its shared outputs.
  - Your Wiz connector wiring uses the local names correctly, but this makes copying patterns between repos slightly harder.

## Recommendations

1. Update or regenerate terraform-docs for `modules/aws/wiz-defend-logging` so the README matches the new optional `wiz_role_names` behavior.
2. Consider adding an output alias `vpc_flow_logs_bucket_name` (or standardizing the name) to stay closer to reference-repo conventions and reduce friction when porting code/automation.
