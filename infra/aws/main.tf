terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

# -----------------------------------------------------------------------------
# 1. SETUP & RANDOMIZATION
# -----------------------------------------------------------------------------
resource "random_id" "suffix" {
  byte_length = 4
  prefix      = "wiz-"
}

# -----------------------------------------------------------------------------
# 2. VULNERABLE SECRETS (FOR WIZ CODE DEMO)
# -----------------------------------------------------------------------------
# INTENTIONAL VULNERABILITY: Hardcoded secrets in IaC
# This triggers Wiz Code secret scanning.
locals {
  aws_access_key        = "EXAMPLE"
  aws_secret_access_key = "EXAMPLESECRETS"
}

# -----------------------------------------------------------------------------
# 3. VPC (NETWORK)
# -----------------------------------------------------------------------------
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "wiz-rsc-demo-vpc-${random_id.suffix.hex}"
  cidr = "10.0.0.0/16"

  azs             = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  private_subnets = var.enable_eks ? ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"] : []

  # NAT Gateway only needed for EKS (nodes in private subnets need internet access)
  enable_nat_gateway = var.enable_eks
  single_nat_gateway = true  # Cost optimization for demo

  enable_dns_hostnames = true
  enable_dns_support   = true

  # Tags required for EKS to discover subnets
  public_subnet_tags = var.enable_eks ? {
    "kubernetes.io/role/elb"                                 = 1
    "kubernetes.io/cluster/wiz-rsc-demo-eks-${random_id.suffix.hex}" = "shared"
  } : {}

  private_subnet_tags = var.enable_eks ? {
    "kubernetes.io/role/internal-elb"                        = 1
    "kubernetes.io/cluster/wiz-rsc-demo-eks-${random_id.suffix.hex}" = "shared"
  } : {}

  tags = {
    Environment = "Demo"
    Project     = "React2Shell"
  }
}

# -----------------------------------------------------------------------------
# 7. VULNERABLE S3 BUCKET (SENSITIVE DATA)
# -----------------------------------------------------------------------------
# INTENTIONAL VULNERABILITY: Public S3 Bucket containing "sensitive" data.
resource "aws_s3_bucket" "sensitive_data" {
  bucket = "wiz-demo-sensitive-data-${random_id.suffix.hex}"

  force_destroy = true

  tags = {
    Name          = "Sensitive Data Bucket"
    Environment   = "Demo"
    Vulnerability = "PublicAccess"
  }
}

