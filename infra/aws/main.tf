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
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--profile", var.aws_profile]
  }
}

# -----------------------------------------------------------------------------
# 1. SETUP & RANDOMIZATION
# -----------------------------------------------------------------------------
# Random string for unique naming (e.g. s3 buckets)
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
  # Fake AWS Access Key (matches regex but invalid)
  fake_aws_key_id     = "AKIAIOSFODNN7EXAMPLE"
  fake_aws_secret_key = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
}

# -----------------------------------------------------------------------------
# 3. VPC (NETWORK)
# -----------------------------------------------------------------------------
# Using upstream module for best practice base
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "wiz-rsc-demo-vpc-${random_id.suffix.hex}"
  cidr = "10.0.0.0/16"

  azs             = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true # Save costs for demo

  enable_dns_hostnames = true
  enable_dns_support   = true

  # Tagging for Wiz Context
  tags = {
    Environment = "Demo"
    Project     = "React2Shell"
  }
}

# -----------------------------------------------------------------------------
# 5. VULNERABLE S3 BUCKET (SENSITIVE DATA)
# -----------------------------------------------------------------------------
# INTENTIONAL VULNERABILITY: Public S3 Bucket containing "sensitive" data.
resource "aws_s3_bucket" "sensitive_data" {
  bucket = "wiz-demo-sensitive-data-${random_id.suffix.hex}"

  # Force destroy to make teardown easy
  force_destroy = true

  tags = {
    Name        = "Sensitive Data Bucket"
    Environment = "Demo"
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

# Fake Sensitive Data Objects
resource "aws_s3_object" "employees" {
  bucket  = aws_s3_bucket.sensitive_data.id
  key     = "employees.json"
  content = jsonencode([
    { id = 1, name = "Alice Admin", role = "SuperAdmin", salary = 150000 },
    { id = 2, name = "Bob Builder", role = "Engineer", salary = 120000 },
    { id = 3, name = "Charlie Chief", role = "CEO", salary = 300000 }
  ])
  content_type = "application/json"
}

resource "aws_s3_object" "secret_roadmap" {
  bucket  = aws_s3_bucket.sensitive_data.id
  key     = "roadmap_2025_confidential.txt"
  content = "1. Launch RCE exploit as a feature.\n2. Buy more crypto.\n3. Take over the world."
  content_type = "text/plain"
}

# -----------------------------------------------------------------------------
# 6. IAM PERMISSIONS (LATERAL MOVEMENT)
# -----------------------------------------------------------------------------
# Allow the EKS Nodes to List/Get this bucket (simulating over-permission)
resource "aws_iam_policy" "node_s3_access" {
  name        = "wiz-demo-node-s3-access-${random_id.suffix.hex}"
  description = "Allow EKS nodes to read sensitive S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:ListBucket",
          "s3:GetObject"
        ]
        Effect   = "Allow"
        Resource = [
          aws_s3_bucket.sensitive_data.arn,
          "${aws_s3_bucket.sensitive_data.arn}/*"
        ]
      }
    ]
  })
}

# Attach to the EKS Managed Node Group Role
resource "aws_iam_role_policy_attachment" "node_s3_access" {
  policy_arn = aws_iam_policy.node_s3_access.arn
  role       = module.eks.eks_managed_node_groups["demo_nodes"].iam_role_name
}

# -----------------------------------------------------------------------------
# 7. ECR REPOSITORY
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
