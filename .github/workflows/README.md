# Full-Stack GitHub Actions Workflows# GitHub Actions CI/CD Pipeline Documentation



Comprehensive CI/CD workflows for the full-stack Java microservice application with React frontend, PostgreSQL database, and Redis cache.This directory contains comprehensive GitHub Actions workflows for automated CI/CD, security scanning, infrastructure management, and release automation.



## 🏗️ Architecture Overview## 📁 Workflow Structure



``````

┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐.github/workflows/

│   Source Code   │    │   CI/CD Pipeline │    │   Deployment    │├── ci-cd-pipeline.yml      # Complete CI/CD pipeline with multi-environment deployment

├─────────────────┤    ├─────────────────┤    ├─────────────────┤├── pull-request.yml        # PR validation, testing, and quality gates

│ Backend (Java)  │───▶│ Parallel Builds │───▶│ Kubernetes      │├── security.yml           # Security scanning and vulnerability management

│ Frontend (React)│    │ Security Scans  │    │ AWS EKS         │├── infrastructure.yml      # Infrastructure provisioning and drift detection

│ Infrastructure  │    │ Quality Gates   │    │ Multi-Env       │├── release.yml            # Release management and automated deployments

│ Documentation   │    │ Approval Gates  │    │ Blue-Green      │└── README.md              # This documentation file

└─────────────────┘    └─────────────────┘    └─────────────────┘```

```

## 🚀 Workflow Overview

## 🔄 Workflows Overview

### 1. **Complete CI/CD Pipeline** (`ci-cd-pipeline.yml`)

### 1. **ci-cd-pipeline.yml** - Complete Full-Stack CI/CD Pipeline

The main comprehensive pipeline handling the entire full-stack application:**Comprehensive build, test, and deployment automation**



**Backend Processing:****Triggers:**

- ☕ Java 17/21 multi-version testing with PostgreSQL/Redis services- Push to `main`, `develop`, `feature/**`, `hotfix/**` branches

- 🧪 Unit and integration tests with real database connections- Pull requests to `main` or `develop`

- 📦 JAR artifact creation and Maven dependency management- Manual workflow dispatch

- 🐳 Backend container build with multi-architecture support

**Key Features:**

**Frontend Processing:**- 🔍 **Code Quality Analysis**: SonarQube integration with quality gates

- ⚛️ React TypeScript build with Node.js 18/20 testing- 🛡️ **Security Scanning**: Snyk, Trivy, and Anchore container security

- 🔍 ESLint code quality and Jest unit tests with coverage- 🏗️ **Multi-Java Testing**: Test against Java 17 and 21

- 🏗️ Vite production build optimization- 🐳 **Container Building**: Multi-architecture builds (AMD64, ARM64)

- 🐳 Frontend container build with Nginx serving- 📊 **SBOM Generation**: Software Bill of Materials for security tracking

- 🚀 **Multi-Environment Deployment**: Development → Staging → Production

**Database Management:**- 🔄 **Blue-Green Deployment**: Zero-downtime production deployments

- 🗄️ Flyway database migrations for development/staging environments- 📈 **Health Checks**: Automated smoke tests and monitoring

- ✅ Schema validation and rollback testing

- 🔧 Connection pooling and performance optimization**Deployment Flow:**

```

**Deployment Strategy:**Development (auto) → Staging (auto) → Production Approval → Production (manual)

- 🚀 Helm-based Kubernetes deployment with full-stack orchestration```

- 🎭 Multi-environment support (dev/staging/prod) with environment-specific values

- 🌟 Blue-green production deployment with health checks### 2. **Pull Request Validation** (`pull-request.yml`)

- 📊 Comprehensive monitoring and rollback capabilities

**Automated PR testing and quality validation**

### 2. **build-and-deploy.yml** - Simplified Full-Stack Build

Streamlined workflow for rapid development and testing:**Triggers:**

- 🔄 Parallel backend and frontend builds- Pull request events (opened, synchronized, reopened)

- 🐳 Dual container registry push (backend/frontend)- Pull request reviews

- 🚀 Single-command full-stack deployment

- ✨ Conditional component deployment (backend-only, frontend-only)**Key Features:**

- ✅ **PR Title Validation**: Semantic commit message enforcement

### 3. **infrastructure.yml** - Full-Stack Infrastructure Management  - 🧪 **Automated Testing**: Unit tests with coverage reporting