# Disable "Block Public Access" to allow public policy
resource "aws_s3_bucket_public_access_block" "sensitive_data" {
  bucket = aws_s3_bucket.sensitive_data.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Public Read Policy
resource "aws_s3_bucket_policy" "sensitive_data" {
  bucket = aws_s3_bucket.sensitive_data.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.sensitive_data.arn}/*"
      },
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.sensitive_data]
}

# Fake Sensitive Data Objects - Enhanced with PII patterns for Wiz detection
resource "aws_s3_object" "employees" {
  bucket = aws_s3_bucket.sensitive_data.id
  key    = "employees.json"
  content = jsonencode([
    {
      id            = 1
      name          = "Alice Admin"
      email         = "alice.admin@acmecorp.com"
      role          = "SuperAdmin"
      salary        = 150000
      ssn           = "123-45-6789"
      phone         = "+1-555-123-4567"
      date_of_birth = "1985-03-15"
      address       = "123 Main Street, San Francisco, CA 94102"
      bank_account  = "****4521"
    },
    {
      id            = 2
      name          = "Bob Builder"
      email         = "bob.builder@acmecorp.com"
      role          = "Engineer"
      salary        = 120000
      ssn           = "987-65-4321"
      phone         = "+1-555-987-6543"
      date_of_birth = "1990-07-22"
      address       = "456 Oak Avenue, Seattle, WA 98101"
      bank_account  = "****8834"
    },
    {
      id            = 3
      name          = "Charlie Chief"
      email         = "charlie.chief@acmecorp.com"
      role          = "CEO"
      salary        = 300000
      ssn           = "456-78-9012"
      phone         = "+1-555-456-7890"
      date_of_birth = "1975-11-30"
      address       = "789 Executive Blvd, New York, NY 10001"
      bank_account  = "****2291"
    }
  ])
  content_type = "application/json"
}

resource "aws_s3_object" "secret_roadmap" {
  bucket       = aws_s3_bucket.sensitive_data.id
  key          = "roadmap_2025_confidential.txt"
  content      = "1. Launch RCE exploit as a feature.\n2. Buy more crypto.\n3. Take over the world."
  content_type = "text/plain"
}

# Customer PII Database
resource "aws_s3_object" "customer_pii" {
  bucket = aws_s3_bucket.sensitive_data.id
  key    = "customers/customer_database.csv"
  content = <<-EOF
customer_id,full_name,email,ssn,credit_card,cvv,phone,address,dob
1001,John Smith,john.smith@gmail.com,234-56-7890,4532-1234-5678-9012,123,+1-408-555-0101,"100 Technology Dr, San Jose, CA 95110",1982-04-12
1002,Jane Doe,jane.doe@yahoo.com,345-67-8901,5425-9876-5432-1098,456,+1-650-555-0202,"200 Innovation Way, Palo Alto, CA 94301",1988-09-23
1003,Michael Johnson,m.johnson@outlook.com,456-78-9012,3782-822463-01005,789,+1-415-555-0303,"300 Market St, San Francisco, CA 94105",1979-12-05
1004,Emily Williams,emily.w@hotmail.com,567-89-0123,6011-1234-5678-9012,234,+1-510-555-0404,"400 Broadway, Oakland, CA 94607",1995-06-18
1005,David Brown,david.brown@proton.me,678-90-1234,4916-3456-7890-1234,567,+1-925-555-0505,"500 Main St, Walnut Creek, CA 94596",1991-02-28
EOF
  content_type = "text/csv"
}

# API Keys and Credentials (intentionally exposed)
resource "aws_s3_object" "api_credentials" {
  bucket = aws_s3_bucket.sensitive_data.id
  key    = "config/api_keys.env"
  content = <<-EOF
# Production API Keys - DO NOT SHARE
AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
STRIPE_SECRET_KEY=sk_test_FAKE_KEY_FOR_DEMO_1234567890
STRIPE_PUBLISHABLE_KEY=pk_test_FAKE_KEY_FOR_DEMO_0987654321
DATABASE_PASSWORD=SuperSecretP@ssw0rd!2024
JWT_SECRET=FAKE_JWT_SECRET_FOR_DEMO_PURPOSES_ONLY
SENDGRID_API_KEY=SG.FAKE_SENDGRID_KEY_FOR_DEMO
GITHUB_TOKEN=ghp_FAKE_TOKEN_FOR_DEMO_ONLY
SLACK_WEBHOOK_URL=https://hooks.example.com/services/FAKE/WEBHOOK/FORDEMO
OPENAI_API_KEY=sk-FAKE-OPENAI-KEY-FOR-DEMO-PURPOSES
EOF
  content_type = "text/plain"
}

# Medical Records (HIPAA sensitive)
resource "aws_s3_object" "medical_records" {
  bucket = aws_s3_bucket.sensitive_data.id
  key    = "healthcare/patient_records.json"
  content = jsonencode([
    {
      patient_id     = "P-10001"
      name           = "Robert Wilson"
      ssn            = "111-22-3333"
      dob            = "1965-08-14"
      medical_record = "MRN-2024-00123"
      diagnosis      = "Type 2 Diabetes Mellitus"
      medications    = ["Metformin 500mg", "Lisinopril 10mg"]
      insurance_id   = "BCBS-123456789"
      physician      = "Dr. Sarah Chen"
    },
    {
      patient_id     = "P-10002"
      name           = "Susan Martinez"
      ssn            = "222-33-4444"
      dob            = "1978-03-22"
      medical_record = "MRN-2024-00456"
      diagnosis      = "Hypertension"
      medications    = ["Amlodipine 5mg"]
      insurance_id   = "AETNA-987654321"
      physician      = "Dr. James Park"
    }
  ])
  content_type = "application/json"
}

# Financial Records
resource "aws_s3_object" "financial_records" {
  bucket = aws_s3_bucket.sensitive_data.id
  key    = "finance/payroll_q4_2024.csv"
  content = <<-EOF
employee_id,name,ssn,bank_routing,bank_account,net_pay,tax_withheld,401k_contribution
E001,Alice Admin,123-45-6789,021000021,****4521,8750.00,2250.00,625.00
E002,Bob Builder,987-65-4321,121000358,****8834,7000.00,1800.00,500.00
E003,Charlie Chief,456-78-9012,322271627,****2291,17500.00,7500.00,1458.33
E004,Diana Developer,234-56-7890,091000019,****7743,6500.00,1650.00,487.50
E005,Edward Engineer,345-67-8901,071000013,****9912,6250.00,1600.00,468.75
EOF
  content_type = "text/csv"
}

# Database Backup (contains credentials)
resource "aws_s3_object" "db_backup_config" {
  bucket = aws_s3_bucket.sensitive_data.id
  key    = "backups/database_config.yaml"
  content = <<-EOF
# Database Configuration - CONFIDENTIAL
production:
  host: prod-db.internal.acmecorp.com
  port: 5432
  database: acme_production
  username: admin
  password: Pr0d_DB_P@ssw0rd!2024
  ssl_mode: require

replica:
  host: replica-db.internal.acmecorp.com
  port: 5432
  database: acme_production
  username: readonly
  password: R3pl1ca_R34d0nly!

redis:
  host: redis.internal.acmecorp.com
  port: 6379
  password: R3d1s_C@che_2024!
EOF
  content_type = "text/yaml"
}

# -----------------------------------------------------------------------------
# 8. CLOUDTRAIL (FOR WIZ DEFEND)
# -----------------------------------------------------------------------------
# S3 bucket for CloudTrail logs
resource "aws_s3_bucket" "cloudtrail_logs" {
  bucket        = "wiz-demo-cloudtrail-${random_id.suffix.hex}"
  force_destroy = true

  tags = {
    Name        = "CloudTrail Logs"
    Environment = "Demo"
  }
}

resource "aws_s3_bucket_policy" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.cloudtrail_logs.arn
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudtrail_logs.arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

# CloudTrail with S3 Data Events
resource "aws_cloudtrail" "main" {
  name                          = "wiz-demo-trail-${random_id.suffix.hex}"
  s3_bucket_name                = aws_s3_bucket.cloudtrail_logs.id
  include_global_service_events = true
  is_multi_region_trail         = false

  # S3 Data Events for sensitive bucket - captures GetObject, PutObject etc
  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type   = "AWS::S3::Object"
      values = ["${aws_s3_bucket.sensitive_data.arn}/"]
    }
  }

  depends_on = [aws_s3_bucket_policy.cloudtrail_logs]

  tags = {
    Environment = "Demo"
  }
}

# -----------------------------------------------------------------------------
# 9. VPC FLOW LOGS (FOR WIZ DEFEND) - S3 DESTINATION
# -----------------------------------------------------------------------------
resource "aws_s3_bucket" "vpc_flow_logs" {
  bucket        = "wiz-demo-vpc-flow-logs-${random_id.suffix.hex}"
  force_destroy = true

  tags = {
    Name        = "VPC Flow Logs"
    Environment = "Demo"
  }
}

resource "aws_flow_log" "main" {
  log_destination_type = "s3"
  log_destination      = aws_s3_bucket.vpc_flow_logs.arn
  traffic_type         = "ALL"
  vpc_id               = module.vpc.vpc_id

  tags = {
    Name        = "wiz-demo-vpc-flow-log"
    Environment = "Demo"
  }
}

# -----------------------------------------------------------------------------
# 10. ROUTE 53 RESOLVER QUERY LOGS (FOR WIZ DEFEND - DNS EXFIL DETECTION) - S3
# -----------------------------------------------------------------------------
resource "aws_s3_bucket" "dns_query_logs" {
  bucket        = "wiz-demo-dns-logs-${random_id.suffix.hex}"
  force_destroy = true

  tags = {
    Name        = "Route 53 DNS Query Logs"
    Environment = "Demo"
  }
}

resource "aws_s3_bucket_policy" "dns_query_logs" {
  bucket = aws_s3_bucket.dns_query_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSLogDeliveryAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.dns_query_logs.arn
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      },
      {
        Sid    = "AWSLogDeliveryWrite"
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.dns_query_logs.arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl"      = "bucket-owner-full-control"
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

data "aws_caller_identity" "current" {}

resource "aws_route53_resolver_query_log_config" "main" {
  name            = "wiz-demo-dns-query-log-${random_id.suffix.hex}"
  destination_arn = aws_s3_bucket.dns_query_logs.arn

  tags = {
    Environment = "Demo"
  }
}

resource "aws_route53_resolver_query_log_config_association" "main" {
  resolver_query_log_config_id = aws_route53_resolver_query_log_config.main.id
  resource_id                  = module.vpc.vpc_id
}

# -----------------------------------------------------------------------------
# 11. ECR REPOSITORY
# -----------------------------------------------------------------------------
resource "aws_ecr_repository" "app_repo" {
  name                 = "wiz-rsc-demo-app-${random_id.suffix.hex}"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Environment = "Demo"
  }
}

# -----------------------------------------------------------------------------
# 12. WIZ LOGGING INTEGRATION (S3 -> SNS -> SQS)
# -----------------------------------------------------------------------------
# Links Terraform buckets to existing Wiz SNS topics created by CloudFormation.

resource "aws_s3_bucket_notification" "cloudtrail_notification" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  topic {
    topic_arn = "arn:aws:sns:ap-southeast-2:079942904060:wiz-cloudtrail-logs-notify"
    events    = ["s3:ObjectCreated:*"]
  }

  depends_on = [null_resource.update_sns_cloudtrail]
}

resource "aws_s3_bucket_notification" "vpc_flow_logs_notification" {
  bucket = aws_s3_bucket.vpc_flow_logs.id

  topic {
    topic_arn = "arn:aws:sns:ap-southeast-2:079942904060:wiz-vpcflow-logs-notify"
    events    = ["s3:ObjectCreated:*"]
  }

  depends_on = [null_resource.update_sns_vpcflow]
}

resource "aws_s3_bucket_notification" "dns_logs_notification" {
  bucket = aws_s3_bucket.dns_query_logs.id

  topic {
    topic_arn = "arn:aws:sns:ap-southeast-2:079942904060:wiz-bucket-notification-topic-route-53-logs"
    events    = ["s3:ObjectCreated:*"]
  }

  depends_on = [null_resource.update_sns_dns]
}

# -----------------------------------------------------------------------------
# 13. SNS POLICY UPDATER (Automation Hook)
# -----------------------------------------------------------------------------
# Updates the existing CloudFormation-managed SNS policies to allow
# the new Terraform-managed S3 buckets to publish events.

resource "null_resource" "update_sns_cloudtrail" {
  triggers = {
    bucket_arn = aws_s3_bucket.cloudtrail_logs.arn
  }

  provisioner "local-exec" {
    command = "bash update_sns_policy.sh arn:aws:sns:ap-southeast-2:079942904060:wiz-cloudtrail-logs-notify ${aws_s3_bucket.cloudtrail_logs.arn} ${var.aws_profile}"
  }
}

resource "null_resource" "update_sns_vpcflow" {
  triggers = {
    bucket_arn = aws_s3_bucket.vpc_flow_logs.arn
  }

  provisioner "local-exec" {
    command = "bash update_sns_policy.sh arn:aws:sns:ap-southeast-2:079942904060:wiz-vpcflow-logs-notify ${aws_s3_bucket.vpc_flow_logs.arn} ${var.aws_profile}"
  }
}

resource "null_resource" "update_sns_dns" {
  triggers = {
    bucket_arn = aws_s3_bucket.dns_query_logs.arn
  }

  provisioner "local-exec" {
    command = "bash update_sns_policy.sh arn:aws:sns:ap-southeast-2:079942904060:wiz-bucket-notification-topic-route-53-logs ${aws_s3_bucket.dns_query_logs.arn} ${var.aws_profile}"
  }
}

# -----------------------------------------------------------------------------
# 14. EKS AUDIT LOG INTEGRATION (CloudWatch -> Kinesis)
# -----------------------------------------------------------------------------
# Wires the new EKS cluster's log group to the existing Wiz Kinesis Firehose
# destination created by CloudFormation.

resource "aws_cloudwatch_log_subscription_filter" "eks_audit_logs" {
  count           = var.enable_eks ? 1 : 0
  name            = "eks-audit-logs-to-wiz"
  log_group_name  = "/aws/eks/${module.eks[0].cluster_name}/cluster"
  filter_pattern  = ""
  destination_arn = "arn:aws:logs:ap-southeast-2:079942904060:destination:WizEksLogsDestination-ap-southeast-2"
  role_arn        = "arn:aws:iam::079942904060:role/WizCloudWatchLogsSubscriptionRole"

  depends_on = [module.eks]
}