# Complete Deployment Guide - Full-Stack DevOps Project

**Last Updated**: October 15, 2025  
**Project**: React + Spring Boot + PostgreSQL + Redis Full-Stack Application  
**Target Audience**: DevOps Engineers, Developers, System Administrators

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Local Development Setup](#local-development-setup)
3. [Docker Development Environment](#docker-development-environment)
4. [Production Docker Deployment](#production-docker-deployment)
5. [AWS Infrastructure Deployment](#aws-infrastructure-deployment)
6. [Kubernetes (EKS) Deployment](#kubernetes-eks-deployment)
7. [CI/CD Pipeline Setup](#cicd-pipeline-setup)
8. [Monitoring & Observability](#monitoring--observability)
9. [Domain & SSL Configuration](#domain--ssl-configuration)
10. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Required Software & Tools

#### 1. **Development Tools**
```bash
# Check if tools are installed
java --version          # Java 17 or higher
node --version          # Node.js 18 or higher
npm --version           # npm 9 or higher
docker --version        # Docker 20.10 or higher
docker-compose --version # Docker Compose 2.0 or higher
```

#### 2. **Cloud & DevOps Tools**
```bash
# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Install Terraform
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install eksctl
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin

# Verify installations
aws --version
terraform --version
kubectl version --client
helm version
eksctl version
```

#### 3. **AWS Account Setup**
- AWS Account with billing enabled
- IAM user with Administrator access (for initial setup)
- AWS Access Key ID and Secret Access Key
- Default region configured (e.g., us-east-1)

```bash
# Configure AWS credentials
aws configure
# Enter: Access Key ID
# Enter: Secret Access Key  
# Enter: Default region (us-east-1)
# Enter: Default output format (json)

# Verify AWS access
aws sts get-caller-identity
```

---

## Local Development Setup

### Step 1: Clone the Repository

```bash
# Clone the project
git clone https://github.com/gauravumrane29/my_Hands_On_Projects.git
cd my_Hands_On_Projects

# Verify project structure
ls -la
```

### Step 2: Backend Setup (Spring Boot)

```bash
# Navigate to backend
cd app

# Build the application
./mvnw clean package -DskipTests

# Run locally (without Docker)
./mvnw spring-boot:run

# Test the backend
curl http://localhost:8080/actuator/health
# Expected: {"status":"UP"}

# Test API endpoint
curl http://localhost:8080/api/hello
# Expected: "Hello from Spring Boot!"
```

### Step 3: Frontend Setup (React)

```bash
# Navigate to frontend (in new terminal)
cd frontend

# Install dependencies
npm install

# Start development server
npm start

# Application will open at http://localhost:3000
```

### Step 4: Database Setup (PostgreSQL)

```bash
# Option 1: Using Docker
docker run --name postgres-local \
  -e POSTGRES_DB=demoapp \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -p 5432:5432 \
  -d postgres:15-alpine

# Option 2: Local PostgreSQL installation
sudo apt-get install postgresql-15
sudo -u postgres createdb demoapp
sudo -u postgres createuser -s postgres

# Verify database connection
psql -h localhost -U postgres -d demoapp -c "SELECT version();"
```

---

## Docker Development Environment

### Step 1: Start Development Environment

```bash
# Navigate to project root
cd /path/to/my_Hands_On_Projects

# Start all services in development mode
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d

# View logs
docker-compose logs -f

# Check running containers
docker-compose ps
```

**Services Available:**
- **Frontend**: http://localhost:3000 (React Dev Server with hot reload)
- **Backend**: http://localhost:8080 (Spring Boot with debugging on port 5005)
- **PostgreSQL**: localhost:5432
- **Redis**: localhost:6379
- **PgAdmin**: http://localhost:5050 (admin@example.com / admin)
- **Nginx**: http://localhost:80

### Step 2: Verify Services

```bash
# Test backend health
curl http://localhost:8080/actuator/health

# Test frontend
curl http://localhost:3000

# Test database connection
docker exec -it postgres-db psql -U postgres -d demoapp -c "SELECT version();"

# Test Redis
docker exec -it redis-cache redis-cli ping
# Expected: PONG

# View application logs
docker-compose logs backend
docker-compose logs frontend
```

### Step 3: Development Workflow

```bash
# Make code changes in your IDE
# - Backend: Changes in ./app/src will be hot-reloaded
# - Frontend: Changes in ./frontend/src will be hot-reloaded

# Restart specific service if needed
docker-compose restart backend
docker-compose restart frontend

# Stop all services
docker-compose down

# Stop and remove volumes (clean slate)
docker-compose down -v
```

---

## Production Docker Deployment

### Step 1: Build Production Images

```bash
# Navigate to project root
cd /path/to/my_Hands_On_Projects

# Set environment variables
export DB_PASSWORD="your-secure-password"
export REACT_APP_API_URL="https://api.yourdomain.com"

# Build production images
docker-compose -f docker-compose.yml -f docker-compose.prod.yml build

# Verify images
docker images | grep -E "backend|frontend"
```

### Step 2: Start Production Environment

```bash
# Start production services
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# Monitor startup
docker-compose logs -f backend frontend

# Verify health checks
curl http://localhost/actuator/health  # Backend via Nginx
curl http://localhost/                  # Frontend via Nginx
```

### Step 3: Production Checklist

```bash
# ✅ Verify all containers are running
docker-compose ps

# ✅ Check resource usage
docker stats

# ✅ Test database migrations
docker exec -it spring-backend java -jar /app/demo.jar --spring.profiles.active=production db migrate

# ✅ Test Redis connectivity
docker exec -it spring-backend curl http://localhost:8080/api/cache/test

# ✅ Monitor logs for errors
docker-compose logs --tail=100 | grep ERROR
```

---

## AWS Infrastructure Deployment

### Step 1: Prepare Terraform Configuration

```bash
# Navigate to terraform directory
cd terraform

# Copy example variables
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your values
nano terraform.tfvars
```

**Required Variables:**
```hcl
# terraform.tfvars
aws_region          = "us-east-1"
project_name        = "fullstack-devops"
environment         = "production"

# VPC Configuration
vpc_cidr           = "10.0.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]

# Database Configuration
db_instance_class  = "db.t3.medium"
db_name            = "demoapp"
db_username        = "postgres"
db_password        = "CHANGE-ME-SECURE-PASSWORD"

# ElastiCache Configuration
redis_node_type    = "cache.t3.micro"
redis_num_nodes    = 2

# EKS Configuration
cluster_name       = "fullstack-eks-cluster"
node_instance_type = "t3.medium"
desired_capacity   = 3
min_size           = 2
max_size           = 10

# Tags
tags = {
  Project     = "FullStack-DevOps"
  Environment = "Production"
  ManagedBy   = "Terraform"
}
```

### Step 2: Initialize & Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Plan deployment (review changes)
terraform plan -out=tfplan

# Apply infrastructure (creates AWS resources)
terraform apply tfplan

# This will create:
# ✅ VPC with public/private subnets across 3 AZs
# ✅ RDS PostgreSQL Multi-AZ instance
# ✅ ElastiCache Redis cluster
# ✅ Application Load Balancer
# ✅ Security Groups
# ✅ Auto Scaling Groups
# ✅ IAM Roles and Policies
# ✅ S3 buckets for logs and artifacts

# Save outputs (RDS endpoint, Redis endpoint, etc.)
terraform output > terraform-outputs.txt
cat terraform-outputs.txt
```

### Step 3: Verify AWS Resources

```bash
# Verify VPC
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=fullstack-devops-vpc"

# Verify RDS instance
aws rds describe-db-instances --db-instance-identifier fullstack-devops-postgres

# Verify ElastiCache cluster
aws elasticache describe-cache-clusters --cache-cluster-id fullstack-devops-redis

# Verify Load Balancer
aws elbv2 describe-load-balancers --names fullstack-devops-alb

# Get RDS endpoint
export DB_ENDPOINT=$(terraform output -raw rds_endpoint)
echo "Database Endpoint: $DB_ENDPOINT"

# Get Redis endpoint
export REDIS_ENDPOINT=$(terraform output -raw redis_endpoint)
echo "Redis Endpoint: $REDIS_ENDPOINT"
```

### Step 4: Infrastructure Costs Estimate

**Monthly AWS Costs (Production):**
```
EKS Control Plane:        $73/month
EC2 Instances (3x t3.medium): $75/month
RDS PostgreSQL (db.t3.medium): $195/month
ElastiCache Redis (2x cache.t3.micro): $73/month
Application Load Balancer: $23/month
NAT Gateway:              $45/month
Data Transfer:            $20/month
CloudWatch & Monitoring:  $15/month
S3 Storage:              $10/month
----------------------------------------------
Total Estimated:         ~$529/month

# Cost optimization applied: ~$654/month actual
```

---

## Kubernetes (EKS) Deployment

### Step 1: Create EKS Cluster

```bash
# Navigate to deployment scripts
cd deployment/eks

# Review cluster configuration
cat setup-eks-cluster.sh

# Create EKS cluster (takes ~15-20 minutes)
./setup-eks-cluster.sh

# Or manually with eksctl
eksctl create cluster \
  --name fullstack-eks-cluster \
  --region us-east-1 \
  --nodegroup-name fullstack-nodes \
  --node-type t3.medium \
  --nodes 3 \
  --nodes-min 2 \
  --nodes-max 10 \
  --managed

# Verify cluster
kubectl get nodes
kubectl cluster-info
```

### Step 2: Configure kubectl Context

```bash
# Update kubeconfig
aws eks update-kubeconfig \
  --region us-east-1 \
  --name fullstack-eks-cluster

# Verify connection
kubectl get svc

# Create namespaces
kubectl create namespace development
kubectl create namespace staging
kubectl create namespace production

# Verify namespaces
kubectl get namespaces
```

### Step 3: Install Helm Dependencies

```bash
# Add Bitnami repository
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Verify repository
helm search repo bitnami/postgresql
helm search repo bitnami/redis
```

### Step 4: Deploy with Helm

#### **Development Environment**

```bash
# Navigate to Helm charts
cd deployment/helm

# Install development environment
helm install fullstack-dev java-microservice \
  -f java-microservice/values-dev.yaml \
  --namespace development \
  --create-namespace

# Wait for deployment
kubectl -n development get pods -w

# Verify services
kubectl -n development get svc
kubectl -n development get ingress
```

#### **Staging Environment**

```bash
# Install staging environment
helm install fullstack-staging java-microservice \
  -f java-microservice/values-staging.yaml \
  --namespace staging \
  --create-namespace

# Verify deployment
kubectl -n staging get pods
kubectl -n staging get svc
```

#### **Production Environment**

```bash
# Review production values
cat java-microservice/values-prod.yaml

# Update with your actual endpoints
nano java-microservice/values-prod.yaml

# Install production environment
helm install fullstack-prod java-microservice \
  -f java-microservice/values-prod.yaml \
  --namespace production \
  --create-namespace \
  --set postgresql.auth.password="YOUR-SECURE-PASSWORD" \
  --set backend.image.registry="YOUR-ECR-REGISTRY" \
  --set frontend.image.registry="YOUR-ECR-REGISTRY"

# Monitor deployment
kubectl -n production get pods -w
kubectl -n production describe pod <pod-name>
```

### Step 5: Verify Kubernetes Deployment

```bash
# Check all pods
kubectl -n production get pods

# Expected output:
# NAME                                           READY   STATUS    RESTARTS   AGE
# fullstack-prod-backend-xxxxx                   1/1     Running   0          2m
# fullstack-prod-frontend-xxxxx                  1/1     Running   0          2m
# fullstack-prod-postgresql-0                    1/1     Running   0          2m
# fullstack-prod-redis-master-0                  1/1     Running   0          2m

# Check services
kubectl -n production get svc

# Check ingress
kubectl -n production get ingress

# Get Load Balancer URL
export LB_URL=$(kubectl -n production get ingress fullstack-prod-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "Application URL: http://$LB_URL"

# Test backend
curl http://$LB_URL/api/actuator/health

# Test frontend
curl http://$LB_URL/
```

### Step 6: Configure Auto-Scaling

```bash
# Verify HPA (Horizontal Pod Autoscaler)
kubectl -n production get hpa

# Expected output:
# NAME                      REFERENCE                        TARGETS         MINPODS   MAXPODS   REPLICAS   AGE
# fullstack-prod-backend    Deployment/backend-deployment    15%/70%         2         10        2          5m

# Test auto-scaling by generating load
kubectl -n production run load-generator --image=busybox --restart=Never -- /bin/sh -c "while true; do wget -q -O- http://fullstack-prod-backend:8080; done"

# Watch pods scale
kubectl -n production get hpa -w

# Clean up load generator
kubectl -n production delete pod load-generator
```

---

## CI/CD Pipeline Setup

### Step 1: GitHub Repository Setup

```bash
# Push code to GitHub
git remote add origin https://github.com/yourusername/my_Hands_On_Projects.git
git branch -M main
git push -u origin main
```

### Step 2: GitHub Secrets Configuration

Go to **GitHub Repository → Settings → Secrets and variables → Actions**

Add the following secrets:

```yaml
# AWS Credentials
AWS_ACCESS_KEY_ID: <your-access-key>
AWS_SECRET_ACCESS_KEY: <your-secret-key>
AWS_REGION: us-east-1

# ECR Registry
ECR_REGISTRY: <account-id>.dkr.ecr.us-east-1.amazonaws.com
ECR_BACKEND_REPOSITORY: java-microservice-backend
ECR_FRONTEND_REPOSITORY: java-microservice-frontend

# Database
DB_PASSWORD: <your-secure-db-password>

# Kubernetes
KUBE_CONFIG: <base64-encoded-kubeconfig>

# Slack/Email (optional)
SLACK_WEBHOOK_URL: <your-slack-webhook>
```

**Get kubeconfig for GitHub Actions:**
```bash
# Encode kubeconfig
cat ~/.kube/config | base64 -w 0
# Copy this value to KUBE_CONFIG secret
```

### Step 3: Enable GitHub Actions

```bash
# Verify workflow files
ls -la .github/workflows/

# You should see:
# - build-and-deploy.yml       # Main deployment workflow
# - ci-cd-pipeline.yml          # Full CI/CD pipeline
# - pull-request.yml            # PR validation
# - security.yml                # Security scanning

# Push changes to trigger workflow
git add .
git commit -m "Enable CI/CD pipeline"
git push origin main

# Monitor workflow
# Go to: GitHub Repository → Actions tab
```

### Step 4: Manual Workflow Trigger

**Via GitHub UI:**
1. Go to **Actions** tab
2. Select **CI/CD Pipeline** workflow
3. Click **Run workflow**
4. Select branch: `main`
5. Select environment: `production`
6. Click **Run workflow**

**Via GitHub CLI:**
```bash
# Install GitHub CLI
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install gh

# Authenticate
gh auth login

# Trigger workflow
gh workflow run ci-cd-pipeline.yml --ref main
```

---

## Monitoring & Observability

### Step 1: Deploy Prometheus

```bash
# Add Prometheus Helm repo
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install Prometheus
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false

# Verify installation
kubectl -n monitoring get pods
kubectl -n monitoring get svc

# Port-forward Prometheus UI
kubectl -n monitoring port-forward svc/prometheus-kube-prometheus-prometheus 9090:9090

# Access: http://localhost:9090
```

### Step 2: Deploy Grafana

```bash
# Grafana is included in Prometheus stack
# Get Grafana admin password
kubectl -n monitoring get secret prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo

# Port-forward Grafana
kubectl -n monitoring port-forward svc/prometheus-grafana 3000:80

# Access: http://localhost:3000
# Username: admin
# Password: <from above command>

# Import custom dashboard
# Dashboard ID from monitoring/grafana/grafana-fullstack-dashboard.json
```

### Step 3: Deploy Jaeger Tracing

```bash
# Deploy Jaeger
kubectl apply -f monitoring/jaeger/jaeger-deployment.yaml -n monitoring

# Verify
kubectl -n monitoring get pods | grep jaeger

# Port-forward Jaeger UI
kubectl -n monitoring port-forward svc/jaeger-query 16686:16686

# Access: http://localhost:16686
```

### Step 4: CloudWatch Integration

```bash
# Deploy CloudWatch agent
kubectl apply -f monitoring/cloudwatch/cloudwatch-agent-daemonset.yaml

# Verify agent
kubectl get daemonset -n kube-system | grep cloudwatch

# View logs in AWS Console
# CloudWatch → Log groups → /aws/eks/fullstack-eks-cluster
```

---

## Domain & SSL Configuration

### Step 1: Domain Setup

```bash
# Register domain (if you don't have one)
# - AWS Route 53
# - Namecheap
# - GoDaddy

# Create hosted zone in Route 53
aws route53 create-hosted-zone \
  --name yourdomain.com \
  --caller-reference $(date +%s)

# Get nameservers
aws route53 list-hosted-zones-by-name --dns-name yourdomain.com

# Update domain registrar with Route 53 nameservers
```

### Step 2: SSL Certificate (ACM)

```bash
# Request certificate
aws acm request-certificate \
  --domain-name yourdomain.com \
  --subject-alternative-names "*.yourdomain.com" \
  --validation-method DNS \
  --region us-east-1

# Get certificate ARN
export CERT_ARN=$(aws acm list-certificates --query "CertificateSummaryList[?DomainName=='yourdomain.com'].CertificateArn" --output text)

# Validate certificate
aws acm describe-certificate --certificate-arn $CERT_ARN

# Add DNS validation records to Route 53
# (AWS Console → ACM → Certificate → Create records in Route 53)
```

### Step 3: Configure Ingress with SSL

```bash
# Update ingress configuration
nano deployment/helm/java-microservice/values-prod.yaml
```

```yaml
ingress:
  enabled: true
  className: alb
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/certificate-arn: <YOUR-CERT-ARN>
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS": 443}]'
    alb.ingress.kubernetes.io/ssl-redirect: '443'
  hosts:
    - host: yourdomain.com
      paths:
        - path: /api
          pathType: Prefix
          backend: backend
        - path: /
          pathType: Prefix
          backend: frontend
```

```bash
# Upgrade Helm release
helm upgrade fullstack-prod java-microservice \
  -f java-microservice/values-prod.yaml \
  --namespace production

# Get ALB DNS name
kubectl -n production get ingress fullstack-prod-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

### Step 4: Create Route 53 Records

```bash
# Get hosted zone ID
export ZONE_ID=$(aws route53 list-hosted-zones-by-name --dns-name yourdomain.com --query "HostedZones[0].Id" --output text)

# Get ALB DNS name
export ALB_DNS=$(kubectl -n production get ingress fullstack-prod-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# Create DNS record
cat > dns-record.json <<EOF
{
  "Changes": [{
    "Action": "CREATE",
    "ResourceRecordSet": {
      "Name": "yourdomain.com",
      "Type": "A",
      "AliasTarget": {
        "HostedZoneId": "Z35SXDOTRQ7X7K",
        "DNSName": "$ALB_DNS",
        "EvaluateTargetHealth": true
      }
    }
  }]
}
EOF

aws route53 change-resource-record-sets \
  --hosted-zone-id $ZONE_ID \
  --change-batch file://dns-record.json

# Verify DNS propagation
dig yourdomain.com
nslookup yourdomain.com

# Test HTTPS
curl https://yourdomain.com
```

---

## Troubleshooting

### Common Issues & Solutions

#### 1. **Pods Not Starting**

```bash
# Check pod status
kubectl -n production get pods

# Describe problematic pod
kubectl -n production describe pod <pod-name>

# Check logs
kubectl -n production logs <pod-name>

# Common fixes:
# - Image pull errors: Check ECR permissions
# - CrashLoopBackOff: Check application logs
# - Pending: Check resource quotas and node capacity
```

#### 2. **Database Connection Issues**

```bash
# Test from backend pod
kubectl -n production exec -it <backend-pod> -- bash

# Inside pod
curl http://fullstack-prod-postgresql:5432
nc -zv fullstack-prod-postgresql 5432

# Check database credentials
kubectl -n production get secret fullstack-prod-postgresql -o yaml

# Verify database is running
kubectl -n production get pods | grep postgresql
```

#### 3. **High Memory/CPU Usage**

```bash
# Check resource usage
kubectl -n production top pods
kubectl -n production top nodes

# Increase resources
kubectl -n production edit deployment fullstack-prod-backend

# Or update Helm values
helm upgrade fullstack-prod java-microservice \
  -f java-microservice/values-prod.yaml \
  --set backend.resources.limits.memory=2Gi \
  --namespace production
```

#### 4. **SSL Certificate Issues**

```bash
# Check certificate status
aws acm describe-certificate --certificate-arn $CERT_ARN

# Verify DNS validation records
dig _<random>.yourdomain.com CNAME

# Check ingress annotations
kubectl -n production describe ingress fullstack-prod-ingress
```

#### 5. **Application Health Check Failures**

```bash
# Check health endpoint manually
kubectl -n production port-forward <pod-name> 8080:8080
curl http://localhost:8080/actuator/health

# Check liveness/readiness probes
kubectl -n production describe pod <pod-name> | grep -A 10 Liveness
kubectl -n production describe pod <pod-name> | grep -A 10 Readiness

# Adjust probe settings if needed
# Edit: deployment/helm/java-microservice/values-prod.yaml
```

### Debug Commands Reference

```bash
# Get all resources in namespace
kubectl -n production get all

# Stream logs from multiple pods
kubectl -n production logs -f -l app.kubernetes.io/component=backend

# Execute command in pod
kubectl -n production exec -it <pod-name> -- /bin/bash

# Copy files from pod
kubectl -n production cp <pod-name>:/app/logs/application.log ./local-log.txt

# Port forward service
kubectl -n production port-forward svc/fullstack-prod-backend 8080:80

# Get events
kubectl -n production get events --sort-by='.lastTimestamp'

# Restart deployment
kubectl -n production rollout restart deployment fullstack-prod-backend

# Check Helm release status
helm -n production status fullstack-prod

# Rollback Helm release
helm -n production rollback fullstack-prod 1
```

---

## Quick Start Commands

### **Development (Local Docker)**
```bash
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d
# Access: http://localhost:3000 (Frontend) | http://localhost:8080 (Backend)
```

### **Production (AWS + Kubernetes)**
```bash
# 1. Deploy infrastructure
cd terraform && terraform apply

# 2. Create EKS cluster
cd deployment/eks && ./setup-eks-cluster.sh

# 3. Deploy application
cd deployment/helm
helm install fullstack-prod java-microservice -f java-microservice/values-prod.yaml --namespace production

# 4. Get application URL
kubectl -n production get ingress
```

### **CI/CD Pipeline Trigger**
```bash
git add .
git commit -m "Deploy to production"
git push origin main
# Monitors: GitHub → Actions tab
```

---

## Cost Optimization Tips

1. **Use Spot Instances** for non-production environments (40-70% savings)
2. **Enable Auto-Scaling** to match actual load
3. **Use Reserved Instances** for production (up to 72% savings)
4. **Implement CloudWatch Alarms** for unusual spending
5. **Regular cleanup** of unused resources
6. **Use S3 Lifecycle Policies** for log rotation
7. **Enable Cost Explorer** and set budgets

---

## Security Best Practices

1. **Secrets Management**: Use AWS Secrets Manager or Kubernetes Secrets
2. **Network Policies**: Restrict pod-to-pod communication
3. **RBAC**: Implement role-based access control
4. **Image Scanning**: Enable ECR vulnerability scanning
5. **SSL/TLS**: Always use HTTPS in production
6. **Regular Updates**: Keep dependencies updated
7. **Audit Logging**: Enable CloudTrail and CloudWatch Logs

---

## Support & Documentation

- **Full Documentation**: [docs/README.md](docs/README.md)
- **Debug Commands**: [docs/copilot-session-debug-commands.md](docs/copilot-session-debug-commands.md)
- **Monitoring Guide**: [docs/monitoring-guide.md](docs/monitoring-guide.md)
- **Interview Questions**: [docs/comprehensive-interview-questions-helm-istio-eks.md](docs/comprehensive-interview-questions-helm-istio-eks.md)

---

**Deployment Complete! 🚀**

Your full-stack application is now running on AWS with:
- ✅ Auto-scaling Kubernetes cluster
- ✅ Managed PostgreSQL database
- ✅ Redis caching layer
- ✅ Application Load Balancer with SSL
- ✅ Complete monitoring stack
- ✅ Automated CI/CD pipeline
- ✅ Production-grade security

**Next Steps**: Monitor performance, optimize costs, and iterate based on user feedback.
