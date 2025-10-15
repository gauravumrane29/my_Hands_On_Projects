# Deployment Verification Checklist

**Use this checklist to verify successful deployment at each stage**

---

## ✅ Local Development Verification

### Docker Compose Environment

- [ ] **All containers are running**
  ```bash
  docker-compose ps
  # Expected: All services in "Up" status
  ```

- [ ] **Backend health check passes**
  ```bash
  curl http://localhost:8080/actuator/health
  # Expected: {"status":"UP"}
  ```

- [ ] **Frontend is accessible**
  ```bash
  curl -I http://localhost:3000
  # Expected: HTTP/1.1 200 OK
  ```

- [ ] **Database is accepting connections**
  ```bash
  docker exec -it postgres-db psql -U postgres -c "SELECT version();"
  # Expected: PostgreSQL version info
  ```

- [ ] **Redis is responding**
  ```bash
  docker exec -it redis-cache redis-cli ping
  # Expected: PONG
  ```

- [ ] **Nginx reverse proxy is working**
  ```bash
  curl http://localhost/api/actuator/health
  curl http://localhost/
  # Expected: Both return 200 OK
  ```

- [ ] **No error logs in containers**
  ```bash
  docker-compose logs | grep -i error
  # Expected: No critical errors
  ```

---

## ✅ AWS Infrastructure Verification

### Terraform Deployment

- [ ] **Terraform init completed successfully**
  ```bash
  ls -la terraform/.terraform/
  # Expected: .terraform directory exists with providers
  ```

- [ ] **Terraform plan shows expected resources**
  ```bash
  terraform plan | grep "Plan:"
  # Expected: Shows number of resources to create
  ```

- [ ] **Terraform apply completed without errors**
  ```bash
  terraform show | grep -i "resource"
  # Expected: All resources created
  ```

- [ ] **VPC is created with correct CIDR**
  ```bash
  aws ec2 describe-vpcs --filters "Name=tag:Name,Values=*fullstack*"
  # Expected: VPC with correct CIDR block
  ```

- [ ] **Subnets are created across availability zones**
  ```bash
  aws ec2 describe-subnets --filters "Name=vpc-id,Values=<VPC-ID>"
  # Expected: Public and private subnets in each AZ
  ```

- [ ] **RDS PostgreSQL instance is available**
  ```bash
  aws rds describe-db-instances --db-instance-identifier <DB-NAME>
  # Expected: Status = "available"
  ```

- [ ] **ElastiCache Redis cluster is available**
  ```bash
  aws elasticache describe-cache-clusters --cache-cluster-id <REDIS-NAME>
  # Expected: Status = "available"
  ```

- [ ] **Application Load Balancer is active**
  ```bash
  aws elbv2 describe-load-balancers --names <ALB-NAME>
  # Expected: State.Code = "active"
  ```

- [ ] **Security groups allow required traffic**
  ```bash
  aws ec2 describe-security-groups --filters "Name=tag:Name,Values=*fullstack*"
  # Expected: Ingress rules for ports 80, 443, 5432, 6379
  ```

- [ ] **NAT Gateway is available**
  ```bash
  aws ec2 describe-nat-gateways --filter "Name=state,Values=available"
  # Expected: At least one NAT Gateway per AZ
  ```

---

## ✅ Kubernetes Cluster Verification

### EKS Cluster Setup

- [ ] **EKS cluster is active**
  ```bash
  aws eks describe-cluster --name <CLUSTER-NAME> --query "cluster.status"
  # Expected: "ACTIVE"
  ```

- [ ] **kubectl can connect to cluster**
  ```bash
  kubectl cluster-info
  # Expected: Cluster endpoint and services info
  ```

- [ ] **All nodes are ready**
  ```bash
  kubectl get nodes
  # Expected: All nodes in "Ready" status
  ```

- [ ] **Required namespaces exist**
  ```bash
  kubectl get namespaces
  # Expected: development, staging, production namespaces
  ```

- [ ] **Storage classes are available**
  ```bash
  kubectl get storageclass
  # Expected: gp2 or gp3 storage class
  ```

