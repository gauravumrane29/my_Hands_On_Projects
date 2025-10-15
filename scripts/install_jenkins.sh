#!/bin/bash

# Jenkins Installation Script for Ubuntu/Debian
# This script installs Jenkins with Java 17 and sets up initial security

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
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

# Check if script is run as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        error "This script should not be run as root for security reasons"
        error "Please run as a regular user with sudo privileges"
        exit 1
    fi
}

# Check system requirements
check_requirements() {
    log "Checking system requirements..."
    
    # Check OS
    if [[ ! -f /etc/os-release ]]; then
        error "Cannot determine OS version"
        exit 1
    fi
    
    source /etc/os-release
    if [[ "$ID" != "ubuntu" ]] && [[ "$ID" != "debian" ]]; then
        error "This script is designed for Ubuntu/Debian systems"
        exit 1
    fi
    
    # Check available disk space (at least 2GB)
    available_space=$(df / | awk 'NR==2 {print $4}')
    if [[ $available_space -lt 2097152 ]]; then # 2GB in KB
        error "Insufficient disk space. At least 2GB required"
        exit 1
    fi
    
    # Check memory (at least 1GB)
    available_memory=$(free -m | awk 'NR==2{print $2}')
    if [[ $available_memory -lt 1024 ]]; then
        warn "Less than 1GB RAM available. Jenkins may run slowly"
    fi
    
    success "System requirements check passed"
}

# Install Java 17
install_java() {
    log "Installing Java 17..."
    
    # Check if Java 17 is already installed
    if java -version 2>&1 | grep -q "17\." ; then
        success "Java 17 is already installed"
        java -version
        return 0
    fi
    
    # Update package repository
    sudo apt update -y
    
    # Install Java 17
    sudo apt install -y openjdk-17-jdk
    
    # Set JAVA_HOME
    echo 'export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64' | sudo tee -a /etc/environment
    export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
    
    # Verify installation
    if java -version 2>&1 | grep -q "17\." ; then
        success "Java 17 installed successfully"
        java -version
    else
        error "Java 17 installation failed"
        exit 1
    fi
}

# Install Jenkins
install_jenkins() {
    log "Installing Jenkins..."
    
    # Add Jenkins repository key
    log "Adding Jenkins repository..."
    curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
        /usr/share/keyrings/jenkins-keyring.asc > /dev/null
    
    # Add Jenkins repository
    echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
        https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
        /etc/apt/sources.list.d/jenkins.list > /dev/null
    
    # Update package repository
    sudo apt update -y
    
    # Install Jenkins
    sudo apt install -y jenkins
    
    # Start and enable Jenkins service
    sudo systemctl start jenkins
    sudo systemctl enable jenkins
    
    # Wait for Jenkins to start
    log "Waiting for Jenkins to start..."
    sleep 30
    
    # Check Jenkins status
    if sudo systemctl is-active --quiet jenkins; then
        success "Jenkins installed and started successfully"
    else
        error "Jenkins installation failed or service is not running"
        sudo systemctl status jenkins
        exit 1
    fi
}

# Configure Jenkins firewall
configure_firewall() {
    log "Configuring firewall for Jenkins..."
    
    # Check if UFW is available
    if command -v ufw >/dev/null 2>&1; then
        # Allow Jenkins port
        sudo ufw allow 8080/tcp
        success "Firewall configured to allow Jenkins on port 8080"
    else
        warn "UFW firewall not found. Please manually configure firewall to allow port 8080"
    fi
}

# Get initial admin password
get_admin_password() {
    log "Retrieving Jenkins initial admin password..."
    
    local password_file="/var/lib/jenkins/secrets/initialAdminPassword"
    
    if [[ -f "$password_file" ]]; then
        local admin_password=$(sudo cat "$password_file")
        success "Jenkins initial setup complete!"
        echo ""
        echo "=========================================="
        echo "Jenkins Installation Summary"
        echo "=========================================="
        echo "Jenkins URL: http://$(hostname -I | awk '{print $1}'):8080"
        echo "Initial Admin Password: $admin_password"
        echo ""
        echo "Next Steps:"
        echo "1. Open Jenkins in your browser"
        echo "2. Use the admin password above to unlock Jenkins"
        echo "3. Install suggested plugins or customize plugin selection"
        echo "4. Create your first admin user"
        echo "5. Configure Jenkins URL and start building!"
        echo "=========================================="
    else
        warn "Initial admin password file not found"
        warn "Jenkins may still be initializing. Check again in a few minutes:"
        warn "sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
    fi
}

# Install additional tools
install_additional_tools() {
    log "Installing additional DevOps tools..."
    
    # Install Git (required for Jenkins)
    sudo apt install -y git curl wget unzip
    
    # Install Docker (for building containers)
    if ! command -v docker >/dev/null 2>&1; then
        log "Installing Docker..."
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        sudo usermod -aG docker jenkins
        sudo usermod -aG docker $USER
        rm get-docker.sh
        success "Docker installed and jenkins user added to docker group"
    else
        success "Docker already installed"
    fi
    
    # Install Maven (for Java builds)
    if ! command -v mvn >/dev/null 2>&1; then
        log "Installing Maven..."
        sudo apt install -y maven
        success "Maven installed"
    else
        success "Maven already installed"
    fi
    
    # Install Node.js and npm (for modern web apps)
    if ! command -v node >/dev/null 2>&1; then
        log "Installing Node.js..."
        curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
        sudo apt install -y nodejs
        success "Node.js and npm installed"
    else
        success "Node.js already installed"
    fi
}

# Create Jenkins backup script
create_backup_script() {
    log "Creating Jenkins backup script..."
    
    sudo tee /usr/local/bin/jenkins-backup.sh > /dev/null << 'EOF'
#!/bin/bash
# Jenkins Backup Script

BACKUP_DIR="/opt/jenkins-backups"
JENKINS_HOME="/var/lib/jenkins"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="jenkins-backup-$DATE.tar.gz"

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Stop Jenkins service
systemctl stop jenkins

# Create backup
tar -czf "$BACKUP_DIR/$BACKUP_FILE" \
    --exclude="$JENKINS_HOME/workspace" \
    --exclude="$JENKINS_HOME/.m2" \
    --exclude="$JENKINS_HOME/logs" \
    "$JENKINS_HOME"

# Start Jenkins service
systemctl start jenkins

# Keep only last 7 backups
find "$BACKUP_DIR" -name "jenkins-backup-*.tar.gz" -type f -mtime +7 -delete

echo "Jenkins backup completed: $BACKUP_DIR/$BACKUP_FILE"
EOF

    sudo chmod +x /usr/local/bin/jenkins-backup.sh
    
    # Create systemd timer for daily backups
    sudo tee /etc/systemd/system/jenkins-backup.service > /dev/null << EOF
[Unit]
Description=Jenkins Backup Service
After=jenkins.service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/jenkins-backup.sh
User=root
EOF

    sudo tee /etc/systemd/system/jenkins-backup.timer > /dev/null << EOF
[Unit]
Description=Daily Jenkins Backup
Requires=jenkins-backup.service

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable jenkins-backup.timer
    sudo systemctl start jenkins-backup.timer
    
    success "Jenkins backup script and daily timer created"
}

# Main installation function
main() {
    log "Starting Jenkins installation..."
    
    check_root
    check_requirements
    install_java
    install_jenkins
    configure_firewall
    install_additional_tools
    create_backup_script
    get_admin_password
    
    success "Jenkins installation completed successfully!"
    log "Jenkins is running and accessible at: http://$(hostname -I | awk '{print $1}'):8080"
}

# Run main function
main "$@"