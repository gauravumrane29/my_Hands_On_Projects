# Amazon EKS Containerization and Deployment

This directory contains comprehensive configuration and automation scripts for deploying the Java microservice to Amazon EKS with GitOps, service mesh, and production-ready features.

## 🏗️ Architecture Overview

### Container Orchestration Stack
- **Amazon EKS**: Managed Kubernetes service with OIDC integration
- **Helm 3**: Package manager for Kubernetes with multi-environment support
- **ArgoCD**: GitOps continuous deployment platform
- **Istio Service Mesh**: Traffic management, security, and observability
- **AWS Load Balancer Controller**: Application Load Balancer integration
- **AWS ECR**: Container image registry with lifecycle policies

### Security Features
- **RBAC**: Role-based access control with least privilege
- **Pod Security Standards**: Enforced security contexts and policies
- **Network Policies**: Micro-segmentation and traffic control
- **mTLS**: Mutual TLS encryption via Istio
- **IRSA**: IAM Roles for Service Accounts integration
- **Security Scanning**: Container vulnerability scanning in CI/CD

### Monitoring and Observability
- **Prometheus**: Metrics collection and alerting
- **Grafana**: Visualization and dashboarding
- **Jaeger**: Distributed tracing
- **Fluent Bit**: Log collection and forwarding
- **AWS CloudWatch**: Native AWS monitoring integration

## 📁 Directory Structure

```
deployment/eks/
├── setup-eks-cluster.sh      # Complete EKS cluster setup automation
├── deploy-app.sh              # Application deployment script
├── cleanup.sh                 # Resource cleanup script
└── README.md                  # This documentation

deployment/helm/java-microservice/
├── Chart.yaml                 # Helm chart metadata
├── values.yaml               # Default configuration values
├── values-dev.yaml           # Development environment values
├── values-staging.yaml       # Staging environment values
├── values-prod.yaml          # Production environment values
└── templates/
    ├── _helpers.tpl          # Helm template helpers
    ├── deployment.yaml       # Kubernetes deployment
    ├── service.yaml          # Kubernetes service
    ├── configmap.yaml        # Application configuration
    ├── ingress.yaml          # ALB ingress controller
    ├── hpa.yaml              # Horizontal Pod Autoscaler
    ├── serviceaccount.yaml   # IAM service account
    ├── pdb.yaml              # Pod Disruption Budget
    └── networkpolicy.yaml    # Network security policies

deployment/argo/
├── applications.yaml         # ArgoCD application definitions
├── projects.yaml            # ArgoCD project configuration
└── application-{env}.yaml   # Environment-specific applications

deployment/istio/
├── gateway.yaml             # Istio gateway and virtual services
├── destinationrule.yaml     # Traffic policies and load balancing
└── security.yaml           # Security policies and authorization
```

## 🚀 Quick Start

### Prerequisites

1. **AWS CLI v2** with configured credentials
2. **kubectl** (compatible with EKS version)
3. **Helm 3**
4. **Docker** for building images
5. **jq** for JSON processing

### Step 1: Create EKS Cluster

```bash
# Set environment variables
export CLUSTER_NAME="java-microservice-eks"
export AWS_REGION="us-east-1"
export ENVIRONMENT="development"

# Run cluster setup (takes 15-20 minutes)
./deployment/eks/setup-eks-cluster.sh
```

### Step 2: Deploy Application

```bash
# Deploy to development environment
./deployment/eks/deploy-app.sh --environment development

# Deploy to staging environment
./deployment/eks/deploy-app.sh --environment staging --tag v1.0.0

# Deploy to production with ArgoCD
./deployment/eks/deploy-app.sh --environment production --argocd-only
```

### Step 3: Verify Deployment

```bash
# Check cluster status
kubectl get nodes

# Check application pods
kubectl get pods -n development

# Check services and ingress
kubectl get svc,ingress -n development

# Test application
kubectl port-forward svc/java-microservice 8080:80 -n development
curl http://localhost:8080/hello
```