- [ ] **CoreDNS is running**
  ```bash
  kubectl -n kube-system get pods | grep coredns
  # Expected: coredns pods in Running status
  ```

- [ ] **Metrics server is installed (for HPA)**
  ```bash
  kubectl -n kube-system get pods | grep metrics-server
  # Expected: metrics-server pod running
  ```

- [ ] **ALB Ingress Controller is installed**
  ```bash
  kubectl -n kube-system get pods | grep alb
  # Expected: aws-load-balancer-controller pod running
  ```

---

## ✅ Application Deployment Verification

### Helm Chart Deployment

- [ ] **Helm repositories are added**
  ```bash
  helm repo list
  # Expected: bitnami repository listed
  ```

- [ ] **Helm chart is installed**
  ```bash
  helm -n production list
  # Expected: Release in "deployed" status
  ```

- [ ] **All pods are running**
  ```bash
  kubectl -n production get pods
  # Expected: All pods in "Running" status
  ```

- [ ] **Backend deployment is ready**
  ```bash
  kubectl -n production get deployment | grep backend
  # Expected: READY shows desired/current replicas match
  ```

- [ ] **Frontend deployment is ready**
  ```bash
  kubectl -n production get deployment | grep frontend
  # Expected: READY shows desired/current replicas match
  ```

- [ ] **PostgreSQL pod is running**
  ```bash
  kubectl -n production get pods | grep postgresql
  # Expected: Pod in "Running" status, READY 1/1
  ```

- [ ] **Redis pod is running**
  ```bash
  kubectl -n production get pods | grep redis
  # Expected: Pod in "Running" status, READY 1/1
  ```

- [ ] **Services are created with ClusterIP**
  ```bash
  kubectl -n production get svc
  # Expected: backend, frontend, postgresql, redis services
  ```

- [ ] **Ingress is created and has IP/hostname**
  ```bash
  kubectl -n production get ingress
  # Expected: Ingress with ALB hostname in ADDRESS field
  ```

- [ ] **ConfigMaps are created**
  ```bash
  kubectl -n production get configmap
  # Expected: Application config maps present
  ```

- [ ] **Secrets are created**
  ```bash
  kubectl -n production get secrets
  # Expected: postgresql and redis secrets present
  ```

### Pod Health Checks

- [ ] **Backend liveness probe is passing**
  ```bash
  kubectl -n production describe pod <backend-pod> | grep -A5 Liveness
  # Expected: No failures
  ```

- [ ] **Backend readiness probe is passing**
  ```bash
  kubectl -n production describe pod <backend-pod> | grep -A5 Readiness
  # Expected: No failures
  ```

- [ ] **Backend logs show successful startup**
  ```bash
  kubectl -n production logs <backend-pod> | grep "Started Application"
  # Expected: Application started message
  ```

- [ ] **Frontend logs show successful startup**
  ```bash
  kubectl -n production logs <frontend-pod>
  # Expected: Nginx started successfully
  ```

- [ ] **Database connection is successful**
  ```bash
  kubectl -n production logs <backend-pod> | grep -i "database"
  # Expected: Database initialized or connected message
  ```

- [ ] **No CrashLoopBackOff errors**
  ```bash
  kubectl -n production get pods | grep -i crash
  # Expected: No results
  ```

---

## ✅ Application Functionality Verification

### API Endpoints

- [ ] **Health endpoint is accessible**
  ```bash
  export APP_URL=$(kubectl -n production get ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
  curl http://$APP_URL/api/actuator/health
  # Expected: {"status":"UP"}
  ```

- [ ] **API endpoints return data**
  ```bash
  curl http://$APP_URL/api/hello
  # Expected: "Hello from Spring Boot!"
  ```

- [ ] **Users API is working**
  ```bash
  curl http://$APP_URL/api/users
  # Expected: JSON array of users or empty array
  ```

- [ ] **Metrics endpoint is accessible**
  ```bash
  curl http://$APP_URL/api/actuator/prometheus
  # Expected: Prometheus metrics in text format
  ```

### Frontend Application

- [ ] **Frontend loads in browser**
  ```bash
  curl -I http://$APP_URL/
  # Expected: HTTP/1.1 200 OK with HTML content
  ```

