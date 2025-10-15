# Deployment Configuration - Clean Structure

This directory contains the cleaned-up deployment configurations for the full-stack Java microservice application.

## 📁 Directory Structure

```
deployment/
├── argo/                           # ArgoCD GitOps configurations
│   ├── applications.yaml          # Application definitions for all environments
│   └── projects.yaml              # ArgoCD project configurations
├── eks/                           # Amazon EKS deployment scripts
│   ├── setup-eks-cluster.sh      # EKS cluster provisioning script
│   ├── deploy-app.sh              # Application deployment script
│   ├── cleanup.sh                 # Cleanup and teardown script
│   └── README.md                  # EKS-specific documentation
├── helm/                          # Helm charts for Kubernetes deployment
│   └── java-microservice/        # Main application Helm chart
│       ├── Chart.yaml             # Chart metadata and dependencies
│       ├── Chart.lock             # Dependency lock file
│       ├── values.yaml            # Default values for all environments
│       ├── values-dev.yaml        # Development environment overrides
│       ├── values-staging.yaml    # Staging environment overrides
│       ├── values-prod.yaml       # Production environment overrides
│       ├── charts/                # Dependency charts (PostgreSQL, Redis)
│       └── templates/             # Kubernetes resource templates
│           ├── _helpers.tpl       # Template helpers and functions
│           ├── backend-deployment.yaml      # Backend Java application
│           ├── frontend-deployment.yaml     # Frontend React application
│           ├── services.yaml      # Backend and frontend services
│           ├── configmap.yaml     # Application configuration
│           ├── ingress.yaml       # Ingress routing configuration
│           ├── hpa.yaml           # Horizontal Pod Autoscaler
│           ├── pdb.yaml           # Pod Disruption Budget
│           ├── networkpolicy.yaml # Network security policies
│           └── serviceaccount.yaml # Service account and RBAC
└── istio/                         # Istio service mesh configurations
    ├── gateway.yaml               # Istio gateway for external traffic
    ├── destinationrule.yaml       # Traffic policies and load balancing
    └── security.yaml              # mTLS and authorization policies
```

## 🧹 Cleanup Completed

### Removed Duplicate Files
The following duplicate and conflicting files have been cleaned up:

#### Values Files Removed:
- ❌ `values-original.yaml` → Kept `values.yaml` (main configuration)
- ❌ `values-dev-original.yaml` → Kept `values-dev.yaml` (development config)
- ❌ `values-staging-original.yaml` → Kept `values-staging.yaml` (staging config)  
- ❌ `values-prod-original.yaml` → Kept `values-prod.yaml` (production config)

#### Template Files Removed:
- ❌ `templates/hpa-original.yaml` → Kept `templates/hpa.yaml` (autoscaling config)

### Retained Working Files
The following files are the clean, working versions:

#### ✅ Chart Configuration:
- `Chart.yaml` - Main chart metadata with PostgreSQL and Redis dependencies
- `Chart.lock` - Locked dependency versions for consistency
- `values.yaml` - Production-ready default configuration

#### ✅ Environment-Specific Configurations:
- `values-dev.yaml` - Development environment (single replica, reduced resources)
- `values-staging.yaml` - Staging environment (balanced resources, production-like)
- `values-prod.yaml` - Production environment (multiple replicas, full resources)

#### ✅ Kubernetes Templates:
- `backend-deployment.yaml` - Spring Boot application deployment
- `frontend-deployment.yaml` - React application deployment with Nginx
- `services.yaml` - Both backend and frontend service definitions
- `ingress.yaml` - Path-based routing for API and web traffic
- `configmap.yaml` - Application configuration and environment variables
- `hpa.yaml` - Horizontal Pod Autoscaler for both services
- `pdb.yaml` - Pod Disruption Budget for high availability
- `networkpolicy.yaml` - Network security and isolation
- `serviceaccount.yaml` - RBAC and service account configuration

## 🔧 Helm Chart Validation

### Validation Results:
```bash
✅ Helm lint: PASSED (0 errors, 1 info - missing icon)
✅ Template rendering: PASSED (all templates valid)
✅ Dependency resolution: PASSED (PostgreSQL 12.12.10, Redis 18.1.5)
```

### Chart Dependencies:
```yaml
dependencies:
  - name: postgresql
    version: "12.12.10"
    repository: "https://charts.bitnami.com/bitnami"
    condition: postgresql.enabled
  - name: redis
    version: "18.1.5"
    repository: "https://charts.bitnami.com/bitnami"
    condition: redis.enabled
```

## 🚀 Deployment Usage

### 1. Development Deployment
```bash
helm upgrade --install java-microservice ./helm/java-microservice \
  --namespace development \
  --create-namespace \
  --values ./helm/java-microservice/values-dev.yaml \
  --set backend.image.tag=dev-latest \
  --set frontend.image.tag=dev-latest
```

### 2. Staging Deployment
```bash
helm upgrade --install java-microservice ./helm/java-microservice \
  --namespace staging \
  --create-namespace \
  --values ./helm/java-microservice/values-staging.yaml \
  --set backend.image.tag=staging-v1.2.3 \
  --set frontend.image.tag=staging-v1.2.3
```

### 3. Production Deployment
```bash
helm upgrade --install java-microservice ./helm/java-microservice \
  --namespace production \
  --create-namespace \
  --values ./helm/java-microservice/values-prod.yaml \
  --set backend.image.tag=v1.2.3 \
  --set frontend.image.tag=v1.2.3
```

## 📊 Configuration Hierarchy

The configuration follows this override hierarchy:

1. **Base**: `values.yaml` (default production-ready configuration)
2. **Environment Override**: `values-{env}.yaml` (environment-specific settings)
3. **Command Line**: `--set` parameters (deployment-time overrides)
4. **ArgoCD**: Application-specific parameters in `applications.yaml`

## 🔍 Key Configuration Areas

### Backend Service:
- **Image**: Configurable registry and tag
- **Resources**: CPU/memory requests and limits
- **Scaling**: Replica count and HPA configuration
- **Health**: Readiness and liveness probes
- **Database**: PostgreSQL connection configuration

### Frontend Service:
- **Image**: React build with Nginx serving
- **Resources**: Optimized for static content serving
- **Scaling**: Independent from backend scaling
- **Routing**: Nginx configuration for SPA routing

### Database & Cache:
- **PostgreSQL**: Bitnami chart with persistent storage
- **Redis**: Bitnami chart with clustering support
- **Persistence**: Environment-specific storage classes
- **Security**: Passwords and encryption configuration

## 🛡️ Security Features

- **Network Policies**: Micro-segmentation and traffic isolation
- **RBAC**: Least-privilege service accounts
- **Pod Security**: Security contexts and non-root execution
- **Secrets Management**: Encrypted secrets for database credentials
- **Image Security**: Private registry and vulnerability scanning

## 📈 Monitoring Integration

The cleaned-up deployment includes monitoring integration:

- **Prometheus**: Service monitors and metric collection
- **Grafana**: Dashboard configurations and alerts
- **Health Checks**: Comprehensive health and readiness probes
- **Log Aggregation**: Structured logging for both services

## ✅ Clean Deployment Structure Complete

The deployment directory now has a clean, consistent structure with:

- 🧹 **No duplicate files** - All conflicting versions removed
- 📁 **Clear organization** - Logical directory structure
- ✅ **Validated configuration** - Helm lint and template validation passed
- 🔧 **Environment separation** - Clean dev/staging/prod configurations
- 📖 **Complete documentation** - Clear usage instructions

Your deployment configuration is now production-ready with a clean, maintainable structure!