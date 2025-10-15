# Configuration Management (Ansible + Shell) - README

This directory contains enhanced configuration management tools built on top of Ansible with additional shell scripts for DevOps automation.

## 📁 Directory Structure

```
ansible/
├── ansible.cfg                 # Enhanced Ansible configuration
├── inventory                   # Multi-environment inventory with production setup
├── server-setup.yml           # Complete server configuration playbook
├── k8s-setup.yml              # Kubernetes ecosystem installation
├── configure-app.yml          # Application-specific configuration (existing)
├── install-docker.yml         # Docker installation playbook (existing)
└── README.md                   # This file

scripts/
├── install_jenkins.sh         # Comprehensive Jenkins installation script
├── install_docker.sh          # Multi-OS Docker installation script  
├── install_devops_tools.sh    # All-in-one DevOps tools installer
└── README.md                   # Scripts documentation
```

## 🚀 Quick Start

### 1. Install DevOps Tools
```bash
# Install all essential DevOps tools (Terraform, Packer, Ansible, kubectl, etc.)
./scripts/install_devops_tools.sh
```

### 2. Install Jenkins CI/CD Server
```bash
# Install Jenkins with Java 17, Docker, and additional tools
./scripts/install_jenkins.sh
```

### 3. Install Docker (Multi-OS Support)
```bash
# Install Docker and Docker Compose on various Linux distributions
./scripts/install_docker.sh
```

## 📋 Ansible Playbooks

### Server Setup Playbook (`server-setup.yml`)
Comprehensive server configuration including:

- **System Updates**: Package management and security updates
- **Java 17 Installation**: OpenJDK with proper environment setup
- **Docker Integration**: Container runtime with security configuration
- **CloudWatch Agent**: AWS monitoring and logging
- **Security Hardening**: SSH, fail2ban, firewall configuration
- **Performance Tuning**: System limits and kernel parameters
- **Application Service**: Systemd service configuration
- **Backup & Maintenance**: Automated scripts and cron jobs

```bash
# Run complete server setup
ansible-playbook -i inventory server-setup.yml --limit production

# Run specific components
ansible-playbook -i inventory server-setup.yml --tags "java,docker"
ansible-playbook -i inventory server-setup.yml --tags "security"
ansible-playbook -i inventory server-setup.yml --tags "monitoring"
```

### Kubernetes Setup Playbook (`k8s-setup.yml`)
Complete Kubernetes ecosystem installation:

- **Container Runtime**: containerd with proper configuration
- **Kubernetes Components**: kubelet, kubeadm, kubectl
- **Cluster Initialization**: Master node setup with networking
- **CNI Plugin**: Calico network plugin installation
- **Helm Package Manager**: Latest Helm with repository setup
- **Ingress Controller**: NGINX ingress for load balancing
- **Monitoring Stack**: Prometheus and Grafana installation
- **DevOps Tools**: kubectx, kubens, k9s dashboard

```bash
# Install Kubernetes on master nodes
ansible-playbook -i inventory k8s-setup.yml --limit k8s_masters

# Install on worker nodes  
ansible-playbook -i inventory k8s-setup.yml --limit k8s_workers

# Complete cluster setup
ansible-playbook -i inventory k8s-setup.yml --limit k8s_cluster
```

## 🏗️ Infrastructure Inventory

The enhanced inventory supports multiple environments and server roles:

### Environments
- **Production**: High-availability setup with redundancy
- **Staging**: Simplified environment for testing  
- **Development**: All-in-one development server
- **Kubernetes**: Dedicated cluster infrastructure
- **CI/CD**: Jenkins and build infrastructure

### Server Roles
- **Web Servers**: NGINX load balancing and SSL termination
- **App Servers**: Java application hosting with JVM tuning
- **Database Servers**: PostgreSQL with replication setup
- **Load Balancers**: Application Load Balancer configuration
- **Monitoring**: Prometheus, Grafana, and logging stack
- **CI/CD**: Jenkins master/agent setup

### Usage Examples
```bash
# Deploy to production web servers
ansible-playbook -i inventory server-setup.yml --limit web_servers

# Configure staging environment
ansible-playbook -i inventory server-setup.yml --limit staging

# Setup CI/CD infrastructure
ansible-playbook -i inventory server-setup.yml --limit cicd

# Configure monitoring stack
ansible-playbook -i inventory server-setup.yml --limit monitoring_servers
```

## 🛠️ Shell Scripts

### Jenkins Installation (`install_jenkins.sh`)
- **Requirements Check**: System compatibility and resources
- **Java 17 Setup**: Automated JDK installation and configuration
- **Jenkins Installation**: Latest LTS version with security
- **Additional Tools**: Docker, Maven, Node.js for builds
- **Backup Configuration**: Automated daily backup system
- **Firewall Setup**: Security configuration