## 🔧 Configuration

### Environment-Specific Values

Each environment has its own values file with optimized settings:

#### Development (`values-dev.yaml`)
- **Resources**: Minimal CPU/memory requests
- **Replicas**: 1 instance
- **Autoscaling**: Disabled
- **Monitoring**: Basic metrics
- **Security**: Relaxed policies for development

#### Staging (`values-staging.yaml`)
- **Resources**: Moderate CPU/memory requests
- **Replicas**: 2 instances
- **Autoscaling**: Enabled (2-5 replicas)
- **Monitoring**: Full observability stack
- **Security**: Production-like policies

#### Production (`values-prod.yaml`)
- **Resources**: Production-grade CPU/memory
- **Replicas**: 3+ instances with anti-affinity
- **Autoscaling**: Enabled (3-10 replicas)
- **Monitoring**: Complete observability with alerting
- **Security**: Strict security policies and compliance

### Key Configuration Options

```yaml
# Image Configuration
image:
  repository: "your-account.dkr.ecr.us-east-1.amazonaws.com/java-microservice-prod"
  tag: "latest"
  pullPolicy: IfNotPresent

# Resource Management
resources:
  requests:
    memory: "512Mi"
    cpu: "500m"
  limits:
    memory: "1Gi"
    cpu: "1000m"

# Autoscaling
autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70

# Service Configuration
service:
  type: ClusterIP
  port: 80
  targetPort: 8080

# Ingress with ALB
ingress:
  enabled: true
  className: "alb"
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
```

## 🛡️ Security Features

### Pod Security Context
```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1001
  fsGroup: 1001
  seccompProfile:
    type: RuntimeDefault
  capabilities:
    drop:
    - ALL
```

### Network Policies
- **Ingress Rules**: Only allow traffic from ALB and monitoring
- **Egress Rules**: Restricted outbound connectivity
- **Namespace Isolation**: Traffic segmentation between environments

### RBAC Configuration
- **Service Accounts**: Dedicated accounts with minimal permissions
- **Role Bindings**: Environment-specific access controls
- **IRSA Integration**: Secure AWS service access without credentials

## 📊 Monitoring and Observability

### Prometheus Metrics
The application exposes metrics at `/actuator/prometheus`:
- JVM metrics (memory, GC, threads)
- Application metrics (requests, latency)
- Custom business metrics

### Distributed Tracing
Istio automatically injects tracing headers for:
- Request correlation across services
- Performance analysis and bottleneck identification
- Dependency mapping

### Logging
Fluent Bit collects and forwards logs to:
- CloudWatch Logs for centralized logging
- Elasticsearch for advanced search and analysis
- Structured logging with correlation IDs

## 🔄 GitOps Workflow

### ArgoCD Applications
Each environment has a dedicated ArgoCD application:

```yaml
spec:
  source:
    repoURL: https://github.com/your-org/devops-project.git
    targetRevision: main
    path: deployment/helm/java-microservice
    helm:
      valueFiles:
        - values.yaml
        - values-production.yaml
  
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

### Deployment Process
1. **Code Push**: Developer pushes code to Git repository
2. **CI Pipeline**: GitHub Actions/Jenkins builds and pushes image
3. **GitOps**: ArgoCD detects changes and syncs to Kubernetes
4. **Validation**: Automated tests verify deployment health
5. **Monitoring**: Observability stack tracks application performance

## 🌐 Service Mesh (Istio)

### Traffic Management
```yaml
# Virtual Service for traffic routing
spec:
  http:
  - match:
    - headers:
        canary:
          exact: "true"
    route:
    - destination:
        host: java-microservice
        subset: canary
      weight: 100
  - route:
    - destination:
        host: java-microservice
        subset: stable
      weight: 100
