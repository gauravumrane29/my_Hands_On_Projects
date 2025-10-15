output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_app_subnet_ids" {
  description = "IDs of the private application subnets"
  value       = aws_subnet.private_app[*].id
}

output "private_db_subnet_ids" {
  description = "IDs of the private database subnets"
  value       = aws_subnet.private_db[*].id
}

output "app_server_private_ip" {
  description = "Private IP address of the application server"
  value       = aws_instance.app_server.private_ip
}

output "app_server_ip" {
  description = "Public IP address of the application server"
  value       = aws_instance.app_server.public_ip
}

output "load_balancer_dns" {
  description = "DNS name of the load balancer"
  value       = aws_lb.app_lb.dns_name
}

output "load_balancer_url" {
  description = "URL to access the application"
  value       = "http://${aws_lb.app_lb.dns_name}"
}

output "web_tier_security_group_id" {
  description = "ID of the web tier security group"
  value       = aws_security_group.web_tier.id
}

output "app_tier_security_group_id" {
  description = "ID of the application tier security group"
  value       = aws_security_group.app_tier.id
}

output "db_tier_security_group_id" {
  description = "ID of the database tier security group"
  value       = aws_security_group.db_sg.id
}

output "postgres_endpoint" {
  description = "PostgreSQL RDS instance endpoint"
  value       = aws_db_instance.postgres_db.endpoint
  sensitive   = true
}

output "postgres_port" {
  description = "PostgreSQL RDS instance port"
  value       = aws_db_instance.postgres_db.port
}

output "postgres_database_name" {
  description = "PostgreSQL database name"
  value       = aws_db_instance.postgres_db.db_name
}

output "postgres_username" {
  description = "PostgreSQL database username"
  value       = aws_db_instance.postgres_db.username
  sensitive   = true
}

output "redis_endpoint" {
  description = "Redis cluster endpoint"
  value       = aws_elasticache_replication_group.redis.configuration_endpoint_address
  sensitive   = true
}

output "redis_port" {
  description = "Redis cluster port"
  value       = aws_elasticache_replication_group.redis.port
}

output "backend_target_group_arn" {
  description = "Backend target group ARN"
  value       = aws_lb_target_group.backend_tg.arn
}

output "frontend_target_group_arn" {
  description = "Frontend target group ARN"
  value       = aws_lb_target_group.frontend_tg.arn
}

output "redis_security_group_id" {
  description = "ID of the Redis security group"
  value       = aws_security_group.redis_sg.id
}

# Database connection strings for application configuration
output "database_connection_string" {
  description = "PostgreSQL connection string for application"
  value       = "postgresql://${aws_db_instance.postgres_db.username}:${var.db_password}@${aws_db_instance.postgres_db.endpoint}:${aws_db_instance.postgres_db.port}/${aws_db_instance.postgres_db.db_name}"
  sensitive   = true
}

output "redis_connection_string" {
  description = "Redis connection string for application"
  value       = "${aws_elasticache_replication_group.redis.configuration_endpoint_address}:${aws_elasticache_replication_group.redis.port}"
  sensitive   = true
}

output "nat_gateway_id" {
  description = "ID of the NAT Gateway"
  value       = aws_nat_gateway.main.id
}

output "nat_gateway_ip" {
  description = "Public IP of the NAT Gateway"
  value       = aws_eip.nat.public_ip
}

output "iam_role_arn" {
  description = "ARN of the IAM role for EC2 instances"
  value       = aws_iam_role.ec2_role.arn
}

output "launch_template_id" {
  description = "ID of the launch template"
  value       = aws_launch_template.app_template.id
}

output "environment_variables" {
  description = "Environment variables for application configuration"
  value = {
    DB_HOST     = aws_db_instance.postgres_db.endpoint
    DB_PORT     = aws_db_instance.postgres_db.port
    DB_NAME     = aws_db_instance.postgres_db.db_name
    DB_USERNAME = aws_db_instance.postgres_db.username
    REDIS_HOST  = aws_elasticache_replication_group.redis.configuration_endpoint_address
    REDIS_PORT  = aws_elasticache_replication_group.redis.port
  }
  sensitive = true
}