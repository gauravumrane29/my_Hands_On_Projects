# CloudWatch Log Groups for Java Microservice
resource "aws_cloudwatch_log_group" "application_logs" {
  name              = "/aws/ec2/java-microservice/application"
  retention_in_days = 30

  tags = {
    Name        = "Java Microservice Application Logs"
    Environment = var.environment
    Project     = "java-microservice"
    Team        = "devops"
  }
}

resource "aws_cloudwatch_log_group" "system_logs" {
  name              = "/aws/ec2/java-microservice/system"
  retention_in_days = 14

  tags = {
    Name        = "Java Microservice System Logs"
    Environment = var.environment
    Project     = "java-microservice"
    Team        = "devops"
  }
}

resource "aws_cloudwatch_log_group" "cloud_init_logs" {
  name              = "/aws/ec2/java-microservice/cloud-init"
  retention_in_days = 7

  tags = {
    Name        = "Java Microservice Cloud Init Logs"
    Environment = var.environment
    Project     = "java-microservice"
    Team        = "devops"
  }
}

resource "aws_cloudwatch_log_group" "docker_logs" {
  name              = "/aws/ec2/java-microservice/docker"
  retention_in_days = 14

  tags = {
    Name        = "Java Microservice Docker Logs"
    Environment = var.environment
    Project     = "java-microservice"
    Team        = "devops"
  }
}

# EKS Container Insights
resource "aws_cloudwatch_log_group" "eks_cluster_logs" {
  name              = "/aws/eks/java-microservice-eks/cluster"
  retention_in_days = 7

  tags = {
    Name        = "EKS Cluster Control Plane Logs"
    Environment = var.environment
    Project     = "java-microservice"
    Team        = "devops"
  }
}

resource "aws_cloudwatch_log_group" "container_insights_application" {
  name              = "/aws/containerinsights/java-microservice-eks/application"
  retention_in_days = 30

  tags = {
    Name        = "Container Insights Application Logs"
    Environment = var.environment
    Project     = "java-microservice"
    Team        = "devops"
  }
}

resource "aws_cloudwatch_log_group" "container_insights_dataplane" {
  name              = "/aws/containerinsights/java-microservice-eks/dataplane"
  retention_in_days = 7

  tags = {
    Name        = "Container Insights Data Plane Logs"
    Environment = var.environment
    Project     = "java-microservice"
    Team        = "devops"
  }
}

resource "aws_cloudwatch_log_group" "container_insights_host" {
  name              = "/aws/containerinsights/java-microservice-eks/host"
  retention_in_days = 7

  tags = {
    Name        = "Container Insights Host Logs"
    Environment = var.environment
    Project     = "java-microservice"
    Team        = "devops"
  }
}

resource "aws_cloudwatch_log_group" "container_insights_performance" {
  name              = "/aws/containerinsights/java-microservice-eks/performance"
  retention_in_days = 14

  tags = {
    Name        = "Container Insights Performance Logs"
    Environment = var.environment
    Project     = "java-microservice"
    Team        = "devops"
  }
}

