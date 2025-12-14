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

  azs            = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]
  public_subnets = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  # No private subnets needed for simple EC2 demo
  enable_nat_gateway = false

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Environment = "Demo"
    Project     = "React2Shell"
  }
}

# -----------------------------------------------------------------------------
# 4. SECURITY GROUP (EC2 ACCESS)
# -----------------------------------------------------------------------------
resource "aws_security_group" "demo_app" {
  name        = "wiz-demo-app-sg-${random_id.suffix.hex}"
  description = "Security group for vulnerable demo app"
  vpc_id      = module.vpc.vpc_id

  # SSH access
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access (port 80)
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # App access (port 3000)
  ingress {
    description = "App"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "wiz-demo-app-sg"
    Environment = "Demo"
  }
}

# -----------------------------------------------------------------------------
# 5. IAM ROLE FOR EC2 (LATERAL MOVEMENT)
# -----------------------------------------------------------------------------
# INTENTIONAL VULNERABILITY: Over-permissive IAM role
resource "aws_iam_role" "demo_ec2" {
  name = "wiz-demo-ec2-role-${random_id.suffix.hex}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Environment   = "Demo"
    Vulnerability = "OverPermissive"
  }
}

resource "aws_iam_instance_profile" "demo_ec2" {
  name = "wiz-demo-ec2-profile-${random_id.suffix.hex}"
  role = aws_iam_role.demo_ec2.name
}

# S3 access policy - allows lateral movement to sensitive bucket
resource "aws_iam_policy" "ec2_s3_access" {
  name        = "wiz-demo-ec2-s3-access-${random_id.suffix.hex}"
  description = "Allow EC2 to read sensitive S3 bucket (intentionally over-permissive)"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:ListAllMyBuckets"
        ]
        Effect = "Allow"
        Resource = [
          aws_s3_bucket.sensitive_data.arn,
          "${aws_s3_bucket.sensitive_data.arn}/*",
          "arn:aws:s3:::*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_s3_access" {
  policy_arn = aws_iam_policy.ec2_s3_access.arn
  role       = aws_iam_role.demo_ec2.name
}

# ECR access for pulling container images
resource "aws_iam_role_policy_attachment" "ec2_ecr_access" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.demo_ec2.name
}

# SSM access for optional Session Manager
resource "aws_iam_role_policy_attachment" "ec2_ssm_access" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.demo_ec2.name
}

# -----------------------------------------------------------------------------
# 6. EC2 INSTANCE (VULNERABLE APP HOST)
# -----------------------------------------------------------------------------
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "demo_app" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.ec2_instance_type
  subnet_id              = module.vpc.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.demo_app.id]
  iam_instance_profile   = aws_iam_instance_profile.demo_ec2.name
  key_name               = var.ssh_key_name

  associate_public_ip_address = true

  # INTENTIONAL VULNERABILITY: IMDSv1 enabled for credential theft demo
  # - http_tokens = "optional" allows IMDSv1 (no token required)
  # - hop_limit = 2 allows Docker containers to reach IMDS
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "optional"
    http_put_response_hop_limit = 2
  }

  # User data script to install Docker (image pulled manually after ECR push)
  user_data = <<-EOF
    #!/bin/bash
    set -e

    # Install Docker and AWS CLI
    dnf install -y docker aws-cli
    systemctl enable docker
    systemctl start docker

    # Add ec2-user to docker group for easier management
    usermod -aG docker ec2-user

    # Create helper script for pulling and running the app
    cat > /home/ec2-user/start-demo.sh << 'SCRIPT'
    #!/bin/bash
    ECR_URL="${aws_ecr_repository.app_repo.repository_url}"
    aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin $ECR_URL
    docker pull $ECR_URL:latest
    docker run -d --restart=always -p 3000:3000 --name wiz-demo $ECR_URL:latest
    echo "Demo app started at http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):3000"
    SCRIPT
    chmod +x /home/ec2-user/start-demo.sh
    chown ec2-user:ec2-user /home/ec2-user/start-demo.sh

    echo "Docker installed. Run ~/start-demo.sh after pushing image to ECR" > /tmp/setup-complete.txt
  EOF

  tags = {
    Name        = "wiz-rsc-demo-${random_id.suffix.hex}"
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

# Fake Sensitive Data Objects
resource "aws_s3_object" "employees" {
  bucket = aws_s3_bucket.sensitive_data.id
  key    = "employees.json"
  content = jsonencode([
    { id = 1, name = "Alice Admin", role = "SuperAdmin", salary = 150000 },
    { id = 2, name = "Bob Builder", role = "Engineer", salary = 120000 },
    { id = 3, name = "Charlie Chief", role = "CEO", salary = 300000 }
  ])
  content_type = "application/json"
}

resource "aws_s3_object" "secret_roadmap" {
  bucket       = aws_s3_bucket.sensitive_data.id
  key          = "roadmap_2025_confidential.txt"
  content      = "1. Launch RCE exploit as a feature.\n2. Buy more crypto.\n3. Take over the world."
  content_type = "text/plain"
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