Infrastructure as Code for complete 3-tier architecture:- 🛡️ **Security Scanning**: Dependency vulnerability checks

- 🏗️ Terraform validation for RDS PostgreSQL + ElastiCache Redis- 🏗️ **Build Verification**: Docker container build testing

- 📦 Packer AMI builds with Ansible provisioning- 🚪 **Quality Gates**: SonarQube analysis for PRs

- 🌐 ALB configuration with path-based routing- 🤖 **Auto-merge**: Support for dependabot and tagged PRs

- 🔄 Auto Scaling Groups with service discovery- 🔮 **Deployment Preview**: Impact analysis and deployment planning

- 📋 **PR Summary**: Comprehensive validation results

### 4. **security.yml** - Full-Stack Security Scanning

Comprehensive security validation:### 3. **Security Scanning** (`security.yml`)

- 🛡️ Backend: OWASP Dependency Check, Snyk, container scanning

- 📦 Frontend: NPM audit, Snyk dependency scanning**Comprehensive security analysis and vulnerability management**

- 🏗️ Infrastructure: Terraform security scanning, AWS compliance

**Triggers:**

### 5. **pull-request.yml** - Full-Stack PR Validation- Daily schedule (2 AM UTC)

Enhanced pull request validation:- Push to `main` or `develop` branches

- 🔍 Component-specific change detection- Manual workflow dispatch

- ⚡ Fast build validation for changed components

- 📊 Code quality gates with coverage thresholds**Key Features:**

- 📦 **Dependency Scanning**: OWASP Dependency Check and Snyk

### 6. **release.yml** - Full-Stack Release Management- 🐳 **Container Security**: Trivy and Grype vulnerability scanning

Automated release creation:- 🔍 **Code Analysis**: CodeQL and Semgrep security rules

- 🏷️ Semantic versioning with component-specific tags- 🔐 **Secrets Scanning**: TruffleHog and GitLeaks detection

- 📝 Automated release notes from conventional commits- 🏗️ **Infrastructure Security**: Terraform security validation

- 📦 Multi-artifact publishing (JAR, containers, documentation)- 📋 **Compliance Checks**: GDPR, licensing, and security headers

- 🔧 **Automated Fixes**: Dependency update PRs

## 🔧 Configuration Requirements- 📊 **Security Reports**: Comprehensive security dashboard



### Required Secrets### 4. **Infrastructure Management** (`infrastructure.yml`)

```bash

# AWS Infrastructure**Automated infrastructure provisioning and management**

AWS_ACCESS_KEY_ID=<aws-access-key>

AWS_SECRET_ACCESS_KEY=<aws-secret-key>**Triggers:**

- Push to `main` (Terraform/Packer changes)

# Database Configuration- Pull requests (validation only)

DB_USERNAME=<postgres-username>- Manual workflow dispatch

DB_PASSWORD=<postgres-password>- Scheduled drift detection

DEV_DB_ENDPOINT=<dev-rds-endpoint>

STAGING_DB_ENDPOINT=<staging-rds-endpoint>**Key Features:**

PROD_DB_ENDPOINT=<prod-rds-endpoint>- 📋 **Terraform Planning**: Infrastructure change preview

- 🛡️ **Security Validation**: tfsec and Checkov infrastructure scanning

# Cache Configuration- 📦 **AMI Building**: Automated Packer image creation

REDIS_PASSWORD=<redis-password>- 🚀 **Infrastructure Deployment**: Automated Terraform apply

- 🧪 **Infrastructure Testing**: VPC, ALB, and security group validation

# Security Tools- 🗑️ **Destruction Support**: Safe infrastructure teardown

SONAR_TOKEN=<sonarcloud-token>- 🔍 **Drift Detection**: Automated configuration drift monitoring

SNYK_TOKEN=<snyk-api-token>- 📊 **Infrastructure Reports**: Deployment status and resource tracking

```

### 5. **Release Management** (`release.yml`)

## 🚀 Usage Examples

**Automated versioning, building, and release deployment**

### 1. Complete Development Workflow

