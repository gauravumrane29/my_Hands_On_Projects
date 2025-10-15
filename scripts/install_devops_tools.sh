#!/bin/bash

# Comprehensive DevOps Tools Installation Script
# Installs Terraform, Packer, Ansible, kubectl, Helm, and other essential DevOps tools

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Tool versions (can be updated as needed)
TERRAFORM_VERSION="1.12.2"
PACKER_VERSION="1.14.2"
ANSIBLE_VERSION="9.2.0"
KUBECTL_VERSION="v1.28.2"
HELM_VERSION="v3.13.0"
DOCKER_COMPOSE_VERSION="v2.20.2"
AWSCLI_VERSION="2.15.0"
JENKINS_CLI_VERSION="2.414.1"
VAULT_VERSION="1.15.0"
CONSUL_VERSION="1.16.0"

# Installation directory
INSTALL_DIR="/usr/local/bin"
TEMP_DIR="/tmp/devops-install"

# Logging functions
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

success() {
    echo -e "${GREEN}[SUCCESS] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}" >&2
}

warn() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

info() {
    echo -e "${PURPLE}[INFO] $1${NC}"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        warn "Running as root. Some tools will be installed system-wide."
        INSTALL_DIR="/usr/local/bin"
    else
        info "Running as non-root user. Tools will be installed to $INSTALL_DIR (requires sudo)"
    fi
}

# Detect OS and architecture
detect_system() {
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    ARCH=$(uname -m)
    
    case $ARCH in
        x86_64)
            ARCH="amd64"
            ;;
        aarch64|arm64)
            ARCH="arm64"
            ;;
        armv7l)
            ARCH="arm"
            ;;
        *)
            error "Unsupported architecture: $ARCH"
            exit 1
            ;;
    esac
    
    log "Detected system: $OS/$ARCH"
}

# Create temporary directory
setup_temp_dir() {
    mkdir -p "$TEMP_DIR"
    cd "$TEMP_DIR"
    log "Created temporary directory: $TEMP_DIR"
}

# Cleanup function
cleanup() {
    log "Cleaning up temporary files..."
    rm -rf "$TEMP_DIR"
}

# Trap to ensure cleanup
trap cleanup EXIT

# Install system dependencies
install_dependencies() {
    log "Installing system dependencies..."
    
    if command_exists apt-get; then
        # Ubuntu/Debian
        sudo apt-get update
        sudo apt-get install -y curl wget unzip software-properties-common gnupg2 python3 python3-pip git jq
    elif command_exists yum; then
        # CentOS/RHEL/Amazon Linux
        sudo yum update -y
        sudo yum install -y curl wget unzip python3 python3-pip git which jq
    elif command_exists brew; then
        # macOS
        brew install curl wget python3 git jq
    else
        error "Unsupported package manager. Please install dependencies manually."
        exit 1
    fi
    
    success "System dependencies installed"
}

# Install Terraform
install_terraform() {
    if command_exists terraform; then
        local current_version=$(terraform version -json | jq -r '.terraform_version')
        if [[ "$current_version" == "$TERRAFORM_VERSION" ]]; then
            success "Terraform $TERRAFORM_VERSION already installed"
            return 0
        else
            warn "Terraform $current_version found, upgrading to $TERRAFORM_VERSION"
        fi
    fi
    
    log "Installing Terraform $TERRAFORM_VERSION..."
    
    local download_url="https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_${OS}_${ARCH}.zip"
    
    wget -q "$download_url" -O terraform.zip
    unzip -q terraform.zip
    sudo mv terraform "$INSTALL_DIR/"
    sudo chmod +x "$INSTALL_DIR/terraform"
    
    # Verify installation
    if terraform version | grep -q "$TERRAFORM_VERSION"; then
        success "Terraform $TERRAFORM_VERSION installed successfully"
    else
        error "Terraform installation failed"
        return 1
    fi
}

# Install Packer
install_packer() {
    if command_exists packer; then
        local current_version=$(packer version | awk '{print $2}' | sed 's/v//')
        if [[ "$current_version" == "$PACKER_VERSION" ]]; then
            success "Packer $PACKER_VERSION already installed"
            return 0
        else
            warn "Packer $current_version found, upgrading to $PACKER_VERSION"
        fi
    fi
    
    log "Installing Packer $PACKER_VERSION..."
    
    local download_url="https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_${OS}_${ARCH}.zip"
    
    wget -q "$download_url" -O packer.zip
    unzip -q packer.zip
    sudo mv packer "$INSTALL_DIR/"
    sudo chmod +x "$INSTALL_DIR/packer"
    
    # Verify installation
    if packer version | grep -q "$PACKER_VERSION"; then
        success "Packer $PACKER_VERSION installed successfully"
    else
        error "Packer installation failed"
        return 1
    fi
}

