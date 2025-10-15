#!/bin/bash

# Jenkins Docker Configuration Script
# Sets up Jenkins with Docker support for containerized builds

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
JENKINS_VERSION="${JENKINS_VERSION:-lts-jdk17}"
JENKINS_PORT="${JENKINS_PORT:-8080}"
JENKINS_AGENT_PORT="${JENKINS_AGENT_PORT:-50000}"
DOCKER_NETWORK="${DOCKER_NETWORK:-jenkins-network}"
JENKINS_HOME="${JENKINS_HOME:-$(pwd)/jenkins_home}"
COMPOSE_FILE="${COMPOSE_FILE:-docker-compose.jenkins.yml}"

echo -e "${BLUE}🐳 Jenkins Docker Setup${NC}"
echo "========================="

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
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        print_error "Docker is required but not installed"
        print_status "Please install Docker: https://docs.docker.com/get-docker/"
        exit 1
    fi
    
    # Check Docker Compose
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        print_error "Docker Compose is required but not installed"
        print_status "Please install Docker Compose: https://docs.docker.com/compose/install/"
        exit 1
    fi
    
    # Check if running as root or docker group member
    if [ "$EUID" -ne 0 ] && ! groups "$USER" | grep -q docker; then
        print_warning "Current user is not in docker group. You may need to run with sudo or add user to docker group:"
        print_status "sudo usermod -aG docker \$USER"
    fi
    
    print_status "✅ Prerequisites check passed"
}

# Function to create Jenkins directories
create_directories() {
    print_header "Creating Jenkins Directories"
    
    mkdir -p "${JENKINS_HOME}"
    mkdir -p "${JENKINS_HOME}/workspace"
    mkdir -p "${JENKINS_HOME}/jobs"
    mkdir -p "${JENKINS_HOME}/plugins"
    mkdir -p "${JENKINS_HOME}/secrets"
    mkdir -p "${JENKINS_HOME}/logs"
    mkdir -p "${JENKINS_HOME}/backup"
    
    # Create casc_configs directory for Configuration as Code
    mkdir -p "${JENKINS_HOME}/casc_configs"
    
    # Copy Jenkins configuration if it exists
    if [ -f "jenkins.yaml" ]; then
        cp jenkins.yaml "${JENKINS_HOME}/casc_configs/jenkins.yaml"
        print_status "✅ Copied Jenkins Configuration as Code file"
    fi
    
    # Set proper permissions
    if [ "$EUID" -eq 0 ]; then
        chown -R 1000:1000 "${JENKINS_HOME}"
    fi
    
    print_status "✅ Jenkins directories created at ${JENKINS_HOME}"
}

# Function to create Docker Compose file
create_docker_compose() {
    print_header "Creating Docker Compose Configuration"
    
    cat > "${COMPOSE_FILE}" << EOF
version: '3.8'

services:
  jenkins:
    image: jenkins/jenkins:${JENKINS_VERSION}
    container_name: jenkins-master
    restart: unless-stopped
    user: root
    ports:
      - "${JENKINS_PORT}:8080"
      - "${JENKINS_AGENT_PORT}:50000"
    volumes:
      - ${JENKINS_HOME}:/var/jenkins_home
      - /var/run/docker.sock:/var/run/docker.sock
      - /usr/bin/docker:/usr/bin/docker:ro
      - /usr/local/bin/docker-compose:/usr/local/bin/docker-compose:ro
    environment:
      - JENKINS_OPTS="--httpPort=8080"
      - JAVA_OPTS="-Djenkins.install.runSetupWizard=false -Dorg.apache.commons.jelly.tags.fmt.timeZone=UTC -Xmx2048m -XX:MaxPermSize=512m"
      - CASC_JENKINS_CONFIG=/var/jenkins_home/casc_configs
      - TZ=UTC
    networks:
      - ${DOCKER_NETWORK}
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:8080/login || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 120s

  jenkins-agent:
    image: jenkins/inbound-agent:latest-jdk17
    container_name: jenkins-agent-docker
    restart: unless-stopped
    depends_on:
      - jenkins
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - /usr/bin/docker:/usr/bin/docker:ro
    environment:
      - JENKINS_URL=http://jenkins:8080
      - JENKINS_SECRET=\${JENKINS_AGENT_SECRET}
      - JENKINS_AGENT_NAME=docker-agent
      - JENKINS_AGENT_WORKDIR=/home/jenkins/agent
    networks:
      - ${DOCKER_NETWORK}
    labels:
      - "jenkins.agent.name=docker-agent"
      - "jenkins.agent.labels=docker,container,linux"

  sonarqube:
    image: sonarqube:community
    container_name: sonarqube
    restart: unless-stopped
    ports:
      - "9000:9000"
    environment:
      - SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true
      - SONAR_JDBC_URL=jdbc:postgresql://postgres:5432/sonar
      - SONAR_JDBC_USERNAME=sonar
      - SONAR_JDBC_PASSWORD=sonar
    volumes:
      - sonarqube_data:/opt/sonarqube/data
      - sonarqube_extensions:/opt/sonarqube/extensions
      - sonarqube_logs:/opt/sonarqube/logs
    networks:
      - ${DOCKER_NETWORK}
    depends_on:
      - postgres

  postgres:
    image: postgres:13
    container_name: postgres-sonar
    restart: unless-stopped
    environment:
      - POSTGRES_USER=sonar
      - POSTGRES_PASSWORD=sonar
      - POSTGRES_DB=sonar
    volumes:
      - postgresql_data:/var/lib/postgresql/data
    networks:
      - ${DOCKER_NETWORK}

  portainer:
    image: portainer/portainer-ce:latest
    container_name: portainer
    restart: unless-stopped
    ports:
      - "9443:9443"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - portainer_data:/data
    networks:
      - ${DOCKER_NETWORK}
    command: -H unix:///var/run/docker.sock

  registry:
    image: registry:2
    container_name: docker-registry
    restart: unless-stopped
    ports:
      - "5000:5000"
    environment:
      - REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY=/data
    volumes:
      - registry_data:/data
    networks:
      - ${DOCKER_NETWORK}

networks:
  ${DOCKER_NETWORK}:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16

volumes:
  sonarqube_data:
  sonarqube_extensions:
  sonarqube_logs:
  postgresql_data:
  portainer_data:
  registry_data:
EOF

    print_status "✅ Docker Compose file created: ${COMPOSE_FILE}"
}