# Log Metric Filters
resource "aws_cloudwatch_log_metric_filter" "error_count" {
  name           = "java-microservice-error-count"
  log_group_name = aws_cloudwatch_log_group.application_logs.name
  pattern        = "[timestamp, requestId, level=\"ERROR\", ...]"

  metric_transformation {
    name      = "ErrorCount"
    namespace = "JavaMicroservice/Logs"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "warning_count" {
  name           = "java-microservice-warning-count"
  log_group_name = aws_cloudwatch_log_group.application_logs.name
  pattern        = "[timestamp, requestId, level=\"WARN\", ...]"

  metric_transformation {
    name      = "WarningCount"
    namespace = "JavaMicroservice/Logs"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "exception_count" {
  name           = "java-microservice-exception-count"
  log_group_name = aws_cloudwatch_log_group.application_logs.name
  pattern        = "Exception"

  metric_transformation {
    name      = "ExceptionCount"
    namespace = "JavaMicroservice/Logs"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "outofmemory_count" {
  name           = "java-microservice-oom-count"
  log_group_name = aws_cloudwatch_log_group.application_logs.name
  pattern        = "OutOfMemoryError"

  metric_transformation {
    name      = "OutOfMemoryCount"
    namespace = "JavaMicroservice/Logs"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "gc_count" {
  name           = "java-microservice-gc-count"
  log_group_name = aws_cloudwatch_log_group.application_logs.name
  pattern        = "[..., message=\"*GC*\", ...]"

  metric_transformation {
    name      = "GCCount"
    namespace = "JavaMicroservice/Logs"
    value     = "1"
  }
}

# CloudWatch Alarms based on Log Metrics
resource "aws_cloudwatch_metric_alarm" "high_error_rate" {
  alarm_name          = "java-microservice-high-error-rate-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ErrorCount"
  namespace           = "JavaMicroservice/Logs"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "This metric monitors error log entries"
  alarm_actions       = [var.sns_topic_critical_arn]
  treat_missing_data  = "notBreaching"

  tags = {
    Name        = "High Error Rate from Logs"
    Environment = var.environment
    Project     = "java-microservice"
  }
}

resource "aws_cloudwatch_metric_alarm" "oom_detected" {
  alarm_name          = "java-microservice-oom-detected-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "OutOfMemoryCount"
  namespace           = "JavaMicroservice/Logs"
  period              = "60"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "This metric detects OutOfMemoryError in logs"
  alarm_actions       = [var.sns_topic_critical_arn]
  treat_missing_data  = "notBreaching"

  tags = {
    Name        = "OutOfMemory Detected"
    Environment = var.environment
    Project     = "java-microservice"
  }
}

# CloudWatch Insights Queries (saved as CloudFormation since TF doesn't support)
resource "aws_cloudformation_stack" "cloudwatch_insights_queries" {
  name = "java-microservice-insights-queries-${var.environment}"

  template_body = jsonencode({
    AWSTemplateFormatVersion = "2010-09-09"
    Description = "CloudWatch Insights Saved Queries for Java Microservice"
    
    Resources = {
      ErrorAnalysisQuery = {
        Type = "AWS::Logs::QueryDefinition"
        Properties = {
          Name = "Java Microservice - Error Analysis"
          LogGroupNames = [
            aws_cloudwatch_log_group.application_logs.name
          ]
          QueryString = join("\n", [
            "fields @timestamp, @message",
            "| filter @message like /ERROR/",
            "| sort @timestamp desc",
            "| limit 100"
          ])
        }
      }
      
      PerformanceAnalysisQuery = {
        Type = "AWS::Logs::QueryDefinition"
        Properties = {
          Name = "Java Microservice - Performance Analysis"
          LogGroupNames = [
            aws_cloudwatch_log_group.application_logs.name
          ]
          QueryString = join("\n", [
            "fields @timestamp, @message",
            "| filter @message like /duration/ or @message like /response_time/",
            "| parse @message /duration=(?<duration>\\d+)/",
            "| stats avg(duration), max(duration), min(duration) by bin(5m)"
          ])
        }
      }
      
      GCAnalysisQuery = {
        Type = "AWS::Logs::QueryDefinition"
        Properties = {
          Name = "Java Microservice - GC Analysis"
          LogGroupNames = [
            aws_cloudwatch_log_group.application_logs.name
          ]
          QueryString = join("\n", [
            "fields @timestamp, @message",
            "| filter @message like /GC/",
            "| parse @message /GC\\s+\\((?<gc_type>\\w+)\\).*?(?<duration>\\d+\\.\\d+)ms/",
            "| stats count(), avg(duration), max(duration) by gc_type, bin(5m)"
          ])
        }
      }
      
      ExceptionAnalysisQuery = {
        Type = "AWS::Logs::QueryDefinition"
        Properties = {
          Name = "Java Microservice - Exception Analysis"  
          LogGroupNames = [
            aws_cloudwatch_log_group.application_logs.name
          ]
          QueryString = join("\n", [
            "fields @timestamp, @message",
            "| filter @message like /Exception/ or @message like /Error/",
            "| parse @message /(?<exception>\\w+Exception)/",
            "| stats count() by exception, bin(1h)",
            "| sort count desc"
          ])
        }
      }
    }
  })

  tags = {
    Name        = "CloudWatch Insights Queries"
    Environment = var.environment
    Project     = "java-microservice"
  }
}

# CloudWatch Dashboard for Logs
resource "aws_cloudwatch_dashboard" "logs_dashboard" {
  dashboard_name = "java-microservice-logs-${var.environment}"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "log"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          query   = "SOURCE '${aws_cloudwatch_log_group.application_logs.name}' | fields @timestamp, @message | filter @message like /ERROR/ | sort @timestamp desc | limit 20"
          region  = var.aws_region
          title   = "Recent Errors"
          view    = "table"
        }
      }
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["JavaMicroservice/Logs", "ErrorCount"],
            [".", "WarningCount"],
            [".", "ExceptionCount"]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "Log-based Metrics"
          yAxis = {
            left = {
              min = 0
            }
          }
        }
      }
      {
        type   = "log"
        x      = 0
        y      = 6
        width  = 24
        height = 6
        properties = {
          query   = "SOURCE '${aws_cloudwatch_log_group.application_logs.name}' | fields @timestamp, @message | filter @message like /GC/ | sort @timestamp desc | limit 20"
          region  = var.aws_region
          title   = "Garbage Collection Events"
          view    = "table"
        }
      }
    ]
  })
}

# Log Streams for different environments
resource "aws_cloudwatch_log_stream" "application_dev" {
  count          = var.environment == "development" ? 1 : 0
  name           = "dev-application-stream"
  log_group_name = aws_cloudwatch_log_group.application_logs.name
}

resource "aws_cloudwatch_log_stream" "application_staging" {
  count          = var.environment == "staging" ? 1 : 0
  name           = "staging-application-stream"
  log_group_name = aws_cloudwatch_log_group.application_logs.name
}

resource "aws_cloudwatch_log_stream" "application_prod" {
  count          = var.environment == "production" ? 1 : 0
  name           = "prod-application-stream"
  log_group_name = aws_cloudwatch_log_group.application_logs.name
}

# Outputs
output "application_log_group_name" {
  description = "Name of the application log group"
  value       = aws_cloudwatch_log_group.application_logs.name
}

output "application_log_group_arn" {
  description = "ARN of the application log group"
  value       = aws_cloudwatch_log_group.application_logs.arn
}

output "container_insights_log_group_name" {
  description = "Name of the Container Insights application log group"
  value       = aws_cloudwatch_log_group.container_insights_application.name
}

# Variables
variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "sns_topic_critical_arn" {
  description = "ARN of the critical alerts SNS topic"
  type        = string
}