# Install Ansible
install_ansible() {
    if command_exists ansible; then
        local current_version=$(ansible --version | head -n1 | awk '{print $3}' | sed 's/\]//')
        info "Ansible $current_version already installed"
        # Don't skip, might want to upgrade
    fi
    
    log "Installing Ansible $ANSIBLE_VERSION..."
    
    # Install via pip for better version control
    if command_exists pip3; then
        sudo pip3 install "ansible==$ANSIBLE_VERSION" --upgrade
    elif command_exists pip; then
        sudo pip install "ansible==$ANSIBLE_VERSION" --upgrade
    else
        # Fallback to package manager
        if command_exists apt-get; then
            sudo apt-add-repository --yes --update ppa:ansible/ansible
            sudo apt-get install -y ansible
        elif command_exists yum; then
            sudo yum install -y epel-release
            sudo yum install -y ansible
        fi
    fi
    
    # Install additional Ansible collections
    ansible-galaxy collection install kubernetes.core community.general ansible.posix --force
    
    success "Ansible installed with additional collections"
}

# Install kubectl
install_kubectl() {
    if command_exists kubectl; then
        local current_version=$(kubectl version --client -o json 2>/dev/null | jq -r '.clientVersion.gitVersion')
        if [[ "$current_version" == "$KUBECTL_VERSION" ]]; then
            success "kubectl $KUBECTL_VERSION already installed"
            return 0
        else
            warn "kubectl $current_version found, upgrading to $KUBECTL_VERSION"
        fi
    fi
    
    log "Installing kubectl $KUBECTL_VERSION..."
    
    local download_url="https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/${OS}/${ARCH}/kubectl"
    
    wget -q "$download_url" -O kubectl
    sudo mv kubectl "$INSTALL_DIR/"
    sudo chmod +x "$INSTALL_DIR/kubectl"
    
    # Verify installation
    if kubectl version --client | grep -q "$KUBECTL_VERSION"; then
        success "kubectl $KUBECTL_VERSION installed successfully"
    else
        error "kubectl installation failed"
        return 1
    fi
}

# Install Helm
install_helm() {
    if command_exists helm; then
        local current_version=$(helm version --template='{{.Version}}')
        if [[ "$current_version" == "$HELM_VERSION" ]]; then
            success "Helm $HELM_VERSION already installed"
            return 0
        else
            warn "Helm $current_version found, upgrading to $HELM_VERSION"
        fi
    fi
    
    log "Installing Helm $HELM_VERSION..."
    
    local download_url="https://get.helm.sh/helm-${HELM_VERSION}-${OS}-${ARCH}.tar.gz"
    
    wget -q "$download_url" -O helm.tar.gz
    tar -xzf helm.tar.gz
    sudo mv "${OS}-${ARCH}/helm" "$INSTALL_DIR/"
    sudo chmod +x "$INSTALL_DIR/helm"
    
    success "Helm $HELM_VERSION installed successfully"
}

# Install Docker Compose
install_docker_compose() {
    if command_exists docker-compose; then
        local current_version=$(docker-compose version --short)
        info "Docker Compose $current_version already installed"
    fi
    
    log "Installing Docker Compose $DOCKER_COMPOSE_VERSION..."
    
    local download_url="https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-${OS}-$(uname -m)"
    
    sudo wget -q "$download_url" -O "$INSTALL_DIR/docker-compose"
    sudo chmod +x "$INSTALL_DIR/docker-compose"
    
    success "Docker Compose $DOCKER_COMPOSE_VERSION installed successfully"
}

