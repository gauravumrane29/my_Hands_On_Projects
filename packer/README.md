# Packer Build Configuration

This directory contains Packer configurations for building custom AMIs with pre-installed application dependencies.

## Files

- **`app_ami.pkr.hcl`** - Modern HCL2 Packer configuration (recommended)
- **`app_ami.json`** - Legacy JSON Packer configuration (for compatibility)
- **`variables.pkrvars.hcl`** - Variable definitions file

## Prerequisites

1. **Packer installed** (>= 1.8.0)
   ```bash
   # Install via package manager or download from https://packer.io
   curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
   sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
   sudo apt-get update && sudo apt-get install packer
   ```

2. **AWS CLI configured** with appropriate permissions
   ```bash
   aws configure
   ```

3. **Ansible installed** on the build machine
   ```bash
   pip install ansible
   ```

## Required AWS Permissions

The AWS user/role needs the following permissions:
- `ec2:*` (for launching build instances)
- `iam:PassRole` (if using instance profiles)

## Building AMIs

### Using HCL2 Configuration (Recommended)

```bash
# Initialize Packer (downloads required plugins)
packer init .

# Validate configuration
packer validate -var-file="variables.pkrvars.hcl" app_ami.pkr.hcl

# Build the AMI
packer build -var-file="variables.pkrvars.hcl" app_ami.pkr.hcl
```

### Using JSON Configuration (Legacy)

```bash
# Validate configuration
packer validate -var-file="variables.pkrvars.hcl" app_ami.json

# Build the AMI
packer build -var-file="variables.pkrvars.hcl" app_ami.json
```

## Customizing the Build

### Environment Variables
```bash
export PKR_VAR_region="us-west-2"
export PKR_VAR_environment="staging"
export PKR_VAR_app_version="v2.0.0"
packer build app_ami.pkr.hcl
```

### Command Line Variables
```bash
packer build \
  -var 'region=us-west-2' \
  -var 'environment=prod' \
  -var 'app_version=v2.0.0' \
  app_ami.pkr.hcl
```

## What Gets Installed

The AMI build process installs and configures:

1. **System Updates**
   - Latest Amazon Linux 2 packages
   - Essential development tools

2. **Java Runtime**
   - Amazon Corretto 17 (OpenJDK)
   - JAVA_HOME configuration

3. **Docker**
   - Latest Docker CE
   - Docker Compose
   - User permissions for ec2-user

4. **Application Framework**
   - Application user (appuser)
   - Directory structure (/opt/app)
   - Systemd service configuration
   - Log rotation setup

5. **Monitoring**
   - CloudWatch agent
   - System monitoring tools
   - Custom metrics configuration

6. **Security & Optimization**
   - Log cleanup and rotation
   - Temporary file cleanup
   - History cleanup for security

## Build Process

1. **Packer launches** a temporary EC2 instance
2. **Base AMI** (Amazon Linux 2) is used as source
3. **Ansible playbook** runs to configure the instance
4. **Cleanup** removes temporary files and logs
5. **AMI creation** snapshots the configured instance
6. **Temporary instance** is terminated

## Output

After successful build:
- **AMI ID** will be displayed and saved to `packer-manifest.json`
- **Tags** are applied for identification and cost tracking
- **Manifest file** contains build metadata

## Integration with Terraform

Update your Terraform configuration to use the new AMI:

```hcl
data "aws_ami" "custom_app_ami" {
  most_recent = true
  owners      = ["self"]
  
  filter {
    name   = "name"
    values = ["java-app-*"]
  }
  
  filter {
    name   = "tag:Environment"
    values = [var.environment]
  }
}

resource "aws_instance" "app_server" {
  ami           = data.aws_ami.custom_app_ami.id
  instance_type = var.instance_type
  # ... other configuration
}
```

## Troubleshooting

### Common Issues

1. **Build fails with permission errors**
   - Check AWS credentials and permissions
   - Ensure IAM user has necessary EC2 permissions

2. **Ansible provisioner fails**
   - Check Ansible is installed on build machine
   - Verify playbook syntax: `ansible-playbook --syntax-check ../ansible/configure-app.yml`

3. **Instance launch fails**
   - Check if default VPC exists
   - Verify security groups allow SSH access
   - Ensure instance type is available in the region

4. **Build hangs on SSH connection**
   - Check security groups allow inbound SSH (port 22)
   - Verify the source AMI supports SSH access

### Debugging Commands

```bash
# Enable debug logging
export PACKER_LOG=1
packer build app_ami.pkr.hcl

# Validate Ansible playbook separately
ansible-playbook --syntax-check ../ansible/configure-app.yml

# Check AWS credentials
aws sts get-caller-identity
```

## Best Practices

1. **Version Control**
   - Tag AMIs with version numbers
   - Use consistent naming conventions
   - Document changes in AMI descriptions

2. **Security**
   - Minimize installed packages
   - Regular security updates
   - Use least-privilege IAM roles

3. **Cost Optimization**
   - Clean up failed builds
   - Use spot instances for builds when possible
   - Delete old AMIs regularly

4. **Testing**
   - Validate AMIs before production use
   - Automate AMI testing in CI/CD pipelines
   - Monitor build times and optimize

## Next Steps

1. **Automated Builds** - Integrate with CI/CD pipeline
2. **Multi-Region** - Build AMIs in multiple regions
3. **Testing** - Add automated AMI testing
4. **Monitoring** - Set up build notifications