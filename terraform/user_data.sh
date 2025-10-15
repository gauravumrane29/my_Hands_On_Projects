#!/bin/bash

# Update system
yum update -y

# Install Java 17
yum install -y java-17-amazon-corretto-devel

# Install Node.js 18
curl -fsSL https://rpm.nodesource.com/setup_18.x | bash -
yum install -y nodejs

# Install Docker
yum install -y docker
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Install CloudWatch agent
yum install -y amazon-cloudwatch-agent

# Create application directory
mkdir -p /opt/app
mkdir -p /opt/app/backend
mkdir -p /opt/app/frontend
mkdir -p /opt/app/config
cd /opt/app

# Set environment variables
cat > /opt/app/config/.env << EOF
# Database Configuration
DB_HOST=${postgres_endpoint}
DB_PORT=${postgres_port}
DB_NAME=${postgres_database}
DB_USERNAME=${postgres_username}
DB_PASSWORD=${postgres_password}

# Redis Configuration
REDIS_HOST=${redis_endpoint}
REDIS_PORT=${redis_port}

# Application Configuration
APP_VERSION=${app_version}
SPRING_PROFILES_ACTIVE=aws
REACT_APP_API_URL=http://localhost:8080/api

# AWS Configuration
AWS_REGION=us-east-1
EOF

# Set proper permissions
chown -R ec2-user:ec2-user /opt/app
chmod 600 /opt/app/config/.env

# Install PostgreSQL client for testing
yum install -y postgresql15

# Create systemd service for application
cat > /etc/systemd/system/fullstack-app.service << EOF
[Unit]
Description=Full Stack Application
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=true
WorkingDirectory=/opt/app
EnvironmentFile=/opt/app/config/.env
ExecStart=/usr/local/bin/docker-compose up -d
ExecStop=/usr/local/bin/docker-compose down
User=ec2-user
Group=ec2-user

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable fullstack-app.service

# Create docker-compose.yml for the application
cat > /opt/app/docker-compose.yml << EOF
version: '3.8'
services:
  backend:
    image: \$${BACKEND_IMAGE:-openjdk:17-jre-slim}
    container_name: backend
    ports:
      - "8080:8080"
    environment:
      - SPRING_PROFILES_ACTIVE=\$${SPRING_PROFILES_ACTIVE}
      - DB_HOST=\$${DB_HOST}
      - DB_PORT=\$${DB_PORT}
      - DB_NAME=\$${DB_NAME}
      - DB_USERNAME=\$${DB_USERNAME}
      - DB_PASSWORD=\$${DB_PASSWORD}
      - REDIS_HOST=\$${REDIS_HOST}
      - REDIS_PORT=\$${REDIS_PORT}
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/actuator/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    restart: unless-stopped

  frontend:
    image: \$${FRONTEND_IMAGE:-nginx:alpine}
    container_name: frontend
    ports:
      - "3000:80"
    environment:
      - REACT_APP_API_URL=\$${REACT_APP_API_URL}
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:80"]
      interval: 30s
      timeout: 10s
      retries: 3
    restart: unless-stopped
EOF

chown ec2-user:ec2-user /opt/app/docker-compose.yml

# Install and configure CloudWatch agent
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << EOF
{
    "agent": {
        "metrics_collection_interval": 60,
        "run_as_user": "root"
    },
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {
                        "file_path": "/opt/app/logs/application.log",
                        "log_group_name": "/aws/ec2/fullstack-app",
                        "log_stream_name": "{instance_id}/application.log"
                    }
                ]
            }
        }
    },
    "metrics": {
        "namespace": "AWS/EC2/FullStackApp",
        "metrics_collected": {
            "cpu": {
                "measurement": [
                    "cpu_usage_idle",
                    "cpu_usage_iowait",
                    "cpu_usage_user",
                    "cpu_usage_system"
                ],
                "metrics_collection_interval": 60
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
            "mem": {
                "measurement": [
                    "mem_used_percent"
                ],
                "metrics_collection_interval": 60
            }
        }
    }
}
EOF

# Start CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s
cat > app-startup.sh << 'EOF'
#!/bin/bash
# Placeholder for application startup
# This would typically:
# 1. Pull Docker image from ECR
# 2. Or download JAR from S3/Nexus/Artifactory
# 3. Start the application with proper configuration

echo "Starting application version: ${app_version}"
echo "Application will be available on port 8080"

# For demo purposes, create a simple health check endpoint
mkdir -p /tmp/app
echo '{"status": "healthy", "version": "${app_version}"}' > /tmp/app/health.json

# Start a simple HTTP server for testing (replace with actual app)
python3 -m http.server 8080 --directory /tmp/app &
EOF

chmod +x app-startup.sh

# Setup systemd service for the application
cat > /etc/systemd/system/app.service << 'EOF'
[Unit]
Description=3-Tier Demo Application
After=network.target

[Service]
Type=forking
User=ec2-user
ExecStart=/opt/app/app-startup.sh
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the application service
systemctl daemon-reload
systemctl enable app.service
systemctl start app.service

# Install CloudWatch agent (for monitoring)
yum install -y amazon-cloudwatch-agent

# Setup log rotation
cat > /etc/logrotate.d/app << 'EOF'
/var/log/app/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    create 644 ec2-user ec2-user
}
EOF

echo "User data script completed successfully" > /tmp/user-data.log