# Install AWS CLI
install_awscli() {
    if command_exists aws; then
        local current_version=$(aws --version 2>&1 | awk '{print $1}' | awk -F/ '{print $2}')
        info "AWS CLI $current_version already installed"
        # AWS CLI auto-updates, so we don't need to reinstall
        return 0
    fi
    
    log "Installing AWS CLI $AWSCLI_VERSION..."
    
    if [[ "$OS" == "linux" ]]; then
        local download_url="https://awscli.amazonaws.com/awscli-exe-linux-$(uname -m).zip"
        wget -q "$download_url" -O awscliv2.zip
        unzip -q awscliv2.zip
        sudo ./aws/install --update
        rm -rf aws awscliv2.zip
    elif [[ "$OS" == "darwin" ]]; then
        local download_url="https://awscli.amazonaws.com/AWSCLIV2.pkg"
        wget -q "$download_url" -O AWSCLIV2.pkg
        sudo installer -pkg AWSCLIV2.pkg -target /
        rm AWSCLIV2.pkg
    fi
    
    success "AWS CLI installed successfully"
}

# Install Vault
install_vault() {
    if command_exists vault; then
        local current_version=$(vault version | head -n1 | awk '{print $2}' | sed 's/v//')
        if [[ "$current_version" == "$VAULT_VERSION" ]]; then
            success "Vault $VAULT_VERSION already installed"
            return 0
        fi
    fi
    
    log "Installing Vault $VAULT_VERSION..."
    
    local download_url="https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_${OS}_${ARCH}.zip"
    
    wget -q "$download_url" -O vault.zip
    unzip -q vault.zip
    sudo mv vault "$INSTALL_DIR/"
    sudo chmod +x "$INSTALL_DIR/vault"
    
    success "Vault $VAULT_VERSION installed successfully"
}

# Install additional DevOps tools
install_additional_tools() {
    log "Installing additional DevOps tools..."
    
    # Install jq (JSON processor) if not already installed
    if ! command_exists jq; then
        if command_exists apt-get; then
            sudo apt-get install -y jq
        elif command_exists yum; then
            sudo yum install -y jq
        fi
    fi
    
    # Install yq (YAML processor)
    if ! command_exists yq; then
        log "Installing yq..."
        local download_url="https://github.com/mikefarah/yq/releases/latest/download/yq_${OS}_${ARCH}"
        sudo wget -q "$download_url" -O "$INSTALL_DIR/yq"
        sudo chmod +x "$INSTALL_DIR/yq"
        success "yq installed successfully"
    fi
    
    # Install kubectx and kubens
    if ! command_exists kubectx; then
        log "Installing kubectx and kubens..."
        sudo wget -q https://raw.githubusercontent.com/ahmetb/kubectx/master/kubectx -O "$INSTALL_DIR/kubectx"
        sudo wget -q https://raw.githubusercontent.com/ahmetb/kubectx/master/kubens -O "$INSTALL_DIR/kubens"
        sudo chmod +x "$INSTALL_DIR/kubectx" "$INSTALL_DIR/kubens"
        success "kubectx and kubens installed successfully"
    fi
    
    # Install k9s (Kubernetes CLI dashboard)
    if ! command_exists k9s; then
        log "Installing k9s..."
        local download_url="https://github.com/derailed/k9s/releases/latest/download/k9s_${OS^}_${ARCH}.tar.gz"
        wget -q "$download_url" -O k9s.tar.gz
        tar -xzf k9s.tar.gz k9s
        sudo mv k9s "$INSTALL_DIR/"
        sudo chmod +x "$INSTALL_DIR/k9s"
        success "k9s installed successfully"
    fi
}