### Docker Installation (`install_docker.sh`)
- **Multi-OS Support**: Ubuntu, Debian, CentOS, RHEL, Amazon Linux
- **Version Management**: Specific version installation
- **Security Configuration**: Production-ready daemon settings
- **Docker Compose**: Latest compose version
- **Management Scripts**: Cleanup and monitoring tools

### DevOps Tools Installer (`install_devops_tools.sh`)
Installs complete DevOps toolkit:
- **Infrastructure as Code**: Terraform, Packer
- **Configuration Management**: Ansible with collections
- **Container Orchestration**: kubectl, Helm
- **Cloud Tools**: AWS CLI, Azure CLI
- **Monitoring**: Prometheus tools
- **Version Control**: Git with LFS
- **Shell Enhancements**: Completions and aliases

## 🔧 Configuration Features

### Advanced Ansible Configuration
- **Performance Optimized**: Pipelining, connection multiplexing
- **Security Hardened**: SSH key management, privilege escalation
- **Multi-Environment**: Environment-specific variables and settings
- **Plugin Support**: Comprehensive plugin configuration
- **Callback Plugins**: Enhanced output and timing information

### Environment Variables
Each environment includes specific configurations:
- **Resource Limits**: Memory, CPU, and storage allocations
- **Security Settings**: SSL, firewall, and access controls
- **Monitoring**: Logging levels and retention policies  
- **Backup Policies**: Retention and scheduling configuration

## 📊 Monitoring and Maintenance

### Health Check Scripts
```bash
# System health report
/usr/local/bin/health-check.sh

# Application backup
/usr/local/bin/java-microservice-backup.sh

# Docker system cleanup
/usr/local/bin/docker-cleanup.sh

# DevOps tools version check
devops-versions
```

### Automated Maintenance
- **Daily Backups**: Application and configuration backups
- **Log Rotation**: Automated log management with retention
- **Security Updates**: Automatic security patch installation
- **Performance Monitoring**: System metrics and alerting
- **Health Checks**: Automated service status verification

## 🔐 Security Features

### System Hardening
- **SSH Security**: Key-only authentication, port changes
- **Firewall Configuration**: UFW/firewalld with service rules  
- **Fail2ban Protection**: Brute force attack prevention
- **User Management**: Restricted service accounts
- **File Permissions**: Secure application directories

### Container Security
- **Docker Security**: Non-root containers, resource limits
- **Image Security**: Verified base images, vulnerability scanning
- **Network Security**: Container network isolation
- **Secret Management**: Secure credential handling

## 🚀 Deployment Workflows

### Production Deployment
```bash
# 1. Prepare infrastructure
ansible-playbook -i inventory server-setup.yml --limit production --check

# 2. Deploy configuration
ansible-playbook -i inventory server-setup.yml --limit production

# 3. Verify deployment
ansible-playbook -i inventory server-setup.yml --limit production --tags "verification"
```

### Development Setup
```bash
# Quick development environment setup
ansible-playbook -i inventory server-setup.yml --limit development

# Install development tools
./scripts/install_devops_tools.sh
```

## 📚 Best Practices

### Ansible Usage
- **Idempotency**: All playbooks are designed for repeated execution
- **Tags**: Use tags for selective task execution
- **Dry Run**: Always test with `--check` before production deployment
- **Inventory Management**: Keep environment-specific variables organized
- **Secret Management**: Use Ansible Vault for sensitive data

### Infrastructure Management
- **Version Control**: All configurations should be version controlled
- **Testing**: Test playbooks in staging before production
- **Documentation**: Keep inventory and playbooks well-documented
- **Monitoring**: Implement comprehensive monitoring and alerting
- **Backup Strategy**: Regular backups with tested restore procedures

## 🔗 Integration Points

This configuration management setup integrates with:
- **Terraform**: Infrastructure provisioning and networking
- **Packer**: AMI building with pre-configured software
- **Jenkins**: CI/CD pipeline automation
- **Docker**: Containerized application deployment
- **Kubernetes**: Container orchestration at scale
- **AWS CloudWatch**: Monitoring and logging services

## 📞 Support and Troubleshooting

### Common Issues
1. **SSH Connection Issues**: Check key permissions and inventory configuration
2. **Privilege Escalation**: Ensure sudo access for target hosts
3. **Package Installation**: Verify internet connectivity and package repositories
4. **Service Startup**: Check system logs and service status

### Debugging
```bash
# Verbose Ansible output
ansible-playbook -vvv -i inventory playbook.yml

# Check specific host connectivity
ansible -i inventory production -m ping

# Test specific tasks
ansible-playbook -i inventory playbook.yml --tags "debug" --check
```

For additional support, refer to the individual script documentation and Ansible official documentation.