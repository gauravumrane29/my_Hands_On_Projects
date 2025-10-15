#!/bin/bash

# Amazon EKS Cluster Setup Script
# This script creates and configures an EKS cluster with all necessary components

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
CLUSTER_NAME="${CLUSTER_NAME:-java-microservice-eks}"
AWS_REGION="${AWS_REGION:-us-east-1}"
NODE_GROUP_NAME="${NODE_GROUP_NAME:-java-microservice-nodes}"
KUBERNETES_VERSION="${KUBERNETES_VERSION:-1.28}"
INSTANCE_TYPES="${INSTANCE_TYPES:-t3.medium,t3.large}"
MIN_NODES="${MIN_NODES:-2}"
MAX_NODES="${MAX_NODES:-10}"
DESIRED_NODES="${DESIRED_NODES:-3}"

echo -e "${BLUE}🚀 Amazon EKS Cluster Setup${NC}"
echo "============================"

# Function to print colored output
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

# Function to check prerequisites
check_prerequisites() {
    print_header "Checking Prerequisites"
    
    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is required but not installed"
        print_status "Install AWS CLI: https://aws.amazon.com/cli/"
        exit 1
    fi
    
    # Check eksctl
    if ! command -v eksctl &> /dev/null; then
        print_error "eksctl is required but not installed"
        print_status "Install eksctl: https://eksctl.io/installation/"
        exit 1
    fi
    
    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is required but not installed"
        print_status "Install kubectl: https://kubernetes.io/docs/tasks/tools/"
        exit 1
    fi
    
    # Check Helm
    if ! command -v helm &> /dev/null; then
        print_error "Helm is required but not installed"
        print_status "Install Helm: https://helm.sh/docs/intro/install/"
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials not configured"
        print_status "Run 'aws configure' to set up credentials"
        exit 1
    fi
    
    print_status "✅ Prerequisites check passed"
}

# Function to create EKS cluster
create_eks_cluster() {
    print_header "Creating EKS Cluster"
    
    # Check if cluster already exists
    if eksctl get cluster --name="${CLUSTER_NAME}" --region="${AWS_REGION}" &> /dev/null; then
        print_warning "Cluster ${CLUSTER_NAME} already exists"
        return 0
    fi
    
    # Create cluster configuration
    cat > cluster-config.yaml << EOF
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: ${CLUSTER_NAME}
  region: ${AWS_REGION}
  version: "${KUBERNETES_VERSION}"
  tags:
    Project: java-microservice
    Environment: multi-environment
    CreatedBy: eksctl
    ManagedBy: devops-team

# IAM configuration
iam:
  withOIDC: true
  serviceAccounts:
    - metadata:
        name: aws-load-balancer-controller
        namespace: kube-system
      wellKnownPolicies:
        awsLoadBalancerController: true
    - metadata:
        name: ebs-csi-controller-sa
        namespace: kube-system
      wellKnownPolicies:
        ebsCSIController: true
    - metadata:
        name: efs-csi-controller-sa
        namespace: kube-system
      wellKnownPolicies:
        efsCSIController: true
    - metadata:
        name: external-dns
        namespace: kube-system
      wellKnownPolicies:
        externalDNS: true
    - metadata:
        name: cert-manager
        namespace: cert-manager
      wellKnownPolicies:
        certManager: true
    - metadata:
        name: cluster-autoscaler
        namespace: kube-system
      wellKnownPolicies:
        autoScaling: true

# VPC configuration
vpc:
  enableDnsHostnames: true
  enableDnsSupport: true
  publicAccessCIDRs: ["0.0.0.0/0"]
  clusterEndpoints:
    privateAccess: true
    publicAccess: true

# Managed node groups
managedNodeGroups:
  # Production node group
  - name: production-nodes
    instanceTypes: [${INSTANCE_TYPES}]
    minSize: ${MIN_NODES}
    maxSize: ${MAX_NODES}
    desiredCapacity: ${DESIRED_NODES}
    volumeSize: 100
    volumeType: gp3
    amiFamily: AmazonLinux2
    ssh:
      allow: true
    labels:
      node-type: production
      workload-type: application
    tags:
      k8s.io/cluster-autoscaler/enabled: "true"
      k8s.io/cluster-autoscaler/${CLUSTER_NAME}: "owned"
      NodeGroup: production
    taints:
      - key: production-workload
        value: "true"
        effect: NoSchedule
    iam:
      attachPolicyARNs:
        - arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy
        - arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy
        - arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly
        - arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy

  # Development node group (smaller instances)
  - name: development-nodes
    instanceTypes: [t3.small, t3.medium]
    minSize: 1
    maxSize: 5
    desiredCapacity: 2
    volumeSize: 50
    volumeType: gp3
    amiFamily: AmazonLinux2
    ssh:
      allow: true
    labels:
      node-type: development
      workload-type: development
    tags:
      k8s.io/cluster-autoscaler/enabled: "true"
      k8s.io/cluster-autoscaler/${CLUSTER_NAME}: "owned"
      NodeGroup: development
    iam:
      attachPolicyARNs:
        - arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy
        - arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy
        - arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly

# Add-ons
addons:
  - name: vpc-cni
    version: latest
  - name: coredns
    version: latest
  - name: kube-proxy
    version: latest
  - name: aws-ebs-csi-driver
    version: latest

# CloudWatch logging
cloudWatch:
  clusterLogging:
    enable: ["api", "audit", "authenticator", "controllerManager", "scheduler"]
    logRetentionInDays: 30
EOF

    print_status "Creating EKS cluster ${CLUSTER_NAME}..."
    print_status "This may take 15-20 minutes..."
    
    eksctl create cluster -f cluster-config.yaml
    
    print_status "✅ EKS cluster created successfully"
    
    # Update kubeconfig
    aws eks update-kubeconfig --region "${AWS_REGION}" --name "${CLUSTER_NAME}"
    
    print_status "✅ Kubeconfig updated"
}

