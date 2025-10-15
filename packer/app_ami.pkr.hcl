packer {
  required_version = ">= 1.8.0"
  
  required_plugins {
    amazon = {
      version = ">= 1.2.8"
      source  = "github.com/hashicorp/amazon"
    }
    ansible = {
      version = ">= 1.1.0"
      source  = "github.com/hashicorp/ansible"
    }
  }
}

# Variables
variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "app_version" {
  description = "Application version"
  type        = string
  default     = "latest"
}

variable "instance_type" {
  description = "Instance type for building AMI"
  type        = string
  default     = "t2.micro"
}

# Local values
locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
  ami_name  = "java-app-${var.environment}-${local.timestamp}"
}

# Data source for base AMI
data "amazon-ami" "amazon_linux" {
  filters = {
    virtualization-type = "hvm"
    name                = "amzn2-ami-hvm-*-x86_64-gp2"
    root-device-type    = "ebs"
  }
  owners      = ["amazon"]
  most_recent = true
  region      = var.region
}

# Build configuration
source "amazon-ebs" "java_app" {
  ami_name                    = local.ami_name
  ami_description            = "Custom AMI with Java 17, Docker, and application dependencies for ${var.environment}"
  instance_type              = var.instance_type
  region                     = var.region
  source_ami                 = data.amazon-ami.amazon_linux.id
  ssh_username               = "ec2-user"
  associate_public_ip_address = true
  
  # Storage configuration
  ebs_optimized = false
  
  launch_block_device_mappings {
    device_name           = "/dev/xvda"
    volume_size           = 20
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = false
  }
  
  # Tags for the AMI
  tags = {
    Name         = local.ami_name
    Environment  = var.environment
    Project      = "3-tier-devops"
    CreatedBy    = "Packer"
    BaseAMI      = data.amazon-ami.amazon_linux.id
    BuildDate    = timestamp()
    AppVersion   = var.app_version
    OS           = "Amazon Linux 2"
    Architecture = "x86_64"
  }
  
  # Tags for the builder instance
  run_tags = {
    Name = "Packer-Builder-${local.ami_name}"
    Type = "TemporaryPackerInstance"
  }
  
  # Tags for EBS volumes during build
  run_volume_tags = {
    Name = "Packer-Builder-Volume-${local.ami_name}"
  }
}

# Build steps
build {
  name = "java-app-ami"
  sources = [
    "source.amazon-ebs.java_app"
  ]
  
  # Wait for cloud-init to complete
  provisioner "shell" {
    inline = [
      "echo 'Waiting for cloud-init to complete...'",
      "cloud-init status --wait",
      "echo 'System ready for provisioning'",
      "sudo yum update -y"
    ]
  }
  
  # Run Ansible playbook
  provisioner "ansible" {
    playbook_file = "../ansible/configure-app.yml"
    user          = "ec2-user"
    use_proxy     = false
    
    ansible_env_vars = [
      "ANSIBLE_HOST_KEY_CHECKING=False",
      "ANSIBLE_SSH_ARGS='-o ForwardAgent=yes -o ControlMaster=auto -o ControlPersist=60s'",
      "ANSIBLE_NOCOLOR=True"
    ]
    
    extra_arguments = [
      "--verbose",
      "--extra-vars",
      "target_env=${var.environment} app_version=${var.app_version}"
    ]
  }
  
  # Final cleanup
  provisioner "shell" {
    inline = [
      "echo 'Running post-provision cleanup...'",
      "sudo yum clean all",
      "sudo rm -rf /tmp/*",
      "sudo rm -rf /var/tmp/*",
      "sudo find /var/log -type f -exec truncate -s 0 {} \\;",
      "history -c && history -w",
      "echo 'AMI preparation completed successfully'"
    ]
  }
  
  # Generate manifest
  post-processor "manifest" {
    output     = "packer-manifest.json"
    strip_path = true
    custom_data = {
      build_time    = timestamp()
      environment   = var.environment
      app_version   = var.app_version
      base_ami      = data.amazon-ami.amazon_linux.id
      packer_version = packer.version
    }
  }
}