# Function to create Jenkins plugins file
create_plugins_file() {
    print_header "Creating Jenkins Plugins List"
    
    cat > "${JENKINS_HOME}/plugins.txt" << 'EOF'
# Core Pipeline Plugins
workflow-aggregator:latest
workflow-job:latest
workflow-cps:latest
workflow-multibranch:latest
pipeline-stage-view:latest
pipeline-utility-steps:latest
pipeline-build-step:latest
pipeline-input-step:latest
pipeline-milestone-step:latest

# Source Control Management
git:latest
github:latest
github-branch-source:latest
github-pullrequest:latest
bitbucket:latest
gitlab-plugin:latest

# Build Tools
maven-plugin:latest
gradle:latest
ant:latest
nodejs:latest

# Docker Integration
docker-plugin:latest
docker-workflow:latest
docker-commons:latest
docker-build-step:latest

# Kubernetes Integration
kubernetes:latest
kubernetes-credentials:latest
kubernetes-cli:latest

# Quality & Security
sonar:latest
jacoco:latest
checkstyle:latest
warnings-ng:latest
dependency-check-jenkins-plugin:latest
owasp-markup-formatter:latest
htmlpublisher:latest
junit:latest
xunit:latest
cobertura:latest
performance:latest

# Notifications
email-ext:latest
slack:latest
jira:latest
build-failure-analyzer:latest

# Credentials & Security
credentials:latest
credentials-binding:latest
ssh-credentials:latest
ssh-slaves:latest
matrix-auth:latest
role-strategy:latest
authorize-project:latest

# Configuration as Code
configuration-as-code:latest
job-dsl:latest

# UI & Visualization
blueocean:latest
build-pipeline-plugin:latest
delivery-pipeline-plugin:latest
dashboard-view:latest
nested-view:latest
build-monitor-plugin:latest
radiatorview:latest

# Utilities
timestamper:latest
build-timeout:latest
ws-cleanup:latest
copyartifact:latest
parameterized-trigger:latest
conditional-buildstep:latest
envinject:latest
build-name-setter:latest
build-user-vars-plugin:latest
ansicolor:latest
embeddable-build-status:latest

# Monitoring & Metrics
prometheus:latest
monitoring:latest
metrics:latest
disk-usage:latest

# File Management
publish-over-ssh:latest
ssh-publish:latest

# Testing
performance:latest
plot:latest
test-results-analyzer:latest

# Multijob
multijob:latest

# Webhook Support
generic-webhook-trigger:latest
gitlab-hook:latest
github-webhook:latest

# Pipeline Libraries
pipeline-github-lib:latest
pipeline-stage-tags:latest

# Additional Utilities
cloudbees-folder:latest
matrix-project:latest
mailer:latest
antisamy-markup-formatter:latest
lockable-resources:latest
rebuild:latest
throttle-concurrents:latest
EOF

    print_status "✅ Jenkins plugins list created"
}