# Function to install AWS Load Balancer Controller
install_alb_controller() {
    print_header "Installing AWS Load Balancer Controller"
    
    # Add EKS Helm repository
    helm repo add eks https://aws.github.io/eks-charts
    helm repo update
    
    # Install AWS Load Balancer Controller
    helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
        -n kube-system \
        --set clusterName="${CLUSTER_NAME}" \
        --set serviceAccount.create=false \
        --set serviceAccount.name=aws-load-balancer-controller \
        --set region="${AWS_REGION}" \
        --set vpcId=$(aws eks describe-cluster --name "${CLUSTER_NAME}" --region "${AWS_REGION}" --query "cluster.resourcesVpcConfig.vpcId" --output text)
    
    print_status "✅ AWS Load Balancer Controller installed"
}

# Function to install cluster autoscaler
install_cluster_autoscaler() {
    print_header "Installing Cluster Autoscaler"
    
    # Download cluster autoscaler manifest
    curl -o cluster-autoscaler-autodiscover.yaml https://raw.githubusercontent.com/kubernetes/autoscaler/master/cluster-autoscaler/cloudprovider/aws/examples/cluster-autoscaler-autodiscover.yaml
    
    # Update cluster name in manifest
    sed -i.bak "s/<YOUR CLUSTER NAME>/${CLUSTER_NAME}/g" cluster-autoscaler-autodiscover.yaml
    
    # Apply manifest
    kubectl apply -f cluster-autoscaler-autodiscover.yaml
    
    # Patch deployment to add service account annotation
    kubectl patch deployment cluster-autoscaler \
        -n kube-system \
        -p '{"spec":{"template":{"metadata":{"annotations":{"cluster-autoscaler.kubernetes.io/safe-to-evict":"false"}}}}}'
    
    # Add cluster-autoscaler.kubernetes.io/safe-to-evict annotation
    kubectl -n kube-system annotate deployment.apps/cluster-autoscaler cluster-autoscaler.kubernetes.io/safe-to-evict="false"
    
    print_status "✅ Cluster Autoscaler installed"
    
    # Cleanup
    rm -f cluster-autoscaler-autodiscover.yaml cluster-autoscaler-autodiscover.yaml.bak
}

# Function to install metrics server
install_metrics_server() {
    print_header "Installing Metrics Server"
    
    kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
    
    print_status "✅ Metrics Server installed"
}

