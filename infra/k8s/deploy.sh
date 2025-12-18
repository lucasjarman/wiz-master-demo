#!/bin/bash
#
# Deploy Wiz RSC Demo to EKS
# Usage: ./deploy.sh
#
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TF_DIR="$REPO_ROOT/infra/aws"
APP_DIR="$REPO_ROOT/app/nextjs"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  Wiz RSC Demo - EKS Deployment${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo ""

# Get Terraform outputs
echo -e "${YELLOW}[1/5] Getting Terraform outputs...${NC}"
cd "$TF_DIR"
ECR_URL=$(terraform output -raw ecr_repository_url 2>/dev/null || echo "")
AWS_REGION=$(terraform output -raw aws_region 2>/dev/null || echo "ap-southeast-2")
EKS_CLUSTER=$(terraform output -raw eks_cluster_name 2>/dev/null || echo "")

if [ -z "$ECR_URL" ]; then
    echo -e "${RED}Error: Could not get ECR URL from Terraform. Run 'terraform apply' first.${NC}"
    exit 1
fi

if [ -z "$EKS_CLUSTER" ]; then
    echo -e "${RED}Error: EKS cluster not found. Make sure enable_eks=true in terraform.tfvars${NC}"
    exit 1
fi

echo -e "  ECR: ${GREEN}$ECR_URL${NC}"
echo -e "  EKS: ${GREEN}$EKS_CLUSTER${NC}"
echo -e "  Region: ${GREEN}$AWS_REGION${NC}"
echo ""

# Build and push Docker image
echo -e "${YELLOW}[2/5] Building Docker image...${NC}"
cd "$APP_DIR"
docker build --platform linux/amd64 -t wiz-rsc-demo:latest .
echo ""

echo -e "${YELLOW}[3/5] Pushing to ECR...${NC}"
aws ecr get-login-password --region "$AWS_REGION" --profile wiz-demo | docker login --username AWS --password-stdin "$ECR_URL"
docker tag wiz-rsc-demo:latest "$ECR_URL:latest"
docker push "$ECR_URL:latest"
echo ""

# Update kubeconfig
echo -e "${YELLOW}[4/5] Configuring kubectl...${NC}"
aws eks update-kubeconfig --name "$EKS_CLUSTER" --region "$AWS_REGION" --profile wiz-demo
echo ""

# Deploy to Kubernetes
echo -e "${YELLOW}[5/5] Deploying to EKS...${NC}"
cd "$SCRIPT_DIR"

# Create namespace if not exists
kubectl apply -f deployment.yaml

# Inject ECR URL into deployment and apply
sed "s|IMAGE_PLACEHOLDER|$ECR_URL:latest|g" deployment.yaml | kubectl apply -f -

# Apply service
kubectl apply -f service.yaml
kubectl apply -f rbac.yaml

echo "Waiting for LoadBalancer IP..."
kubectl rollout status deployment/wiz-rsc-demo -n wiz-demo --timeout=120s

# Get Load Balancer URL
echo ""
echo -e "${YELLOW}Waiting for Load Balancer...${NC}"
sleep 10
LB_URL=$(kubectl get svc wiz-rsc-demo -n wiz-demo -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "pending")

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  Deployment Complete!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "  App URL: ${CYAN}http://$LB_URL${NC}"
echo ""
echo -e "  ${YELLOW}Note: NLB DNS may take 2-3 minutes to propagate${NC}"
echo ""
echo -e "  Run exploit:"
echo -e "  ${CYAN}./wiz-demo.sh $LB_URL 80${NC}"
echo ""

