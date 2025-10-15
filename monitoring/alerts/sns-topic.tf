# SNS Topics for Grafana and CloudWatch Alerts
resource "aws_sns_topic" "alert_notifications_critical" {
  name = "grafana-alerts-critical"
  
  tags = {
    Name        = "Grafana Critical Alerts"
    Environment = var.environment
    Project     = "java-microservice"
    Team        = "devops"
  }
}

resource "aws_sns_topic" "alert_notifications_warning" {
  name = "grafana-alerts-warning"
  
  tags = {
    Name        = "Grafana Warning Alerts"
    Environment = var.environment
    Project     = "java-microservice"
    Team        = "devops"
  }
}

resource "aws_sns_topic" "cloudwatch_alerts" {
  name = "cloudwatch-alerts"
  
  tags = {
    Name        = "CloudWatch Infrastructure Alerts"
    Environment = var.environment
    Project     = "java-microservice"
    Team        = "devops"
  }
}

# Email Subscriptions for DevOps Team
resource "aws_sns_topic_subscription" "devops_team_critical_email" {
  topic_arn = aws_sns_topic.alert_notifications_critical.arn
  protocol  = "email"
  endpoint  = var.devops_team_email
}

resource "aws_sns_topic_subscription" "devops_team_warning_email" {
  topic_arn = aws_sns_topic.alert_notifications_warning.arn
  protocol  = "email"
  endpoint  = var.devops_team_email
}

resource "aws_sns_topic_subscription" "devops_team_cloudwatch_email" {
  topic_arn = aws_sns_topic.cloudwatch_alerts.arn
  protocol  = "email"
  endpoint  = var.devops_team_email
}

# Slack Integration (Optional)
resource "aws_sns_topic_subscription" "slack_critical_webhook" {
  count     = var.slack_webhook_url != "" ? 1 : 0
  topic_arn = aws_sns_topic.alert_notifications_critical.arn
  protocol  = "https"
  endpoint  = var.slack_webhook_url
}

resource "aws_sns_topic_subscription" "slack_warning_webhook" {
  count     = var.slack_webhook_url != "" ? 1 : 0
  topic_arn = aws_sns_topic.alert_notifications_warning.arn
  protocol  = "https"
  endpoint  = var.slack_webhook_url
}

# PagerDuty Integration for Critical Alerts
resource "aws_sns_topic_subscription" "pagerduty_critical" {
  count     = var.pagerduty_endpoint != "" ? 1 : 0
  topic_arn = aws_sns_topic.alert_notifications_critical.arn
  protocol  = "https"
  endpoint  = var.pagerduty_endpoint
}

# SMS Notifications for Critical Alerts (On-Call)
resource "aws_sns_topic_subscription" "oncall_sms_critical" {
  count     = var.oncall_phone_number != "" ? 1 : 0
  topic_arn = aws_sns_topic.alert_notifications_critical.arn
  protocol  = "sms"
  endpoint  = var.oncall_phone_number
}

# CloudWatch Alarms for Infrastructure Monitoring
resource "aws_cloudwatch_metric_alarm" "high_cpu_utilization" {
  alarm_name          = "java-microservice-high-cpu-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ec2 cpu utilization"
  alarm_actions       = [aws_sns_topic.cloudwatch_alerts.arn]

  dimensions = {
    AutoScalingGroupName = var.asg_name
  }

  tags = {
    Name        = "High CPU Utilization"
    Environment = var.environment
    Project     = "java-microservice"
  }
}

resource "aws_cloudwatch_metric_alarm" "high_memory_utilization" {
  alarm_name          = "java-microservice-high-memory-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "MEM_USED_PERCENT"
  namespace           = "DevOps/JavaMicroservice"
  period              = "300"
  statistic           = "Average"
  threshold           = "85"
  alarm_description   = "This metric monitors memory utilization"
  alarm_actions       = [aws_sns_topic.cloudwatch_alerts.arn]

  dimensions = {
    AutoScalingGroupName = var.asg_name
  }

  tags = {
    Name        = "High Memory Utilization"
    Environment = var.environment
    Project     = "java-microservice"
  }
}

resource "aws_cloudwatch_metric_alarm" "disk_space_utilization" {
  alarm_name          = "java-microservice-disk-space-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "DISK_USED_PERCENT"
  namespace           = "DevOps/JavaMicroservice"
  period              = "300"
  statistic           = "Average"
  threshold           = "85"
  alarm_description   = "This metric monitors disk space utilization"
  alarm_actions       = [aws_sns_topic.cloudwatch_alerts.arn]

  dimensions = {
    AutoScalingGroupName = var.asg_name
  }

  tags = {
    Name        = "High Disk Utilization"
    Environment = var.environment
    Project     = "java-microservice"
  }
}