```

### Security Policies
- **Authorization Policies**: RBAC at service level
- **Peer Authentication**: mTLS enforcement
- **Request Authentication**: JWT validation

### Observability
- **Kiali**: Service mesh visualization
- **Jaeger**: Distributed tracing
- **Prometheus**: Service mesh metrics

## 🏗️ Multi-Environment Strategy

### Environment Promotion
```bash
# Development → Staging
./deployment/eks/deploy-app.sh --environment staging --tag $(git rev-parse --short HEAD)

# Staging → Production (via ArgoCD)
kubectl patch application java-microservice-production -n argocd --type='merge' -p='{"spec":{"source":{"helm":{"parameters":[{"name":"image.tag","value":"v1.2.3"}]}}}}'
```

### Environment Isolation
- **Namespaces**: Logical separation of environments
- **Network Policies**: Traffic isolation between environments
- **RBAC**: Access control per environment
- **Resource Quotas**: Prevent resource contention

## 📈 Scaling and Performance

### Horizontal Pod Autoscaler (HPA)
```yaml
spec:
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

### Vertical Pod Autoscaler (VPA)
- **Automatic**: Right-size containers based on usage
- **Recommendations**: CPU and memory optimization
- **Update Policies**: Safe resource adjustments

### Cluster Autoscaler
- **Node Groups**: Automatic scaling of worker nodes
- **Spot Instances**: Cost optimization with mixed instance types
- **Multi-AZ**: High availability across availability zones

## 🔍 Troubleshooting

### Common Issues

#### Pod Startup Issues
```bash
# Check pod status
kubectl get pods -n development

# Check pod logs
kubectl logs -f deployment/java-microservice -n development

# Describe pod for events
kubectl describe pod <pod-name> -n development
```

#### Network Connectivity
```bash
# Test service connectivity
kubectl exec -it <pod-name> -n development -- curl http://java-microservice/hello

# Check network policies
kubectl get networkpolicy -n development

# Test external connectivity
kubectl exec -it <pod-name> -n development -- nslookup google.com
```

#### Performance Issues
```bash
# Check resource utilization
kubectl top pods -n development

# Check HPA status
kubectl get hpa -n development

# View metrics in Prometheus
kubectl port-forward svc/prometheus-server 9090:80 -n monitoring
```

### Debugging Commands

```bash
# Get cluster information
kubectl cluster-info

# Check node status and resources
kubectl get nodes -o wide
kubectl describe node <node-name>

# Check system pods
kubectl get pods -n kube-system

# View events
kubectl get events --sort-by=.metadata.creationTimestamp

# Check Istio configuration
istioctl analyze -n development

# Validate configuration
kubectl dry-run=client -o yaml apply -f deployment.yaml
```

## 🧹 Cleanup

### Application Cleanup
```bash
# Remove applications only
./deployment/eks/cleanup.sh --apps-only
```

### Full Infrastructure Cleanup
```bash
# Remove everything including EKS cluster
./deployment/eks/cleanup.sh --full-cleanup
```

### Selective Cleanup
```bash
# Remove specific environment
helm uninstall java-microservice-development -n development
kubectl delete namespace development
```

## 📚 Additional Resources

### Documentation
- [Amazon EKS User Guide](https://docs.aws.amazon.com/eks/latest/userguide/)
- [Helm Documentation](https://helm.sh/docs/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Istio Documentation](https://istio.io/latest/docs/)

### Best Practices
- [EKS Best Practices Guide](https://aws.github.io/aws-eks-best-practices/)
- [Kubernetes Security Best Practices](https://kubernetes.io/docs/concepts/security/)
- [GitOps Best Practices](https://www.weave.works/technologies/gitops/)

### Monitoring and Observability
- [Prometheus Best Practices](https://prometheus.io/docs/practices/)
- [Grafana Dashboards](https://grafana.com/grafana/dashboards/)
- [Jaeger Tracing](https://www.jaegertracing.io/docs/)

## 🤝 Contributing

1. Follow the established patterns for multi-environment support
2. Update documentation when adding new features
3. Test changes in development environment first
4. Ensure security policies are maintained
5. Add monitoring and alerting for new services

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.