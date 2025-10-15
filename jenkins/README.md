# Jenkins CI/CD Pipeline Documentation

> 📋 **Quick Links**: 
> - 🚀 **[Quick Start](./QUICK_START.md)** - Get running in 5 minutes
> - 🔧 **[Tool Config Fix](./TOOL_CONFIGURATION_ERROR_FIX.md)** - Fix Maven/NodeJS errors
> - 🔌 **[Plugin Installation](./PLUGIN_INSTALLATION.md)** - Install required plugins
> - 🩺 **[Troubleshooting](./TROUBLESHOOTING.md)** - Common errors and solutions
> - 🛠️ **[Agent Setup](./AGENT_SETUP_GUIDE.md)** - Configure Jenkins agents
> - 📁 **[Cleanup Analysis](./JENKINS_CLEANUP_ANALYSIS.md)** - File organization details

## Overview

This Jenkins CI/CD setup provides a comprehensive pipeline solution for the DevOps microservice project, featuring:

- **Declarative Pipeline**: Modern Jenkins pipeline with comprehensive stages
- **Multi-Environment Support**: Development, staging, and production environments
- **Security Integration**: OWASP dependency check, Trivy container scanning
- **Quality Gates**: SonarQube integration, code coverage, testing
- **Container Management**: Docker build, push, and deployment
- **Infrastructure Pipeline**: Terraform and Ansible automation
- **Configuration as Code**: JCasC for Jenkins configuration management

## 🏗️ Architecture

### Components

1. **Jenkins Master**: Main Jenkins controller with pipeline orchestration
2. **Build Agents**: Specialized agents for different build types
3. **SonarQube**: Code quality and security analysis
4. **Docker Registry**: Container image storage
5. **Portainer**: Docker container management
6. **PostgreSQL**: Database for SonarQube

### Network Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Jenkins Network                          │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │   Jenkins   │  │ Build Agent │  │ Build Agent │        │
│  │   Master    │  │  (Maven)    │  │  (Docker)   │        │
│  │   :8080     │  │             │  │             │        │
│  └─────────────┘  └─────────────┘  └─────────────┘        │
│         │                                                  │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │  SonarQube  │  │ PostgreSQL  │  │   Docker    │        │
│  │    :9000    │  │   Database  │  │  Registry   │        │
│  │             │  │             │  │    :5000    │        │
│  └─────────────┘  └─────────────┘  └─────────────┘        │
│                                                            │
│  ┌─────────────┐                                          │
│  │  Portainer  │                                          │
│  │    :9443    │                                          │
│  └─────────────┘                                          │
└─────────────────────────────────────────────────────────────┘
```

## 📋 Pipeline Features

### Main Application Pipeline (`Jenkinsfile`)

- **Environment Setup**: Dynamic configuration based on deployment target
- **Code Quality Analysis**: SonarQube integration with quality gates
- **Security Scanning**: 
  - OWASP Dependency Check for vulnerabilities
  - Trivy container vulnerability scanning
  - Dockerfile linting with hadolint
- **Build & Test**: 
  - Maven build with multiple Java versions
  - Unit and integration testing
  - Code coverage with JaCoCo
- **Container Management**:
  - Docker image building with multi-stage builds
  - Image security scanning
  - Registry push with proper tagging
- **Deployment**:
  - Kubernetes deployment with Helm
  - Multi-environment support (dev/staging/production)
  - Rolling updates and health checks
- **Infrastructure Validation**: Terraform and Packer validation

### Infrastructure Pipeline (`infrastructure-pipeline.groovy`)

- **Terraform Management**:
  - Multi-environment state management
  - Plan, apply, destroy operations
  - Drift detection
  - Cost analysis with Infracost
- **Security Scanning**: Checkov for infrastructure security
- **Ansible Configuration**: Automated server configuration post-deployment
- **Validation**: Infrastructure health checks and connectivity tests

### Key Pipeline Stages

#### 1. Environment Setup
```groovy
// Dynamic environment configuration
switch(params.DEPLOYMENT_ENVIRONMENT) {
    case 'production':
        env.REPLICAS = '3'
        env.RESOURCE_LIMITS = 'cpu=2000m,memory=4Gi'
        break
    case 'staging':
        env.REPLICAS = '2'
        env.RESOURCE_LIMITS = 'cpu=1000m,memory=2Gi'
        break
    default: // development
        env.REPLICAS = '1'
        env.RESOURCE_LIMITS = 'cpu=500m,memory=1Gi'
}
```

#### 2. Security Scanning
```groovy
// OWASP Dependency Check
mvn org.owasp:dependency-check-maven:check \
    -DfailBuildOnCVSS=7 \
    -Dformat=ALL

