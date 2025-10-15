#!/bin/bash

# Cleanup script for EKS resources
# This script helps clean up AWS and Kubernetes resources

set -euo pipefail

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Configuration
CLUSTER_NAME="${CLUSTER_NAME:-java-microservice-eks}"
AWS_REGION="${AWS_REGION:-us-east-1}"
APP_NAME="java-microservice"

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "\n${PURPLE}📋 $1${NC}"
    echo "$(echo "$1" | sed 's/./=/g')"
}

# Function to confirm action
confirm_action() {
    local message="$1"
    read -p "$(echo -e "${YELLOW}⚠️  ${message} (y/N): ${NC}")" -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Operation cancelled"
        return 1
    fi
    return 0
}

# Function to cleanup applications
cleanup_applications() {
    print_header "Cleaning up Applications"
    
    local environments=("development" "staging" "production")
    
    for env in "${environments[@]}"; do
        print_status "Checking environment: ${env}"
        
        # Check if namespace exists
        if kubectl get namespace "${env}" &> /dev/null; then
            if confirm_action "Delete all resources in ${env} namespace?"; then
                
                # Delete Helm releases
                print_status "Deleting Helm releases in ${env}..."
                helm list -n "${env}" --short | xargs -r helm uninstall -n "${env}"
                
                # Delete ArgoCD applications
                if kubectl get namespace argocd &> /dev/null; then
                    print_status "Deleting ArgoCD applications for ${env}..."
                    kubectl delete application "${APP_NAME}-${env}" -n argocd --ignore-not-found
                fi
                
                # Delete namespace
                kubectl delete namespace "${env}" --ignore-not-found
                print_status "✅ Environment ${env} cleaned up"
            fi
        else
            print_status "Environment ${env} not found, skipping"
        fi
    done
}

# Function to cleanup ECR repositories
cleanup_ecr() {
    print_header "Cleaning up ECR Repositories"
    
    local environments=("development" "staging" "production")
    
    for env in "${environments[@]}"; do
        local repo_name="${APP_NAME}-${env}"
        
        # Check if repository exists
        if aws ecr describe-repositories --repository-names "${repo_name}" --region "${AWS_REGION}" &> /dev/null; then
            if confirm_action "Delete ECR repository ${repo_name}?"; then
                print_status "Deleting ECR repository: ${repo_name}"
                
                # Delete all images first
                aws ecr list-images --repository-name "${repo_name}" --region "${AWS_REGION}" \
                    --query 'imageIds[*]' --output json | \
                    jq '.[] | select(.imageTag != null)' | \
                    aws ecr batch-delete-image --repository-name "${repo_name}" \
                    --region "${AWS_REGION}" --image-ids file:///dev/stdin || true
                
                # Delete repository
                aws ecr delete-repository --repository-name "${repo_name}" --region "${AWS_REGION}" --force
                print_status "✅ ECR repository ${repo_name} deleted"
            fi
        else
            print_status "ECR repository ${repo_name} not found, skipping"
        fi
    done
}

# Function to cleanup EKS cluster
cleanup_eks_cluster() {
    print_header "Cleaning up EKS Cluster"
    
    # Check if cluster exists
    if aws eks describe-cluster --name "${CLUSTER_NAME}" --region "${AWS_REGION}" &> /dev/null; then
        if confirm_action "Delete EKS cluster ${CLUSTER_NAME}? This will delete ALL resources in the cluster!"; then
            print_status "Deleting EKS cluster: ${CLUSTER_NAME}"
            
            # Delete cluster (this will also delete node groups)
            aws eks delete-cluster --name "${CLUSTER_NAME}" --region "${AWS_REGION}"
            
            print_status "⏳ Waiting for cluster deletion (this may take 10-15 minutes)..."
            aws eks wait cluster-deleted --name "${CLUSTER_NAME}" --region "${AWS_REGION}"
            
            print_status "✅ EKS cluster ${CLUSTER_NAME} deleted"
        fi
    else
        print_status "EKS cluster ${CLUSTER_NAME} not found, skipping"
    fi
}

