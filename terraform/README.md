# Terraform Infrastructure for Full-Stack Java Application

This directory contains Terraform configurations for deploying a complete full-stack application with React frontend, Spring Boot backend, PostgreSQL database, and Redis cache on AWS.

## Architecture Overview

The infrastructure creates a 3-tier architecture:

### Web Tier (Public Subnets)
- Application Load Balancer (ALB) with path-based routing
- Internet Gateway for public access
- Routes `/api/*` and `/actuator/*` to backend
- Routes all other traffic to frontend

### Application Tier (Private Subnets)
- EC2 instances running both frontend and backend services
- Auto-scaling launch template for future scaling
- NAT Gateway for outbound internet access
- Security groups with least privilege access

### Database Tier (Private Subnets)
- PostgreSQL 15.4 RDS instance with encryption
- Redis ElastiCache cluster for caching/sessions
- Dedicated security groups for database access
- Automated backups and maintenance windows

## Prerequisites

- AWS CLI configured with appropriate credentials and permissions:
  - EC2, VPC, RDS, ElastiCache, IAM, CloudWatch permissions
- Terraform installed (version >= 1.0)
- An existing AWS key pair for SSH access (optional)

## Quick Start

1. **Copy and customize variables:**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your specific values
   ```

2. **Initialize Terraform:**
   ```bash
   terraform init
   ```

3. **Review the plan:**
   ```bash
   terraform plan
   ```

4. **Deploy infrastructure:**
   ```bash
   terraform apply
   ```

5. **Access your application:**
   ```bash
   # Get the load balancer URL
   terraform output load_balancer_url
   ```

## Configuration Variables

### Essential Variables (terraform.tfvars)

```hcl
# AWS Configuration
region = "us-east-1"
environment = "dev"
project_name = "java-microservice"

# Database Security
db_password = "your-secure-password-here"

# Optional: SSH Key for debugging
key_name = "your-aws-key-pair"
```

### Available Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `region` | us-east-1 | AWS region for deployment |
| `environment` | dev | Environment name (dev/staging/prod) |
| `project_name` | java-microservice | Project name for resource naming |
| `instance_type` | t3.small | EC2 instance type |
| `db_instance_class` | db.t3.micro | PostgreSQL instance class |
| `db_password` | postgres | Database password (change this!) |
| `redis_node_type` | cache.t3.micro | Redis node type |
| `redis_num_cache_nodes` | 1 | Number of Redis nodes |

## Infrastructure Components

### Networking
- **VPC**: 10.0.0.0/16 CIDR with DNS support
- **Public Subnets**: 2 AZs (10.0.1.0/24, 10.0.2.0/24)
- **Private App Subnets**: 2 AZs (10.0.10.0/24, 10.0.11.0/24)
- **Private DB Subnets**: 2 AZs (10.0.20.0/24, 10.0.21.0/24)
- **Internet Gateway**: Public internet access
- **NAT Gateway**: Outbound access for private subnets

### Load Balancing & Routing
- **Application Load Balancer**: Internet-facing with SSL termination
- **Backend Target Group**: Health checks on `/actuator/health`
- **Frontend Target Group**: Health checks on `/`
- **Path-based Routing**: API requests to backend, UI to frontend

### Compute
- **EC2 Instances**: Application servers with IAM roles
- **Launch Template**: Auto-scaling ready configuration
- **User Data**: Automated setup of Docker, Node.js, Java
- **IAM Role**: CloudWatch and Systems Manager permissions

### Database & Caching
- **PostgreSQL RDS**: 15.4 with encryption and automated backups
- **Redis ElastiCache**: Cluster with encryption in transit/rest
- **Subnet Groups**: Multi-AZ deployment for high availability

### Security
- **Web Tier SG**: HTTP/HTTPS from internet
- **App Tier SG**: Backend (8080) and Frontend (3000) from ALB
- **DB Tier SG**: PostgreSQL (5432) from app tier only
- **Redis SG**: Redis (6379) from app tier only

## Outputs

The Terraform configuration provides these outputs:

### Application Access
- `load_balancer_url`: Public URL to access your application
- `load_balancer_dns`: ALB DNS name

### Database Connections
- `database_connection_string`: Full PostgreSQL connection string
- `redis_connection_string`: Redis connection details
- `postgres_endpoint`: PostgreSQL RDS endpoint
- `redis_endpoint`: Redis cluster endpoint

### Infrastructure Details
- `vpc_id`: VPC identifier
- `subnet_ids`: All subnet identifiers by tier
- `security_group_ids`: Security group identifiers
- `iam_role_arn`: EC2 IAM role ARN

## Application Deployment

The infrastructure sets up the foundation. To deploy your application:

1. **Build and push Docker images** to ECR or Docker Hub
2. **Update user_data.sh** with your image references
3. **Configure environment variables** in the EC2 instance
4. **Use the launch template** for auto-scaling groups

### Environment Variables Set by Infrastructure

The EC2 instances are configured with these environment variables:

```bash
# Database
DB_HOST=<postgres-endpoint>
DB_PORT=5432
DB_NAME=demoapp
DB_USERNAME=postgres
DB_PASSWORD=<your-password>

# Redis
REDIS_HOST=<redis-endpoint>
REDIS_PORT=6379

# Application
REACT_APP_API_URL=http://localhost:8080/api
SPRING_PROFILES_ACTIVE=aws
```

## Monitoring & Logging

The infrastructure includes:
- **CloudWatch Agent**: System metrics and application logs
- **Custom Metrics**: Application performance monitoring
- **Log Groups**: Structured logging for troubleshooting

## Security Considerations

- Database passwords are marked as sensitive
- All database traffic is within private subnets
- Security groups follow least privilege principles
- RDS and Redis use encryption at rest and in transit
- IAM roles have minimal required permissions

## Cost Optimization

For development environments:
- Use t3.micro for EC2 and database instances
- Single Redis node instead of cluster
- Consider using RDS Aurora Serverless for variable workloads

For production:
- Enable Multi-AZ for RDS
- Use larger instance types
- Enable Performance Insights
- Consider Reserved Instances for cost savings

## Cleanup

To destroy all infrastructure:

```bash
terraform destroy
```

**Warning**: This will permanently delete all resources including databases. Ensure you have backups if needed.

## Troubleshooting

### Common Issues

1. **Permission Errors**: Ensure your AWS credentials have sufficient permissions
2. **Key Pair Not Found**: Create an EC2 key pair in your region first
3. **Resource Limits**: Check AWS service quotas for your region
4. **Database Connection**: Verify security groups allow database access

### Debugging

- Check CloudWatch logs for application issues
- Use Systems Manager Session Manager for SSH access
- Monitor ALB target health in the AWS Console
- Review security group rules for connectivity issues

## Next Steps

After infrastructure deployment:
1. Set up CI/CD pipelines (Jenkins configuration in `/jenkins`)
2. Configure monitoring (Prometheus/Grafana in `/monitoring`)
3. Deploy with Ansible playbooks (`/ansible`)
4. Set up Kubernetes deployment (`/deployment/helm`)

## Support

For issues specific to this infrastructure:
1. Check the troubleshooting section above
2. Review AWS CloudWatch logs
3. Validate Terraform plan before applying changes