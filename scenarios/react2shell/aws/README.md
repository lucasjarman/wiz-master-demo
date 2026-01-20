# React2Shell RCE Demo Scenario

## Overview

This scenario demonstrates **CVE-2025-66478**, a critical Remote Code Execution (RCE) vulnerability in React Server Components that allows attackers to execute arbitrary shell commands through specially crafted input.

## Vulnerability Description

The React2Shell vulnerability exploits improper input sanitization in React Server Components, allowing an attacker to inject and execute shell commands on the server. When user input is passed to server-side rendering functions without adequate validation, malicious payloads can escape the intended context and execute arbitrary commands.

## Attack Path

1. **Initial Access**: Attacker sends crafted HTTP request to the vulnerable React application
2. **Code Execution**: Malicious payload triggers shell command execution via RSC
3. **Credential Discovery**: Attacker uses RCE to access AWS IRSA credentials from pod metadata
4. **Data Exfiltration**: Attacker uses stolen credentials to access S3 bucket containing sensitive data

## Infrastructure Components

This Terraform configuration creates:

- **S3 Bucket**: Contains "sensitive" demo data accessible via the vulnerable application
- **IRSA Role**: IAM role with S3 permissions, assumable by the Kubernetes service account
- **K8s Deployment**: Vulnerable React application deployed to EKS cluster
- **Network Load Balancer**: External access to the vulnerable application

## Usage

```bash
# Initialize Terraform
terraform init

# Plan changes
terraform plan

# Apply configuration
terraform apply
```

## Wiz Detection

After deployment, Wiz will detect:

- Attack path from internet-exposed application to sensitive S3 data
- Overly permissive IRSA role permissions
- Container running with known vulnerable dependencies
- Potential for lateral movement via compromised credentials

