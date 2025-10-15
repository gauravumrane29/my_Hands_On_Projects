#!/bin/bash

# Application Deployment Script for EKS
# Deploys the Java microservice to EKS using Helm and ArgoCD

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
IMAGE_TAG="${IMAGE_TAG:-latest}"
ENVIRONMENT="${ENVIRONMENT:-development}"

# AWS Account ID (will be retrieved)
AWS_ACCOUNT_ID=""

echo -e "${BLUE}🚀 Java Microservice Deployment to EKS${NC}"
echo "==========================================="

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
    
    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is required but not installed"
        exit 1
    fi
    
    # Check helm
    if ! command -v helm &> /dev/null; then
        print_error "helm is required but not installed"
        exit 1
    fi
    
    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is required but not installed"
        exit 1
    fi
    
    # Check cluster connectivity
    if ! kubectl cluster-info &> /dev/null; then
        print_error "Cannot connect to Kubernetes cluster"
        print_status "Make sure you have the correct kubeconfig"
        exit 1
    fi
    
    # Get AWS Account ID
    AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    print_status "✅ Prerequisites check passed (Account: ${AWS_ACCOUNT_ID})"
}

# Function to build and push Docker image
build_and_push_image() {
    print_header "Building and Pushing Docker Image"
    
    local ecr_repo="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
    local image_name="${ecr_repo}/${APP_NAME}-${ENVIRONMENT}:${IMAGE_TAG}"
    
    # Change to app directory
    cd app
    
    # Build Docker image
    print_status "Building Docker image..."
    docker build -t "${APP_NAME}:${IMAGE_TAG}" .
    
    # Tag for ECR
    docker tag "${APP_NAME}:${IMAGE_TAG}" "${image_name}"
    
    # Login to ECR
    print_status "Logging into ECR..."
    aws ecr get-login-password --region "${AWS_REGION}" | docker login --username AWS --password-stdin "${ecr_repo}"
    
    # Push image
    print_status "Pushing image to ECR..."
    docker push "${image_name}"
    
    print_status "✅ Image pushed: ${image_name}"
    
    # Set environment variable for Helm
    export ECR_IMAGE="${image_name}"
    
    cd ..
}

# Function to deploy with Helm
deploy_with_helm() {
    print_header "Deploying with Helm"
    
    local namespace="${ENVIRONMENT}"
    local values_file="deployment/helm/${APP_NAME}/values-${ENVIRONMENT}.yaml"
    
    # Check if values file exists
    if [[ ! -f "${values_file}" ]]; then
        print_warning "Values file ${values_file} not found, using default values.yaml"
        values_file="deployment/helm/${APP_NAME}/values.yaml"
    fi
    
    # Create namespace if it doesn't exist
    kubectl create namespace "${namespace}" --dry-run=client -o yaml | kubectl apply -f -
    
    # Deploy with Helm
    print_status "Deploying ${APP_NAME} to ${namespace} namespace..."
    
    helm upgrade --install "${APP_NAME}-${ENVIRONMENT}" \
        "deployment/helm/${APP_NAME}" \
        --namespace "${namespace}" \
        --values "${values_file}" \
        --set image.repository="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${APP_NAME}-${ENVIRONMENT}" \
        --set image.tag="${IMAGE_TAG}" \
        --set ecr.accountId="${AWS_ACCOUNT_ID}" \
        --set ecr.region="${AWS_REGION}" \
        --wait \
        --timeout=10m
    
    print_status "✅ Helm deployment completed"
}

# Function to deploy with ArgoCD
deploy_with_argocd() {
    print_header "Deploying with ArgoCD"
    
    # Check if ArgoCD is available
    if ! kubectl get namespace argocd &> /dev/null; then
        print_warning "ArgoCD not installed, skipping ArgoCD deployment"
        return 0
    fi
    
    # Apply ArgoCD application
    print_status "Creating ArgoCD application..."
    
    # Update application manifest with current image tag
    cat > "deployment/argo/application-${ENVIRONMENT}.yaml" << EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ${APP_NAME}-${ENVIRONMENT}
  namespace: argocd
  labels:
    app.kubernetes.io/name: ${APP_NAME}
    app.kubernetes.io/instance: ${APP_NAME}-${ENVIRONMENT}
    environment: ${ENVIRONMENT}
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  
  source:
    repoURL: https://github.com/your-org/devops-project.git
    targetRevision: main
    path: deployment/helm/${APP_NAME}
    helm:
      releaseName: ${APP_NAME}-${ENVIRONMENT}
      valueFiles:
        - values.yaml
        - values-${ENVIRONMENT}.yaml
      parameters:
        - name: image.tag
          value: "${IMAGE_TAG}"
        - name: ecr.accountId
          value: "${AWS_ACCOUNT_ID}"
        - name: ecr.region
          value: "${AWS_REGION}"
  
  destination:
    server: https://kubernetes.default.svc
    namespace: ${ENVIRONMENT}
  
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
  
  revisionHistoryLimit: 10
EOF

    # Apply the application
    kubectl apply -f "deployment/argo/application-${ENVIRONMENT}.yaml"
    
    print_status "✅ ArgoCD application created"
    
    # Wait for sync (optional)
    read -p "Wait for ArgoCD to sync the application? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Waiting for ArgoCD sync..."
        
        # Install argocd CLI if not present
        if ! command -v argocd &> /dev/null; then
            print_status "Installing ArgoCD CLI..."
            curl -sSL -o /tmp/argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
            sudo install -m 555 /tmp/argocd-linux-amd64 /usr/local/bin/argocd
            rm /tmp/argocd-linux-amd64
        fi
        
        # Wait for sync
        kubectl wait --for=condition=Synced application/"${APP_NAME}-${ENVIRONMENT}" -n argocd --timeout=600s
        print_status "✅ ArgoCD sync completed"
    fi
}

