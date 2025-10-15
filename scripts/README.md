# Shell Scripts for DevOps Automation

This directory contains comprehensive shell scripts for automating DevOps tool installations and system configuration.

## 📁 Script Overview

### `install_jenkins.sh`
**Comprehensive Jenkins CI/CD Server Installation**

Features:
- ✅ System requirements validation (disk space, memory, OS compatibility)
- ✅ Java 17 installation with JAVA_HOME configuration
- ✅ Jenkins LTS installation with official repositories
- ✅ Security hardening and firewall configuration
- ✅ Additional DevOps tools (Docker, Maven, Node.js)
- ✅ Automated backup system with daily scheduling
- ✅ Initial admin password retrieval

Usage:
```bash
# Make executable and run
chmod +x install_jenkins.sh
./install_jenkins.sh
```

System Requirements:
- Ubuntu/Debian Linux
- 2GB+ disk space
- 1GB+ RAM (recommended)
- Sudo privileges

### `install_docker.sh`
**Multi-OS Docker and Docker Compose Installation**

Features:
- ✅ Multi-OS support (Ubuntu, Debian, CentOS, RHEL, Amazon Linux, macOS)
- ✅ Architecture detection (x86_64, ARM64, ARMv7)
- ✅ Old Docker version cleanup
- ✅ Production-ready daemon configuration
- ✅ Docker Compose installation
- ✅ User group management
- ✅ System cleanup and monitoring scripts

Usage:
```bash
# Make executable and run
chmod +x install_docker.sh
./install_docker.sh
```

Supported Systems:
- Ubuntu 18.04+
- Debian 9+
- CentOS 7+
- RHEL 7+
- Amazon Linux 2
- macOS (via Homebrew)

### `install_devops_tools.sh`
**All-in-One DevOps Toolkit Installer**

Installs and configures:
- 🔧 **Terraform** 1.12.2 - Infrastructure as Code
- 🔧 **Packer** 1.14.2 - Image building automation
- 🔧 **Ansible** 9.2.0 - Configuration management
- 🔧 **kubectl** v1.28.2 - Kubernetes CLI
- 🔧 **Helm** v3.13.0 - Kubernetes package manager
- 🔧 **Docker Compose** v2.20.2 - Multi-container applications
- 🔧 **AWS CLI** 2.15.0 - Amazon Web Services CLI
- 🔧 **Vault** 1.15.0 - Secrets management
- 🔧 **Additional Tools**: jq, yq, kubectx, kubens, k9s

Features:
- ✅ Version-specific installations
- ✅ Architecture auto-detection
- ✅ Shell completions and aliases
- ✅ Version verification and reporting
- ✅ Cleanup and error handling
- ✅ Production-ready configurations

Usage:
```bash
# Make executable and run
chmod +x install_devops_tools.sh
./install_devops_tools.sh

# Check installed versions
devops-versions
```

## 🚀 Quick Start Guide

### 1. Complete DevOps Environment Setup
```bash
# Install all essential DevOps tools first
./install_devops_tools.sh

# Install Jenkins for CI/CD
./install_jenkins.sh

# Install Docker (if not already installed by devops tools)
./install_docker.sh
```

### 2. Verify Installations
```bash
# Check all tool versions
devops-versions

# Verify Docker
docker --version
docker run hello-world

# Verify Jenkins
sudo systemctl status jenkins
curl -I http://localhost:8080

# Verify Kubernetes tools
kubectl version --client
helm version
```

## 🔧 Configuration Details

### Jenkins Configuration
After installation, Jenkins includes:
- **Java 17** with proper JAVA_HOME
- **Docker** integration for containerized builds
- **Maven** for Java project builds
- **Node.js** for modern web development
- **Daily backup system** with 7-day retention
- **Security hardening** with firewall rules

Access Jenkins at: `http://your-server:8080`

Initial admin password location: `/var/lib/jenkins/secrets/initialAdminPassword`

### Docker Configuration
Production-ready Docker setup includes:
- **JSON file logging** with size and rotation limits
- **Overlay2 storage driver** for better performance
- **BuildKit enabled** for improved build performance
- **User group management** for secure access
- **System cleanup scripts** for maintenance

### DevOps Tools Configuration
Post-installation setup includes:
- **Shell completions** for all CLI tools
- **Useful aliases** (k=kubectl, tf=terraform, etc.)
- **Version checking utility** (`devops-versions`)
- **Environment variables** properly configured
- **Plugin installations** for Ansible collections

## 📊 System Requirements

### Minimum Requirements
- **OS**: Linux (Ubuntu 18.04+, CentOS 7+, Amazon Linux 2)
- **CPU**: 2 cores
- **RAM**: 4GB (8GB recommended for Jenkins + Docker)
- **Disk**: 20GB available space
- **Network**: Internet connectivity for downloads

### Recommended Setup
- **OS**: Ubuntu 20.04 LTS or Amazon Linux 2
- **CPU**: 4 cores
- **RAM**: 8GB
- **Disk**: 50GB SSD
- **Network**: High-speed internet connection