- [ ] **Static assets are served**
  ```bash
  curl -I http://$APP_URL/static/css/main.*.css
  # Expected: HTTP/1.1 200 OK
  ```

- [ ] **API calls from frontend work**
  ```bash
  # Test in browser console or with curl
  curl http://$APP_URL/api/users
  # Expected: Valid JSON response
  ```

### Database Functionality

- [ ] **Database accepts connections from backend**
  ```bash
  kubectl -n production exec -it <backend-pod> -- curl localhost:8080/api/actuator/health | grep db
  # Expected: Database health check shows UP
  ```

- [ ] **Database tables are created**
  ```bash
  kubectl -n production exec -it <postgresql-pod> -- psql -U postgres -d demoapp -c "\dt"
  # Expected: List of application tables
  ```

- [ ] **Flyway migrations have run**
  ```bash
  kubectl -n production logs <backend-pod> | grep -i flyway
  # Expected: Migration success messages
  ```

### Cache Functionality

- [ ] **Redis accepts connections from backend**
  ```bash
  kubectl -n production exec -it <redis-pod> -- redis-cli ping
  # Expected: PONG
  ```

- [ ] **Cache hit/miss metrics are being tracked**
  ```bash
  curl http://$APP_URL/api/actuator/metrics/cache.gets | jq
  # Expected: Metrics showing cache operations
  ```

---

## ✅ Auto-Scaling Verification

### Horizontal Pod Autoscaler

- [ ] **HPA is configured**
  ```bash
  kubectl -n production get hpa
  # Expected: HPA resources for backend and frontend
  ```

- [ ] **HPA can read metrics**
  ```bash
  kubectl -n production describe hpa <hpa-name>
  # Expected: Current CPU/Memory percentages shown
  ```

- [ ] **HPA scales up under load**
  ```bash
  # Generate load
  kubectl -n production run load-test --image=busybox --restart=Never -- /bin/sh -c "while true; do wget -q -O- http://backend-svc:8080; done"
  
  # Watch scaling
  kubectl -n production get hpa -w
  # Expected: Replicas increase when CPU > 70%
  ```

- [ ] **HPA scales down after load decreases**
  ```bash
  # Stop load generator
  kubectl -n production delete pod load-test
  
  # Wait 5-10 minutes, then check
  kubectl -n production get hpa
  # Expected: Replicas decrease to minimum
  ```

---

## ✅ Monitoring & Observability Verification

### Prometheus

- [ ] **Prometheus is installed**
  ```bash
  kubectl -n monitoring get pods | grep prometheus
  # Expected: Prometheus pods running
  ```

- [ ] **Prometheus UI is accessible**
  ```bash
  kubectl -n monitoring port-forward svc/prometheus-kube-prometheus-prometheus 9090:9090
  # Access: http://localhost:9090
  # Expected: Prometheus UI loads
  ```

- [ ] **Targets are being scraped**
  ```bash
  # In Prometheus UI: Status → Targets
  # Expected: All targets showing as "UP"
  ```

- [ ] **Metrics are being collected**
  ```bash
  # In Prometheus UI, query: up{job="kubernetes-pods"}
  # Expected: Results showing all pods
  ```

### Grafana

- [ ] **Grafana is installed**
  ```bash
  kubectl -n monitoring get pods | grep grafana
  # Expected: Grafana pod running
  ```

- [ ] **Grafana UI is accessible**
  ```bash
  kubectl -n monitoring get secret prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 --decode
  kubectl -n monitoring port-forward svc/prometheus-grafana 3000:80
  # Access: http://localhost:3000 (admin / <password>)
  # Expected: Grafana UI loads
  ```

- [ ] **Prometheus data source is configured**
  ```bash
  # In Grafana: Configuration → Data Sources
  # Expected: Prometheus data source present and working
  ```

- [ ] **Dashboards are showing data**
  ```bash
  # In Grafana: Dashboards → Browse
  # Expected: Kubernetes dashboards showing metrics
  ```

### Jaeger Tracing