# Function to verify deployment
verify_deployment() {
    print_header "Verifying Deployment"
    
    local namespace="${ENVIRONMENT}"
    
    # Check deployment status
    print_status "Checking deployment status..."
    kubectl get deployment "${APP_NAME}" -n "${namespace}" || {
        print_error "Deployment not found"
        return 1
    }
    
    # Wait for deployment to be ready
    print_status "Waiting for deployment to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/"${APP_NAME}" -n "${namespace}"
    
    # Check pods
    print_status "Checking pod status..."
    kubectl get pods -n "${namespace}" -l app.kubernetes.io/name="${APP_NAME}"
    
    # Check service
    print_status "Checking service..."
    kubectl get service "${APP_NAME}" -n "${namespace}"
    
    # Check ingress (if exists)
    if kubectl get ingress "${APP_NAME}" -n "${namespace}" &> /dev/null; then
        print_status "Checking ingress..."
        kubectl get ingress "${APP_NAME}" -n "${namespace}"
        
        # Get ALB hostname
        local alb_hostname=$(kubectl get ingress "${APP_NAME}" -n "${namespace}" -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
        if [[ -n "${alb_hostname}" ]]; then
            print_status "Application accessible at: http://${alb_hostname}"
        fi
    fi
    
    # Health check
    print_status "Performing health check..."
    local pod_name=$(kubectl get pods -n "${namespace}" -l app.kubernetes.io/name="${APP_NAME}" -o jsonpath='{.items[0].metadata.name}')
    
    if [[ -n "${pod_name}" ]]; then
        kubectl exec "${pod_name}" -n "${namespace}" -- curl -f http://localhost:8080/actuator/health || {
            print_warning "Health check failed, but deployment may still be starting"
        }
    fi
    
    print_status "✅ Deployment verification completed"
}

# Function to setup monitoring
setup_monitoring() {
    print_header "Setting up Application Monitoring"
    
    local namespace="${ENVIRONMENT}"
    
    # Check if Prometheus is installed
    if ! kubectl get namespace monitoring &> /dev/null; then
        print_warning "Monitoring namespace not found, skipping monitoring setup"
        return 0
    fi
    
    # Create ServiceMonitor for Prometheus
    cat << EOF | kubectl apply -f -
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: ${APP_NAME}-${ENVIRONMENT}
  namespace: monitoring
  labels:
    app.kubernetes.io/name: ${APP_NAME}
    environment: ${ENVIRONMENT}
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: ${APP_NAME}
      app.kubernetes.io/instance: ${APP_NAME}
  namespaceSelector:
    matchNames:
    - ${namespace}
  endpoints:
  - port: http
    path: /actuator/prometheus
    interval: 30s
    scrapeTimeout: 10s
EOF

    print_status "✅ ServiceMonitor created for Prometheus scraping"
}

# Function to run tests
run_deployment_tests() {
    print_header "Running Deployment Tests"
    
    local namespace="${ENVIRONMENT}"
    
    # Create test job
    cat << EOF | kubectl apply -f -
apiVersion: batch/v1
kind: Job
metadata:
  name: ${APP_NAME}-test-${RANDOM}
  namespace: ${namespace}
  labels:
    app.kubernetes.io/name: ${APP_NAME}-test
    environment: ${ENVIRONMENT}
spec:
  template:
    spec:
      containers:
      - name: test
        image: curlimages/curl:latest
        command:
        - /bin/sh
        - -c
        - |
          echo "Testing application endpoints..."
          
          # Test health endpoint
          echo "Testing health endpoint..."
          curl -f http://${APP_NAME}.${namespace}.svc.cluster.local/actuator/health
          
          # Test main application endpoint
          echo "Testing main endpoint..."
          curl -f http://${APP_NAME}.${namespace}.svc.cluster.local/hello
          
          echo "All tests passed!"
      restartPolicy: Never
  backoffLimit: 4
EOF

    # Wait for test completion
    local job_name=$(kubectl get jobs -n "${namespace}" -l app.kubernetes.io/name="${APP_NAME}-test" --sort-by=.metadata.creationTimestamp -o jsonpath='{.items[-1].metadata.name}')
    
    if [[ -n "${job_name}" ]]; then
        print_status "Waiting for tests to complete..."
        kubectl wait --for=condition=complete job/"${job_name}" -n "${namespace}" --timeout=300s
        
        # Show test results
        local pod_name=$(kubectl get pods -n "${namespace}" -l job-name="${job_name}" -o jsonpath='{.items[0].metadata.name}')
        if [[ -n "${pod_name}" ]]; then
            kubectl logs "${pod_name}" -n "${namespace}"
        fi
        
        # Cleanup test job
        kubectl delete job "${job_name}" -n "${namespace}"
        
        print_status "✅ Deployment tests completed"
    else
        print_warning "Test job not found, skipping tests"
    fi
}

