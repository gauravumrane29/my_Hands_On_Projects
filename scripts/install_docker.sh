#!/bin/bash

# Docker and Docker Compose Installation Script
# Supports Ubuntu, Debian, CentOS, RHEL, and Amazon Linux

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}" >&2
}

success() {
    echo -e "${GREEN}[SUCCESS] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

# Detect OS
detect_os() {
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        OS=$ID
        VER=$VERSION_ID
    elif [[ -f /etc/redhat-release ]]; then
        OS="centos"
        VER=$(cat /etc/redhat-release | grep -oE '[0-9]+\.[0-9]+')
    else
        error "Cannot detect operating system"
        exit 1
    fi
    
    log "Detected OS: $OS $VER"
}

# Check system requirements
check_requirements() {
    log "Checking system requirements..."
    
    # Check if running as root
    if [[ $EUID -eq 0 ]]; then
        warn "Running as root. Consider using a non-root user with sudo privileges"
    fi
    
    # Check architecture
    ARCH=$(uname -m)
    if [[ "$ARCH" != "x86_64" ]] && [[ "$ARCH" != "aarch64" ]] && [[ "$ARCH" != "armv7l" ]]; then
        error "Unsupported architecture: $ARCH"
        exit 1
    fi
    
    # Check available disk space (at least 2GB)
    available_space=$(df / | awk 'NR==2 {print $4}')
    if [[ $available_space -lt 2097152 ]]; then # 2GB in KB
        error "Insufficient disk space. At least 2GB required"
        exit 1
    fi
    
    success "System requirements check passed"
}

# Remove old Docker versions
remove_old_docker() {
    log "Removing old Docker versions if present..."
    
    case "$OS" in
        ubuntu|debian)
            sudo apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
            ;;
        centos|rhel|fedora)
            sudo yum remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine 2>/dev/null || true
            ;;
        amzn)
            sudo yum remove -y docker 2>/dev/null || true
            ;;
    esac
    
    success "Old Docker versions removed"
}

# Install Docker on Ubuntu/Debian
install_docker_debian() {
    log "Installing Docker on Debian/Ubuntu..."
    
    # Update package database
    sudo apt-get update -y
    
    # Install required packages
    sudo apt-get install -y \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg \
        lsb-release
    
    # Add Docker's official GPG key
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/$OS/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    
    # Set up the repository
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$OS \
        $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Update package database with Docker packages
    sudo apt-get update -y
    
    # Install Docker Engine
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
}

# Install Docker on CentOS/RHEL/Fedora
install_docker_redhat() {
    log "Installing Docker on Red Hat based system..."
    
    # Install required packages
    sudo yum install -y yum-utils
    
    # Set up the repository
    sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    
    # Install Docker Engine
    sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
}

# Install Docker on Amazon Linux
install_docker_amazon() {
    log "Installing Docker on Amazon Linux..."
    
    # Update packages
    sudo yum update -y
    
    # Install Docker
    sudo yum install -y docker
    
    # Install Docker Compose separately for Amazon Linux
    DOCKER_COMPOSE_VERSION="2.20.2"
    sudo curl -L "https://github.com/docker/compose/releases/download/v${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
}

# Configure Docker
configure_docker() {
    log "Configuring Docker..."
    
    # Start and enable Docker service
    sudo systemctl start docker
    sudo systemctl enable docker
    
    # Add current user to docker group (if not root)
    if [[ $EUID -ne 0 ]]; then
        sudo usermod -aG docker $USER
        success "User $USER added to docker group"
        warn "Please log out and log back in for group changes to take effect"
    fi
    
    # Configure Docker daemon with best practices
    sudo tee /etc/docker/daemon.json > /dev/null << EOF
{
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "100m",
        "max-file": "3"
    },
    "storage-driver": "overlay2",
    "features": {
        "buildkit": true
    },
    "default-ulimits": {
        "nofile": {
            "Name": "nofile",
            "Hard": 64000,
            "Soft": 64000
        }
    }
}
EOF

    # Restart Docker to apply configuration
    sudo systemctl restart docker
    
    success "Docker configured with production settings"
}