# Setup shell completions
setup_completions() {
    log "Setting up shell completions..."
    
    local completion_dir="$HOME/.bash_completion.d"
    mkdir -p "$completion_dir"
    
    # Generate completions for installed tools
    if command_exists kubectl; then
        kubectl completion bash > "$completion_dir/kubectl"
    fi
    
    if command_exists helm; then
        helm completion bash > "$completion_dir/helm"
    fi
    
    if command_exists terraform; then
        terraform -install-autocomplete 2>/dev/null || true
    fi
    
    # Add to .bashrc if not already present
    local bashrc="$HOME/.bashrc"
    if [[ -f "$bashrc" ]] && ! grep -q "bash_completion.d" "$bashrc"; then
        cat >> "$bashrc" << 'EOF'

# Load custom completions
if [ -d ~/.bash_completion.d ]; then
    for f in ~/.bash_completion.d/*; do
        [ -r "$f" ] && source "$f"
    done
fi

# Useful aliases for DevOps tools
alias k=kubectl
alias tf=terraform
alias pk=packer
alias dc=docker-compose
alias kx=kubectx
alias kn=kubens
EOF
    fi
    
    success "Shell completions and aliases configured"
}

# Create useful scripts
create_devops_scripts() {
    log "Creating useful DevOps scripts..."
    
    # Create a tool version checker script
    sudo tee "$INSTALL_DIR/devops-versions" > /dev/null << 'EOF'
#!/bin/bash
# DevOps Tools Version Checker

echo "=== DevOps Tools Version Report ==="
echo "Generated: $(date)"
echo ""

check_version() {
    local tool="$1"
    local command="$2"
    
    if command -v "$tool" >/dev/null 2>&1; then
        local version=$(eval "$command" 2>/dev/null | head -n1)
        printf "%-20s %s\n" "$tool:" "$version"
    else
        printf "%-20s %s\n" "$tool:" "Not installed"
    fi
}

check_version "terraform" "terraform version | head -n1"
check_version "packer" "packer version"
check_version "ansible" "ansible --version | head -n1"
check_version "kubectl" "kubectl version --client --short"
check_version "helm" "helm version --short"
check_version "docker" "docker --version"
check_version "docker-compose" "docker-compose --version"
check_version "aws" "aws --version"
check_version "vault" "vault version"
check_version "jq" "jq --version"
check_version "yq" "yq --version"
check_version "git" "git --version"
check_version "curl" "curl --version | head -n1"

echo ""
echo "=== System Information ==="
echo "OS: $(uname -s) $(uname -r)"
echo "Architecture: $(uname -m)"
echo "Shell: $SHELL"
echo "User: $(whoami)"
echo "Path: $PATH"
EOF

    sudo chmod +x "$INSTALL_DIR/devops-versions"
    success "Created devops-versions tool in $INSTALL_DIR"
}

# Verify all installations
verify_installations() {
    log "Verifying all tool installations..."
    
    local failed_tools=()
    
    # Check each tool
    for tool in terraform packer ansible kubectl helm docker-compose aws vault jq yq; do
        if command_exists "$tool"; then
            success "$tool is available"
        else
            failed_tools+=("$tool")
            error "$tool is not available"
        fi
    done
    
    if [ ${#failed_tools[@]} -eq 0 ]; then
        success "All DevOps tools installed successfully!"
        info "Run 'devops-versions' to see all installed versions"
    else
        error "Some tools failed to install: ${failed_tools[*]}"
        return 1
    fi
}

# Print installation summary
print_summary() {
    echo ""
    echo "=========================================="
    echo "DevOps Tools Installation Summary"
    echo "=========================================="
    echo "Installation completed on: $(date)"
    echo "Installation directory: $INSTALL_DIR"
    echo ""
    echo "Installed tools:"
    echo "  • Terraform $TERRAFORM_VERSION"
    echo "  • Packer $PACKER_VERSION"
    echo "  • Ansible $ANSIBLE_VERSION"
    echo "  • kubectl $KUBECTL_VERSION"
    echo "  • Helm $HELM_VERSION"
    echo "  • Docker Compose $DOCKER_COMPOSE_VERSION"
    echo "  • AWS CLI $AWSCLI_VERSION"
    echo "  • Vault $VAULT_VERSION"
    echo "  • Additional tools: jq, yq, kubectx, kubens, k9s"
    echo ""
    echo "Useful commands:"
    echo "  devops-versions    - Check all tool versions"
    echo "  source ~/.bashrc   - Load new aliases and completions"
    echo ""
    echo "Next steps:"
    echo "  1. Configure AWS credentials: aws configure"
    echo "  2. Test Kubernetes connection: kubectl cluster-info"
    echo "  3. Initialize Terraform project: terraform init"
    echo "  4. Start building infrastructure!"
    echo "=========================================="
}

# Main installation function
main() {
    log "Starting DevOps tools installation..."
    
    check_root
    detect_system
    setup_temp_dir
    install_dependencies
    
    # Install core tools
    install_terraform
    install_packer
    install_ansible
    install_kubectl
    install_helm
    install_docker_compose
    install_awscli
    install_vault
    install_additional_tools
    
    # Setup environment
    setup_completions
    create_devops_scripts
    
    # Verify and summarize
    verify_installations
    print_summary
    
    success "DevOps tools installation completed!"
}

# Run main function
main "$@"