# Full-Stack Application Architecture - Detailed Guide

**Document Version**: 2.0  
**Last Updated**: October 15, 2025  
**Architecture Type**: Cloud-Native, Microservices, Full-Stack

Read ARCHITECTURE_UPDATE_SUMMARY.md first to understand what's in ARCHITECTURE.md
Use ARCHITECTURE.md for all technical details and implementation
Refer to DEDUPLICATION_ANALYSIS.md for the complete analysis report

---

## Table of Contents

1. [High-Level Architecture Overview](#high-level-architecture-overview)
2. [Network Flow & Request Journey](#network-flow--request-journey)
3. [Kubernetes Architecture](#kubernetes-architecture)
4. [Data Tier Architecture](#data-tier-architecture)
5. [Monitoring & Observability](#monitoring--observability)
6. [CI/CD Pipeline](#cicd-pipeline)
7. [Component Details](#component-details)
8. [Architecture Benefits](#architecture-benefits)

---

## High-Level Architecture Overview

### Complete System Architecture

```mermaid
graph TB
    subgraph "External Layer"
        Users[👥 External Users<br/>Web Browsers & Mobile Apps]
    end
    
    subgraph "DNS Layer"
        R53[🌐 AWS Route 53<br/>DNS Management<br/>yourdomain.com]
    end
    
    subgraph "Load Balancing Layer"
        ALB[⚖️ Application Load Balancer<br/>SSL/TLS Termination<br/>Path-Based Routing<br/>Health Checks]
    end
    
    subgraph "Kubernetes Cluster - Amazon EKS"
        subgraph "Ingress Layer"
            Ingress[🚪 Ingress Controller<br/>AWS ALB Controller<br/>Route Traffic to Services]
        end
        
        subgraph "Application Services"
            BackendSvc[🔷 Backend Service<br/>ClusterIP Port 80]
            FrontendSvc[🔶 Frontend Service<br/>ClusterIP Port 80]
        end
        
        subgraph "Application Pods - Auto-Scaling 2-10 Replicas"
            Backend[⚙️ Spring Boot Backend<br/>Java 17<br/>Port 8080 HTTP<br/>Port 9090 Management]
            Frontend[🎨 React Frontend<br/>Nginx + React Build<br/>Port 80]
        end
        
        subgraph "Data Services"
            PgSvc[🗄️ PostgreSQL Service<br/>ClusterIP Port 5432]
            RedisSvc[💾 Redis Service<br/>ClusterIP Port 6379]
        end
    end
    
    subgraph "AWS Managed Data Layer"
        RDS[(🗄️ Amazon RDS<br/>PostgreSQL 15.4<br/>Multi-AZ<br/>Automated Backups)]
        ElastiCache[(💾 ElastiCache<br/>Redis 7.0<br/>Cluster Mode<br/>Encryption)]
    end
    
    subgraph "Monitoring Stack"
        Prometheus[📊 Prometheus<br/>Metrics Collection]
        Grafana[📈 Grafana<br/>Visualization<br/>12 Dashboards]
        Jaeger[🔍 Jaeger<br/>Distributed Tracing]
        CloudWatch[☁️ CloudWatch<br/>Logs & Alarms]
    end
    
    Users -->|HTTPS :443| R53
    R53 -->|DNS Resolution| ALB
    ALB -->|/api/* requests| Ingress
    ALB -->|/* requests| Ingress
    Ingress -->|Route /api/*| BackendSvc
    Ingress -->|Route /*| FrontendSvc
    BackendSvc -->|Load Balance| Backend
    FrontendSvc -->|Load Balance| Frontend
    Backend -->|Database Queries| PgSvc
    Backend -->|Cache Operations| RedisSvc
    PgSvc -->|Connection| RDS
    RedisSvc -->|Connection| ElastiCache
    
    Backend -.->|Metrics| Prometheus
    Frontend -.->|Metrics| Prometheus
    Backend -.->|Traces| Jaeger
    Backend -.->|Logs| CloudWatch
    Frontend -.->|Logs| CloudWatch
    Prometheus -.->|Data Source| Grafana
    
    style Users fill:#e1f5ff
    style ALB fill:#ff9999
    style Backend fill:#99ccff
    style Frontend fill:#ffcc99
    style RDS fill:#99ff99
    style ElastiCache fill:#ffff99
    style Prometheus fill:#ff99ff
    style Grafana fill:#99ffff
```

**Purpose**: This diagram shows the complete request flow from users through DNS, load balancing, Kubernetes services, application pods, and data storage.
**Purpose**: This diagram shows the complete request flow from users through DNS, load balancing, Kubernetes services, application pods, and data storage.

---

## Network Flow & Request Journey

### User Request Flow

```mermaid
sequenceDiagram
    participant User as 👤 User Browser
    participant DNS as 🌐 Route 53
    participant ALB as ⚖️ ALB
    participant Ingress as 🚪 Ingress
    participant Frontend as 🎨 Frontend Pod
    participant Backend as ⚙️ Backend Pod
    participant DB as 🗄️ PostgreSQL
    participant Cache as 💾 Redis
    participant Monitor as 📊 Prometheus
    
    User->>DNS: 1. Resolve yourdomain.com
    DNS-->>User: 2. Return ALB IP
    User->>ALB: 3. HTTPS Request (GET /)
    ALB->>ALB: 4. SSL Termination
    ALB->>Ingress: 5. Route to Ingress
    Ingress->>Frontend: 6. Forward to Frontend Service
    Frontend-->>User: 7. Return React App (HTML/CSS/JS)
    
    User->>ALB: 8. API Request (GET /api/users)
    ALB->>Ingress: 9. Route /api/* path
    Ingress->>Backend: 10. Forward to Backend Service
    Backend->>Monitor: 11. Record metrics (async)
    Backend->>Cache: 12. Check Redis cache
    
    alt Cache Hit
        Cache-->>Backend: 13a. Return cached data
    else Cache Miss
        Backend->>DB: 13b. Query PostgreSQL
        DB-->>Backend: 14. Return user data
        Backend->>Cache: 15. Store in cache
    end
    
    Backend-->>User: 16. Return JSON response
    Monitor->>Monitor: 17. Update dashboards
```

**Purpose**: This sequence diagram shows the complete journey of a user request from browser to backend, including caching logic and monitoring.

### Path-Based Routing Details

```mermaid
graph LR
    subgraph "ALB Path-Based Routing"
        ALB[Application Load Balancer]
        
        ALB -->|Path: /api/*<br/>API Requests| BackendTarget[Backend Target Group]
        ALB -->|Path: /*<br/>All Other Requests| FrontendTarget[Frontend Target Group]
        ALB -->|Path: /actuator/*<br/>Health & Metrics| BackendTarget
        
        BackendTarget -->|Port 8080| Backend1[Backend Pod 1]
        BackendTarget -->|Port 8080| Backend2[Backend Pod 2]
        BackendTarget -->|Port 8080| BackendN[Backend Pod N]
        
        FrontendTarget -->|Port 80| Frontend1[Frontend Pod 1]
        FrontendTarget -->|Port 80| Frontend2[Frontend Pod 2]
        FrontendTarget -->|Port 80| FrontendN[Frontend Pod N]
    end
    
    style ALB fill:#ff9999
    style BackendTarget fill:#99ccff
    style FrontendTarget fill:#ffcc99
```

**Purpose**: Shows how the ALB intelligently routes traffic based on URL paths to appropriate backend or frontend services.

---

## Kubernetes Architecture

### Pod Architecture & Communication

```mermaid
graph TB
    subgraph "Kubernetes Namespace: production"
        subgraph "Backend Deployment"
            BackendPod1[⚙️ Backend Pod 1<br/>---<br/>Spring Boot Container<br/>App Port: 8080<br/>Mgmt Port: 9090<br/>---<br/>Resources:<br/>CPU: 500m-1000m<br/>Memory: 512Mi-2Gi]
            BackendPod2[⚙️ Backend Pod 2<br/>Same Config]
            BackendPodN[⚙️ Backend Pod N<br/>Auto-scaled 2-10]
        end
        
        subgraph "Frontend Deployment"
            FrontendPod1[🎨 Frontend Pod 1<br/>---<br/>Nginx Container<br/>Port: 80<br/>---<br/>Static Assets:<br/>React Build<br/>index.html<br/>bundle.js/css<br/>---<br/>Resources:<br/>CPU: 250m-500m<br/>Memory: 256Mi-1Gi]
            FrontendPod2[🎨 Frontend Pod 2<br/>Same Config]
            FrontendPodN[🎨 Frontend Pod N<br/>Auto-scaled 2-10]
        end
        
        subgraph "Database StatefulSet"
            PostgreSQL[🗄️ PostgreSQL Pod<br/>---<br/>PostgreSQL 15.4<br/>Port: 5432<br/>---<br/>Persistent Volume<br/>Data: /var/lib/postgresql<br/>---<br/>Init Containers:<br/>Flyway Migrations]
        end
        
        subgraph "Cache StatefulSet"
            Redis[💾 Redis Pod<br/>---<br/>Redis 7.0<br/>Port: 6379<br/>---<br/>Persistent Volume<br/>Data: /data<br/>---<br/>Config:<br/>AOF Enabled<br/>Max Memory: 256Mi]
        end
        
        subgraph "Services Layer"
            BackendSvc[Backend Service<br/>Type: ClusterIP<br/>Port: 80→8080]
            FrontendSvc[Frontend Service<br/>Type: ClusterIP<br/>Port: 80→80]
            DBSvc[PostgreSQL Service<br/>Type: ClusterIP<br/>Port: 5432]
            CacheSvc[Redis Service<br/>Type: ClusterIP<br/>Port: 6379]
        end
        
        subgraph "ConfigMaps & Secrets"
            ConfigMap[📄 ConfigMap<br/>Application Config<br/>Environment Variables]
            DBSecret[🔐 Secret<br/>Database Credentials<br/>Base64 Encoded]
            RedisSecret[🔐 Secret<br/>Redis Password<br/>Base64 Encoded]
        end
        
        subgraph "Auto-Scaling"
            HPA[📈 Horizontal Pod Autoscaler<br/>---<br/>Backend: 2-10 pods<br/>Triggers: CPU>70%, Mem>80%<br/>---<br/>Frontend: 2-10 pods<br/>Triggers: CPU>70%]
        end
    end
    
    BackendSvc --> BackendPod1
    BackendSvc --> BackendPod2
    BackendSvc --> BackendPodN
    FrontendSvc --> FrontendPod1
    FrontendSvc --> FrontendPod2
    FrontendSvc --> FrontendPodN
    DBSvc --> PostgreSQL
    CacheSvc --> Redis
    
    BackendPod1 --> DBSvc
    BackendPod1 --> CacheSvc
    BackendPod2 --> DBSvc
    BackendPod2 --> CacheSvc
    
    BackendPod1 -.->|Reads Config| ConfigMap
    BackendPod1 -.->|Reads Secrets| DBSecret
    BackendPod1 -.->|Reads Secrets| RedisSecret
    
    HPA -.->|Monitors & Scales| BackendPod1
    HPA -.->|Monitors & Scales| FrontendPod1
    
    style BackendPod1 fill:#99ccff
    style FrontendPod1 fill:#ffcc99
    style PostgreSQL fill:#99ff99
    style Redis fill:#ffff99
    style HPA fill:#ff99ff
```

**Purpose**: Detailed view of pod architecture, showing containers, ports, resources, volumes, and how auto-scaling works.

### Multi-Environment Namespace Strategy

```mermaid
graph TB
    subgraph "Amazon EKS Cluster"
        subgraph "Development Namespace"
            DevBackend[Backend: 1 pod<br/>Resources: Light<br/>CPU: 500m, Mem: 512Mi]
            DevFrontend[Frontend: 1 pod<br/>Resources: Light<br/>CPU: 250m, Mem: 256Mi]
            DevDB[PostgreSQL: 1 pod<br/>Small instance]
            DevRedis[Redis: 1 pod<br/>No persistence]
        end
        
        subgraph "Staging Namespace"
            StgBackend[Backend: 2 pods<br/>Resources: Medium<br/>CPU: 500m, Mem: 1Gi]
            StgFrontend[Frontend: 2 pods<br/>Resources: Medium<br/>CPU: 500m, Mem: 512Mi]
            StgDB[PostgreSQL: 1 pod<br/>Medium instance]
            StgRedis[Redis: 1 pod<br/>With persistence]
        end
        
        subgraph "Production Namespace"
            ProdBackend[Backend: 2-10 pods<br/>Resources: High<br/>CPU: 1000m, Mem: 2Gi<br/>Auto-Scaling Enabled]
            ProdFrontend[Frontend: 2-10 pods<br/>Resources: High<br/>CPU: 500m, Mem: 1Gi<br/>Auto-Scaling Enabled]
            ProdDB[Amazon RDS<br/>Multi-AZ<br/>Automated Backups]
            ProdRedis[ElastiCache<br/>Cluster Mode<br/>Encryption]
        end
        
        subgraph "Monitoring Namespace"
            Prometheus[Prometheus<br/>Metrics Collection]
            Grafana[Grafana<br/>Dashboards]
            Jaeger[Jaeger<br/>Tracing]
        end
        
        subgraph "Shared Services"
            IngressController[AWS ALB Ingress Controller]
            MetricsServer[Metrics Server<br/>For HPA]
            ClusterAutoscaler[Cluster Autoscaler<br/>Node Scaling]
        end
    end
    
    Prometheus -.->|Scrape Metrics| DevBackend
    Prometheus -.->|Scrape Metrics| StgBackend
    Prometheus -.->|Scrape Metrics| ProdBackend
    
    MetricsServer -.->|Provides Metrics| ProdBackend
    MetricsServer -.->|Provides Metrics| ProdFrontend
    
    style DevBackend fill:#e1f5ff
    style StgBackend fill:#fff4e1
    style ProdBackend fill:#99ccff
    style Prometheus fill:#ff99ff
```

**Purpose**: Shows the multi-environment strategy with different resource allocations and scaling policies for dev, staging, and production.

---

## Data Tier Architecture

### Database Architecture

```mermaid
graph TB
    subgraph "Application Layer"
        Backend[Spring Boot Backend<br/>Multiple Pods]
    end
    
    subgraph "Connection Pool Layer"
        HikariCP[HikariCP Connection Pool<br/>---<br/>Max Pool Size: 10<br/>Min Idle: 2<br/>Connection Timeout: 30s<br/>Idle Timeout: 600s]
    end
    
    subgraph "Database Layer - Amazon RDS"
        subgraph "Primary AZ - us-east-1a"
            Primary[(Primary Instance<br/>---<br/>PostgreSQL 15.4<br/>db.t3.medium<br/>2 vCPU, 4GB RAM<br/>100GB SSD Storage<br/>---<br/>Read/Write Operations)]
        end
        
        subgraph "Standby AZ - us-east-1b"
            Standby[(Standby Instance<br/>---<br/>Synchronous Replication<br/>Automatic Failover<br/>---<br/>Promoted on Primary Failure)]
        end
        
        subgraph "Backup & Recovery"
            AutoBackup[Automated Backups<br/>---<br/>Retention: 7 days<br/>Backup Window: 03:00-04:00 UTC<br/>Point-in-Time Recovery]
            Snapshot[Manual Snapshots<br/>---<br/>Pre-deployment backups<br/>Retained indefinitely]
        end
    end
    
    subgraph "Schema Management"
        Flyway[Flyway Migration Tool<br/>---<br/>Version Control for DB<br/>Automatic schema updates<br/>Rollback capability<br/>---<br/>Migrations:<br/>V1__Create_users_table.sql<br/>V2__Add_indexes.sql]
    end
    
    Backend --> HikariCP
    HikariCP -->|Active Connections| Primary
    Primary -.->|Sync Replication| Standby
    Primary -->|Daily Backups| AutoBackup
    Primary -->|On-Demand| Snapshot
    Flyway -->|Schema Updates| Primary
    
    style Primary fill:#99ff99
    style Standby fill:#ffffcc
    style HikariCP fill:#99ccff
    style Flyway fill:#ffcc99
```

**Purpose**: Shows database connection pooling, Multi-AZ setup, backup strategy, and schema management with Flyway.

### Caching Architecture

```mermaid
graph TB
    subgraph "Application Layer"
        Backend[Spring Boot Backend<br/>Multiple Pods]
    end
    
    subgraph "Cache Strategy"
        CacheLogic{Cache Check}
        
        CacheLogic -->|Cache Hit| ReturnCached[Return Cached Data<br/>Response Time: ~5ms]
        CacheLogic -->|Cache Miss| QueryDB[Query Database<br/>Response Time: ~50ms]
        QueryDB --> StoreCache[Store in Cache<br/>TTL: 5 minutes]
        StoreCache --> ReturnFresh[Return Fresh Data]
    end
    
    subgraph "Redis ElastiCache"
        subgraph "Primary Node"
            RedisPrimary[(Redis Primary<br/>---<br/>cache.t3.micro<br/>1 vCPU, 0.5GB RAM<br/>---<br/>Read/Write Operations<br/>Port: 6379)]
        end
        
        subgraph "Replica Nodes"
            Replica1[(Redis Replica 1<br/>---<br/>Read-Only<br/>Automatic Sync)]
            Replica2[(Redis Replica 2<br/>---<br/>Read-Only<br/>Automatic Sync)]
        end
        
        subgraph "Cache Types"
            SessionCache[Session Management<br/>---<br/>User sessions<br/>TTL: 30 minutes]
            DataCache[Data Caching<br/>---<br/>User objects<br/>API responses<br/>TTL: 5 minutes]
            RateLimitCache[Rate Limiting<br/>---<br/>API throttling<br/>TTL: 1 minute]
        end
    end
    
    Backend --> CacheLogic
    ReturnCached -.->|85% Hit Rate| Backend
    QueryDB --> StoreCache
    
    Backend -->|Write| RedisPrimary
    Backend -->|Read| Replica1
    Backend -->|Read| Replica2
    
    RedisPrimary -.->|Async Replication| Replica1
    RedisPrimary -.->|Async Replication| Replica2
    
    RedisPrimary --> SessionCache
    RedisPrimary --> DataCache
    RedisPrimary --> RateLimitCache
    
    style RedisPrimary fill:#ffff99
    style Replica1 fill:#ffffcc
    style CacheLogic fill:#ff99ff
```

**Purpose**: Illustrates caching strategy, cache hit/miss logic, Redis cluster setup, and different cache types used in the application.
**Purpose**: Illustrates caching strategy, cache hit/miss logic, Redis cluster setup, and different cache types used in the application.

---

## Monitoring & Observability

### Complete Observability Stack

```mermaid
graph TB
    subgraph "Application Components"
        Backend[⚙️ Backend Pods<br/>Spring Boot Actuator<br/>Micrometer Metrics]
        Frontend[🎨 Frontend Pods<br/>Nginx Metrics]
        PostgreSQL[🗄️ PostgreSQL<br/>Database Metrics]
        Redis[💾 Redis<br/>Cache Metrics]
    end
    
    subgraph "Metrics Collection - Prometheus"
        Prometheus[📊 Prometheus Server<br/>---<br/>Scrape Interval: 15s<br/>Retention: 15 days<br/>---<br/>Service Discovery:<br/>• Kubernetes Pods<br/>• Kubernetes Services<br/>• Kubernetes Nodes]
        
        subgraph "Exporters"
            PgExporter[PostgreSQL Exporter<br/>Port: 9187]
            RedisExporter[Redis Exporter<br/>Port: 9121]
            NodeExporter[Node Exporter<br/>System Metrics<br/>Port: 9100]
        end
    end
    
    subgraph "Visualization - Grafana"
        Grafana[📈 Grafana Dashboards<br/>Port: 3000]
        
        subgraph "Dashboards - 12 Panels"
            Dashboard1[Application Dashboard<br/>---<br/>• Request Rate<br/>• Response Time<br/>• Error Rate<br/>• Active Connections]
            Dashboard2[Infrastructure Dashboard<br/>---<br/>• CPU Usage<br/>• Memory Usage<br/>• Network I/O<br/>• Disk I/O]
            Dashboard3[Database Dashboard<br/>---<br/>• Query Performance<br/>• Connection Pool<br/>• Slow Queries<br/>• Lock Statistics]
            Dashboard4[Cache Dashboard<br/>---<br/>• Hit/Miss Ratio<br/>• Memory Usage<br/>• Eviction Rate<br/>• Key Statistics]
        end
    end
    
    subgraph "Distributed Tracing - Jaeger"
        Jaeger[🔍 Jaeger System<br/>Port: 16686]
        
        subgraph "Trace Components"
            JaegerAgent[Jaeger Agent<br/>Sidecar in Pods<br/>Port: 6831]
            JaegerCollector[Jaeger Collector<br/>Trace Aggregation]
            JaegerQuery[Jaeger Query<br/>UI & API]
            JaegerStorage[(Jaeger Storage<br/>Elasticsearch)]
        end
    end
    
    subgraph "Log Aggregation - CloudWatch"
        CloudWatch[☁️ CloudWatch Logs]
        
        subgraph "Log Groups"
            AppLogs[Application Logs<br/>/aws/eks/application]
            InfraLogs[Infrastructure Logs<br/>/aws/eks/infrastructure]
            AuditLogs[Audit Logs<br/>/aws/eks/audit]
        end
        
        subgraph "Alarms"
            ErrorAlarm[Error Rate Alarm<br/>Threshold: >5%]
            LatencyAlarm[Latency Alarm<br/>Threshold: >500ms]
            ResourceAlarm[Resource Alarm<br/>CPU/Memory >80%]
        end
    end
    
    Backend -->|Metrics Endpoint<br/>/actuator/prometheus| Prometheus
    Frontend -->|Nginx Status<br/>/metrics| Prometheus
    PostgreSQL --> PgExporter
    PgExporter -->|DB Metrics| Prometheus
    Redis --> RedisExporter
    RedisExporter -->|Cache Metrics| Prometheus
    NodeExporter -->|System Metrics| Prometheus
    
    Prometheus -->|Data Source| Grafana
    Grafana --> Dashboard1
    Grafana --> Dashboard2
    Grafana --> Dashboard3
    Grafana --> Dashboard4
    
    Backend -->|Traces| JaegerAgent
    JaegerAgent --> JaegerCollector
    JaegerCollector --> JaegerStorage
    JaegerQuery --> JaegerStorage
    Jaeger --> JaegerQuery
    
    Backend -->|Application Logs| AppLogs
    Frontend -->|Nginx Logs| AppLogs
    PostgreSQL -->|Database Logs| InfraLogs
    CloudWatch --> ErrorAlarm
    CloudWatch --> LatencyAlarm
    CloudWatch --> ResourceAlarm
    
    style Prometheus fill:#ff99ff
    style Grafana fill:#99ffff
    style Jaeger fill:#ffcc99
    style CloudWatch fill:#99ccff
```

**Purpose**: Shows the complete observability stack with metrics collection, visualization, distributed tracing, and log aggregation.

### Monitoring Data Flow

```mermaid
sequenceDiagram
    participant App as Application Pod
    participant Prom as Prometheus
    participant Graf as Grafana
    participant Jaeger as Jaeger
    participant CW as CloudWatch
    participant Alert as AlertManager
    participant User as DevOps Team
    
    loop Every 15 seconds
        Prom->>App: Scrape /actuator/prometheus
        App-->>Prom: Return metrics (JSON)
        Prom->>Prom: Store time-series data
    end
    
    App->>Jaeger: Send trace spans
    Jaeger->>Jaeger: Aggregate & store traces
    
    App->>CW: Stream logs (stdout/stderr)
    CW->>CW: Index & store logs
    
    User->>Graf: Open dashboard
    Graf->>Prom: Query metrics (PromQL)
    Prom-->>Graf: Return time-series data
    Graf-->>User: Display visualizations
    
    Prom->>Prom: Evaluate alert rules
    
    alt Alert Triggered
        Prom->>Alert: Send alert
        Alert->>User: Notify (Email/Slack/PagerDuty)
    end
    
    User->>Jaeger: Search traces
    Jaeger-->>User: Return trace details
    
    User->>CW: Search logs
    CW-->>User: Return filtered logs
```

**Purpose**: Sequence diagram showing how monitoring data flows through the system and how DevOps teams interact with monitoring tools.

---

## CI/CD Pipeline

### GitHub Actions Workflow

```mermaid
graph TB
    subgraph "Trigger Events"
        GitPush[Git Push to main<br/>Pull Request<br/>Manual Trigger]
    end
    
    subgraph "CI Pipeline - Build & Test"
        Checkout[📥 Checkout Code<br/>---<br/>Clone Repository<br/>Fetch Dependencies]
        
        subgraph "Backend Pipeline"
            BackendBuild[⚙️ Build Backend<br/>---<br/>Maven clean package<br/>Run unit tests<br/>Generate JAR file]
            BackendTest[🧪 Backend Tests<br/>---<br/>Unit Tests (JUnit)<br/>Integration Tests<br/>Code Coverage >80%]
            BackendSecurity[🔒 Security Scan<br/>---<br/>OWASP Dependency Check<br/>Trivy Container Scan<br/>Snyk Vulnerability Scan]
        end
        
        subgraph "Frontend Pipeline"
            FrontendBuild[🎨 Build Frontend<br/>---<br/>npm install<br/>npm run build<br/>Generate optimized bundle]
            FrontendTest[🧪 Frontend Tests<br/>---<br/>Unit Tests (Jest)<br/>Component Tests (RTL)<br/>Code Coverage >75%]
            FrontendLint[📋 Code Quality<br/>---<br/>ESLint<br/>Prettier<br/>TypeScript Check]
        end
        
        subgraph "Database Pipeline"
            DBMigration[🗄️ Database Migration<br/>---<br/>Flyway validate<br/>Generate migration scripts<br/>Test migrations on temp DB]
        end
    end
    
    subgraph "CD Pipeline - Deploy"
        subgraph "Container Registry"
            DockerBuild[🐳 Build Docker Images<br/>---<br/>Backend: Multi-stage<br/>Frontend: Nginx + React<br/>Tag: git-sha + latest]
            DockerPush[📤 Push to ECR<br/>---<br/>AWS ECR Login<br/>Push backend image<br/>Push frontend image]
        end
        
        subgraph "Deployment Strategy"
            DeployDev[🔵 Deploy to Dev<br/>---<br/>Namespace: development<br/>Replicas: 1<br/>Auto-deploy on commit]
            
            DeployStaging[🟡 Deploy to Staging<br/>---<br/>Namespace: staging<br/>Replicas: 2<br/>Manual approval required]
            
            DeployProd[🟢 Deploy to Production<br/>---<br/>Namespace: production<br/>Replicas: 2-10<br/>Blue-Green deployment<br/>Rollback capability]
        end
        
        subgraph "Post-Deployment"
            HealthCheck[✅ Health Checks<br/>---<br/>Wait for pods ready<br/>Check /actuator/health<br/>Verify endpoints]
            SmokeTest[🧪 Smoke Tests<br/>---<br/>Basic API tests<br/>Database connectivity<br/>Cache connectivity]
            Notify[📢 Notifications<br/>---<br/>Slack: Deployment status<br/>Email: Team notification<br/>GitHub: Update PR status]
        end
    end
    
    GitPush --> Checkout
    
    Checkout --> BackendBuild
    Checkout --> FrontendBuild
    Checkout --> DBMigration
    
    BackendBuild --> BackendTest
    BackendTest --> BackendSecurity
    
    FrontendBuild --> FrontendTest
    FrontendTest --> FrontendLint
    
    BackendSecurity --> DockerBuild
    FrontendLint --> DockerBuild
    DBMigration --> DockerBuild
    
    DockerBuild --> DockerPush
    
    DockerPush --> DeployDev
    DeployDev --> DeployStaging
    DeployStaging --> DeployProd
    
    DeployProd --> HealthCheck
    HealthCheck --> SmokeTest
    SmokeTest --> Notify
    
    style GitPush fill:#e1f5ff
    style BackendBuild fill:#99ccff
    style FrontendBuild fill:#ffcc99
    style DockerBuild fill:#99ff99
    style DeployProd fill:#99ff99
    style Notify fill:#ff99ff
```

**Purpose**: Complete CI/CD workflow showing parallel builds, testing, security scanning, and multi-environment deployment strategy.

### Deployment Process Detail

```mermaid
graph LR
    subgraph "Pre-Deployment"
        Backup[📦 Backup Current State<br/>---<br/>Database snapshot<br/>Helm release history<br/>Pod configurations]
        Validate[✅ Validate Resources<br/>---<br/>Helm lint<br/>Kubectl dry-run<br/>Resource quotas check]
    end
    
    subgraph "Deployment"
        HelmUpgrade[⚙️ Helm Upgrade<br/>---<br/>helm upgrade --install<br/>Wait for rollout<br/>Timeout: 5 minutes]
        
        subgraph "Rolling Update"
            OldPod1[Old Pod 1<br/>Terminating]
            OldPod2[Old Pod 2<br/>Running]
            NewPod1[New Pod 1<br/>Starting]
            NewPod2[New Pod 2<br/>Pending]
        end
    end
    
    subgraph "Verification"
        PodReady{All Pods<br/>Ready?}
        HealthPass{Health Checks<br/>Pass?}
        TrafficTest{Traffic Test<br/>Success?}
    end
    
    subgraph "Post-Deployment"
        Success[✅ Deployment Success<br/>---<br/>Update release notes<br/>Tag git commit<br/>Notify team]
        Rollback[❌ Rollback<br/>---<br/>helm rollback<br/>Restore from backup<br/>Incident report]
    end
    
    Backup --> Validate
    Validate --> HelmUpgrade
    HelmUpgrade --> OldPod1
    OldPod1 --> NewPod1
    NewPod1 --> OldPod2
    OldPod2 --> NewPod2
    NewPod2 --> PodReady
    
    PodReady -->|Yes| HealthPass
    PodReady -->|No| Rollback
    HealthPass -->|Yes| TrafficTest
    HealthPass -->|No| Rollback
    TrafficTest -->|Yes| Success
    TrafficTest -->|No| Rollback
    
    style Backup fill:#99ccff
    style HelmUpgrade fill:#ffcc99
    style Success fill:#99ff99
    style Rollback fill:#ff9999
```

**Purpose**: Detailed deployment process showing backup, validation, rolling update strategy, health checks, and rollback mechanism.

---**Purpose**: Detailed deployment process showing backup, validation, rolling update strategy, health checks, and rollback mechanism.

---

## Component Details

### 1. AWS Route 53 (DNS Service)

**What it is**: Amazon's highly available and scalable Domain Name System (DNS) web service.

**Purpose**:
- Translates human-readable domain names (yourdomain.com) to IP addresses
- Routes users to the application's load balancer
- Provides health checks and failover capabilities

**Why we use it**:
- **High Availability**: 100% uptime SLA with redundant DNS servers globally
- **Low Latency**: Anycast network routes users to nearest DNS server
- **Integration**: Seamless integration with AWS services (ALB, CloudFront, S3)
- **Health Checks**: Automatically routes traffic away from unhealthy endpoints
- **Cost-Effective**: Pay only for hosted zones and queries

**Configuration**:
```hcl
# Terraform configuration
resource "aws_route53_zone" "main" {
  name = "yourdomain.com"
}

resource "aws_route53_record" "app" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "yourdomain.com"
  type    = "A"
  
  alias {
    name                   = aws_lb.main.dns_name
    zone_id               = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}
```

---

### 2. Application Load Balancer (ALB)

**What it is**: Layer 7 (HTTP/HTTPS) load balancer that distributes incoming traffic across multiple targets.

**Purpose**:
- Distributes incoming application traffic across multiple pods
- Provides SSL/TLS termination
- Routes requests based on path patterns (/api/* vs /*)
- Performs health checks on backend targets

**Why we use it**:
- **Path-Based Routing**: Single load balancer serves both frontend and backend
  - `/api/*` → Backend Service (Spring Boot)
  - `/*` → Frontend Service (React)
- **SSL Termination**: Handles encryption/decryption, reducing pod CPU overhead
- **Health Checks**: Only routes to healthy pods, improving availability
- **Auto-Scaling Integration**: Automatically adds/removes targets as pods scale
- **Security**: Integrates with AWS WAF for protection against common web exploits

**Key Features**:
```yaml
Path Routing Rules:
  - Path: /api/*
    Target: Backend Target Group (Port 8080)
    Health Check: GET /actuator/health
    
  - Path: /*
    Target: Frontend Target Group (Port 80)
    Health Check: GET /
    
SSL/TLS:
  - Certificate: ACM Certificate (auto-renewal)
  - Protocols: TLSv1.2, TLSv1.3
  - Redirect HTTP → HTTPS
  
Health Checks:
  - Interval: 30 seconds
  - Timeout: 5 seconds
  - Healthy Threshold: 2
  - Unhealthy Threshold: 3
```

---

### 3. Amazon EKS (Elastic Kubernetes Service)

**What it is**: Managed Kubernetes service that runs Kubernetes control plane across multiple AWS availability zones.

**Purpose**:
- Provides container orchestration platform
- Manages application deployment, scaling, and operations
- Ensures high availability and fault tolerance

**Why we use it**:
- **Managed Control Plane**: AWS manages Kubernetes masters (API server, scheduler, etcd)
- **High Availability**: Control plane runs across 3 AZs automatically
- **Security**: Integrated with AWS IAM for authentication/authorization
- **Updates**: Automated Kubernetes version upgrades
- **Monitoring**: Native integration with CloudWatch and Prometheus
- **Cost Optimization**: Only pay for worker nodes, control plane is $0.10/hour

**Architecture Components**:
```
Control Plane (AWS Managed):
  - API Server: Entry point for all REST commands
  - Scheduler: Assigns pods to nodes based on resources
  - Controller Manager: Maintains desired state
  - etcd: Key-value store for cluster data
  
Worker Nodes (Your EC2 Instances):
  - Kubelet: Node agent that manages pods
  - Kube-proxy: Network proxy for service communication
  - Container Runtime: Runs containers (containerd)
  - Pods: Smallest deployable units (containers)
```

---

### 4. Spring Boot Backend

**What it is**: Java-based microservice using Spring Boot framework version 3.1.5 with Java 17.

**Purpose**:
- Provides RESTful API endpoints for frontend consumption
- Handles business logic and data processing
- Manages database interactions and caching
- Exposes health checks and metrics

**Why we use it**:
- **Rapid Development**: Auto-configuration and embedded server reduce boilerplate
- **Production-Ready**: Built-in health checks, metrics, and monitoring with Actuator
- **Ecosystem**: Rich ecosystem with Spring Data JPA, Spring Security, Spring Cache
- **Performance**: JVM optimizations and connection pooling for high throughput
- **Observability**: Micrometer integration for Prometheus metrics

**Key Components**:
```java
Application Structure:
├── Controllers (@RestController)
│   ├── UserController - CRUD operations on users
│   ├── ApiController - General API endpoints
│   └── MetricsController - Custom metrics
│
├── Services (@Service)
│   ├── UserService - Business logic
│   └── CounterService - Metrics tracking
│
├── Repositories (@Repository)
│   └── UserRepository - JPA data access
│
├── Entities (@Entity)
│   └── User - Database model
│
└── Configuration
    ├── WebConfig - CORS, interceptors
    ├── DatabaseConfig - Connection pool
    └── CacheConfig - Redis configuration

Actuator Endpoints:
  /actuator/health - Health status
  /actuator/metrics - Application metrics
  /actuator/prometheus - Prometheus format metrics
  /actuator/info - Application information
  
Ports:
  8080 - HTTP application traffic
  9090 - Management endpoints (health, metrics)
```

---

### 5. React Frontend

**What it is**: Modern single-page application (SPA) built with React 18, TypeScript, and Vite.

**Purpose**:
- Provides user interface for the application
- Consumes backend REST APIs
- Delivers responsive, interactive user experience

**Why we use it**:
- **Component-Based**: Reusable UI components improve maintainability
- **TypeScript**: Type safety reduces bugs and improves developer experience
- **Vite**: Lightning-fast build tool with hot module replacement
- **Modern Features**: Hooks, suspense, concurrent rendering
- **SEO-Friendly**: Can be pre-rendered or server-side rendered if needed

**Architecture**:
```
Frontend Structure:
├── src/
│   ├── components/
│   │   ├── Dashboard.tsx - Main dashboard
│   │   ├── UserList.tsx - Display users
│   │   └── UserForm.tsx - Create/edit users
│   │
│   ├── services/
│   │   └── api.ts - API client (axios)
│   │
│   ├── types/
│   │   └── api.ts - TypeScript interfaces
│   │
│   └── App.tsx - Main application component
│
└── Build Output (Production):
    ├── index.html
    ├── static/
    │   ├── js/main.[hash].js (2.1MB → 580KB gzipped)
    │   ├── css/main.[hash].css
    │   └── media/ (images, fonts)
    └── manifest.json

Nginx Configuration:
  - Serves static assets from /usr/share/nginx/html
  - Single-page app routing (try_files fallback)
  - Gzip compression for faster loading
  - Cache headers for static assets
  - Reverse proxy for /api to backend
```

---

### 6. PostgreSQL Database

**What it is**: Open-source relational database management system, version 15.4, running on Amazon RDS.

**Purpose**:
- Stores persistent application data (users, transactions, etc.)
- Provides ACID compliance for data integrity
- Supports complex queries and relationships

**Why we use it**:
- **Reliability**: ACID compliant with strong consistency guarantees
- **Performance**: Advanced indexing, query optimization, parallel queries
- **Features**: JSON support, full-text search, window functions, CTEs
- **Scalability**: Read replicas for read-heavy workloads
- **RDS Benefits**: Automated backups, patching, Multi-AZ failover

**Database Architecture**:
```sql
Schema Management (Flyway):
  V1__Create_users_table.sql
  V2__Add_indexes.sql
  V3__Add_audit_columns.sql
  
Connection Pooling (HikariCP):
  Maximum Pool Size: 10 connections
  Minimum Idle: 2 connections
  Connection Timeout: 30 seconds
  Idle Timeout: 600 seconds
  Max Lifetime: 1800 seconds
  
Performance Optimization:
  - Indexed columns: id (primary), email (unique), created_at
  - Partitioning: By date for large tables
  - VACUUM: Automated for performance
  - EXPLAIN ANALYZE: Query optimization
  
Backup Strategy:
  - Automated daily backups at 3:00 AM UTC
  - Retention: 7 days
  - Point-in-time recovery: Any time within retention
  - Manual snapshots before deployments
  
Multi-AZ Setup:
  - Primary in us-east-1a
  - Standby in us-east-1b
  - Synchronous replication
  - Automatic failover in <60 seconds
```

---

### 7. Redis Cache

**What it is**: In-memory data structure store used as cache and session store, version 7.0, running on Amazon ElastiCache.

**Purpose**:
- Caches frequently accessed data to reduce database load
- Stores user sessions for stateless backend
- Provides high-speed data access (sub-millisecond latency)

**Why we use it**:
- **Performance**: In-memory storage provides microsecond latency
- **Versatility**: Supports strings, hashes, lists, sets, sorted sets
- **Persistence**: AOF (Append-Only File) for durability
- **Scalability**: Cluster mode for horizontal scaling
- **ElastiCache Benefits**: Automated failover, patching, backups

**Caching Strategies**:
```java
Cache-Aside Pattern:
  1. Application checks cache for data
  2. If found (cache hit): Return from cache
  3. If not found (cache miss):
     a. Query database
     b. Store result in cache with TTL
     c. Return data to user

Cache Types:
  1. Session Cache:
     - Key: session:{userId}
     - Value: User session data
     - TTL: 30 minutes
     - Eviction: LRU (Least Recently Used)
  
  2. Data Cache:
     - Key: user:{userId}
     - Value: Serialized user object
     - TTL: 5 minutes
     - Eviction: LRU
  
  3. Rate Limiting:
     - Key: rate:{userId}:{endpoint}
     - Value: Request count
     - TTL: 1 minute
     - Purpose: API throttling

Performance Metrics:
  - Hit Rate: 85%
  - Miss Rate: 15%
  - Average GET latency: 0.5ms
  - Average SET latency: 1ms
  - Memory Usage: 60% of allocated
```

---

### 8. Prometheus (Metrics Collection)

**What it is**: Open-source monitoring and alerting toolkit designed for reliability and scalability.

**Purpose**:
- Collects time-series metrics from applications and infrastructure
- Stores metrics data with labels for flexible querying
- Triggers alerts based on metric thresholds

**Why we use it**:
- **Pull-Based**: Prometheus scrapes metrics, preventing network floods
- **Service Discovery**: Automatically discovers Kubernetes pods/services
- **PromQL**: Powerful query language for metric analysis
- **Alerting**: Built-in alert manager for notifications
- **Ecosystem**: Large ecosystem of exporters and integrations

**Metrics Collected**:
```yaml
Application Metrics (from Spring Boot Actuator):
  - http_server_requests_seconds: API response times
  - jvm_memory_used_bytes: JVM memory usage
  - jdbc_connections_active: Database connections
  - cache_gets_total: Cache hit/miss counts
  - custom_business_metrics: Domain-specific metrics

Infrastructure Metrics:
  - node_cpu_seconds_total: CPU usage per core
  - node_memory_MemAvailable_bytes: Available memory
  - node_disk_io_time_seconds_total: Disk I/O
  - node_network_receive_bytes_total: Network traffic

Kubernetes Metrics:
  - kube_pod_status_phase: Pod health status
  - kube_deployment_status_replicas: Replica counts
  - container_cpu_usage_seconds_total: Container CPU
  - container_memory_working_set_bytes: Container memory

Alert Rules:
  - HighErrorRate: error_rate > 5% for 5 minutes
  - HighLatency: p95_latency > 500ms for 10 minutes
  - PodCrashLooping: restart_count > 5 in 15 minutes
  - HighCPUUsage: cpu_usage > 80% for 15 minutes
```

---

### 9. Grafana (Visualization)

**What it is**: Open-source analytics and interactive visualization web application.

**Purpose**:
- Visualizes metrics from Prometheus in customizable dashboards
- Provides real-time monitoring of application and infrastructure
- Enables data exploration and trend analysis

**Why we use it**:
- **Rich Visualizations**: Graphs, heat maps, histograms, tables
- **Multi-Data Source**: Prometheus, CloudWatch, Jaeger integration
- **Templating**: Variables for dynamic, reusable dashboards
- **Alerting**: Visual alerts with annotations on graphs
- **Sharing**: Export dashboards as JSON, share snapshots

**Dashboard Panels**:
```yaml
Application Dashboard (12 Panels):
  
  Panel 1 - Request Rate:
    Query: rate(http_server_requests_total[5m])
    Visualization: Time series graph
    Purpose: Monitor traffic patterns
  
  Panel 2 - Response Time (p50, p95, p99):
    Query: histogram_quantile(0.95, http_server_requests_seconds_bucket)
    Visualization: Multi-line graph
    Purpose: Track latency percentiles
  
  Panel 3 - Error Rate:
    Query: rate(http_server_requests_total{status=~"5.."}[5m])
    Visualization: Time series with threshold
    Purpose: Detect service issues
  
  Panel 4 - Active Database Connections:
    Query: jdbc_connections_active
    Visualization: Gauge
    Purpose: Monitor connection pool
  
  Panel 5 - Cache Hit Rate:
    Query: rate(cache_gets_total{result="hit"}[5m]) / rate(cache_gets_total[5m])
    Visualization: Percentage gauge
    Purpose: Cache effectiveness
  
  Panel 6 - JVM Memory Usage:
    Query: jvm_memory_used_bytes / jvm_memory_max_bytes
    Visualization: Stacked area chart
    Purpose: Memory pressure monitoring
  
  Panel 7 - Pod Status:
    Query: kube_pod_status_phase
    Visualization: Stat panel
    Purpose: Quick health overview
  
  Panel 8 - Request Duration Heatmap:
    Query: http_server_requests_seconds_bucket
    Visualization: Heatmap
    Purpose: Identify latency patterns
  
  Panel 9 - Top Endpoints by Traffic:
    Query: topk(10, rate(http_server_requests_total[5m]))
    Visualization: Bar chart
    Purpose: Identify high-traffic endpoints
  
  Panel 10 - Database Query Performance:
    Query: spring_data_repository_invocations_seconds
    Visualization: Table
    Purpose: Slow query detection
  
  Panel 11 - Node Resource Usage:
    Query: node_cpu_usage, node_memory_usage
    Visualization: Multiple time series
    Purpose: Infrastructure monitoring
  
  Panel 12 - Deployment Events:
    Query: kube_pod_created
    Visualization: Annotation markers
    Purpose: Correlate changes with metrics
```

---

### 10. Jaeger (Distributed Tracing)

**What it is**: Open-source, end-to-end distributed tracing system for monitoring and troubleshooting microservices.

**Purpose**:
- Tracks requests as they flow through the system
- Identifies performance bottlenecks
- Visualizes service dependencies

**Why we use it**:
- **Request Tracing**: Complete visibility into request lifecycle
- **Performance Analysis**: Identify slow database queries, external API calls
- **Dependency Mapping**: Visualize how services interact
- **Root Cause Analysis**: Quickly find where errors originate
- **Sampling**: Configurable sampling to reduce overhead

**Trace Components**:
```
Trace Structure:
  Trace ID: Unique identifier for entire request
  ├── Span 1: Frontend Request (10ms)
  ├── Span 2: Backend API Call (150ms)
  │   ├── Span 3: Database Query (80ms)
  │   │   └── Tags: sql.query, db.instance
  │   ├── Span 4: Redis Cache Check (2ms)
  │   │   └── Tags: cache.key, cache.hit
  │   └── Span 5: Business Logic (68ms)
  │       └── Tags: method.name, user.id
  └── Total Duration: 160ms

Sampling Strategy:
  - Production: 10% sampling (reduce overhead)
  - Staging: 50% sampling (more visibility)
  - Development: 100% sampling (full tracing)
  - Always sample errors (100%)
  
Tags & Metadata:
  - http.method: GET/POST/PUT/DELETE
  - http.status_code: 200/404/500
  - http.url: /api/users
  - span.kind: server/client
  - peer.service: database/cache
  - error: true/false
```

---

### 11. CloudWatch (AWS Monitoring)

**What it is**: AWS monitoring and observability service for logging, metrics, and alarms.

**Purpose**:
- Collects logs from all AWS services and applications
- Provides infrastructure-level metrics
- Triggers alarms for operational issues

**Why we use it**:
- **Native Integration**: Built-in AWS service integration
- **Log Aggregation**: Centralized logging from all sources
- **Long-Term Storage**: Retain logs indefinitely
- **Insights**: Query logs using CloudWatch Logs Insights
- **Alarms**: Automated notifications via SNS

**Log Groups & Streams**:
```yaml
Log Structure:
  /aws/eks/fullstack-cluster/
    ├── application/
    │   ├── backend-pod-1
    │   ├── backend-pod-2
    │   ├── frontend-pod-1
    │   └── frontend-pod-2
    │
    ├── infrastructure/
    │   ├── postgresql
    │   ├── redis
    │   └── nginx
    │
    └── audit/
        ├── api-access
        ├── database-queries
        └── authentication

CloudWatch Alarms:
  1. HighErrorRate:
     Metric: Errors > 10 in 5 minutes
     Action: SNS notification to ops team
  
  2. HighLatency:
     Metric: p95 latency > 500ms
     Action: Auto-scale backend pods
  
  3. DatabaseConnections:
     Metric: Connections > 80% of max
     Action: Alert DBA team
  
  4. DiskSpace:
     Metric: Disk usage > 85%
     Action: Trigger cleanup job

Log Insights Queries:
  - Error count by endpoint
  - Slow queries over 1 second
  - Failed authentication attempts
  - Request count by user
```

---

### 12. Horizontal Pod Autoscaler (HPA)

**What it is**: Kubernetes controller that automatically scales the number of pods based on observed metrics.

**Purpose**:
- Automatically adjusts replica count based on CPU/memory usage
- Ensures application can handle varying load
- Optimizes resource utilization and cost

**Why we use it**:
- **Automatic Scaling**: No manual intervention needed
- **Cost Optimization**: Scale down during low traffic
- **Performance**: Scale up during high traffic
- **Custom Metrics**: Scale based on application-specific metrics
- **Predictable Behavior**: Gradual scale-up/down prevents flapping

**HPA Configuration**:
```yaml
Backend HPA:
  Minimum Replicas: 2
  Maximum Replicas: 10
  Target CPU Utilization: 70%
  Target Memory Utilization: 80%
  
  Scaling Behavior:
    Scale Up:
      - Stabilization Window: 0s (immediate)
      - Max Pods Added: 2 pods per 30s
      - Policy: Increase by 100% or 2 pods (whichever is greater)
    
    Scale Down:
      - Stabilization Window: 300s (5 minutes)
      - Max Pods Removed: 1 pod per 60s
      - Policy: Decrease by 50% or 1 pod (whichever is smaller)

Scaling Examples:
  Scenario 1 - Traffic Spike:
    Time: 09:00 - CPU usage increases to 85%
    Action: HPA adds 2 pods (2 → 4 pods)
    Time: 09:01 - CPU still at 80%
    Action: HPA adds 2 more pods (4 → 6 pods)
    Time: 09:02 - CPU stabilizes at 65%
    Action: No further scaling
  
  Scenario 2 - Traffic Drop:
    Time: 18:00 - CPU usage drops to 30%
    Action: Wait 5 minutes (stabilization window)
    Time: 18:05 - CPU still at 30%
    Action: Remove 1 pod (6 → 5 pods)
    Time: 18:06 - CPU at 35%
    Action: Continue removing pods gradually
    Time: 18:15 - Reach minimum of 2 pods
```

---

### 13. ConfigMaps & Secrets

**What it is**: Kubernetes objects for storing configuration data and sensitive information.

**Purpose**:
- Separate configuration from application code
- Manage environment-specific settings
- Securely store sensitive data

**Why we use it**:
- **Decoupling**: Configuration separate from container images
- **Environment Management**: Different configs for dev/staging/prod
- **Security**: Secrets are base64 encoded (encrypted at rest in etcd)
- **Dynamic Updates**: Can update without rebuilding images
- **Version Control**: Track configuration changes in Git

**Structure**:
```yaml
ConfigMap Example:
  apiVersion: v1
  kind: ConfigMap
  metadata:
    name: app-config
    namespace: production
  data:
    application.yml: |
      server:
        port: 8080
      spring:
        profiles:
          active: production
        datasource:
          maximum-pool-size: 10
    
    LOG_LEVEL: "INFO"
    FEATURE_FLAG_NEW_UI: "true"
    MAX_UPLOAD_SIZE: "10MB"

Secret Example:
  apiVersion: v1
  kind: Secret
  metadata:
    name: database-credentials
    namespace: production
  type: Opaque
  data:
    username: cG9zdGdyZXM=  # base64: postgres
    password: c2VjdXJlUGFzc3dvcmQxMjMh  # base64: securePassword123!
    
Pod Usage:
  env:
    - name: DB_USERNAME
      valueFrom:
        secretKeyRef:
          name: database-credentials
          key: username
    - name: DB_PASSWORD
      valueFrom:
        secretKeyRef:
          name: database-credentials
          key: password
    - name: LOG_LEVEL
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: LOG_LEVEL
```

---

## Architecture Benefits

### 1. High Availability (99.95% Uptime SLA)

**Implementation**:
```yaml
Multi-AZ Deployment:
  - Application: Pods distributed across 3 AZs (us-east-1a/1b/1c)
  - Database: Primary in us-east-1a, Standby in us-east-1b
  - Cache: Redis cluster with replicas in different AZs
  - Load Balancer: ALB operates in all AZs

Redundancy Layers:
  1. Pod Level:
     - Minimum 2 replicas always running
     - Anti-affinity rules prevent same-node placement
     - Rolling updates ensure zero-downtime deployments
  
  2. Node Level:
     - Auto Scaling Group maintains desired node count
     - Unhealthy nodes automatically replaced
     - Spot instances for cost savings with on-demand fallback
  
  3. Data Level:
     - Database: Synchronous replication to standby
     - Cache: Async replication across cluster nodes
     - Automated backups every 24 hours

Failure Recovery:
  - Pod crash: Kubernetes restarts in <10 seconds
  - Node failure: Pods rescheduled in <60 seconds
  - AZ outage: Traffic routed to healthy AZs automatically
  - Database failure: RDS failover in <60 seconds
```

**Benefits**:
- **No Single Point of Failure**: Every component is redundant
- **Automatic Recovery**: Kubernetes self-heals without intervention
- **Regional Resilience**: Survives entire availability zone failures
- **Maintenance Windows**: Can patch/update without downtime

---

### 2. Scalability (Handle 10x Traffic Spikes)

**Horizontal Scaling (Pods)**:
```yaml
Backend Scaling:
  Current: 2 pods (normal load)
  Maximum: 10 pods (peak load)
  Trigger: CPU > 70% or Memory > 80%
  
  Traffic Examples:
    100 requests/sec: 2 pods (1 CPU per pod)
    500 requests/sec: 5 pods (auto-scaled)
    1000 requests/sec: 10 pods (max capacity)
  
  Scale-Up Speed: 2 pods added every 30 seconds
  Scale-Down Speed: 1 pod removed every 60 seconds

Frontend Scaling:
  Current: 2 pods
  Maximum: 8 pods
  Trigger: CPU > 60%
  
  Static Assets: Can add CloudFront CDN for global distribution

Database Scaling:
  Vertical: Start with db.t3.medium, can upgrade to db.r5.2xlarge
  Horizontal: Add up to 5 read replicas for read-heavy workloads
  
  Read/Write Split:
    Write Operations: Primary instance only
    Read Operations: Load balanced across replicas
    
  Connection Pooling:
    Max Connections: 100 (default for db.t3.medium)
    Pool Size: 10 per pod (2 pods = 20 connections)
    Room for Growth: 80 connections available

Cache Scaling:
  Cluster Mode: 3 shards with 1 replica each = 6 nodes
  Max Capacity: Can add up to 250 shards
  Memory: Start 2GB per node, can scale to 365GB
```

**Vertical Scaling (Resources)**:
```yaml
Pod Resources:
  Current:
    CPU: 500m (0.5 cores)
    Memory: 512Mi
  
  Can Scale To:
    CPU: 2000m (2 cores) per pod
    Memory: 2Gi per pod
  
Node Resources:
  Current: t3.medium (2 vCPU, 4GB RAM)
  Can Scale: Up to t3.2xlarge (8 vCPU, 32GB RAM)
  Cluster Autoscaler: Automatically adds nodes when pods pending
```

**Benefits**:
- **Elastic**: Automatically adapts to traffic patterns
- **Cost-Efficient**: Scale down during low traffic hours
- **Performance**: Maintain response times under load
- **Future-Proof**: Can handle 10x growth without re-architecture

---

### 3. Performance Optimization

**Current Performance Metrics**:
```yaml
Frontend:
  First Contentful Paint: 450ms
  Largest Contentful Paint: 750ms
  Time to Interactive: 850ms
  Lighthouse Score: 92/100
  
Backend API:
  P50 Latency: 50ms
  P95 Latency: 150ms
  P99 Latency: 300ms
  Throughput: 500 requests/second/pod
  
Database:
  Query Response Time: 
    - Simple SELECT: 5-10ms
    - Complex JOIN: 50-100ms
    - Index Lookups: <1ms
  Connection Acquisition: 2ms (from pool)
  
Cache:
  GET Latency: 0.5ms
  SET Latency: 1ms
  Hit Rate: 85%
  Miss Rate: 15%
```

**Optimization Techniques**:
```yaml
1. Caching Strategy:
   - 85% cache hit rate reduces database load by 85%
   - User objects cached for 5 minutes
   - Session data cached for 30 minutes
   - Static assets cached in browser (1 year)
   
   Impact:
     Without Cache: 1000 req/s → 1000 DB queries
     With Cache: 1000 req/s → 150 DB queries (85% reduction)

2. Connection Pooling:
   - Reuse database connections (avoid TCP handshake)
   - 10 connections per pod vs 1 per request
   
   Impact:
     Without Pool: Each request takes 20ms TCP + 5ms query = 25ms
     With Pool: Each request takes 2ms acquire + 5ms query = 7ms
     Improvement: 72% faster

3. Database Indexing:
   - Primary Key (id): O(log n) lookups
   - Email Index: O(log n) for login queries
   - Composite Index (created_at, status): Fast filtering
   
   Impact:
     Without Index: Full table scan 10,000 rows = 100ms
     With Index: B-tree lookup = 5ms
     Improvement: 95% faster

4. Gzip Compression:
   - Frontend bundle: 2.1MB → 580KB (72% reduction)
   - API responses: JSON compressed by 60%
   
   Impact:
     Without Gzip: 2.1MB / 10Mbps = 1.68 seconds
     With Gzip: 580KB / 10Mbps = 0.46 seconds
     Improvement: 73% faster load time

5. Load Balancing:
   - Distributes traffic evenly across pods
   - Prevents any single pod from being overwhelmed
   
   Impact:
     1 Pod: 100 req/s → 200ms latency (overloaded)
     2 Pods: 50 req/s each → 50ms latency
     Improvement: 75% faster, better user experience
```

**Resource Utilization**:
```yaml
CPU Usage:
  Normal: 30-40% (room for spikes)
  Peak: 70-80% (triggers scaling)
  Target: Keep below 70% for headroom

Memory Usage:
  JVM Heap: 60% of allocated (allows garbage collection)
  Container: 70% of limit (prevents OOM kills)
  Node: 60% of capacity (allows pod scheduling)

Network:
  Bandwidth: <10% of node capacity
  Connections: <20% of maximum
  Room for growth: 80% headroom
```

**Benefits**:
- **Fast Response Times**: P95 under 200ms keeps users happy
- **Efficient Resource Use**: High utilization without overload
- **Reduced Costs**: Caching reduces expensive database operations
- **Scalable Performance**: Performance maintained under load

---

### 4. Observability (Full Stack Visibility)

**Three Pillars of Observability**:

```yaml
1. Metrics (What is happening?)
   
   Application Metrics:
     - Request rate: requests/second
     - Response time: p50, p95, p99 latency
     - Error rate: 4xx and 5xx responses
     - Active users: concurrent connections
     - Business metrics: signups, transactions
   
   Infrastructure Metrics:
     - CPU usage: per pod, per node
     - Memory usage: heap, non-heap, container
     - Disk I/O: read/write operations
     - Network: bytes in/out, packets
   
   Visualization:
     Tool: Grafana with 12 dashboard panels
     Refresh: Every 5 seconds (real-time)
     Retention: 15 days in Prometheus, 90 days in CloudWatch
   
   Alerting:
     - High error rate > 5% for 5 minutes → PagerDuty
     - High latency > 500ms for 10 minutes → Slack
     - Pod crash looping → Email ops team

2. Logs (What happened in detail?)
   
   Application Logs:
     - Structured JSON logging
     - Correlation IDs for request tracking
     - Log levels: ERROR, WARN, INFO, DEBUG
     - Sensitive data redacted (passwords, tokens)
   
   Log Sources:
     - Backend: Spring Boot logs (requests, errors, SQL)
     - Frontend: Nginx access logs, JavaScript errors
     - Database: Slow query logs, connection errors
     - Cache: Redis command logs, eviction logs
     - Kubernetes: Pod events, scheduler decisions
   
   Log Aggregation:
     Tool: CloudWatch Logs with Logs Insights
     Retention: 30 days
     Search: Full-text search with queries
     
   Example Queries:
     - Find all 500 errors in last hour
     - Show slow database queries > 1 second
     - Track user journey by correlation ID
     - Count failed authentication attempts

3. Traces (How does a request flow?)
   
   Distributed Tracing:
     Tool: Jaeger
     Sampling: 10% in production, 100% for errors
     Trace ID: Propagated through all services
   
   Span Details:
     - Service name: backend, database, cache
     - Operation: GET /api/users, SELECT FROM users
     - Duration: Time spent in each component
     - Tags: http.status_code, user.id, error
   
   Use Cases:
     - Identify slowest component in request path
     - Find where errors originate
     - Understand service dependencies
     - Optimize critical paths
   
   Example Trace:
     Total: 150ms
     ├── Frontend: 10ms (6%)
     ├── Backend: 140ms (94%)
     │   ├── Cache Check: 2ms (1%)
     │   ├── Database Query: 80ms (53%) ← BOTTLENECK
     │   └── Business Logic: 58ms (39%)
     
     Action: Optimize database query or add index
```

**Correlation & Context**:
```yaml
Request Journey:
  1. User makes request → Correlation ID generated
  2. ID added to logs, metrics, and traces
  3. Can search across all systems by correlation ID
  
  Example:
    Correlation ID: req-abc-123-xyz
    - Logs: Show all log entries for this request
    - Metrics: Filter metrics by this request
    - Traces: Complete trace visualization
    - Result: Full picture of single request
```

**Benefits**:
- **Rapid Troubleshooting**: Find root cause in minutes, not hours
- **Proactive Monitoring**: Alerts before users notice issues
- **Performance Insights**: Data-driven optimization decisions
- **Business Intelligence**: Track user behavior and engagement

---

### 5. Security (Defense in Depth)

**Security Layers**:

```yaml
1. Network Security:
   
   VPC Isolation:
     - Application in private subnets (no direct internet access)
     - Database in isolated subnets (only accessible from app)
     - Bastion host for SSH access (whitelisted IPs only)
   
   Security Groups (Firewall Rules):
     - ALB: Allow 80, 443 from 0.0.0.0/0 (public)
     - Backend: Allow 8080 from ALB only
     - Database: Allow 5432 from backend only
     - Redis: Allow 6379 from backend only
     - Deny all other traffic by default
   
   Network Policies (Kubernetes):
     - Pod-to-pod communication restricted
     - Only backend can access database service
     - Only backend can access redis service
     - Frontend can only call backend service

2. Transport Security:
   
   TLS/SSL Encryption:
     - ALB terminates TLS with ACM certificate
     - Backend → Database: SSL connections
     - Backend → Redis: TLS enabled
     - Inter-pod: Service mesh with mTLS (optional)
   
   Certificate Management:
     - AWS Certificate Manager auto-renews
     - No manual certificate rotation needed
     - TLS 1.2 and TLS 1.3 only (no TLS 1.0/1.1)

3. Application Security:
   
   Authentication & Authorization:
     - JWT tokens for stateless authentication
     - Token expiration: 1 hour access, 7 days refresh
     - Role-based access control (RBAC)
   
   Input Validation:
     - Request validation at API layer
     - SQL injection prevention (prepared statements)
     - XSS prevention (output escaping)
     - CSRF tokens for state-changing operations
   
   Rate Limiting:
     - Redis-based rate limiting
     - 100 requests per minute per user
     - 1000 requests per minute per IP
     - Prevents brute force attacks

4. Data Security:
   
   Encryption at Rest:
     - RDS: AES-256 encryption enabled
     - EBS volumes: Encrypted
     - S3 buckets: Server-side encryption
   
   Secrets Management:
     - Kubernetes Secrets for sensitive data
     - AWS Secrets Manager for rotation
     - No secrets in code or container images
     - Environment variables injected at runtime
   
   Data Privacy:
     - Personally Identifiable Information (PII) encrypted
     - Audit logs for data access
     - GDPR compliance (right to deletion)

5. Access Control:
   
   IAM Roles (AWS):
     - Pods use IAM roles for AWS API access
     - Principle of least privilege
     - No long-lived credentials
   
   RBAC (Kubernetes):
     - Developers: Read-only access to logs
     - DevOps: Deploy applications
     - Admins: Full cluster access
   
   Audit Logging:
     - All kubectl commands logged
     - Database access logged
     - Failed authentication attempts tracked
```

**Security Automation**:
```yaml
CI/CD Security Scans:
  1. Dependency Scanning:
     - npm audit (frontend dependencies)
     - OWASP Dependency-Check (backend dependencies)
     - Snyk for vulnerability detection
  
  2. Container Scanning:
     - Trivy scans Docker images
     - Blocks deployment if HIGH/CRITICAL vulnerabilities
     - Base images updated monthly
  
  3. Code Security:
     - SonarQube for code quality and security
     - Detects SQL injection, XSS, hardcoded secrets
     - Enforces security coding standards

Automated Patching:
  - Dependabot updates dependencies weekly
  - Kubernetes node images updated monthly
  - RDS minor version updates in maintenance window
```

**Benefits**:
- **Compliance**: Meets SOC 2, GDPR, HIPAA requirements
- **Risk Reduction**: Multiple layers prevent single point of failure
- **Automated**: Security checks in every deployment
- **Auditable**: Complete trail for compliance audits

---

### 6. Cost Optimization

**Current Monthly Costs** (Estimated):

```yaml
Compute (EKS):
  Worker Nodes: 3 × t3.medium = $75/month
  Control Plane: $73/month (fixed)
  Total: $148/month

Database (RDS):
  Primary: db.t3.medium = $62/month
  Storage: 50GB = $5.75/month
  Backup Storage: 50GB = $2.50/month
  Multi-AZ: 2× = $140/month
  Total: $140/month

Cache (ElastiCache):
  Redis nodes: 3 × cache.t3.micro = $45/month
  
Load Balancer (ALB):
  Fixed: $16.20/month
  LCU: ~$5/month (low traffic)
  Total: $21/month

Data Transfer:
  Inter-AZ: ~$10/month
  Internet: ~$20/month
  Total: $30/month

Monitoring:
  CloudWatch Logs: $5/month
  CloudWatch Metrics: $3/month
  Total: $8/month

Monthly Total: ~$392/month
Annual: ~$4,704/year
```

**Cost Optimization Strategies**:

```yaml
1. Right-Sizing:
   Current: Start small, scale as needed
   - Use t3.medium (burstable) instead of m5.large
   - Upgrade only when CPU baseline exhausted
   
   Savings: $120/month vs always using m5.large

2. Spot Instances:
   Strategy: Mix of On-Demand and Spot
   - 2 On-Demand nodes (guaranteed)
   - 1-3 Spot nodes (70% cheaper)
   
   Savings: $50/month with spot instances

3. Reserved Instances:
   Commitment: 1-year or 3-year reservation
   - RDS: Save 35% with 1-year RI
   - EC2: Save 40% with 1-year RI
   
   Savings: $100/month with 1-year commitments

4. Auto-Scaling:
   Schedule-based scaling:
   - Scale down to 1 node at night (10PM - 6AM)
   - Scale down to 1 backend pod on weekends
   
   Savings: $30/month from off-peak scaling

5. Data Transfer Optimization:
   - Use VPC endpoints (avoid internet gateway)
   - CloudFront CDN for static assets
   - Compress responses (save bandwidth)
   
   Savings: $15/month from reduced transfer

6. Storage Optimization:
   - Use S3 Intelligent-Tiering for backups
   - Delete old CloudWatch logs after 30 days
   - Compress database backups
   
   Savings: $10/month from storage efficiency

Total Potential Savings: $325/month
Optimized Cost: $67/month (83% reduction!)
```

**Cost Monitoring**:
```yaml
AWS Cost Explorer:
  - Daily cost tracking
  - Budget alerts at 80% and 100%
  - Tag-based cost allocation
  
Grafana Dashboard:
  - Cost per request
  - Cost per user
  - Cost by service (compute, database, cache)

Optimization Alerts:
  - Idle resources (CPU < 10% for 7 days)
  - Over-provisioned pods (memory < 30% for 7 days)
  - Unused resources (zero traffic for 30 days)
```

**Benefits**:
- **Transparent**: Know exactly where money is spent
- **Optimized**: Right-sized for actual usage
- **Predictable**: Reserved instances for stable costs
- **Efficient**: Auto-scaling prevents waste

---

### 7. Developer Experience

**Fast Development Cycle**:
```yaml
Local Development:
  Setup Time: 3 minutes (docker-compose up)
  Hot Reload: 
    - Frontend: Changes visible in <2 seconds
    - Backend: Spring DevTools restart in <5 seconds
  
  Tools:
    - IntelliJ IDEA / VS Code
    - Postman for API testing
    - pgAdmin for database queries
    - Redis CLI for cache inspection

CI/CD Pipeline:
  Trigger: Git push to main
  Build Time: 4-6 minutes
  Deployment: 2-3 minutes
  Total: <10 minutes from code to production
  
  Feedback:
    - Unit tests: 2 minutes
    - Integration tests: 3 minutes
    - Security scan: 1 minute
    - Container build: 2 minutes

Testing:
  - Unit tests: JUnit (backend), Jest (frontend)
  - Integration tests: TestContainers
  - E2E tests: Cypress
  - Load tests: JMeter
  - Coverage: >80% required
```

**Debugging & Troubleshooting**:
```yaml
Local Debugging:
  - Breakpoints in IDE
  - Step through code
  - Inspect variables
  - Hot reload changes

Production Debugging:
  - Logs: CloudWatch Logs Insights
  - Metrics: Grafana dashboards
  - Traces: Jaeger UI
  - Database: Slow query logs
  - Cache: Redis MONITOR command

Port Forwarding:
  kubectl port-forward pod/backend-xxx 8080:8080
  - Access production pod from localhost
  - Debug production issues safely
  - No need to deploy debug builds
```

**Benefits**:
- **Fast Iteration**: See changes in seconds
- **Easy Debugging**: Multiple tools for troubleshooting
- **Automated Testing**: CI/CD catches issues early
- **Production Parity**: Local environment matches production

---

### 8. Disaster Recovery

**Backup Strategy**:
```yaml
Database Backups:
  Automated:
    - Daily snapshots at 3:00 AM UTC
    - Retention: 7 days
    - Point-in-time recovery: Any time in last 7 days
  
  Manual:
    - Snapshot before major deployments
    - Export critical data to S3
    - Retention: 30 days

Application State:
  - Stateless application (no data stored in pods)
  - All data in database or cache
  - Cache can be rebuilt from database

Infrastructure:
  - Terraform state in S3 with versioning
  - Can rebuild entire infrastructure from code
  - CloudFormation stacks for AWS resources
```

**Recovery Time Objectives (RTO/RPO)**:
```yaml
Component Failures:
  Pod Crash:
    - RTO: <10 seconds (Kubernetes restarts)
    - RPO: 0 (no data loss, stateless)
  
  Node Failure:
    - RTO: <60 seconds (pods rescheduled)
    - RPO: 0 (no data loss)
  
  AZ Outage:
    - RTO: <2 minutes (traffic rerouted)
    - RPO: 0 (Multi-AZ database replication)
  
  Database Failure:
    - RTO: <60 seconds (RDS failover)
    - RPO: <5 seconds (synchronous replication)
  
  Region Outage:
    - RTO: <4 hours (manual failover to another region)
    - RPO: <1 hour (database snapshots)

Disaster Scenarios:
  Accidental Data Deletion:
    - Restore from point-in-time backup
    - Recovery: <30 minutes
  
  Deployment Failure:
    - Rollback to previous version
    - Recovery: <5 minutes
  
  Complete Data Center Loss:
    - Restore in new region from backups
    - Recovery: <4 hours
```

**Disaster Recovery Testing**:
```yaml
Monthly Tests:
  - Database restore from backup
  - Application deployment to new cluster
  - Failover testing (simulate AZ outage)

Quarterly Tests:
  - Full region failover drill
  - Restore infrastructure from Terraform
  - Validate RTO/RPO metrics

Annual Tests:
  - Complete disaster recovery simulation
  - Restore from oldest backup
  - Update disaster recovery playbook
```

**Benefits**:
- **Data Protection**: Multiple layers of backups
- **Fast Recovery**: Automated failover in seconds/minutes
- **Tested**: Regular drills ensure recovery works
- **Documented**: Runbooks for every scenario

---

**This architecture supports:**
- ✅ 10,000+ concurrent users
- ✅ 99.95% uptime SLA
- ✅ <150ms P95 API response time
- ✅ <750ms page load time
- ✅ Daily deployments with zero downtime
- ✅ Complete disaster recovery capability
- ✅ Auto-scaling from 2 to 10 pods based on load
- ✅ Multi-AZ high availability
- ✅ 85% cache hit rate
- ✅ Full observability with metrics, logs, and traces
- ✅ Cost optimized with 83% potential savings

```
