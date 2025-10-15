# Get the latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Create VPC for 3-tier architecture
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "3-tier-vpc"
    Environment = var.environment
    Project     = "DevOps-Demo"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "3-tier-igw"
    Environment = var.environment
  }
}

# Public Subnets (Web Tier)
resource "aws_subnet" "public" {
  count = 2

  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.${count.index + 1}.0/24"
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name        = "public-subnet-${count.index + 1}"
    Environment = var.environment
    Tier        = "Web"
  }
}

# Private Subnets (Application Tier)
resource "aws_subnet" "private_app" {
  count = 2

  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 10}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name        = "private-app-subnet-${count.index + 1}"
    Environment = var.environment
    Tier        = "Application"
  }
}

# Private Subnets (Database Tier)
resource "aws_subnet" "private_db" {
  count = 2

  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 20}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name        = "private-db-subnet-${count.index + 1}"
    Environment = var.environment
    Tier        = "Database"
  }
}

# Route Table for Public Subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "public-rt"
    Environment = var.environment
  }
}

# Associate Public Subnets with Public Route Table
resource "aws_route_table_association" "public" {
  count = 2

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name        = "nat-eip"
    Environment = var.environment
  }

  depends_on = [aws_internet_gateway.main]
}

# NAT Gateway for private subnets
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name        = "main-nat-gateway"
    Environment = var.environment
  }

  depends_on = [aws_internet_gateway.main]
}

# Route Table for Private Subnets
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name        = "private-rt"
    Environment = var.environment
  }
}

# Associate Private App Subnets with Private Route Table
resource "aws_route_table_association" "private_app" {
  count = 2

  subnet_id      = aws_subnet.private_app[count.index].id
  route_table_id = aws_route_table.private.id
}

# Associate Private DB Subnets with Private Route Table
resource "aws_route_table_association" "private_db" {
  count = 2

  subnet_id      = aws_subnet.private_db[count.index].id
  route_table_id = aws_route_table.private.id
}

# Security Group for Web Tier (Load Balancer)
resource "aws_security_group" "web_tier" {
  name_prefix = "web-tier-"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "web-tier-sg"
    Environment = var.environment
  }
}

# Security Group for Application Tier
resource "aws_security_group" "app_tier" {
  name_prefix = "app-tier-"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.web_tier.id]
    description     = "Backend API access from web tier"
  }

  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.web_tier.id]
    description     = "Frontend access from web tier"
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
    description = "SSH access from VPC"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "app-tier-sg"
    Environment = var.environment
  }
}

# Security Group for Database Tier (PostgreSQL)
resource "aws_security_group" "db_sg" {
  name_prefix = "db-tier-"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app_tier.id]
  }

  tags = {
    Name        = "db-tier-sg"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Security Group for Redis Cache
resource "aws_security_group" "redis_sg" {
  name_prefix = "redis-tier-"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.app_tier.id]
  }

  tags = {
    Name        = "redis-tier-sg"
    Environment = var.environment
    Project     = var.project_name
  }
}

# IAM Role for EC2 instances
resource "aws_iam_role" "ec2_role" {
  name = "${var.project_name}-${var.environment}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-ec2-role"
    Environment = var.environment
  }
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-${var.environment}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

# IAM Policy for CloudWatch and SSM access
resource "aws_iam_role_policy" "ec2_policy" {
  name = "${var.project_name}-${var.environment}-ec2-policy"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:*",
          "logs:*",
          "ssm:*"
        ]
        Resource = "*"
      }
    ]
  })
}

# Application Server Instance
resource "aws_instance" "app_server" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private_app[0].id
  vpc_security_group_ids = [aws_security_group.app_tier.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    app_version           = var.app_version
    postgres_endpoint     = aws_db_instance.postgres_db.endpoint
    postgres_port         = aws_db_instance.postgres_db.port
    postgres_database     = aws_db_instance.postgres_db.db_name
    postgres_username     = aws_db_instance.postgres_db.username
    postgres_password     = var.db_password
    redis_endpoint        = aws_elasticache_replication_group.redis.configuration_endpoint_address
    redis_port            = aws_elasticache_replication_group.redis.port
  }))

  tags = {
    Name        = "app-server"
    Environment = var.environment
    Tier        = "Application"
  }

  depends_on = [
    aws_db_instance.postgres_db,
    aws_elasticache_replication_group.redis
  ]
}

# Launch Template for Auto Scaling (for future scaling)
resource "aws_launch_template" "app_template" {
  name_prefix   = "${var.project_name}-${var.environment}-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.app_tier.id]
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    app_version           = var.app_version
    postgres_endpoint     = aws_db_instance.postgres_db.endpoint
    postgres_port         = aws_db_instance.postgres_db.port
    postgres_database     = aws_db_instance.postgres_db.db_name
    postgres_username     = aws_db_instance.postgres_db.username
    postgres_password     = var.db_password
    redis_endpoint        = aws_elasticache_replication_group.redis.configuration_endpoint_address
    redis_port            = aws_elasticache_replication_group.redis.port
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "${var.project_name}-${var.environment}-app-server"
      Environment = var.environment
      Tier        = "Application"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Application Load Balancer
resource "aws_lb" "app_lb" {
  name               = "app-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web_tier.id]
  subnets            = aws_subnet.public[*].id

  tags = {
    Name        = "app-lb"
    Environment = var.environment
  }
}

# Target Group for Backend API
resource "aws_lb_target_group" "backend_tg" {
  name     = "backend-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/actuator/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 3
  }

  tags = {
    Name        = "backend-tg"
    Environment = var.environment
  }
}

