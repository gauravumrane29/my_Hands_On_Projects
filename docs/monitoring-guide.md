# Comprehensive Monitoring & Observability Guide

## Table of Contents
1. [Monitoring Architecture Overview](#monitoring-architecture-overview)
2. [Prometheus Monitoring Stack](#prometheus-monitoring-stack)
3. [Grafana Dashboards & Visualization](#grafana-dashboards--visualization)
4. [Distributed Tracing with Jaeger](#distributed-tracing-with-jaeger)
5. [Centralized Logging (EFK Stack)](#centralized-logging-efk-stack)
6. [AWS CloudWatch Integration](#aws-cloudwatch-integration)
7. [Alerting & Incident Management](#alerting--incident-management)
8. [Security Monitoring](#security-monitoring)
9. [Performance Monitoring](#performance-monitoring)
10. [Business Metrics & KPIs](#business-metrics--kpis)
11. [Monitoring Best Practices](#monitoring-best-practices)
12. [Troubleshooting Guide](#troubleshooting-guide)

## Monitoring Architecture Overview

### Complete Full-Stack Observability Stack
```
┌─────────────────────────────────────────────────────────────┐
│                Full-Stack Observability Layers              │
├─────────────────────┬─────────────────┬────────────────────┤
│     Metrics         │      Logs       │      Traces        │
│   (Prometheus)      │   (EFK Stack)   │    (Jaeger)        │
├─────────────────────┼─────────────────┼────────────────────┤
│  • Backend (8080)   │  • Spring Boot  │  • API Requests    │
│  • Frontend (80)    │  • React App    │  • Database Calls  │
│  • PostgreSQL       │  • PostgreSQL   │  • Redis Cache     │
│  • Redis Cache      │  • Redis        │  • Frontend→API    │
│  • Infrastructure   │  • Infrastructure│  • Full Request    │
│  • Business KPIs    │  • Audit/Security│    Journey        │
└─────────────────────┴─────────────────┴────────────────────┘
                              │
┌─────────────────────────────▼───────────────────────────────┐
│              Unified Monitoring Dashboard                   │
│  Grafana + CloudWatch + Kibana + Jaeger UI                │
└─────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────▼───────────────────────────────┐
│               Alerting & Notification                       │
│  Email + Slack + PagerDuty + SMS + Webhook                │
└─────────────────────────────────────────────────────────────┘
```

### Monitoring Components Integration
- **Data Collection**: Prometheus, Fluentd, Jaeger agents
- **Storage**: Prometheus TSDB, Elasticsearch, Jaeger storage
- **Visualization**: Grafana dashboards, Kibana, Jaeger UI
- **Alerting**: AlertManager, SNS, multi-channel notifications
- **Analysis**: Custom queries, anomaly detection, trend analysis

## Prometheus Monitoring Stack

### Comprehensive Prometheus Configuration
```yaml
# prometheus.yaml - Production Configuration
global:
  scrape_interval: 15s
  evaluation_interval: 15s
  external_labels:
    cluster: 'java-microservice-prod'
    region: 'us-east-1'

rule_files:
  - "/etc/prometheus/rules/*.yml"

alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - alertmanager:9093

scrape_configs:
  # Kubernetes API Server
  - job_name: 'kubernetes-apiservers'
    kubernetes_sd_configs:
      - role: endpoints
        namespaces:
          names:
            - default
    scheme: https
    tls_config:
      ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
      insecure_skip_verify: false
    bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
    relabel_configs:
      - source_labels: [__meta_kubernetes_namespace, __meta_kubernetes_service_name, __meta_kubernetes_endpoint_port_name]
        action: keep
        regex: default;kubernetes;https

  # Kubernetes Nodes
  - job_name: 'kubernetes-nodes'
    kubernetes_sd_configs:
      - role: node
    scheme: https
    tls_config:
      ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
      insecure_skip_verify: false
    bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
    relabel_configs:
      - action: labelmap
        regex: __meta_kubernetes_node_label_(.+)

  # Java Microservice Application
  - job_name: 'java-microservice'
    kubernetes_sd_configs:
      - role: endpoints
        namespaces:
          names:
            - production
            - staging
            - development
    relabel_configs:
      - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_scrape]
        action: keep
        regex: true
      - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_path]
        action: replace
        target_label: __metrics_path__
        regex: (.+)
      - source_labels: [__address__, __meta_kubernetes_service_annotation_prometheus_io_port]
        action: replace
        regex: ([^:]+)(?::\d+)?;(\d+)
        replacement: $1:$2
        target_label: __address__
      - action: labelmap
        regex: __meta_kubernetes_service_label_(.+)
      - source_labels: [__meta_kubernetes_namespace]
        action: replace
        target_label: kubernetes_namespace
      - source_labels: [__meta_kubernetes_service_name]
        action: replace
        target_label: kubernetes_name

  # Istio Service Mesh Metrics
  - job_name: 'istio-mesh'
    kubernetes_sd_configs:
      - role: endpoints
        namespaces:
          names:
            - istio-system
    relabel_configs:
      - source_labels: [__meta_kubernetes_service_name, __meta_kubernetes_endpoint_port_name]
        action: keep
        regex: istio-telemetry;prometheus

  # Node Exporter for System Metrics
  - job_name: 'node-exporter'
    kubernetes_sd_configs:
      - role: endpoints
    relabel_configs:
      - source_labels: [__meta_kubernetes_endpoints_name]
        regex: 'node-exporter'
        action: keep

  # kube-state-metrics for Kubernetes Objects
  - job_name: 'kube-state-metrics'
    static_configs:
      - targets: ['kube-state-metrics:8080']

# Remote Write Configuration for Long-term Storage
remote_write:
  - url: "https://prometheus-remote-write.monitoring.svc.cluster.local/api/v1/write"
    queue_config:
      capacity: 2500
      max_samples_per_send: 1000
      batch_send_deadline: 5s

# Remote Read for Historical Data
remote_read:
  - url: "https://prometheus-remote-read.monitoring.svc.cluster.local/api/v1/read"
```

### Custom Application Metrics Implementation
```java
// Java Microservice Metrics Implementation
@RestController
@Slf4j
public class MetricsController {

    private final MeterRegistry meterRegistry;
    private final Counter httpRequestsTotal;
    private final Timer httpRequestDuration;
    private final Gauge activeConnections;
    private final Counter businessEventsTotal;

    public MetricsController(MeterRegistry meterRegistry) {
        this.meterRegistry = meterRegistry;
        
        // HTTP Request Metrics
        this.httpRequestsTotal = Counter.builder("http_requests_total")
            .description("Total HTTP requests")
            .tag("application", "java-microservice")
            .register(meterRegistry);
            
        this.httpRequestDuration = Timer.builder("http_request_duration_seconds")
            .description("HTTP request duration")
            .register(meterRegistry);
            
        // Application Metrics
        this.activeConnections = Gauge.builder("active_database_connections")
            .description("Active database connections")
            .register(meterRegistry, this, MetricsController::getActiveConnections);
            
        // Business Metrics
        this.businessEventsTotal = Counter.builder("business_events_total")
            .description("Total business events processed")
            .register(meterRegistry);
    }

    @EventListener
    public void handleHttpRequest(HttpRequestEvent event) {
        httpRequestsTotal.increment(
            Tags.of(
                "method", event.getMethod(),
                "status", String.valueOf(event.getStatusCode()),
                "endpoint", event.getEndpoint()
            )
        );
    }

    @Timed(name = "api_endpoint_duration", description = "API endpoint response time")
    @GetMapping("/api/users")
    public ResponseEntity<List<User>> getUsers() {
        Timer.Sample sample = Timer.start(meterRegistry);
        try {
            List<User> users = userService.getAllUsers();
            businessEventsTotal.increment(Tags.of("event_type", "user_fetch"));
            return ResponseEntity.ok(users);
        } finally {
            sample.stop(httpRequestDuration.tag("endpoint", "/api/users"));
        }
    }

    private Double getActiveConnections() {
        return (double) dataSource.getHikariPoolMXBean().getActiveConnections();
    }
}
```

### Prometheus Recording Rules
```yaml
# /etc/prometheus/rules/recording_rules.yml
groups:
  - name: java_microservice.rules
    rules:
      # HTTP Request Rate
      - record: java_microservice:http_request_rate
        expr: |
          sum(rate(http_requests_total[5m])) by (instance, method, status)
          
      # Error Rate Percentage
      - record: java_microservice:error_rate_percentage
        expr: |
          (
            sum(rate(http_requests_total{status=~"5.."}[5m])) by (instance) /
            sum(rate(http_requests_total[5m])) by (instance)
          ) * 100
          
      # Response Time Percentiles
      - record: java_microservice:response_time_99p
        expr: |
          histogram_quantile(0.99, 
            sum(rate(http_request_duration_seconds_bucket[5m])) by (le, instance)
          )
          
      # JVM Memory Usage Percentage
      - record: java_microservice:jvm_memory_usage_percentage
        expr: |
          (
            jvm_memory_used_bytes{area="heap"} / 
            jvm_memory_max_bytes{area="heap"}
          ) * 100
          
      # Database Connection Pool Utilization
      - record: java_microservice:db_connection_pool_utilization
        expr: |
          (
            active_database_connections / 
            max_database_connections
          ) * 100
```

## Full-Stack Application Monitoring

### Complete Application Architecture Monitoring

Our full-stack monitoring covers all tiers of the application:

#### Frontend Monitoring (React + Nginx)
```yaml
# Frontend Service Discovery
- job_name: 'frontend-nginx'
  kubernetes_sd_configs:
    - role: pod
  relabel_configs:
    - source_labels: [__meta_kubernetes_pod_label_app_kubernetes_io_component]
      action: keep
      regex: frontend
    - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
      action: keep
      regex: true
    - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
      action: replace
      target_label: __metrics_path__
      regex: (.+)
  metrics_path: '/metrics'
  scrape_interval: 30s
```

#### Backend Monitoring (Spring Boot)
```yaml
# Spring Boot Application Metrics
- job_name: 'spring-boot-backend'
  kubernetes_sd_configs:
    - role: pod
  relabel_configs:
    - source_labels: [__meta_kubernetes_pod_label_app_kubernetes_io_component]
      action: keep
      regex: backend
    - source_labels: [__meta_kubernetes_pod_container_port_number]
      action: keep
      regex: 9090  # Management port
  metrics_path: '/actuator/prometheus'
  scrape_interval: 15s
```

#### Database Monitoring
```yaml
# PostgreSQL Monitoring
- job_name: 'postgresql'
  static_configs:
    - targets: ['postgres-exporter:9187']
  scrape_interval: 30s

# Redis Monitoring  
- job_name: 'redis'
  static_configs:
    - targets: ['redis-exporter:9121']
  scrape_interval: 30s
```

### Key Full-Stack Metrics

#### Frontend Metrics (Nginx + Application)
- **nginx_http_requests_total**: Total HTTP requests to frontend
- **nginx_http_request_duration_seconds**: Frontend response times
- **nginx_up**: Frontend service availability
- **static_asset_cache_hits**: Cache efficiency for static assets

#### Backend Metrics (Spring Boot Actuator)
- **http_server_requests_seconds**: API endpoint performance
- **jvm_memory_used_bytes**: JVM memory utilization
- **jdbc_connections_active**: Database connection pool usage
- **spring_data_repository_invocations**: Database query performance
- **cache_gets_total**: Redis cache hit/miss rates

#### Database Metrics
- **pg_up**: PostgreSQL availability
- **pg_stat_database_tup_returned**: Database query efficiency
- **pg_locks_count**: Database lock contention
- **redis_connected_clients**: Redis connection count
- **redis_keyspace_hits_total**: Cache effectiveness

#### Application Flow Metrics
- **frontend_to_api_requests**: Frontend → Backend API calls
- **api_to_database_queries**: Backend → Database interactions
- **cache_lookup_requests**: Backend → Redis cache requests

## Grafana Dashboards & Visualization

### Java Microservice Application Dashboard
```json
{
  "dashboard": {
    "id": null,
    "title": "Java Microservice Production Dashboard",
    "tags": ["java", "microservice", "production"],
    "timezone": "browser",
    "refresh": "30s",
    "time": {
      "from": "now-1h",
      "to": "now"
    },
    "panels": [
      {
        "id": 1,
        "title": "Request Rate & Response Time",
        "type": "graph",
        "gridPos": {"h": 8, "w": 12, "x": 0, "y": 0},
        "targets": [
          {
            "expr": "sum(java_microservice:http_request_rate) by (instance)",
            "legendFormat": "Request Rate (req/s) - {{instance}}",
            "refId": "A"
          },
          {
            "expr": "java_microservice:response_time_99p",
            "legendFormat": "99th Percentile Response Time - {{instance}}",
            "refId": "B",
            "yAxis": 2
          }
        ],
        "yAxes": [
          {"label": "Requests/sec", "min": 0},
          {"label": "Response Time (ms)", "min": 0}
        ],
        "alert": {
          "conditions": [
            {
              "query": {"params": ["A", "5m", "now"]},
              "reducer": {"type": "avg"},
              "evaluator": {"params": [100], "type": "gt"}
            }
          ],
          "executionErrorState": "alerting",
          "for": "2m",
          "frequency": "10s",
          "handler": 1,
          "name": "High Request Rate Alert",
          "noDataState": "no_data"
        }
      },
      {
        "id": 2,
        "title": "Error Rate Percentage",
        "type": "singlestat",
        "gridPos": {"h": 4, "w": 6, "x": 12, "y": 0},
        "targets": [
          {
            "expr": "avg(java_microservice:error_rate_percentage)",
            "refId": "A"
          }
        ],
        "valueName": "current",
        "format": "percent",
        "thresholds": "1,5",
        "colors": ["green", "yellow", "red"],
        "colorBackground": true
      },
      {
        "id": 3,
        "title": "JVM Memory Usage",
        "type": "graph",
        "gridPos": {"h": 8, "w": 12, "x": 0, "y": 8},
        "targets": [
          {
            "expr": "java_microservice:jvm_memory_usage_percentage",
            "legendFormat": "Heap Memory Usage % - {{instance}}",
            "refId": "A"
          },
          {
            "expr": "rate(jvm_gc_collection_seconds_sum[5m]) * 1000",
            "legendFormat": "GC Time (ms/s) - {{instance}}",
            "refId": "B"
          }
        ],
        "yAxes": [
          {"label": "Memory %", "min": 0, "max": 100},
          {"label": "GC Time (ms)", "min": 0}
        ]
      },
      {
        "id": 4,
        "title": "Database Performance",
        "type": "graph",
        "gridPos": {"h": 8, "w": 12, "x": 12, "y": 8},
        "targets": [
          {
            "expr": "java_microservice:db_connection_pool_utilization",
            "legendFormat": "Connection Pool Utilization % - {{instance}}",
            "refId": "A"
          },
          {
            "expr": "rate(database_query_duration_seconds_sum[5m])",
            "legendFormat": "Average Query Time (s) - {{instance}}",
            "refId": "B"
          }
        ]
      },
      {
        "id": 5,
        "title": "Kubernetes Resources",
        "type": "graph",
        "gridPos": {"h": 8, "w": 24, "x": 0, "y": 16},
        "targets": [
          {
            "expr": "sum(rate(container_cpu_usage_seconds_total{pod=~\"java-microservice-.*\"}[5m])) by (pod)",
            "legendFormat": "CPU Usage - {{pod}}",
            "refId": "A"
          },
          {
            "expr": "sum(container_memory_working_set_bytes{pod=~\"java-microservice-.*\"}) by (pod) / 1024 / 1024",
            "legendFormat": "Memory Usage (MB) - {{pod}}",
            "refId": "B"
          }
        ]
      },
      {
        "id": 6,
        "title": "Business Metrics",
        "type": "graph",
        "gridPos": {"h": 8, "w": 12, "x": 0, "y": 24},
        "targets": [
          {
            "expr": "sum(rate(business_events_total[5m])) by (event_type)",
            "legendFormat": "{{event_type}} Events/sec",
            "refId": "A"
          }
        ]
      },
      {
        "id": 7,
        "title": "Network I/O",
        "type": "graph",
        "gridPos": {"h": 8, "w": 12, "x": 12, "y": 24},
        "targets": [
          {
            "expr": "sum(rate(container_network_receive_bytes_total{pod=~\"java-microservice-.*\"}[5m])) by (pod)",
            "legendFormat": "Network Rx (bytes/s) - {{pod}}",
            "refId": "A"
          },
          {
            "expr": "sum(rate(container_network_transmit_bytes_total{pod=~\"java-microservice-.*\"}[5m])) by (pod)",
            "legendFormat": "Network Tx (bytes/s) - {{pod}}",
            "refId": "B"
          }
        ]
      }
    ],
    "templating": {
      "list": [
        {
          "name": "environment",
          "type": "query",
          "query": "label_values(up{job=\"java-microservice\"}, kubernetes_namespace)",
          "refresh": 1,
          "multi": false,
          "includeAll": false
        },
        {
          "name": "instance",
          "type": "query",
          "query": "label_values(up{job=\"java-microservice\", kubernetes_namespace=\"$environment\"}, instance)",
          "refresh": 1,
          "multi": true,
          "includeAll": true
        }
      ]
    }
  }
}
```

### Infrastructure Overview Dashboard
```json
{
  "dashboard": {
    "title": "Infrastructure Overview Dashboard",
    "panels": [
      {
        "id": 1,
        "title": "Cluster Resource Utilization",
        "type": "graph",
        "targets": [
          {
            "expr": "(sum(rate(container_cpu_usage_seconds_total[5m])) by (node) / sum(machine_cpu_cores) by (node)) * 100",
            "legendFormat": "CPU Utilization % - {{node}}"
          },
          {
            "expr": "(sum(container_memory_working_set_bytes) by (node) / sum(machine_memory_bytes) by (node)) * 100",
            "legendFormat": "Memory Utilization % - {{node}}"
          }
        ]
      },
      {
        "id": 2,
        "title": "Pod Status Overview",
        "type": "table",
        "targets": [
          {
            "expr": "kube_pod_status_phase",
            "format": "table",
            "instant": true
          }
        ]
      }
    ]
  }
}
```

## Distributed Tracing with Jaeger

### Jaeger Configuration for Microservice Tracing
```yaml
# jaeger-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: jaeger
  namespace: monitoring
spec:
  replicas: 1
  selector:
    matchLabels:
      app: jaeger
  template:
    metadata:
      labels:
        app: jaeger
    spec:
      containers:
      - name: jaeger
        image: jaegertracing/all-in-one:1.47
        ports:
        - containerPort: 16686
          name: ui
        - containerPort: 14268
          name: collector
        - containerPort: 6831
          protocol: UDP
          name: agent-compact
        - containerPort: 6832
          protocol: UDP
          name: agent-binary
        env:
        - name: COLLECTOR_ZIPKIN_HTTP_PORT
          value: "9411"
        - name: SPAN_STORAGE_TYPE
          value: "elasticsearch"
        - name: ES_SERVER_URLS
          value: "http://elasticsearch:9200"
        - name: ES_USERNAME
          value: "elastic"
        - name: ES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: elasticsearch-credentials
              key: password
        resources:
          limits:
            memory: "500Mi"
            cpu: "500m"
          requests:
            memory: "256Mi"
            cpu: "100m"
---
apiVersion: v1
kind: Service
metadata:
  name: jaeger-service
  namespace: monitoring
spec:
  selector:
    app: jaeger
  ports:
  - port: 16686
    targetPort: 16686
    name: ui
  - port: 14268
    targetPort: 14268
    name: collector
  - port: 6831
    protocol: UDP
    targetPort: 6831
    name: agent-compact
  - port: 6832
    protocol: UDP
    targetPort: 6832
    name: agent-binary
```

### Application Tracing Implementation
```java
// Spring Boot Jaeger Integration
@Configuration
@EnableAutoConfiguration
public class TracingConfiguration {

    @Bean
    public JaegerTracer jaegerTracer() {
        Configuration.SamplerConfiguration samplerConfig = 
            Configuration.SamplerConfiguration.fromEnv()
                .withType("const")
                .withParam(1); // Sample 100% of traces in development

        Configuration.ReporterConfiguration reporterConfig = 
            Configuration.ReporterConfiguration.fromEnv()
                .withLogSpans(true)
                .withFlushInterval(1000)
                .withMaxQueueSize(10000);

        Configuration config = new Configuration("java-microservice")
            .withSampler(samplerConfig)
            .withReporter(reporterConfig);

        return config.getTracer();
    }
}

@RestController
@Slf4j
public class TracedController {

    @Autowired
    private Tracer tracer;

    @Autowired
    private UserService userService;

    @GetMapping("/api/users/{id}")
    public ResponseEntity<User> getUser(@PathVariable Long id) {
        Span span = tracer.nextSpan()
            .name("get-user-operation")
            .tag("user.id", String.valueOf(id))
            .tag("operation.type", "read")
            .start();

        try (Tracer.SpanInScope ws = tracer.withSpanInScope(span)) {
            log.info("Fetching user with ID: {}", id);
            
            // Add custom events to trace
            span.event("user.fetch.started");
            
            User user = userService.findById(id);
            
            if (user != null) {
                span.tag("user.found", "true");
                span.event("user.fetch.completed");
                return ResponseEntity.ok(user);
            } else {
                span.tag("user.found", "false");
                span.tag("error", "true");
                span.event("user.not.found");
                return ResponseEntity.notFound().build();
            }
        } catch (Exception e) {
            span.tag("error", "true");
            span.tag("error.message", e.getMessage());
            span.event("user.fetch.error");
            throw e;
        } finally {
            span.end();
        }
    }
}

@Service
public class TracedUserService {

    @Autowired
    private Tracer tracer;

    @Autowired
    private UserRepository userRepository;

    @NewSpan("user-service-find-by-id")
    public User findById(@SpanTag("userId") Long id) {
        Span span = tracer.nextSpan()
            .name("database-query")
            .tag("db.type", "mysql")
            .tag("db.operation", "select")
            .start();

        try (Tracer.SpanInScope ws = tracer.withSpanInScope(span)) {
            span.event("db.query.started");
            
            User user = userRepository.findById(id).orElse(null);
            
            span.tag("db.rows.affected", user != null ? "1" : "0");
            span.event("db.query.completed");
            
            return user;
        } finally {
            span.end();
        }
    }
}
```

### Trace Analysis Queries
```javascript
// Jaeger UI Query Examples

// 1. Find slow requests (>1 second)
{
  "service": "java-microservice",
  "operation": "get-user-operation",
  "minDuration": "1s"
}

// 2. Find error traces in last hour
{
  "service": "java-microservice",
  "tags": {
    "error": "true"
  },
  "lookback": "1h"
}

// 3. Find database-related performance issues
{
  "service": "java-microservice",
  "operation": "database-query",
  "minDuration": "500ms",
  "limit": 100
}

// 4. Trace dependency analysis
{
  "service": "java-microservice",
  "tags": {
    "operation.type": "read"
  }
}
```

## Centralized Logging (EFK Stack)

### Complete EFK Stack Deployment
```yaml
# elasticsearch-cluster.yaml
apiVersion: elasticsearch.k8s.elastic.co/v1
kind: Elasticsearch
metadata:
  name: elasticsearch
  namespace: monitoring
spec:
  version: 8.8.0
  nodeSets:
  - name: master
    count: 3
    config:
      node.roles: ["master"]
      xpack.security.enabled: true
      xpack.security.transport.ssl.enabled: true
    podTemplate:
      spec:
        containers:
        - name: elasticsearch
          resources:
            limits:
              memory: 2Gi
              cpu: 1000m
            requests:
              memory: 1Gi
              cpu: 500m
          env:
          - name: ES_JAVA_OPTS
            value: "-Xms1g -Xmx1g"
    volumeClaimTemplates:
    - metadata:
        name: elasticsearch-data
      spec:
        accessModes:
        - ReadWriteOnce
        resources:
          requests:
            storage: 50Gi
        storageClassName: gp3
  - name: data
    count: 3
    config:
      node.roles: ["data", "ingest"]
      xpack.security.enabled: true
    podTemplate:
      spec:
        containers:
        - name: elasticsearch
          resources:
            limits:
              memory: 4Gi
              cpu: 2000m
            requests:
              memory: 2Gi
              cpu: 1000m
          env:
          - name: ES_JAVA_OPTS
            value: "-Xms2g -Xmx2g"
    volumeClaimTemplates:
    - metadata:
        name: elasticsearch-data
      spec:
        accessModes:
        - ReadWriteOnce
        resources:
          requests:
            storage: 100Gi
        storageClassName: gp3

---
# fluentd-daemonset.yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fluentd
  namespace: monitoring
spec:
  selector:
    matchLabels:
      name: fluentd
  template:
    metadata:
      labels:
        name: fluentd
    spec:
      serviceAccountName: fluentd
      containers:
      - name: fluentd
        image: fluent/fluentd-kubernetes-daemonset:v1.16-debian-elasticsearch7-1
        env:
        - name: FLUENT_ELASTICSEARCH_HOST
          value: "elasticsearch-es-http"
        - name: FLUENT_ELASTICSEARCH_PORT
          value: "9200"
        - name: FLUENT_ELASTICSEARCH_SCHEME
          value: "https"
        - name: FLUENT_ELASTICSEARCH_SSL_VERIFY
          value: "false"
        - name: FLUENT_ELASTICSEARCH_USER
          value: "elastic"
        - name: FLUENT_ELASTICSEARCH_PASSWORD
          valueFrom:
            secretKeyRef:
              name: elasticsearch-es-elastic-user
              key: elastic
        - name: FLUENT_ELASTICSEARCH_INDEX_NAME
          value: "kubernetes"
        resources:
          limits:
            memory: 512Mi
            cpu: 500m
          requests:
            memory: 256Mi
            cpu: 100m
        volumeMounts:
        - name: varlog
          mountPath: /var/log
          readOnly: true
        - name: varlibdockercontainers
          mountPath: /var/lib/docker/containers
          readOnly: true
        - name: fluentd-config
          mountPath: /fluentd/etc/fluent.conf
          subPath: fluent.conf
      volumes:
      - name: varlog
        hostPath:
          path: /var/log
      - name: varlibdockercontainers
        hostPath:
          path: /var/lib/docker/containers
      - name: fluentd-config
        configMap:
          name: fluentd-config

---
# kibana-deployment.yaml
apiVersion: kibana.k8s.elastic.co/v1
kind: Kibana
metadata:
  name: kibana
  namespace: monitoring
spec:
  version: 8.8.0
  count: 1
  elasticsearchRef:
    name: elasticsearch
  config:
    server.publicBaseUrl: "https://kibana.example.com"
    xpack.security.enabled: true
  podTemplate:
    spec:
      containers:
      - name: kibana
        resources:
          limits:
            memory: 2Gi
            cpu: 1000m
          requests:
            memory: 1Gi
            cpu: 500m
```

### Fluentd Configuration for Application Logs
```ruby
# fluent.conf - Advanced log processing configuration
<source>
  @type tail
  @id java_microservice_logs
  path /var/log/containers/*java-microservice*.log
  pos_file /var/log/fluentd-java-microservice.log.pos
  tag kubernetes.java-microservice
  format json
  time_key timestamp
  time_format %Y-%m-%dT%H:%M:%S.%N%z
  read_from_head true
</source>

# Parse Kubernetes metadata
<filter kubernetes.java-microservice>
  @type kubernetes_metadata
  @id kubernetes_metadata_java_microservice
  kubernetes_url "#{ENV['FLUENT_FILTER_KUBERNETES_URL'] || 'https://' + ENV.fetch('KUBERNETES_SERVICE_HOST') + ':' + ENV.fetch('KUBERNETES_SERVICE_PORT') + '/api'}"
  verify_ssl "#{ENV['KUBERNETES_VERIFY_SSL'] || true}"
  ca_file "#{ENV['KUBERNETES_CA_FILE']}"
  skip_labels "#{ENV['FLUENT_KUBERNETES_METADATA_SKIP_LABELS'] || 'false'}"
  skip_container_metadata "#{ENV['FLUENT_KUBERNETES_METADATA_SKIP_CONTAINER_METADATA'] || 'false'}"
  skip_master_url "#{ENV['FLUENT_KUBERNETES_METADATA_SKIP_MASTER_URL'] || 'false'}"
  skip_namespace_metadata "#{ENV['FLUENT_KUBERNETES_METADATA_SKIP_NAMESPACE_METADATA'] || 'false'}"
</filter>

# Parse Java application logs
<filter kubernetes.java-microservice>
  @type parser
  @id java_log_parser
  key_name log
  reserve_data true
  remove_key_name_field false
  <parse>
    @type multiline_grok
    grok_pattern %{TIMESTAMP_ISO8601:timestamp} %{LOGLEVEL:level} %{DATA:thread} %{DATA:logger} : %{GREEDYDATA:message}
    multiline_start_regexp /^\d{4}-\d{2}-\d{2}/
    multiline_flush_interval 5s
  </parse>
</filter>

# Add environment and service information
<filter kubernetes.java-microservice>
  @type record_transformer
  @id java_microservice_transformer
  <record>
    service_name java-microservice
    environment ${record["kubernetes"]["namespace_name"]}
    cluster_name ${ENV["CLUSTER_NAME"] || "unknown"}
    region ${ENV["AWS_REGION"] || "unknown"}
  </record>
</filter>

# Route to Elasticsearch
<match kubernetes.java-microservice>
  @type elasticsearch
  @id elasticsearch_java_microservice
  host "#{ENV['FLUENT_ELASTICSEARCH_HOST']}"
  port "#{ENV['FLUENT_ELASTICSEARCH_PORT']}"
  scheme "#{ENV['FLUENT_ELASTICSEARCH_SCHEME'] || 'http'}"
  ssl_verify "#{ENV['FLUENT_ELASTICSEARCH_SSL_VERIFY'] || 'true'}"
  user "#{ENV['FLUENT_ELASTICSEARCH_USER'] || use_default}"
  password "#{ENV['FLUENT_ELASTICSEARCH_PASSWORD'] || use_default}"
  
  index_name java-microservice-logs
  template_name java-microservice-template
  template_file /fluentd/etc/elasticsearch-template.json
  
  <buffer>
    @type file
    path /var/log/fluentd-buffers/java-microservice.buffer
    flush_mode interval
    retry_type exponential_backoff
    flush_thread_count 2
    flush_interval 5s
    retry_forever true
    retry_max_interval 30
    chunk_limit_size 2M
    total_limit_size 500M
    overflow_action block
  </buffer>
</match>
```

### Elasticsearch Index Templates and Mappings
```json
{
  "index_patterns": ["java-microservice-logs-*"],
  "template": {
    "settings": {
      "number_of_shards": 3,
      "number_of_replicas": 1,
      "index.lifecycle.name": "java-microservice-policy",
      "index.lifecycle.rollover_alias": "java-microservice-logs"
    },
    "mappings": {
      "properties": {
        "timestamp": {
          "type": "date",
          "format": "strict_date_optional_time||epoch_millis"
        },
        "level": {
          "type": "keyword"
        },
        "logger": {
          "type": "keyword"
        },
        "message": {
          "type": "text",
          "analyzer": "standard"
        },
        "thread": {
          "type": "keyword"
        },
        "service_name": {
          "type": "keyword"
        },
        "environment": {
          "type": "keyword"
        },
        "kubernetes": {
          "properties": {
            "namespace_name": {"type": "keyword"},
            "pod_name": {"type": "keyword"},
            "container_name": {"type": "keyword"},
            "labels": {
              "type": "object",
              "dynamic": true
            }
          }
        },
        "trace_id": {
          "type": "keyword"
        },
        "span_id": {
          "type": "keyword"
        }
      }
    }
  }
}
```

## AWS CloudWatch Integration

### CloudWatch Agent Configuration
```json
{
  "agent": {
    "metrics_collection_interval": 60,
    "run_as_user": "cwagent"
  },
  "metrics": {
    "namespace": "JavaMicroservice/EKS",
    "metrics_collected": {
      "cpu": {
        "measurement": [
          "cpu_usage_idle",
          "cpu_usage_iowait",
          "cpu_usage_user",
          "cpu_usage_system"
        ],
        "metrics_collection_interval": 60,
        "resources": [
          "*"
        ],
        "totalcpu": false
      },
      "disk": {
        "measurement": [
          "used_percent"
        ],
        "metrics_collection_interval": 60,
        "resources": [
          "*"
        ]
      },
      "diskio": {
        "measurement": [
          "io_time",
          "read_bytes",
          "write_bytes",
          "reads",
          "writes"
        ],
        "metrics_collection_interval": 60,
        "resources": [
          "*"
        ]
      },
      "mem": {
        "measurement": [
          "mem_used_percent"
        ],
        "metrics_collection_interval": 60
      },
      "netstat": {
        "measurement": [
          "tcp_established",
          "tcp_time_wait"
        ],
        "metrics_collection_interval": 60
      },
      "swap": {
        "measurement": [
          "swap_used_percent"
        ],
        "metrics_collection_interval": 60
      }
    },
    "append_dimensions": {
      "AutoScalingGroupName": "${aws:AutoScalingGroupName}",
      "InstanceId": "${aws:InstanceId}",
      "InstanceType": "${aws:InstanceType}"
    }
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/containers/*java-microservice*.log",
            "log_group_name": "/aws/eks/java-microservice/application",
            "log_stream_name": "{instance_id}/java-microservice",
            "timezone": "UTC",
            "multi_line_start_pattern": "^\\d{4}-\\d{2}-\\d{2}",
            "encoding": "utf-8"
          },
          {
            "file_path": "/var/log/messages",
            "log_group_name": "/aws/eks/java-microservice/system",
            "log_stream_name": "{instance_id}/messages",
            "timezone": "UTC"
          }
        ]
      }
    },
    "log_stream_name": "java-microservice-{instance_id}"
  }
}
```

### CloudWatch Custom Dashboards
```json
{
  "widgets": [
    {
      "type": "metric",
      "properties": {
        "metrics": [
          ["JavaMicroservice/EKS", "CPUUtilization", "AutoScalingGroupName", "java-microservice-nodes"],
          [".", "MemoryUtilization", ".", "."],
          [".", "NetworkIn", ".", "."],
          [".", "NetworkOut", ".", "."]
        ],
        "period": 300,
        "stat": "Average",
        "region": "us-east-1",
        "title": "EKS Node Performance"
      }
    },
    {
      "type": "log",
      "properties": {
        "query": "SOURCE '/aws/eks/java-microservice/application'\n| fields @timestamp, level, logger, message\n| filter level = \"ERROR\"\n| sort @timestamp desc\n| limit 100",
        "region": "us-east-1",
        "title": "Recent Application Errors"
      }
    }
  ]
}
```

### CloudWatch Insights Queries
```sql
-- Application Error Analysis
SOURCE '/aws/eks/java-microservice/application'
| fields @timestamp, level, logger, message, trace_id
| filter level = "ERROR"
| stats count() by logger
| sort count desc

-- Performance Analysis
SOURCE '/aws/eks/java-microservice/application'
| fields @timestamp, message
| filter message like /response_time/
| parse message "response_time=* ms" as response_time
| stats avg(response_time), max(response_time), min(response_time) by bin(5m)

-- Database Connection Issues
SOURCE '/aws/eks/java-microservice/application'
| fields @timestamp, message
| filter message like /database/ or message like /connection/
| filter level = "ERROR" or level = "WARN"
| sort @timestamp desc
| limit 50

-- Request Volume Analysis
SOURCE '/aws/eks/java-microservice/application'
| fields @timestamp, message
| filter message like /HTTP/
| parse message "method=* uri=* status=*" as method, uri, status
| stats count() by method, uri
| sort count desc
```

## Alerting & Incident Management

### Comprehensive Alert Rules Configuration
```yaml
# alerting-rules.yml
groups:
  - name: java-microservice-alerts
    rules:
      # High-Priority Alerts
      - alert: ServiceDown
        expr: up{job="java-microservice"} == 0
        for: 1m
        labels:
          severity: critical
          service: java-microservice
          team: backend
        annotations:
          summary: "Java Microservice is down"
          description: "Java Microservice {{ $labels.instance }} has been down for more than 1 minute"
          runbook_url: "https://wiki.company.com/runbooks/java-microservice-down"
          
      - alert: HighErrorRate
        expr: java_microservice:error_rate_percentage > 5
        for: 2m
        labels:
          severity: critical
          service: java-microservice
          team: backend
        annotations:
          summary: "High error rate detected"
          description: "Error rate is {{ $value }}% for {{ $labels.instance }}"
          dashboard_url: "https://grafana.company.com/d/java-microservice"
          
      - alert: HighResponseTime
        expr: java_microservice:response_time_99p > 2
        for: 3m
        labels:
          severity: warning
          service: java-microservice
          team: backend
        annotations:
          summary: "High response time detected"
          description: "99th percentile response time is {{ $value }}s"
          
      # Resource Alerts
      - alert: HighMemoryUsage
        expr: java_microservice:jvm_memory_usage_percentage > 85
        for: 5m
        labels:
          severity: warning
          service: java-microservice
          team: backend
        annotations:
          summary: "High JVM memory usage"
          description: "JVM heap memory usage is {{ $value }}%"
          
      - alert: HighCPUUsage
        expr: rate(container_cpu_usage_seconds_total{pod=~"java-microservice-.*"}[5m]) * 100 > 80
        for: 5m
        labels:
          severity: warning
          service: java-microservice
          team: backend
        annotations:
          summary: "High CPU usage detected"
          description: "CPU usage is {{ $value }}% for pod {{ $labels.pod }}"
          
      # Database Alerts
      - alert: DatabaseConnectionPoolHigh
        expr: java_microservice:db_connection_pool_utilization > 90
        for: 3m
        labels:
          severity: warning
          service: java-microservice
          team: backend
        annotations:
          summary: "Database connection pool nearly exhausted"
          description: "Connection pool utilization is {{ $value }}%"
          
      - alert: SlowDatabaseQueries
        expr: rate(database_query_duration_seconds_sum[5m]) / rate(database_query_duration_seconds_count[5m]) > 1
        for: 3m
        labels:
          severity: warning
          service: java-microservice
          team: backend
        annotations:
          summary: "Slow database queries detected"
          description: "Average query time is {{ $value }}s"
          
      # Business Logic Alerts
      - alert: LowBusinessEventRate
        expr: rate(business_events_total[5m]) < 0.1
        for: 10m
        labels:
          severity: warning
          service: java-microservice
          team: product
        annotations:
          summary: "Low business event processing rate"
          description: "Business event rate is {{ $value }} events/second"
          
      # Infrastructure Alerts
      - alert: PodCrashLooping
        expr: rate(kube_pod_container_status_restarts_total{pod=~"java-microservice-.*"}[15m]) > 0
        for: 1m
        labels:
          severity: critical
          service: java-microservice
          team: sre
        annotations:
          summary: "Pod is crash looping"
          description: "Pod {{ $labels.pod }} is restarting frequently"
          
      - alert: PersistentVolumeSpaceLow
        expr: (kubelet_volume_stats_available_bytes / kubelet_volume_stats_capacity_bytes) * 100 < 10
        for: 5m
        labels:
          severity: warning
          service: java-microservice
          team: sre
        annotations:
          summary: "Persistent volume space low"
          description: "PV {{ $labels.persistentvolumeclaim }} has less than 10% space remaining"
```

### Multi-Channel Alert Manager Configuration
```yaml
# alertmanager.yml
global:
  smtp_smarthost: 'smtp.company.com:587'
  smtp_from: 'alerts@company.com'
  slack_api_url: 'https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK'

route:
  group_by: ['alertname', 'service']
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 12h
  receiver: 'default-receiver'
  routes:
    # Critical alerts go to PagerDuty and Slack
    - match:
        severity: critical
      receiver: 'critical-alerts'
      group_wait: 10s
      repeat_interval: 5m
      
    # Warning alerts go to Slack only
    - match:
        severity: warning
      receiver: 'warning-alerts'
      
    # Team-specific routing
    - match:
        team: backend
      receiver: 'backend-team'
      
    - match:
        team: sre
      receiver: 'sre-team'

receivers:
  - name: 'default-receiver'
    email_configs:
      - to: 'devops@company.com'
        subject: '{{ range .Alerts }}{{ .Annotations.summary }}{{ end }}'
        body: |
          {{ range .Alerts }}
          Alert: {{ .Annotations.summary }}
          Description: {{ .Annotations.description }}
          Labels: {{ range .Labels.SortedPairs }}{{ .Name }}={{ .Value }} {{ end }}
          {{ end }}

  - name: 'critical-alerts'
    pagerduty_configs:
      - service_key: 'YOUR_PAGERDUTY_SERVICE_KEY'
        description: '{{ range .Alerts }}{{ .Annotations.summary }}{{ end }}'
        details:
          firing: '{{ .Alerts.Firing | len }}'
          resolved: '{{ .Alerts.Resolved | len }}'
    slack_configs:
      - channel: '#critical-alerts'
        color: 'danger'
        title: 'Critical Alert'
        text: '{{ range .Alerts }}{{ .Annotations.summary }}{{ end }}'
        fields:
          - title: 'Description'
            value: '{{ range .Alerts }}{{ .Annotations.description }}{{ end }}'
          - title: 'Runbook'
            value: '{{ range .Alerts }}{{ .Annotations.runbook_url }}{{ end }}'

  - name: 'warning-alerts'
    slack_configs:
      - channel: '#alerts'
        color: 'warning'
        title: 'Warning Alert'
        text: '{{ range .Alerts }}{{ .Annotations.summary }}{{ end }}'

  - name: 'backend-team'
    slack_configs:
      - channel: '#backend-alerts'
        color: '{{ if eq .Status "firing" }}danger{{ else }}good{{ end }}'
        title: 'Backend Service Alert'
        text: '{{ range .Alerts }}{{ .Annotations.summary }}{{ end }}'
    email_configs:
      - to: 'backend-team@company.com'

  - name: 'sre-team'
    slack_configs:
      - channel: '#sre-alerts'
        color: '{{ if eq .Status "firing" }}danger{{ else }}good{{ end }}'
        title: 'Infrastructure Alert'
        text: '{{ range .Alerts }}{{ .Annotations.summary }}{{ end }}'
    email_configs:
      - to: 'sre-team@company.com'

inhibit_rules:
  # Inhibit warning alerts when critical alerts are firing
  - source_match:
      severity: 'critical'
    target_match:
      severity: 'warning'
    equal: ['service', 'instance']
```

This comprehensive monitoring and observability implementation provides complete visibility into the Java microservice application, infrastructure, and business metrics while ensuring rapid incident detection and response through multi-channel alerting systems.