# Function to create initialization script
create_init_script() {
    print_header "Creating Jenkins Initialization Scripts"
    
    mkdir -p "${JENKINS_HOME}/init.groovy.d"
    
    cat > "${JENKINS_HOME}/init.groovy.d/01-security.groovy" << 'EOF'
#!groovy
import jenkins.model.*
import hudson.security.*
import jenkins.security.s2m.AdminWhitelistRule

def instance = Jenkins.getInstance()

// Create admin user
def hudsonRealm = new HudsonPrivateSecurityRealm(false)
hudsonRealm.createAccount("admin", "admin")
instance.setSecurityRealm(hudsonRealm)

// Enable matrix-based authorization
def strategy = new GlobalMatrixAuthorizationStrategy()
strategy.add(Jenkins.ADMINISTER, "admin")
instance.setAuthorizationStrategy(strategy)

// Disable CLI over remoting
instance.getDescriptor("jenkins.CLI").get().setEnabled(false)

// Enable agent protocols
instance.setAgentProtocols(['JNLP4-connect', 'Ping'] as Set)

instance.save()
println "Security configuration completed"
EOF

    cat > "${JENKINS_HOME}/init.groovy.d/02-executors.groovy" << 'EOF'
#!groovy
import jenkins.model.*

def instance = Jenkins.getInstance()

// Set number of executors
instance.setNumExecutors(2)
instance.save()

println "Executor configuration completed"
EOF

    print_status "✅ Jenkins initialization scripts created"
}

# Function to create environment file
create_env_file() {
    print_header "Creating Environment Configuration"
    
    cat > .env << EOF
# Jenkins Configuration
JENKINS_VERSION=${JENKINS_VERSION}
JENKINS_PORT=${JENKINS_PORT}
JENKINS_AGENT_PORT=${JENKINS_AGENT_PORT}
JENKINS_HOME=${JENKINS_HOME}

# Docker Configuration
DOCKER_NETWORK=${DOCKER_NETWORK}

# Database Configuration
POSTGRES_USER=sonar
POSTGRES_PASSWORD=sonar
POSTGRES_DB=sonar

# SonarQube Configuration
SONARQUBE_PORT=9000

# Registry Configuration
REGISTRY_PORT=5000

# Portainer Configuration
PORTAINER_PORT=9443

# Agent Configuration (will be set after Jenkins starts)
JENKINS_AGENT_SECRET=

# Jenkins Admin Configuration
JENKINS_ADMIN_USER=admin
JENKINS_ADMIN_PASSWORD=admin

# Notification Configuration (optional)
SMTP_HOST=
SMTP_PORT=587
SMTP_USERNAME=
SMTP_PASSWORD=
SLACK_TOKEN=
GITHUB_TOKEN=
EOF

    print_status "✅ Environment file created: .env"
    print_warning "⚠️ Please update the .env file with your actual credentials before production use"
}

# Function to create backup script
create_backup_script() {
    print_header "Creating Backup Script"
    
    cat > backup-jenkins.sh << 'EOF'
#!/bin/bash

# Jenkins Backup Script

set -euo pipefail

BACKUP_DIR="jenkins_backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="jenkins_backup_${TIMESTAMP}"

echo "🔄 Starting Jenkins backup..."

# Create backup directory
mkdir -p "${BACKUP_DIR}"

# Stop Jenkins container
echo "⏹️ Stopping Jenkins container..."
docker-compose -f docker-compose.jenkins.yml stop jenkins

# Create backup
echo "📦 Creating backup archive..."
tar -czf "${BACKUP_DIR}/${BACKUP_NAME}.tar.gz" \
    -C "$(dirname "${JENKINS_HOME}")" \
    "$(basename "${JENKINS_HOME}")" \
    --exclude="workspace" \
    --exclude="logs" \
    --exclude="*.log"

# Start Jenkins container
echo "▶️ Starting Jenkins container..."
docker-compose -f docker-compose.jenkins.yml start jenkins

# Cleanup old backups (keep last 7 days)
find "${BACKUP_DIR}" -name "jenkins_backup_*.tar.gz" -mtime +7 -delete

echo "✅ Backup completed: ${BACKUP_DIR}/${BACKUP_NAME}.tar.gz"
echo "📊 Backup size: $(du -h "${BACKUP_DIR}/${BACKUP_NAME}.tar.gz" | cut -f1)"
EOF

    chmod +x backup-jenkins.sh
    print_status "✅ Backup script created: backup-jenkins.sh"
}