# Function to cleanup IAM roles
cleanup_iam_roles() {
    print_header "Cleaning up IAM Roles"
    
    local roles=(
        "${CLUSTER_NAME}-cluster-role"
        "${CLUSTER_NAME}-nodegroup-role"
        "${CLUSTER_NAME}-efs-csi-role"
        "${CLUSTER_NAME}-ebs-csi-role"
        "${CLUSTER_NAME}-alb-controller-role"
        "${CLUSTER_NAME}-external-dns-role"
    )
    
    for role in "${roles[@]}"; do
        # Check if role exists
        if aws iam get-role --role-name "${role}" &> /dev/null; then
            if confirm_action "Delete IAM role ${role}?"; then
                print_status "Deleting IAM role: ${role}"
                
                # Detach policies
                aws iam list-attached-role-policies --role-name "${role}" --query 'AttachedPolicies[*].PolicyArn' --output text | \
                    xargs -r -n1 aws iam detach-role-policy --role-name "${role}" --policy-arn
                
                # Delete role
                aws iam delete-role --role-name "${role}"
                print_status "✅ IAM role ${role} deleted"
            fi
        else
            print_status "IAM role ${role} not found, skipping"
        fi
    done
}

# Function to cleanup VPC resources (if created by this project)
cleanup_vpc_resources() {
    print_header "Cleaning up VPC Resources"
    
    print_warning "VPC cleanup should be done carefully to avoid affecting other resources"
    print_warning "This function will only clean up resources tagged with the cluster name"
    
    if confirm_action "Proceed with VPC resource cleanup?"; then
        
        # Find VPC by cluster tag
        local vpc_id=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=${CLUSTER_NAME}-vpc" --query 'Vpcs[0].VpcId' --output text --region "${AWS_REGION}")
        
        if [[ "${vpc_id}" != "None" && -n "${vpc_id}" ]]; then
            print_status "Found VPC: ${vpc_id}"
            
            # Delete NAT Gateways
            print_status "Deleting NAT Gateways..."
            aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=${vpc_id}" --query 'NatGateways[*].NatGatewayId' --output text --region "${AWS_REGION}" | \
                xargs -r -n1 aws ec2 delete-nat-gateway --nat-gateway-id --region "${AWS_REGION}"
            
            # Delete Internet Gateway
            print_status "Deleting Internet Gateway..."
            local igw_id=$(aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=${vpc_id}" --query 'InternetGateways[0].InternetGatewayId' --output text --region "${AWS_REGION}")
            if [[ "${igw_id}" != "None" && -n "${igw_id}" ]]; then
                aws ec2 detach-internet-gateway --internet-gateway-id "${igw_id}" --vpc-id "${vpc_id}" --region "${AWS_REGION}"
                aws ec2 delete-internet-gateway --internet-gateway-id "${igw_id}" --region "${AWS_REGION}"
            fi
            
            # Delete subnets
            print_status "Deleting subnets..."
            aws ec2 describe-subnets --filters "Name=vpc-id,Values=${vpc_id}" --query 'Subnets[*].SubnetId' --output text --region "${AWS_REGION}" | \
                xargs -r -n1 aws ec2 delete-subnet --subnet-id --region "${AWS_REGION}"
            
            # Delete security groups (except default)
            print_status "Deleting security groups..."
            aws ec2 describe-security-groups --filters "Name=vpc-id,Values=${vpc_id}" --query 'SecurityGroups[?GroupName!=`default`].GroupId' --output text --region "${AWS_REGION}" | \
                xargs -r -n1 aws ec2 delete-security-group --group-id --region "${AWS_REGION}"
            
            # Delete VPC
            print_status "Deleting VPC..."
            aws ec2 delete-vpc --vpc-id "${vpc_id}" --region "${AWS_REGION}"
            
            print_status "✅ VPC resources cleaned up"
        else
            print_status "VPC not found or not created by this project"
        fi
    fi
}

# Function to cleanup local resources
cleanup_local_resources() {
    print_header "Cleaning up Local Resources"
    
    # Remove kubeconfig
    if confirm_action "Remove kubeconfig for cluster ${CLUSTER_NAME}?"; then
        kubectl config delete-context "arn:aws:eks:${AWS_REGION}:$(aws sts get-caller-identity --query Account --output text):cluster/${CLUSTER_NAME}" || true
        kubectl config delete-cluster "arn:aws:eks:${AWS_REGION}:$(aws sts get-caller-identity --query Account --output text):cluster/${CLUSTER_NAME}" || true
        print_status "✅ Kubeconfig entries removed"
    fi
    
    # Remove Docker images
    if confirm_action "Remove local Docker images for ${APP_NAME}?"; then
        docker images --format "table {{.Repository}}:{{.Tag}}" | grep "${APP_NAME}" | awk '{print $1}' | xargs -r docker rmi -f || true
        print_status "✅ Local Docker images removed"
    fi
}

# Function to display cleanup summary
display_cleanup_summary() {
    print_header "Cleanup Summary"
    
    echo "🧹 Resources that were processed:"
    echo "  • Kubernetes applications and namespaces"
    echo "  • ECR repositories"
    echo "  • EKS cluster and node groups"
    echo "  • IAM roles and policies"
    echo "  • VPC resources (if tagged with cluster)"
    echo "  • Local kubeconfig and Docker images"
    echo ""
    
    echo "📋 Verification Commands:"
    echo "  • Check EKS clusters: aws eks list-clusters --region ${AWS_REGION}"
    echo "  • Check ECR repos: aws ecr describe-repositories --region ${AWS_REGION}"
    echo "  • Check IAM roles: aws iam list-roles --query 'Roles[?contains(RoleName, \`${CLUSTER_NAME}\`)].RoleName'"
    echo "  • Check VPCs: aws ec2 describe-vpcs --filters Name=tag:Name,Values=${CLUSTER_NAME}-vpc --region ${AWS_REGION}"
}

# Main execution
main() {
    print_header "EKS Cleanup Script"
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --cluster-name)
                CLUSTER_NAME="$2"
                shift 2
                ;;
            --region)
                AWS_REGION="$2"
                shift 2
                ;;
            --apps-only)
                APPS_ONLY=true
                shift
                ;;
            --full-cleanup)
                FULL_CLEANUP=true
                shift
                ;;
            -h|--help)
                echo "Usage: $0 [OPTIONS]"
                echo "Options:"
                echo "  --cluster-name NAME     EKS cluster name"
                echo "  --region REGION         AWS region"
                echo "  --apps-only             Only cleanup applications, not infrastructure"
                echo "  --full-cleanup          Full cleanup including VPC resources"
                echo "  -h, --help              Show this help message"
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    print_status "Cluster: ${CLUSTER_NAME}"
    print_status "Region: ${AWS_REGION}"
    echo ""
    
    print_warning "This script will delete AWS resources which may incur costs or affect other workloads"
    print_warning "Please review each step carefully before confirming"
    echo ""
    
    if [[ "${APPS_ONLY:-false}" == "true" ]]; then
        cleanup_applications
        cleanup_local_resources
    else
        cleanup_applications
        cleanup_ecr
        
        if [[ "${FULL_CLEANUP:-false}" == "true" ]]; then
            cleanup_eks_cluster
            cleanup_iam_roles
            cleanup_vpc_resources
        else
            if confirm_action "Proceed with infrastructure cleanup (EKS cluster, IAM roles)?"; then
                cleanup_eks_cluster
                cleanup_iam_roles
            fi
        fi
        
        cleanup_local_resources
    fi
    
    display_cleanup_summary
    
    print_status "✅ Cleanup completed!"
}

# Execute main function
main "$@"