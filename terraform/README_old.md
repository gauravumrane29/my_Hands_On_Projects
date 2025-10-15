# AWS 3-Tier Infrastructure with Terraform

This Terraform configuration creates a complete 3-tier architecture on AWS suitable for hosting the Java Spring Boot microservice.

## Architecture Overview

### **Tier 1: Web/Presentation Tier**
- Application Load Balancer (ALB) in public subnets
- Routes traffic to application servers
- SSL termination and security

### **Tier 2: Application Tier**
- EC2 instances in private subnets
- Auto-configured with Java 17 and Docker
- Security groups restricting access from web tier only

### **Tier 3: Database Tier**
- Private subnets reserved for database resources
- Network isolation from public internet
- Ready for RDS deployment

## Infrastructure Components

### **Networking**
- VPC with DNS support enabled
- 2 Public subnets (across different AZs)
- 2 Private application subnets (across different AZs) 
- 2 Private database subnets (across different AZs)
- Internet Gateway for public access
- Route tables and associations

### **Security**
- Security Groups with least-privilege access
- Web tier: Allows HTTP/HTTPS from internet
- App tier: Allows port 8080 from web tier only
- SSH access restricted to VPC CIDR

### **Compute**
- EC2 instance with latest Amazon Linux 2
- Automated setup via user data script
- Application deployment ready

### **Load Balancing**
- Application Load Balancer with health checks
- Target group configuration
- Health check on `/hello` endpoint

## Usage

### **Prerequisites**
1. AWS CLI configured with appropriate credentials
2. Terraform installed (>= 1.0)

### **Deployment Steps**

1. **Clone and navigate to terraform directory**
   ```bash
   cd terraform/
   ```

2. **Copy and customize variables**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your specific values
   ```

3. **Initialize Terraform**
   ```bash
   terraform init
   ```

4. **Plan the deployment**
   ```bash
   terraform plan
   ```

5. **Apply the configuration**
   ```bash
   terraform apply
   ```

6. **Access the application**
   ```bash
   # Get the load balancer URL
   terraform output load_balancer_url
   ```

### **Cleanup**
```bash
terraform destroy
```

## Configuration

### **Variables**
- `region`: AWS region (default: us-east-1)
- `environment`: Environment name (default: dev)
- `instance_type`: EC2 instance type (default: t2.micro)
- `app_version`: Application version tag (default: latest)
- `project_name`: Project identifier (default: 3-tier-devops)

### **Outputs**
- `load_balancer_url`: URL to access the application
- `vpc_id`: Created VPC ID
- `subnet_ids`: All created subnet IDs
- `security_group_ids`: Security group IDs

## Security Considerations

- All application servers are in private subnets
- No direct internet access to application tier
- Security groups implement least-privilege access
- Database subnets prepared for RDS with no public access
- Load balancer handles all public traffic

## Cost Optimization

- Uses t2.micro instances (free tier eligible)
- Application Load Balancer (pay per use)
- EBS volumes are gp3 by default
- Resources tagged for cost tracking

## Next Steps

1. **Database Integration**: Add RDS instances in database subnets
2. **Auto Scaling**: Implement Auto Scaling Groups
3. **Monitoring**: Add CloudWatch dashboards and alarms
4. **CI/CD Integration**: Connect with deployment pipelines
5. **SSL/TLS**: Add ACM certificates for HTTPS
6. **WAF**: Add Web Application Firewall for security

## Troubleshooting

### **Common Issues**
- **Insufficient IAM permissions**: Ensure AWS credentials have required permissions
- **Resource limits**: Check AWS service quotas in your account
- **AZ availability**: Some regions may not have all AZs available

### **Useful Commands**
```bash
# Check Terraform state
terraform show

# Format Terraform files
terraform fmt

# Validate configuration
terraform validate

# View detailed plan
terraform plan -out=tfplan
terraform show tfplan
```