- [ ] **Jaeger is installed**
  ```bash
  kubectl -n monitoring get pods | grep jaeger
  # Expected: Jaeger pods running
  ```

- [ ] **Jaeger UI is accessible**
  ```bash
  kubectl -n monitoring port-forward svc/jaeger-query 16686:16686
  # Access: http://localhost:16686
  # Expected: Jaeger UI loads
  ```

- [ ] **Traces are being collected**
  ```bash
  # In Jaeger UI: Select service and search
  # Expected: Traces showing request flow
  ```

### CloudWatch

- [ ] **CloudWatch agent is running**
  ```bash
  kubectl -n kube-system get daemonset | grep cloudwatch
  # Expected: CloudWatch agent daemonset running
  ```

- [ ] **Logs are being sent to CloudWatch**
  ```bash
  aws logs describe-log-groups --log-group-name-prefix "/aws/eks"
  # Expected: Log groups for cluster present
  ```

- [ ] **Metrics are visible in CloudWatch**
  ```bash
  # AWS Console: CloudWatch → Metrics → ContainerInsights
  # Expected: Cluster and pod metrics visible
  ```

---

## ✅ CI/CD Pipeline Verification

### GitHub Actions

- [ ] **GitHub Actions workflows exist**
  ```bash
  ls -la .github/workflows/
  # Expected: Multiple .yml workflow files
  ```

- [ ] **Repository secrets are configured**
  ```bash
  # GitHub: Settings → Secrets and variables → Actions
  # Expected: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, etc.
  ```

- [ ] **Workflow runs successfully**
  ```bash
  # GitHub: Actions tab → Select workflow
  # Expected: Green checkmark on recent runs
  ```

- [ ] **Docker images are pushed to ECR**
  ```bash
  aws ecr describe-images --repository-name java-microservice-backend
  aws ecr describe-images --repository-name java-microservice-frontend
  # Expected: List of images with tags
  ```

- [ ] **Deployment to Kubernetes succeeds**
  ```bash
  # Check workflow logs in GitHub Actions
  # Expected: "helm upgrade" command succeeds
  ```

---

## ✅ Security Verification

### Network Security

- [ ] **Security groups have minimal required rules**
  ```bash
  aws ec2 describe-security-groups --filters "Name=tag:Name,Values=*fullstack*"
  # Expected: No 0.0.0.0/0 on sensitive ports
  ```

- [ ] **Network policies are applied**
  ```bash
  kubectl -n production get networkpolicies
  # Expected: Network policies restricting pod communication
  ```

- [ ] **Private subnets have no direct internet access**
  ```bash
  aws ec2 describe-route-tables --filters "Name=tag:Name,Values=*private*"
  # Expected: Routes through NAT Gateway only
  ```

### Application Security

- [ ] **Secrets are not in environment variables (visible)**
  ```bash
  kubectl -n production describe pod <pod-name> | grep -i password
  # Expected: References to secrets, not plain text
  ```

- [ ] **Pods are not running as root**
  ```bash
  kubectl -n production get pod <pod-name> -o jsonpath='{.spec.containers[0].securityContext}'
  # Expected: runAsNonRoot: true or runAsUser: non-zero
  ```

- [ ] **Image vulnerability scanning is enabled**
  ```bash
  aws ecr describe-image-scan-findings --repository-name java-microservice-backend --image-id imageTag=latest
  # Expected: Scan findings (should have minimal HIGH/CRITICAL)
  ```

- [ ] **RBAC is configured**
  ```bash
  kubectl -n production get rolebindings
  kubectl -n production get serviceaccounts
  # Expected: Service accounts with minimal permissions
  ```

### SSL/TLS

- [ ] **ACM certificate is validated**
  ```bash
  aws acm describe-certificate --certificate-arn <CERT-ARN>
  # Expected: Status = "ISSUED"
  ```

- [ ] **HTTPS is enforced on ALB**
  ```bash
  kubectl -n production describe ingress | grep -i ssl-redirect
  # Expected: ssl-redirect: '443' annotation present
  ```

- [ ] **Certificate is properly attached to ALB**
  ```bash
  kubectl -n production describe ingress | grep certificate-arn
  # Expected: Certificate ARN present
  ```