```bash**Triggers:**

# Create feature branch with full-stack changes- Git tags matching `v*.*.*` pattern

git checkout -b feature/user-authentication- Manual workflow dispatch with version bumping



# Backend: Add UserController.java, UserService.java**Key Features:**

# Frontend: Add UserLogin.tsx, UserDashboard.tsx  - 🏷️ **Version Calculation**: Semantic versioning with automatic bumping

# Database: Add V1__Create_User_Table.sql- 🏗️ **Release Builds**: Production-ready artifact generation

- 🐳 **Release Containers**: Tagged container images with metadata

git commit -m "feat: add user authentication with database"- 📝 **Changelog Generation**: Automated release notes from commits

git push origin feature/user-authentication- 📦 **GitHub Releases**: Complete release creation with assets

- 🎭 **Staging Deployment**: Pre-production release testing

# Triggers: PR validation → full-stack build → deployment pipeline- 📋 **Production Approval**: Manual approval gates for releases

```- 🌟 **Production Deployment**: High-availability release deployment

- 🎉 **Post-Release Tasks**: Success notifications and reporting

### 2. Component-Specific Deployments

```bash## 🔧 Configuration Requirements

# Backend-only deployment

GitHub UI → ci-cd-pipeline.yml → Manual Dispatch### GitHub Secrets

→ Environment: development

→ Deploy Backend: trueConfigure the following secrets in your GitHub repository:

→ Deploy Frontend: false

```bash

# Database migration only# AWS Configuration

→ Run Migrations: trueAWS_ACCESS_KEY_ID          # AWS access key for infrastructure deployment

→ Skip Application Deployment: trueAWS_SECRET_ACCESS_KEY      # AWS secret access key

```

# Code Quality

## 📊 Workflow DependenciesSONAR_TOKEN               # SonarQube/SonarCloud authentication token



```mermaid# Security Scanning

graph TBSNYK_TOKEN                # Snyk security scanning token

    A[Code Push] --> B{Change Detection}SEMGREP_APP_TOKEN         # Semgrep security analysis token

    B -->|Backend| C[Java Build + Test]GITLEAKS_LICENSE          # GitLeaks license (if using enterprise)

    B -->|Frontend| D[React Build + Test]  ```

    B -->|Database| E[Migration Validation]

    ### Environment Protection

    C --> F[Backend Container]

    D --> G[Frontend Container] Set up environment protection rules in GitHub:

    E --> H[Database Migration]

    1. **Development**: No restrictions (auto-deployment)

    F --> I[Full-Stack Deployment]2. **Staging**: No restrictions (auto-deployment)

    G --> I3. **Production**: Required reviewers + manual approval

    H --> I4. **Production-Approval**: Required reviewers for release approval

    

    I --> J[Health Checks]### Branch Protection

    J --> K[Production Release]

```Configure branch protection for `main` and `develop`:



## 🔍 Monitoring and Troubleshooting- ✅ Require pull request reviews (2 reviewers)

- ✅ Require status checks to pass

### Health Checks- ✅ Require branches to be up to date

```bash- ✅ Include administrators

# Backend health- ✅ Restrict pushes

kubectl get pods -l app=java-microservice-backend

curl http://backend-url/actuator/health## 📊 Workflow Outputs and Artifacts



# Frontend health  ### Build Artifacts

kubectl get pods -l app=java-microservice-frontend- **JAR Files**: Java application artifacts

curl http://frontend-url/health- **Container Images**: Multi-architecture Docker images

- **Test Reports**: Coverage and test result reports

# Database connectivity- **Security Reports**: SARIF files for security analysis

kubectl exec backend-pod -- pg_isready -h db-endpoint- **SBOM**: Software Bill of Materials

```- **Infrastructure Plans**: Terraform execution plans



### Common Issues### Deployment Information

1. **Database Migration Failures**: Check migration syntax and connectivity- **Version Information**: Calculated semantic versions

2. **Frontend Build Failures**: Verify Node.js version and dependencies- **Environment URLs**: Deployment endpoint information

3. **Container Issues**: Review service discovery and resource limits- **Container Registry**: Image tags and digests

4. **Cross-Service Communication**: Check API endpoints and CORS policies- **Infrastructure Outputs**: VPC, Load Balancer, Security Group IDs



## ✅ GitHub Actions Updates Complete## 🚀 Usage Examples



All workflows have been successfully updated for the full-stack transformation:### Triggering Deployments



### 🎯 Key Enhancements**Development Deployment:**

- **Parallel Processing**: Backend and frontend builds run simultaneously```bash

- **Smart Change Detection**: Only build changed components# Push to develop branch

- **Database Integration**: PostgreSQL/Redis testing services and migrationsgit push origin develop

- **Container Orchestration**: Multi-architecture builds for all components# → Automatic deployment to development environment

- **Security Coverage**: Comprehensive scanning for Java, Node.js, and containers```