# Function to display deployment information
display_deployment_info() {
    print_header "Deployment Summary"
    
    local namespace="${ENVIRONMENT}"
    
    echo "📊 Deployment Information:"
    echo "  • Application: ${APP_NAME}"
    echo "  • Environment: ${ENVIRONMENT}"
    echo "  • Namespace: ${namespace}"
    echo "  • Image Tag: ${IMAGE_TAG}"
    echo "  • ECR Repository: ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${APP_NAME}-${ENVIRONMENT}"
    echo ""
    
    # Get service information
    local service_ip=$(kubectl get service "${APP_NAME}" -n "${namespace}" -o jsonpath='{.spec.clusterIP}')
    local service_port=$(kubectl get service "${APP_NAME}" -n "${namespace}" -o jsonpath='{.spec.ports[0].port}')
    
    echo "🔗 Access Information:"
    echo "  • Internal Service: http://${service_ip}:${service_port}"
    echo "  • Service DNS: http://${APP_NAME}.${namespace}.svc.cluster.local"
    
    # Get ingress information if available
    if kubectl get ingress "${APP_NAME}" -n "${namespace}" &> /dev/null; then
        local ingress_host=$(kubectl get ingress "${APP_NAME}" -n "${namespace}" -o jsonpath='{.spec.rules[0].host}')
        local alb_hostname=$(kubectl get ingress "${APP_NAME}" -n "${namespace}" -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
        
        echo "  • Ingress Host: ${ingress_host}"
        if [[ -n "${alb_hostname}" ]]; then
            echo "  • ALB Hostname: ${alb_hostname}"
        fi
    fi
    echo ""
    
    echo "📋 Useful Commands:"
    echo "  • Check pods: kubectl get pods -n ${namespace} -l app.kubernetes.io/name=${APP_NAME}"
    echo "  • View logs: kubectl logs -f deployment/${APP_NAME} -n ${namespace}"
    echo "  • Port forward: kubectl port-forward svc/${APP_NAME} 8080:80 -n ${namespace}"
    echo "  • Scale deployment: kubectl scale deployment ${APP_NAME} --replicas=3 -n ${namespace}"
    echo "  • Delete deployment: helm uninstall ${APP_NAME}-${ENVIRONMENT} -n ${namespace}"
}

# Main execution flow
main() {
    print_header "Java Microservice Deployment"
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -e|--environment)
                ENVIRONMENT="$2"
                shift 2
                ;;
            -t|--tag)
                IMAGE_TAG="$2"
                shift 2
                ;;
            --skip-build)
                SKIP_BUILD=true
                shift
                ;;
            --skip-tests)
                SKIP_TESTS=true
                shift
                ;;
            --argocd-only)
                ARGOCD_ONLY=true
                shift
                ;;
            -h|--help)
                echo "Usage: $0 [OPTIONS]"
                echo "Options:"
                echo "  -e, --environment ENV    Target environment (development/staging/production)"
                echo "  -t, --tag TAG           Image tag (default: latest)"
                echo "  --skip-build            Skip Docker build and push"
                echo "  --skip-tests            Skip deployment tests"
                echo "  --argocd-only           Only create ArgoCD application"
                echo "  -h, --help              Show this help message"
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    # Validate environment
    case $ENVIRONMENT in
        development|staging|production)
            ;;
        *)
            print_error "Invalid environment: $ENVIRONMENT"
            print_status "Valid environments: development, staging, production"
            exit 1
            ;;
    esac
    
    print_status "Deploying to environment: ${ENVIRONMENT}"
    print_status "Image tag: ${IMAGE_TAG}"
    
    # Execute deployment steps
    check_prerequisites
    
    if [[ "${SKIP_BUILD:-false}" != "true" ]]; then
        build_and_push_image
    fi
    
    if [[ "${ARGOCD_ONLY:-false}" == "true" ]]; then
        deploy_with_argocd
    else
        deploy_with_helm
        verify_deployment
        setup_monitoring
        
        if [[ "${SKIP_TESTS:-false}" != "true" ]]; then
            run_deployment_tests
        fi
    fi
    
    display_deployment_info
    
    print_status "✅ Deployment completed successfully!"
}

# Execute main function
main "$@"