// Trivy Container Scanning
trivy image --severity HIGH,CRITICAL \
    ${env.IMAGE_NAME}:${env.IMAGE_TAG}
```

#### 3. Quality Gates
```groovy
// SonarQube Analysis
mvn sonar:sonar \
    -Dsonar.projectKey=${env.SONAR_PROJECT_KEY} \
    -Dsonar.coverage.jacoco.xmlReportPaths=target/site/jacoco/jacoco.xml
```

## 🛠️ Configuration

### Jenkins Configuration as Code (JCasC)

The `jenkins.yaml` file provides complete Jenkins configuration:

- **Security**: Matrix-based authorization, user management
- **Tools**: Maven, JDK, NodeJS, Docker configurations
- **Credentials**: Secure credential management for various services
- **Plugins**: Comprehensive plugin installation and configuration
- **Views**: Custom dashboard and pipeline views

### Environment Variables

```bash
# Jenkins Configuration
JENKINS_VERSION=lts-jdk17
JENKINS_PORT=8080
JENKINS_AGENT_PORT=50000

# Security Credentials
JENKINS_ADMIN_PASSWORD=your-secure-password
GITHUB_TOKEN=your-github-token
SONARQUBE_TOKEN=your-sonarqube-token
AWS_ACCESS_KEY_ID=your-aws-key
AWS_SECRET_ACCESS_KEY=your-aws-secret

# Service URLs
SONARQUBE_URL=http://sonarqube:9000
JIRA_URL=https://your-company.atlassian.net
SLACK_TEAM_DOMAIN=your-team
```

## 🚀 Setup Instructions

### 1. Prerequisites

- Docker and Docker Compose
- Git
- Basic understanding of Jenkins, Terraform, and Ansible

### 2. Initial Setup

```bash
# Clone the repository
git clone https://github.com/your-org/devops-project.git
cd devops-project

# Setup Jenkins with Docker
cd jenkins
chmod +x setup-jenkins-docker.sh
./setup-jenkins-docker.sh
```

### 3. Start Jenkins Infrastructure

```bash
# Start all services
./start-jenkins.sh

# Check status
./status-jenkins.sh

# View logs
./logs-jenkins.sh
```

### 4. Configure Jenkins

1. **Access Jenkins**: http://localhost:8080
2. **Login**: admin/admin (change immediately)
3. **Configure Credentials**: Add GitHub, AWS, SonarQube tokens
4. **Setup Build Agents**: Configure Maven and Docker agents
5. **Create Jobs**: Use Job DSL or manually create pipeline jobs

### 5. Pipeline Setup

```bash
# Create main application pipeline
# Point to repository containing Jenkinsfile