# Target Group for Frontend
resource "aws_lb_target_group" "frontend_tg" {
  name     = "frontend-tg"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 3
  }

  tags = {
    Name        = "frontend-tg"
    Environment = var.environment
  }
}

# Load Balancer Listener with path-based routing
resource "aws_lb_listener" "app_listener" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "forward"

    forward {
      target_group {
        arn = aws_lb_target_group.frontend_tg.arn
      }
    }
  }
}

# Backend API Listener Rule
resource "aws_lb_listener_rule" "backend_rule" {
  listener_arn = aws_lb_listener.app_listener.arn
  priority     = 100

  action {
    type = "forward"

    forward {
      target_group {
        arn = aws_lb_target_group.backend_tg.arn
      }
    }
  }

  condition {
    path_pattern {
      values = ["/api/*", "/actuator/*"]
    }
  }
}

# Attach Backend Instance to Target Group
resource "aws_lb_target_group_attachment" "backend_tg_attachment" {
  target_group_arn = aws_lb_target_group.backend_tg.id
  target_id        = aws_instance.app_server.id
  port             = 8080
}

# Attach Frontend Instance to Target Group
resource "aws_lb_target_group_attachment" "frontend_tg_attachment" {
  target_group_arn = aws_lb_target_group.frontend_tg.id
  target_id        = aws_instance.app_server.id
  port             = 3000
}

# Get available AZs
data "aws_availability_zones" "available" {
  state = "available"
}

# DB Subnet Group for RDS
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "${var.project_name}-${var.environment}-db-subnet-group"
  subnet_ids = aws_subnet.private_db[*].id

  tags = {
    Name        = "${var.project_name}-${var.environment}-db-subnet-group"
    Environment = var.environment
    Project     = var.project_name
  }
}

# RDS PostgreSQL Database Instance
resource "aws_db_instance" "postgres_db" {
  allocated_storage       = var.db_allocated_storage
  storage_type            = "gp3"
  storage_encrypted       = true
  engine                  = var.db_engine
  engine_version          = var.db_engine_version
  instance_class          = var.db_instance_class
  identifier              = "${var.project_name}-${var.environment}-postgres"
  db_name                 = var.db_name
  username                = var.db_username
  password                = var.db_password
  parameter_group_name    = "default.postgres15"
  db_subnet_group_name    = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids  = [aws_security_group.db_sg.id]
  backup_retention_period = 7
  backup_window           = "07:00-09:00"
  maintenance_window      = "sun:09:00-sun:11:00"
  skip_final_snapshot     = true
  deletion_protection     = false
  multi_az                = var.environment == "prod" ? true : false
  performance_insights_enabled = var.environment == "prod" ? true : false
  monitoring_interval     = var.environment == "prod" ? 60 : 0
  
  tags = {
    Name        = "${var.project_name}-${var.environment}-postgres"
    Environment = var.environment
    Project     = var.project_name
    Tier        = "Database"
  }
}

# Redis Subnet Group
resource "aws_elasticache_subnet_group" "redis_subnet_group" {
  name       = "${var.project_name}-${var.environment}-redis-subnet-group"
  subnet_ids = aws_subnet.private_db[*].id

  tags = {
    Name        = "${var.project_name}-${var.environment}-redis-subnet-group"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Redis Cluster
resource "aws_elasticache_replication_group" "redis" {
  replication_group_id         = "${var.project_name}-${var.environment}-redis"
  description                  = "Redis cluster for ${var.project_name} ${var.environment}"
  
  node_type                    = var.redis_node_type
  port                         = 6379
  parameter_group_name         = "default.redis7"
  
  num_cache_clusters           = var.redis_num_cache_nodes
  
  subnet_group_name            = aws_elasticache_subnet_group.redis_subnet_group.name
  security_group_ids           = [aws_security_group.redis_sg.id]
  
  at_rest_encryption_enabled   = true
  transit_encryption_enabled   = true
  
  automatic_failover_enabled   = var.redis_num_cache_nodes > 1 ? true : false
  multi_az_enabled             = var.redis_num_cache_nodes > 1 ? true : false
  
  maintenance_window           = "sun:05:00-sun:07:00"
  snapshot_retention_limit     = 3
  snapshot_window              = "03:00-05:00"
  
  apply_immediately            = true
  
  tags = {
    Name        = "${var.project_name}-${var.environment}-redis"
    Environment = var.environment
    Project     = var.project_name
    Tier        = "Cache"
  }
}