# Function to create management scripts
create_management_scripts() {
    print_header "Creating Management Scripts"
    
    # Start script
    cat > start-jenkins.sh << EOF
#!/bin/bash
echo "🚀 Starting Jenkins infrastructure..."
docker-compose -f ${COMPOSE_FILE} up -d
echo "✅ Jenkins started successfully!"
echo "📊 Jenkins Dashboard: http://localhost:${JENKINS_PORT}"
echo "📊 SonarQube: http://localhost:9000"
echo "📊 Portainer: https://localhost:9443"
echo "📊 Docker Registry: http://localhost:5000"
EOF

    # Stop script
    cat > stop-jenkins.sh << EOF
#!/bin/bash
echo "⏹️ Stopping Jenkins infrastructure..."
docker-compose -f ${COMPOSE_FILE} down
echo "✅ Jenkins stopped successfully!"
EOF

    # Status script
    cat > status-jenkins.sh << EOF
#!/bin/bash
echo "📊 Jenkins Infrastructure Status:"
echo "================================="
docker-compose -f ${COMPOSE_FILE} ps
echo ""
echo "📊 Network Information:"
docker network ls | grep jenkins
echo ""
echo "📊 Volume Information:"
docker volume ls | grep jenkins
EOF

    # Logs script
    cat > logs-jenkins.sh << EOF
#!/bin/bash
echo "📋 Jenkins Logs:"
echo "================"
docker-compose -f ${COMPOSE_FILE} logs -f jenkins
EOF

    # Make scripts executable
    chmod +x start-jenkins.sh stop-jenkins.sh status-jenkins.sh logs-jenkins.sh
    
    print_status "✅ Management scripts created"
}

# Function to start Jenkins
start_jenkins() {
    print_header "Starting Jenkins Infrastructure"
    
    # Create Docker network
    if ! docker network ls | grep -q "${DOCKER_NETWORK}"; then
        docker network create "${DOCKER_NETWORK}"
        print_status "✅ Docker network created: ${DOCKER_NETWORK}"
    fi
    
    # Start services
    print_status "Starting Jenkins services..."
    if command -v docker-compose &> /dev/null; then
        docker-compose -f "${COMPOSE_FILE}" up -d
    else
        docker compose -f "${COMPOSE_FILE}" up -d
    fi
    
    print_status "✅ Jenkins infrastructure started successfully!"
    
    # Wait for Jenkins to be ready
    print_status "⏳ Waiting for Jenkins to be ready..."
    local retries=0
    while [ $retries -lt 30 ]; do
        if curl -s "http://localhost:${JENKINS_PORT}/login" > /dev/null 2>&1; then
            print_status "✅ Jenkins is ready!"
            break
        fi
        sleep 10
        ((retries++))
        print_status "Waiting for Jenkins... (attempt $retries/30)"
    done
    
    if [ $retries -eq 30 ]; then
        print_warning "⚠️ Jenkins may still be starting up"
    fi
}

# Function to display access information
display_access_info() {
    print_header "Access Information"
    
    echo "🔗 Service URLs:"
    echo "  • Jenkins Dashboard: http://localhost:${JENKINS_PORT}"
    echo "  • SonarQube: http://localhost:9000"
    echo "  • Portainer: https://localhost:9443"
    echo "  • Docker Registry: http://localhost:5000"
    echo ""
    echo "🔐 Default Credentials:"
    echo "  • Jenkins: admin/admin"
    echo "  • SonarQube: admin/admin"
    echo "  • Portainer: Set on first login"
    echo ""
    echo "📁 Important Paths:"
    echo "  • Jenkins Home: ${JENKINS_HOME}"
    echo "  • Docker Compose: ${COMPOSE_FILE}"
    echo "  • Environment: .env"
    echo ""
    echo "🛠️ Management Commands:"
    echo "  • Start: ./start-jenkins.sh"
    echo "  • Stop: ./stop-jenkins.sh"
    echo "  • Status: ./status-jenkins.sh"
    echo "  • Logs: ./logs-jenkins.sh"
    echo "  • Backup: ./backup-jenkins.sh"
    echo ""
    echo "⚠️ Security Notes:"
    echo "  • Change default passwords immediately"
    echo "  • Configure proper authentication"
    echo "  • Set up SSL certificates for production"
    echo "  • Regularly backup Jenkins configuration"
}

# Main execution flow
main() {
    print_header "Jenkins Docker Setup"
    
    check_prerequisites
    create_directories
    create_docker_compose
    create_plugins_file
    create_init_script
    create_env_file
    create_backup_script
    create_management_scripts
    
    # Ask if user wants to start Jenkins now
    echo ""
    read -p "🚀 Would you like to start Jenkins now? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        start_jenkins
    else
        print_status "Jenkins setup completed. Run './start-jenkins.sh' to start when ready."
    fi
    
    display_access_info
    
    print_status "✅ Jenkins Docker setup completed successfully!"
}

# Execute main function
main "$@"