# ELB/ALB Target Health Alarms
resource "aws_cloudwatch_metric_alarm" "unhealthy_targets" {
  count               = var.target_group_arn != "" ? 1 : 0
  alarm_name          = "java-microservice-unhealthy-targets-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Average"
  threshold           = "0"
  alarm_description   = "This metric monitors unhealthy targets"
  alarm_actions       = [aws_sns_topic.alert_notifications_critical.arn]

  dimensions = {
    TargetGroup = var.target_group_arn
  }

  tags = {
    Name        = "Unhealthy Targets"
    Environment = var.environment
    Project     = "java-microservice"
  }
}

resource "aws_cloudwatch_metric_alarm" "high_response_time" {
  count               = var.target_group_arn != "" ? 1 : 0
  alarm_name          = "java-microservice-high-response-time-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Average"
  threshold           = "1"
  alarm_description   = "This metric monitors response time"
  alarm_actions       = [aws_sns_topic.alert_notifications_warning.arn]

  dimensions = {
    TargetGroup = var.target_group_arn
  }

  tags = {
    Name        = "High Response Time"
    Environment = var.environment
    Project     = "java-microservice"
  }
}

# RDS Database Alarms (if applicable)
resource "aws_cloudwatch_metric_alarm" "rds_cpu_utilization" {
  count               = var.rds_instance_id != "" ? 1 : 0
  alarm_name          = "java-microservice-rds-cpu-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors RDS CPU utilization"
  alarm_actions       = [aws_sns_topic.alert_notifications_warning.arn]

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_id
  }

  tags = {
    Name        = "RDS High CPU"
    Environment = var.environment
    Project     = "java-microservice"
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_connection_count" {
  count               = var.rds_instance_id != "" ? 1 : 0
  alarm_name          = "java-microservice-rds-connections-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "40"
  alarm_description   = "This metric monitors RDS connection count"
  alarm_actions       = [aws_sns_topic.alert_notifications_warning.arn]

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_id
  }

  tags = {
    Name        = "RDS High Connections"
    Environment = var.environment
    Project     = "java-microservice"
  }
}

# Lambda for Slack Formatting (Optional)
resource "aws_lambda_function" "slack_formatter" {
  count            = var.create_slack_formatter ? 1 : 0
  filename         = "slack_formatter.zip"
  function_name    = "grafana-slack-formatter-${var.environment}"
  role            = aws_iam_role.lambda_role[0].arn
  handler         = "index.handler"
  source_code_hash = data.archive_file.lambda_zip[0].output_base64sha256
  runtime         = "python3.9"
  timeout         = 30

  environment {
    variables = {
      SLACK_WEBHOOK_URL = var.slack_webhook_url
    }
  }

  tags = {
    Name        = "Slack Alert Formatter"
    Environment = var.environment
    Project     = "java-microservice"
  }
}

data "archive_file" "lambda_zip" {
  count       = var.create_slack_formatter ? 1 : 0
  type        = "zip"
  output_path = "slack_formatter.zip"
  source {
    content = templatefile("${path.module}/slack_formatter.py", {
      webhook_url = var.slack_webhook_url
    })
    filename = "index.py"
  }
}

resource "aws_iam_role" "lambda_role" {
  count = var.create_slack_formatter ? 1 : 0
  name  = "grafana-slack-formatter-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  count      = var.create_slack_formatter ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_role[0].name
}

# Outputs
output "sns_topic_critical_arn" {
  description = "ARN of the critical alerts SNS topic"
  value       = aws_sns_topic.alert_notifications_critical.arn
}

output "sns_topic_warning_arn" {
  description = "ARN of the warning alerts SNS topic"
  value       = aws_sns_topic.alert_notifications_warning.arn
}

output "sns_topic_cloudwatch_arn" {
  description = "ARN of the CloudWatch alerts SNS topic"
  value       = aws_sns_topic.cloudwatch_alerts.arn
}

# Variables
variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "devops_team_email" {
  description = "DevOps team email for alert notifications"
  type        = string
  default     = "devops-team@example.com"
}

variable "slack_webhook_url" {
  description = "Slack webhook URL for notifications"
  type        = string
  default     = ""
}

variable "pagerduty_endpoint" {
  description = "PagerDuty integration endpoint"
  type        = string
  default     = ""
}

variable "oncall_phone_number" {
  description = "On-call phone number for critical SMS alerts"
  type        = string
  default     = ""
}

variable "asg_name" {
  description = "Auto Scaling Group name"
  type        = string
  default     = "java-microservice-asg"
}

variable "target_group_arn" {
  description = "ALB Target Group ARN"
  type        = string
  default     = ""
}

variable "rds_instance_id" {
  description = "RDS instance identifier"
  type        = string
  default     = ""
}

variable "create_slack_formatter" {
  description = "Whether to create Slack formatter Lambda"
  type        = bool
  default     = false
}