# Quick Start Guide - Deploy in 30 Minutes

**Fast track deployment guide for experienced DevOps engineers**

---

## 🚀 Option 1: Local Docker (5 Minutes)

### Prerequisites
- Docker & Docker Compose installed
- 8GB RAM available

### Deploy
```bash
# Clone and start
git clone https://github.com/gauravumrane29/my_Hands_On_Projects.git
cd my_Hands_On_Projects

# Start all services
docker-compose up -d

# Verify
docker-compose ps
curl http://localhost:8080/actuator/health
curl http://localhost:3000
```

**Access:**
- Frontend: http://localhost:3000
- Backend API: http://localhost:8080
- Database: localhost:5432
- Redis: localhost:6379
- Nginx: http://localhost:80

**Stop:**
```bash
docker-compose down
```

---

## ☁️ Option 2: AWS Production (30 Minutes)

### Prerequisites
```bash
# Install tools
aws configure  # Your AWS credentials
terraform --version
kubectl version --client
helm version
```

### Step 1: Deploy Infrastructure (10 min)
```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

terraform init
terraform plan
terraform apply -auto-approve
```

### Step 2: Create EKS Cluster (15 min)
```bash
eksctl create cluster \
  --name fullstack-eks \
  --region us-east-1 \
  --nodegroup-name nodes \
  --node-type t3.medium \
  --nodes 3

# Configure kubectl
aws eks update-kubeconfig --name fullstack-eks --region us-east-1
```

### Step 3: Deploy Application (5 min)
```bash
cd deployment/helm

# Add Helm repos
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Deploy to production
helm install fullstack java-microservice \
  -f java-microservice/values-prod.yaml \
  --namespace production \
  --create-namespace \
  --set postgresql.auth.password="YourSecurePassword123!"

# Get application URL
kubectl -n production get ingress
```

**Monitor:**
```bash
kubectl -n production get pods -w
kubectl -n production logs -f -l app.kubernetes.io/component=backend
```

---

## 🔧 Option 3: Development Environment (3 Minutes)

### Local Development with Hot Reload
```bash
# Backend (Terminal 1)
cd app
./mvnw spring-boot:run

# Frontend (Terminal 2)
cd frontend
npm install
npm start

# Database (Terminal 3)
docker run -d --name postgres \
  -e POSTGRES_DB=demoapp \
  -e POSTGRES_PASSWORD=postgres \
  -p 5432:5432 \
  postgres:15-alpine
```

**Access:**
- Frontend: http://localhost:3000 (React Dev Server)
- Backend: http://localhost:8080 (Spring Boot)

---

## 🎯 GitHub Actions CI/CD (One-Time Setup)

### Configure Secrets
**GitHub Repository → Settings → Secrets → Actions**

Add these secrets:
```yaml
AWS_ACCESS_KEY_ID: <your-key>
AWS_SECRET_ACCESS_KEY: <your-secret>
AWS_REGION: us-east-1
ECR_REGISTRY: <account>.dkr.ecr.us-east-1.amazonaws.com
KUBE_CONFIG: <base64-encoded-kubeconfig>
DB_PASSWORD: <secure-password>
```

### Trigger Deployment
```bash
git add .
git commit -m "Deploy to production"
git push origin main
# Check: GitHub → Actions tab
```

---

## 📊 Monitoring Setup (5 Minutes)

### Install Prometheus + Grafana
```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace

# Access Grafana
kubectl -n monitoring port-forward svc/monitoring-grafana 3000:80
# URL: http://localhost:3000
# Username: admin
# Password: prom-operator
```

---

## ✅ Verification Checklist

```bash
# All pods running
kubectl -n production get pods
# Expected: All pods in Running status

# Services accessible
kubectl -n production get svc
# Expected: ClusterIP services for backend, frontend, postgres, redis

# Ingress configured
kubectl -n production get ingress
# Expected: ALB hostname

# Application health
export APP_URL=$(kubectl -n production get ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
curl http://$APP_URL/api/actuator/health
# Expected: {"status":"UP"}

# Database connected
kubectl -n production logs -l app.kubernetes.io/component=backend | grep "Database initialized"
# Expected: Database connection logs

# Monitoring active
kubectl -n monitoring get pods
# Expected: Prometheus and Grafana pods running
```

---

## 🆘 Quick Troubleshooting

### Pods Not Starting
```bash
kubectl -n production describe pod <pod-name>
kubectl -n production logs <pod-name>
```

### Database Connection Issues
```bash
kubectl -n production get secret fullstack-postgresql -o yaml
kubectl -n production exec -it <backend-pod> -- env | grep DB_
```

### Image Pull Errors
```bash
# Login to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account>.dkr.ecr.us-east-1.amazonaws.com

# Build and push
docker build -t <ecr-repo>/backend:latest ./app
docker push <ecr-repo>/backend:latest
```

---

## 🧹 Cleanup

### Stop Local Development
```bash
docker-compose down -v
```

### Destroy AWS Infrastructure
```bash
# Delete Kubernetes resources
helm uninstall fullstack -n production
kubectl delete namespace production

# Delete EKS cluster
eksctl delete cluster --name fullstack-eks --region us-east-1

# Destroy Terraform resources
cd terraform
terraform destroy -auto-approve
```

---

## 📚 Full Documentation

For detailed explanations, see:
- **[DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)** - Complete deployment guide
- **[docs/copilot-session-debug-commands.md](docs/copilot-session-debug-commands.md)** - Debug commands
- **[FULL_STACK_TRANSFORMATION_SUMMARY.md](FULL_STACK_TRANSFORMATION_SUMMARY.md)** - Architecture overview

---

## 💡 Pro Tips

1. **Use development environment first** to test changes locally
2. **Always review `terraform plan`** before applying
3. **Monitor costs** in AWS Cost Explorer
4. **Set up CloudWatch alarms** for critical metrics
5. **Enable auto-scaling** for production workloads
6. **Use Helm values files** for environment-specific configs
7. **Tag all resources** for better cost tracking

---

**Need Help?** 

Check the comprehensive [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) for detailed instructions, troubleshooting, and best practices.

**Ready to Deploy? Choose your option above and get started!** 🚀