# Function to create namespaces
create_namespaces() {
    print_header "Creating Application Namespaces"
    
    # Create namespaces with labels
    cat << EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: development
  labels:
    name: development
    environment: development
    project: java-microservice
---
apiVersion: v1
kind: Namespace
metadata:
  name: staging
  labels:
    name: staging
    environment: staging
    project: java-microservice
---
apiVersion: v1
kind: Namespace
metadata:
  name: production
  labels:
    name: production
    environment: production
    project: java-microservice
---
apiVersion: v1
kind: Namespace
metadata:
  name: monitoring
  labels:
    name: monitoring
    environment: shared
    project: java-microservice
EOF

    print_status "✅ Application namespaces created"
}

# Function to install ArgoCD
install_argocd() {
    print_header "Installing ArgoCD"
    
    # Create argocd namespace
    kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
    
    # Install ArgoCD
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    
    # Wait for ArgoCD to be ready
    kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
    
    # Get ArgoCD admin password
    ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
    
    print_status "✅ ArgoCD installed"
    print_status "ArgoCD admin password: ${ARGOCD_PASSWORD}"
    print_warning "Please save this password securely and change it after first login"
    
    # Create ArgoCD ingress
    cat << EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: argocd-server
  namespace: argocd
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS": 443}]'
    alb.ingress.kubernetes.io/ssl-redirect: "443"
    alb.ingress.kubernetes.io/backend-protocol: HTTPS
    alb.ingress.kubernetes.io/healthcheck-path: /healthz
spec:
  rules:
  - host: argocd.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: argocd-server
            port:
              number: 443
EOF
    
    print_status "✅ ArgoCD ingress created"
}

# Function to install Istio (optional)
install_istio() {
    print_header "Installing Istio Service Mesh"
    
    read -p "Do you want to install Istio service mesh? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_warning "Skipping Istio installation"
        return 0
    fi
    
    # Download Istio
    curl -L https://istio.io/downloadIstio | sh -
    
    # Move to PATH
    sudo mv istio-*/bin/istioctl /usr/local/bin/
    
    # Install Istio
    istioctl install --set values.defaultRevision=default -y
    
    # Enable sidecar injection for production namespace
    kubectl label namespace production istio-injection=enabled
    kubectl label namespace staging istio-injection=enabled
    
    # Install Istio ingress gateway
    kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.19/samples/addons/prometheus.yaml
    kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.19/samples/addons/grafana.yaml
    kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.19/samples/addons/jaeger.yaml
    kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.19/samples/addons/kiali.yaml
    
    print_status "✅ Istio installed with observability stack"
    
    # Cleanup
    rm -rf istio-*
}

# Function to setup monitoring
setup_monitoring() {
    print_header "Setting up Monitoring Stack"
    
    # Add Prometheus Helm repository
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo add grafana https://grafana.github.io/helm-charts
    helm repo update
    
    # Install Prometheus Operator
    helm upgrade --install prometheus-stack prometheus-community/kube-prometheus-stack \
        --namespace monitoring \
        --create-namespace \
        --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
        --set prometheus.prometheusSpec.podMonitorSelectorNilUsesHelmValues=false \
        --set grafana.adminPassword="admin123" \
        --set grafana.ingress.enabled=true \
        --set grafana.ingress.ingressClassName=alb \
        --set grafana.ingress.annotations."kubernetes\.io/ingress\.class"=alb \
        --set grafana.ingress.annotations."alb\.ingress\.kubernetes\.io/scheme"=internet-facing \
        --set grafana.ingress.annotations."alb\.ingress\.kubernetes\.io/target-type"=ip \
        --set grafana.ingress.hosts[0]=grafana.example.com \
        --wait
    
    print_status "✅ Prometheus and Grafana installed"
    print_status "Grafana admin password: admin123"
}