- **Environment Management**: Enhanced multi-environment support

**Staging and Production:**

Your GitHub Actions workflows now fully support the complete full-stack enterprise application with modern DevOps practices! 🎉```bash
# Push to main branch
git push origin main
# → Automatic deployment to staging
# → Manual approval required for production
```

**Manual Deployment:**
```bash
# Use workflow dispatch
# → Select environment and deployment options
```

### Creating Releases

**Automated Release (Recommended):**
```bash
# Create and push semantic version tag
git tag v1.2.3
git push origin v1.2.3
# → Automatic release creation and deployment
```

**Manual Release:**
```bash
# Use workflow dispatch in release.yml
# → Select release type (major/minor/patch/prerelease)
# → Automatic version calculation and release creation
```

### Infrastructure Management

**Infrastructure Updates:**
```bash
# Modify Terraform files and push
git add terraform/
git commit -m "feat: add new security group rules"
git push origin main
# → Automatic infrastructure plan and apply
```

**Drift Detection:**
```bash
# Runs automatically on schedule
# → Creates GitHub issue if drift detected
# → Manual intervention required to resolve
```

## 📋 Best Practices

### Commit Messages
Use semantic commit messages for automated changelog generation:
```bash
feat: add user authentication system
fix: resolve memory leak in data processing
docs: update API documentation
chore: update dependency versions
```

### Pull Request Process
1. **Create Feature Branch**: `feature/user-auth`
2. **Submit PR**: Automated validation runs
3. **Code Review**: Required reviewers approve
4. **Merge**: Automatic deployment to staging
5. **Release**: Manual production approval

### Security Management
- **Regular Scans**: Daily automated security scanning
- **Dependency Updates**: Automated PR creation for security patches
- **Secret Management**: Never commit secrets to repository
- **Container Security**: Multi-layer security scanning

### Infrastructure Management
- **Infrastructure as Code**: All infrastructure defined in Terraform
- **Validation**: Automated security and compliance checking
- **Drift Detection**: Regular monitoring of configuration drift
- **Disaster Recovery**: Automated backup and restoration procedures

## 🔍 Monitoring and Troubleshooting

### Workflow Monitoring
- **GitHub Actions Tab**: Real-time workflow execution
- **Environment Deployments**: Deployment history and status
- **Security Tab**: Security scanning results and alerts
- **Issues**: Automated issue creation for failures

### Common Issues and Solutions

**Build Failures:**
1. Check Java/Maven configuration
2. Verify dependency availability
3. Review test failures in artifacts

**Deployment Failures:**
1. Verify AWS credentials and permissions
2. Check Kubernetes cluster connectivity
3. Review Helm chart configuration

**Security Scan Failures:**
1. Review vulnerability reports in Security tab
2. Update dependencies with known vulnerabilities
3. Add suppressions for false positives

**Infrastructure Issues:**
1. Check Terraform plan for errors
2. Verify AWS service limits and quotas
3. Review security group and network configuration

## 🔗 Integration Points

### External Services
- **SonarQube/SonarCloud**: Code quality analysis
- **Snyk**: Security vulnerability scanning
- **AWS**: Cloud infrastructure deployment
- **Container Registry**: GitHub Container Registry (ghcr.io)
- **Kubernetes**: Application deployment platform

### Notification Integration
Configure notifications for:
- **Slack/Teams**: Deployment notifications
- **Email**: Security alert notifications
- **PagerDuty**: Production incident alerting
- **GitHub**: Issue creation and PR comments

## 📚 Additional Resources

### GitHub Actions Documentation
- [GitHub Actions Workflow Syntax](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions)
- [Environment Protection Rules](https://docs.github.com/en/actions/deployment/targeting-different-environments)
- [Security Hardening](https://docs.github.com/en/actions/security-guides/security-hardening-for-github-actions)

### Tool Documentation
- [Terraform GitHub Actions](https://learn.hashicorp.com/tutorials/terraform/github-actions)
- [Helm Actions](https://github.com/Azure/k8s-deploy)
- [Security Scanning Actions](https://github.com/github/codeql-action)

### Best Practices
- [CI/CD Best Practices](https://docs.github.com/en/actions/guides/about-continuous-integration)
- [Container Security](https://docs.github.com/en/code-security/supply-chain-security)
- [Infrastructure Security](https://learn.hashicorp.com/tutorials/terraform/security-scanning)