## 🛠️ Advanced Usage

### Custom Tool Versions
Edit version variables at the top of each script:
```bash
# In install_devops_tools.sh
TERRAFORM_VERSION="1.12.2"
PACKER_VERSION="1.14.2"
KUBECTL_VERSION="v1.28.2"
```

### Jenkins Plugins
Install additional Jenkins plugins:
```bash
# Install Jenkins CLI
wget http://localhost:8080/jnlpJars/jenkins-cli.jar

# Install plugins
java -jar jenkins-cli.jar -s http://localhost:8080/ install-plugin \
  pipeline-stage-view \
  docker-pipeline \
  kubernetes \
  ansible
```

### Docker Cleanup Automation
Set up automated cleanup:
```bash
# Add to crontab for weekly cleanup
echo "0 2 * * 0 /usr/local/bin/docker-cleanup.sh" | sudo crontab -
```

## 🔐 Security Considerations

### Jenkins Security
- Change default admin password immediately
- Enable security realm and authorization
- Install security plugins (OWASP, Security Scanner)
- Configure proper user permissions
- Enable CSRF protection
- Use HTTPS in production

### Docker Security
- Run containers as non-root users
- Use minimal base images
- Scan images for vulnerabilities
- Limit container resources
- Use Docker secrets for sensitive data
- Enable Docker Content Trust

### System Security
- Keep all tools updated to latest versions
- Use SSH key authentication
- Configure firewall rules properly
- Enable fail2ban for brute force protection
- Regular security updates and patches

## 🔧 Troubleshooting

### Common Issues

#### Jenkins Won't Start
```bash
# Check service status
sudo systemctl status jenkins

# Check logs
sudo journalctl -u jenkins -f

# Check Java installation
java -version

# Verify port availability
sudo netstat -tlnp | grep :8080
```

#### Docker Permission Denied
```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Logout and login again, or run:
newgrp docker

# Test Docker access
docker run hello-world
```

#### Tool Not Found After Installation
```bash
# Check PATH
echo $PATH

# Reload shell configuration
source ~/.bashrc

# Check installation location
which terraform
which kubectl
```

#### Network/Download Issues
```bash
# Check internet connectivity
ping google.com

# Check DNS resolution
nslookup releases.hashicorp.com

# Use proxy if needed (set in script)
export HTTP_PROXY=http://proxy:port
export HTTPS_PROXY=http://proxy:port
```

## 📋 Maintenance Scripts

### Automated Backups
```bash
# Jenkins backup (created by install script)
/usr/local/bin/jenkins-backup.sh

# Manual backup
sudo systemctl stop jenkins
sudo tar -czf jenkins-backup.tar.gz /var/lib/jenkins/
sudo systemctl start jenkins
```

### System Updates
```bash
# Update all DevOps tools
./install_devops_tools.sh  # Re-run to update

# Update Docker
./install_docker.sh  # Re-run to update

# Update system packages
sudo apt update && sudo apt upgrade  # Ubuntu/Debian
sudo yum update  # CentOS/RHEL
```

### Health Monitoring
```bash
# Check all services
sudo systemctl status jenkins docker

# Monitor resource usage
htop
df -h
free -h

# Check logs
sudo journalctl -u jenkins -f
sudo journalctl -u docker -f
```

## 🚀 Integration Examples

### CI/CD Pipeline Setup
```bash
# 1. Install all tools
./install_devops_tools.sh
./install_jenkins.sh

# 2. Configure Jenkins pipeline with:
# - Git checkout
# - Maven/Gradle build
# - Docker image build
# - Kubernetes deployment
# - Ansible configuration
```

### Infrastructure Automation
```bash
# 1. Use Terraform to provision infrastructure
terraform init
terraform plan
terraform apply

# 2. Use Packer to build AMIs
packer build app_ami.pkr.hcl

# 3. Use Ansible to configure servers
ansible-playbook -i inventory site.yml
```

## 📚 Additional Resources

### Documentation Links
- [Jenkins User Documentation](https://www.jenkins.io/doc/)
- [Docker Documentation](https://docs.docker.com/)
- [Terraform Documentation](https://www.terraform.io/docs/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Ansible Documentation](https://docs.ansible.com/)

### Best Practices
- Always test scripts in non-production environments first
- Keep scripts version-controlled
- Use configuration management for consistency
- Implement proper logging and monitoring
- Regular backups and disaster recovery testing

### Community Resources
- [DevOps Roadmap](https://roadmap.sh/devops)
- [12-Factor App Methodology](https://12factor.net/)
- [Cloud Native Computing Foundation](https://www.cncf.io/)

## 📞 Support

For issues and questions:
1. Check the troubleshooting section above
2. Review system logs for error messages
3. Verify system requirements are met
4. Check network connectivity and permissions
5. Consult official tool documentation

Remember to always backup your systems before running installation scripts in production environments.