# Function to create ECR repositories
create_ecr_repositories() {
    print_header "Creating ECR Repositories"
    
    # Create ECR repository for each environment
    for env in dev staging prod; do
        repo_name="java-microservice-${env}"
        
        if aws ecr describe-repositories --repository-names "${repo_name}" --region "${AWS_REGION}" &> /dev/null; then
            print_warning "ECR repository ${repo_name} already exists"
        else
            aws ecr create-repository \
                --repository-name "${repo_name}" \
                --region "${AWS_REGION}" \
                --image-scanning-configuration scanOnPush=true \
                --encryption-configuration encryptionType=AES256
            
            print_status "✅ ECR repository ${repo_name} created"
        fi
    done
    
    # Set lifecycle policies
    for env in dev staging prod; do
        repo_name="java-microservice-${env}"
        
        aws ecr put-lifecycle-policy \
            --repository-name "${repo_name}" \
            --region "${AWS_REGION}" \
            --lifecycle-policy-text '{
                "rules": [
                    {
                        "rulePriority": 1,
                        "description": "Keep last 30 images",
                        "selection": {
                            "tagStatus": "any",
                            "countType": "imageCountMoreThan",
                            "countNumber": 30
                        },
                        "action": {
                            "type": "expire"
                        }
                    }
                ]
            }'
    done
    
    print_status "✅ ECR lifecycle policies configured"
}

# Function to display cluster information
display_cluster_info() {
    print_header "EKS Cluster Information"
    
    echo "📊 Cluster Details:"
    echo "  • Cluster Name: ${CLUSTER_NAME}"
    echo "  • Region: ${AWS_REGION}"
    echo "  • Kubernetes Version: ${KUBERNETES_VERSION}"
    echo "  • Node Groups: production-nodes, development-nodes"
    echo ""
    
    echo "🔗 Service URLs (after DNS configuration):"
    echo "  • ArgoCD: https://argocd.example.com"
    echo "  • Grafana: https://grafana.example.com"
    echo "  • Application (Dev): https://java-microservice-dev.example.com"
    echo "  • Application (Staging): https://java-microservice-staging.example.com"
    echo "  • Application (Prod): https://java-microservice.example.com"
    echo ""
    
    echo "🔐 Access Information:"
    echo "  • ArgoCD admin password: ${ARGOCD_PASSWORD:-'Run: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath=\"{.data.password}\" | base64 -d'}"
    echo "  • Grafana admin password: admin123"
    echo ""
    
    echo "📋 Useful Commands:"
    echo "  • View cluster: kubectl cluster-info"
    echo "  • View nodes: kubectl get nodes"
    echo "  • View namespaces: kubectl get namespaces"
    echo "  • Port forward ArgoCD: kubectl port-forward svc/argocd-server -n argocd 8080:443"
    echo "  • Port forward Grafana: kubectl port-forward svc/prometheus-stack-grafana -n monitoring 3000:80"
    echo ""
    
    echo "🚀 Next Steps:"
    echo "  1. Configure DNS for service hostnames"
    echo "  2. Set up TLS certificates"
    echo "  3. Deploy applications using ArgoCD"
    echo "  4. Configure monitoring dashboards"
    echo "  5. Set up CI/CD pipelines to push to ECR"
}

# Main execution flow
main() {
    print_header "Amazon EKS Setup for Java Microservice"
    
    check_prerequisites
    
    # Confirm cluster creation
    echo ""
    echo "🔧 Cluster Configuration:"
    echo "  • Name: ${CLUSTER_NAME}"
    echo "  • Region: ${AWS_REGION}"
    echo "  • Kubernetes Version: ${KUBERNETES_VERSION}"
    echo "  • Node Instance Types: ${INSTANCE_TYPES}"
    echo "  • Node Count: ${MIN_NODES}-${MAX_NODES} (desired: ${DESIRED_NODES})"
    echo ""
    
    read -p "Do you want to proceed with cluster creation? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_warning "Cluster creation cancelled"
        exit 0
    fi
    
    # Execute setup steps
    create_eks_cluster
    create_namespaces
    install_alb_controller
    install_cluster_autoscaler
    install_metrics_server
    create_ecr_repositories
    install_argocd
    setup_monitoring
    install_istio
    
    display_cluster_info
    
    print_status "✅ EKS cluster setup completed successfully!"
    print_warning "⚠️ Don't forget to configure DNS and TLS certificates for production use"
}

# Execute main function
main "$@"