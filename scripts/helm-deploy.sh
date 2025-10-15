#!/bin/bash
# Helm deployment script for full-stack Java microservice

set -e

# Configuration
CHART_NAME="java-microservice"
CHART_PATH="deployment/helm/java-microservice"
NAMESPACE_PREFIX="java-microservice"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to show usage
show_usage() {
    cat << EOF
Usage: $0 [ENVIRONMENT] [ACTION] [OPTIONS]

ENVIRONMENT:
  dev         Deploy to development environment
  staging     Deploy to staging environment
  prod        Deploy to production environment

ACTION:
  install     Install the Helm release
  upgrade     Upgrade existing Helm release
  uninstall   Uninstall the Helm release
  template    Generate templates only (dry run)
  lint        Lint the Helm chart

OPTIONS:
  --debug     Enable debug output
  --dry-run   Simulate the deployment
  --wait      Wait for deployment to complete
  --timeout   Timeout for deployment (default: 300s)

Examples:
  $0 dev install                    # Install to development
  $0 staging upgrade --wait         # Upgrade staging with wait
  $0 prod template --debug          # Generate production templates
  $0 lint                          # Lint all charts
EOF
}

# Parse command line arguments
ENVIRONMENT=""
ACTION=""
DEBUG=""
DRY_RUN=""
WAIT=""
TIMEOUT="300s"

while [[ $# -gt 0 ]]; do
    case $1 in
        dev|staging|prod)
            ENVIRONMENT="$1"
            shift
            ;;
        install|upgrade|uninstall|template|lint)
            ACTION="$1"
            shift
            ;;
        --debug)
            DEBUG="--debug"
            shift
            ;;
        --dry-run)
            DRY_RUN="--dry-run"
            shift
            ;;
        --wait)
            WAIT="--wait"
            shift
            ;;
        --timeout)
            TIMEOUT="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Validate inputs
if [[ "$ACTION" == "lint" ]]; then
    # Lint doesn't require environment
    ENVIRONMENT=""
elif [[ -z "$ENVIRONMENT" ]] || [[ -z "$ACTION" ]]; then
    print_error "Environment and action are required"
    show_usage
    exit 1
fi

# Set deployment variables based on environment
if [[ -n "$ENVIRONMENT" ]]; then
    RELEASE_NAME="${CHART_NAME}-${ENVIRONMENT}"
    NAMESPACE="${NAMESPACE_PREFIX}-${ENVIRONMENT}"
    VALUES_FILE="${CHART_PATH}/values-${ENVIRONMENT}.yaml"
    
    if [[ ! -f "$VALUES_FILE" ]]; then
        print_error "Values file not found: $VALUES_FILE"
        exit 1
    fi
fi

print_status "Starting Helm deployment process..."
print_status "Chart: $CHART_NAME"
[[ -n "$ENVIRONMENT" ]] && print_status "Environment: $ENVIRONMENT"
print_status "Action: $ACTION"

# Function to lint charts
lint_charts() {
    print_status "Linting Helm charts..."
    
    if helm lint "$CHART_PATH" $DEBUG; then
        print_success "Chart linting passed"
    else
        print_error "Chart linting failed"
        exit 1
    fi
    
    # Test template generation for each environment
    for env in dev staging prod; do
        print_status "Testing template generation for $env environment..."
        if helm template "${CHART_NAME}-${env}" "$CHART_PATH" -f "${CHART_PATH}/values-${env}.yaml" $DEBUG > /dev/null; then
            print_success "Template generation for $env environment passed"
        else
            print_error "Template generation for $env environment failed"
            exit 1
        fi
    done
}

# Function to check if release exists
release_exists() {
    helm list -n "$NAMESPACE" | grep -q "^$RELEASE_NAME"
}

# Function to create namespace if it doesn't exist
ensure_namespace() {
    if ! kubectl get namespace "$NAMESPACE" > /dev/null 2>&1; then
        print_status "Creating namespace: $NAMESPACE"
        kubectl create namespace "$NAMESPACE"
        
        # Add labels to namespace
        kubectl label namespace "$NAMESPACE" \
            app.kubernetes.io/name="$CHART_NAME" \
            app.kubernetes.io/instance="$RELEASE_NAME" \
            environment="$ENVIRONMENT" \
            --overwrite
    else
        print_status "Namespace $NAMESPACE already exists"
    fi
}

# Function to install Helm release
install_release() {
    print_status "Installing Helm release: $RELEASE_NAME"
    
    ensure_namespace
    
    helm install "$RELEASE_NAME" "$CHART_PATH" \
        --namespace "$NAMESPACE" \
        --values "$VALUES_FILE" \
        --timeout "$TIMEOUT" \
        $DEBUG $DRY_RUN $WAIT
        
    if [[ -z "$DRY_RUN" ]]; then
        print_success "Helm release $RELEASE_NAME installed successfully"
        
        # Show deployment status
        print_status "Deployment status:"
        kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/instance="$RELEASE_NAME"
    fi
}

# Function to upgrade Helm release
upgrade_release() {
    print_status "Upgrading Helm release: $RELEASE_NAME"
    
    helm upgrade "$RELEASE_NAME" "$CHART_PATH" \
        --namespace "$NAMESPACE" \
        --values "$VALUES_FILE" \
        --timeout "$TIMEOUT" \
        $DEBUG $DRY_RUN $WAIT
        
    if [[ -z "$DRY_RUN" ]]; then
        print_success "Helm release $RELEASE_NAME upgraded successfully"
        
        # Show deployment status
        print_status "Deployment status:"
        kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/instance="$RELEASE_NAME"
    fi
}

# Function to uninstall Helm release
uninstall_release() {
    print_status "Uninstalling Helm release: $RELEASE_NAME"
    
    helm uninstall "$RELEASE_NAME" --namespace "$NAMESPACE" $DEBUG
    
    print_success "Helm release $RELEASE_NAME uninstalled successfully"
    
    # Optionally delete namespace
    read -p "Delete namespace $NAMESPACE? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        kubectl delete namespace "$NAMESPACE"
        print_success "Namespace $NAMESPACE deleted"
    fi
}

# Function to generate templates
template_release() {
    print_status "Generating templates for: $RELEASE_NAME"
    
    helm template "$RELEASE_NAME" "$CHART_PATH" \
        --namespace "$NAMESPACE" \
        --values "$VALUES_FILE" \
        $DEBUG
}

# Main execution
case "$ACTION" in
    lint)
        lint_charts
        ;;
    install)
        if release_exists; then
            print_error "Release $RELEASE_NAME already exists in namespace $NAMESPACE"
            print_status "Use 'upgrade' action to update existing release"
            exit 1
        fi
        install_release
        ;;
    upgrade)
        if ! release_exists; then
            print_warning "Release $RELEASE_NAME doesn't exist in namespace $NAMESPACE"
            print_status "Installing new release instead..."
            install_release
        else
            upgrade_release
        fi
        ;;
    uninstall)
        if ! release_exists; then
            print_error "Release $RELEASE_NAME not found in namespace $NAMESPACE"
            exit 1
        fi
        uninstall_release
        ;;
    template)
        template_release
        ;;
    *)
        print_error "Unknown action: $ACTION"
        show_usage
        exit 1
        ;;
esac

print_success "Helm operation completed successfully!"