---

## ✅ Performance Verification

### Response Times

- [ ] **Backend API responds quickly**
  ```bash
  curl -w "@curl-format.txt" -o /dev/null -s http://$APP_URL/api/hello
  # Expected: time_total < 0.5s
  ```

- [ ] **Frontend loads quickly**
  ```bash
  curl -w "@curl-format.txt" -o /dev/null -s http://$APP_URL/
  # Expected: time_total < 1.0s
  ```

- [ ] **Database queries are optimized**
  ```bash
  # Check slow query logs in CloudWatch or RDS
  # Expected: Most queries < 100ms
  ```

### Resource Utilization

- [ ] **Pod CPU usage is reasonable**
  ```bash
  kubectl -n production top pods
  # Expected: CPU usage < 70% under normal load
  ```

- [ ] **Pod memory usage is stable**
  ```bash
  kubectl -n production top pods
  # Expected: Memory not constantly increasing (no memory leak)
  ```

- [ ] **Node resources are not exhausted**
  ```bash
  kubectl top nodes
  # Expected: CPU and memory < 80% on all nodes
  ```

---

## ✅ Cost Optimization Verification

- [ ] **Auto-scaling is working (not over-provisioned)**
  ```bash
  kubectl -n production get hpa
  # Expected: Replicas match actual load
  ```

- [ ] **Reserved instances or Savings Plans are active** (for production)
  ```bash
  # AWS Console: EC2 → Reserved Instances
  # Expected: Reserved instances for production nodes
  ```

- [ ] **Spot instances are used for non-production**
  ```bash
  kubectl get nodes -o custom-columns=NAME:.metadata.name,INSTANCE-LIFECYCLE:.metadata.labels.eks\.amazonaws\.com/capacityType
  # Expected: "SPOT" for dev/staging nodes
  ```

- [ ] **Unused resources are terminated**
  ```bash
  aws ec2 describe-instances --filters "Name=instance-state-name,Values=stopped"
  # Expected: No long-running stopped instances
  ```

- [ ] **Cost allocation tags are applied**
  ```bash
  aws ec2 describe-instances --query "Reservations[].Instances[].Tags"
  # Expected: Environment, Project, ManagedBy tags
  ```

---

## ✅ Disaster Recovery Verification

- [ ] **Database backups are enabled**
  ```bash
  aws rds describe-db-instances --db-instance-identifier <DB-NAME> --query "DBInstances[0].BackupRetentionPeriod"
  # Expected: Number > 0 (e.g., 7 days)
  ```

- [ ] **Database snapshots exist**
  ```bash
  aws rds describe-db-snapshots --db-instance-identifier <DB-NAME>
  # Expected: Recent automated snapshots
  ```

- [ ] **Multi-AZ is enabled for RDS**
  ```bash
  aws rds describe-db-instances --db-instance-identifier <DB-NAME> --query "DBInstances[0].MultiAZ"
  # Expected: true
  ```

- [ ] **Helm releases can be rolled back**
  ```bash
  helm -n production history fullstack-prod
  # Expected: Multiple revisions available
  ```

- [ ] **Application state is in external storage (not local)**
  ```bash
  kubectl -n production get pvc
  # Expected: PersistentVolumeClaims for data
  ```

---

## 🎯 Final Production Readiness Checklist

- [ ] All pods are running and healthy
- [ ] Application is accessible via HTTPS
- [ ] Database connections are working
- [ ] Cache is functioning
- [ ] Auto-scaling is configured
- [ ] Monitoring dashboards show data
- [ ] Logs are centralized
- [ ] Backups are automated
- [ ] Security best practices implemented
- [ ] CI/CD pipeline is operational
- [ ] Cost optimization measures in place
- [ ] Documentation is complete
- [ ] Team has access credentials
- [ ] Runbooks are prepared
- [ ] Incident response plan is ready

---

**Status**: ✅ Production Ready | ⚠️ Needs Attention | ❌ Not Ready

**Deployment Date**: _____________

**Verified By**: _____________

**Notes**: 
_____________________________________________________________
_____________________________________________________________
_____________________________________________________________