# Create infrastructure pipeline
# Point to repository containing infrastructure-pipeline.groovy
```

## 📊 Monitoring & Observability

### Service Dashboards

- **Jenkins Dashboard**: http://localhost:8080
- **SonarQube**: http://localhost:9000 (admin/admin)
- **Portainer**: https://localhost:9443
- **Docker Registry**: http://localhost:5000

### Pipeline Monitoring

1. **Build Status**: Real-time build status in Jenkins dashboard
2. **Quality Metrics**: Code coverage, technical debt in SonarQube
3. **Security Reports**: Vulnerability reports in build artifacts
4. **Resource Usage**: Container metrics in Portainer

### Notifications

- **Email**: Build success/failure notifications
- **Slack**: Real-time pipeline updates
- **JIRA**: Automatic issue linking and updates

## 🛡️ Security Features

### Pipeline Security

- **Credential Management**: Secure credential storage and rotation
- **Code Scanning**: SAST with SonarQube, dependency scanning with OWASP
- **Container Security**: Trivy vulnerability scanning, Dockerfile linting
- **Infrastructure Security**: Checkov for Terraform security scanning

### Access Control

- **Role-Based Access**: Matrix authorization with environment-specific permissions
- **Agent Security**: Secure agent communication with JNLP4
- **Network Security**: Isolated Docker network for services

## 📈 Best Practices

### Pipeline Development

1. **Use Declarative Syntax**: More readable and maintainable
2. **Parallel Stages**: Run independent tasks in parallel for speed
3. **Quality Gates**: Fail fast on quality issues
4. **Artifact Management**: Proper artifact archiving and cleanup
5. **Error Handling**: Comprehensive error handling and notifications

### Security Practices

1. **Credential Rotation**: Regular rotation of API keys and passwords
2. **Least Privilege**: Minimal required permissions for each component
3. **Vulnerability Management**: Regular security scanning and patching
4. **Audit Logging**: Comprehensive logging for security events

### Performance Optimization

1. **Agent Scaling**: Dynamic agent provisioning based on load
2. **Caching**: Maven dependency caching, Docker layer caching
3. **Resource Limits**: Proper resource allocation for containers
4. **Build Parallelization**: Parallel test execution

## 🔧 Troubleshooting

### Common Issues

#### Jenkins Won't Start
```bash
# Check Docker status
docker-compose -f docker-compose.jenkins.yml ps

# Check logs
docker-compose -f docker-compose.jenkins.yml logs jenkins

# Check permissions
sudo chown -R 1000:1000 ./jenkins_home
```

#### Build Agent Connection Issues
```bash
# Check agent logs
docker-compose -f docker-compose.jenkins.yml logs jenkins-agent

# Verify network connectivity
docker network ls | grep jenkins
```

#### SonarQube Integration Issues
```bash
# Check SonarQube status
curl -u admin:admin http://localhost:9000/api/system/status

# Verify database connection
docker-compose -f docker-compose.jenkins.yml logs postgres
```

### Performance Issues

#### Slow Builds
- Check agent resources and scaling
- Implement Maven dependency caching
- Use parallel test execution
- Optimize Docker build stages

#### Memory Issues
- Increase Java heap size for Jenkins
- Configure proper resource limits
- Monitor container resource usage

## 📚 Additional Resources

### Documentation

- [Jenkins Pipeline Syntax](https://www.jenkins.io/doc/book/pipeline/syntax/)
- [Configuration as Code](https://www.jenkins.io/projects/jcasc/)
- [SonarQube Integration](https://docs.sonarqube.org/latest/analysis/scan/sonarscanner-for-jenkins/)
- [Docker in Jenkins](https://www.jenkins.io/doc/book/installing/docker/)

### Example Repositories

- [Jenkins Shared Libraries](https://github.com/your-org/jenkins-shared-library)
- [Job DSL Examples](https://github.com/your-org/jenkins-jobs)
- [Pipeline Examples](https://github.com/your-org/jenkins-pipelines)

## 🔄 Maintenance

### Regular Tasks

1. **Backup Jenkins Configuration**: Use `./backup-jenkins.sh`
2. **Update Plugins**: Regular plugin updates for security
3. **Monitor Disk Usage**: Clean old builds and artifacts
4. **Security Patches**: Keep base images updated
5. **Performance Monitoring**: Monitor resource usage and optimize

### Backup Strategy

```bash
# Automated backup script
./backup-jenkins.sh

# Manual backup
tar -czf jenkins_backup_$(date +%Y%m%d).tar.gz jenkins_home/
```

### Update Procedure

```bash
# Update Jenkins
docker-compose -f docker-compose.jenkins.yml pull jenkins
docker-compose -f docker-compose.jenkins.yml up -d jenkins

# Update other services
docker-compose -f docker-compose.jenkins.yml pull
docker-compose -f docker-compose.jenkins.yml up -d
```

---

**Note**: This documentation provides a comprehensive guide for setting up and managing the Jenkins CI/CD pipeline. For production deployment, ensure proper security hardening, regular backups, and monitoring implementation.