# Verify Docker installation
verify_installation() {
    log "Verifying Docker installation..."
    
    # Check Docker version
    if docker --version; then
        success "Docker installed successfully"
    else
        error "Docker installation verification failed"
        exit 1
    fi
    
    # Check Docker Compose
    if docker compose version 2>/dev/null || docker-compose --version 2>/dev/null; then
        success "Docker Compose is available"
    else
        warn "Docker Compose not found or not working"
    fi
    
    # Test Docker with hello-world (only if user is in docker group)
    if groups $USER | grep -q docker 2>/dev/null || [[ $EUID -eq 0 ]]; then
        log "Testing Docker with hello-world container..."
        if docker run --rm hello-world > /dev/null 2>&1; then
            success "Docker is working correctly"
        else
            warn "Docker test failed. You may need to log out and back in"
        fi
    else
        warn "Cannot test Docker. User not in docker group yet"
    fi
}

# Create useful Docker scripts
create_docker_scripts() {
    log "Creating useful Docker management scripts..."
    
    # Create docker cleanup script
    sudo tee /usr/local/bin/docker-cleanup.sh > /dev/null << 'EOF'
#!/bin/bash
# Docker System Cleanup Script

echo "Cleaning up Docker system..."

# Remove stopped containers
echo "Removing stopped containers..."
docker container prune -f

# Remove unused images
echo "Removing unused images..."
docker image prune -f

# Remove unused volumes
echo "Removing unused volumes..."
docker volume prune -f

# Remove unused networks
echo "Removing unused networks..."
docker network prune -f

# Show disk usage after cleanup
echo "Docker disk usage after cleanup:"
docker system df

echo "Docker cleanup completed!"
EOF

    sudo chmod +x /usr/local/bin/docker-cleanup.sh
    
    # Create docker monitoring script
    sudo tee /usr/local/bin/docker-monitor.sh > /dev/null << 'EOF'
#!/bin/bash
# Docker System Monitoring Script

echo "=== Docker System Information ==="
echo "Docker Version:"
docker version --format 'Client: {{.Client.Version}}, Server: {{.Server.Version}}'

echo -e "\n=== Docker System Status ==="
docker system df

echo -e "\n=== Running Containers ==="
docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"

echo -e "\n=== Container Resource Usage ==="
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}"

echo -e "\n=== Docker Service Status ==="
systemctl is-active docker && echo "Docker service: ACTIVE" || echo "Docker service: INACTIVE"
EOF

    sudo chmod +x /usr/local/bin/docker-monitor.sh
    
    success "Docker management scripts created in /usr/local/bin/"
}

# Main installation function
main() {
    log "Starting Docker installation..."
    
    detect_os
    check_requirements
    remove_old_docker
    
    case "$OS" in
        ubuntu|debian)
            install_docker_debian
            ;;
        centos|rhel|fedora)
            install_docker_redhat
            ;;
        amzn)
            install_docker_amazon
            ;;
        *)
            error "Unsupported operating system: $OS"
            exit 1
            ;;
    esac
    
    configure_docker
    verify_installation
    create_docker_scripts
    
    success "Docker installation completed successfully!"
    
    echo ""
    echo "=========================================="
    echo "Docker Installation Summary"
    echo "=========================================="
    echo "Docker Version: $(docker --version)"
    echo "Docker Compose: $(docker compose version 2>/dev/null || echo 'Not available')"
    echo ""
    echo "Useful Commands:"
    echo "  docker-cleanup.sh    - Clean up unused Docker resources"
    echo "  docker-monitor.sh    - Monitor Docker system status"
    echo ""
    echo "Next Steps:"
    if [[ $EUID -ne 0 ]]; then
        echo "  1. Log out and log back in to use Docker without sudo"
    fi
    echo "  2. Test Docker: docker run hello-world"
    echo "  3. Start building containers!"
    echo "=========================================="
}

# Run main function
main "$@"