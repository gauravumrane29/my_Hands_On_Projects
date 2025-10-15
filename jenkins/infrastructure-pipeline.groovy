# Jenkins Infrastructure Pipeline
# Multi-environment Terraform and Ansible deployment pipeline

@Library('jenkins-shared-library') _

pipeline {
    agent {
        label 'terraform-agent'
    }
    
    options {
        buildDiscarder(logRotator(numToKeepStr: '20'))
        timeout(time: 60, unit: 'MINUTES')
        skipStagesAfterUnstable()
        timestamps()
        ansiColor('xterm')
        disableConcurrentBuilds()
    }
    
    environment {
        // Terraform Configuration
        TF_VERSION = '1.5.5'
        TF_LOG = 'INFO'
        TF_INPUT = 'false'
        TF_IN_AUTOMATION = 'true'
        
        // Ansible Configuration
        ANSIBLE_VERSION = '9.2.0'
        ANSIBLE_HOST_KEY_CHECKING = 'False'
        ANSIBLE_STDOUT_CALLBACK = 'yaml'
        
        // AWS Configuration
        AWS_DEFAULT_REGION = 'us-east-1'
        
        // Workspace Configuration
        TF_WORKSPACE = "${params.ENVIRONMENT}"
        PLAN_FILE = "tfplan-${env.BUILD_NUMBER}"
        
        // State Management
        TF_STATE_BUCKET = 'devops-terraform-state-bucket'
        TF_STATE_KEY = "environments/${params.ENVIRONMENT}/terraform.tfstate"
        TF_STATE_REGION = 'us-east-1'
        
        // Security
        CHECKOV_VERSION = '2.3.228'
    }
    
    parameters {
        choice(
            name: 'ENVIRONMENT',
            choices: ['development', 'staging', 'production'],
            description: 'Target environment for deployment'
        )
        choice(
            name: 'ACTION',
            choices: ['plan', 'apply', 'destroy', 'drift-detect'],
            description: 'Terraform action to execute'
        )
        booleanParam(
            name: 'AUTO_APPROVE',
            defaultValue: false,
            description: 'Automatically approve Terraform apply (not recommended for production)'
        )
        booleanParam(
            name: 'RUN_SECURITY_SCAN',
            defaultValue: true,
            description: 'Run security scans on infrastructure code'
        )
        booleanParam(
            name: 'RUN_ANSIBLE_PLAYBOOK',
            defaultValue: true,
            description: 'Run Ansible configuration after Terraform apply'
        )
        string(
            name: 'CUSTOM_VARS',
            defaultValue: '',
            description: 'Additional Terraform variables (key=value,key2=value2)'
        )
        text(
            name: 'DESTROY_CONFIRMATION',
            defaultValue: '',
            description: 'Type "CONFIRM DESTROY" to enable destroy action'
        )
    }
    
    stages {
        stage('🔍 Environment Validation') {
            steps {
                script {
                    // Validate destroy confirmation
                    if (params.ACTION == 'destroy' && params.DESTROY_CONFIRMATION != 'CONFIRM DESTROY') {
                        error('❌ Destroy action requires confirmation. Please type "CONFIRM DESTROY" in the DESTROY_CONFIRMATION parameter.')
                    }
                    
                    // Production safety checks
                    if (params.ENVIRONMENT == 'production') {
                        if (params.ACTION == 'apply' && !params.AUTO_APPROVE) {
                            env.REQUIRE_APPROVAL = 'true'
                        }
                        if (params.ACTION == 'destroy') {
                            timeout(time: 10, unit: 'MINUTES') {
                                input message: "⚠️ PRODUCTION DESTROY CONFIRMATION ⚠️\\n\\nYou are about to DESTROY the PRODUCTION environment!\\n\\nThis action is IRREVERSIBLE and will result in:\\n- Loss of all production data\\n- Service downtime\\n- Potential revenue impact\\n\\nAre you absolutely sure?", 
                                      ok: "YES, DESTROY PRODUCTION",
                                      submitterParameter: 'DESTROYER'
                            }
                            echo "🎯 Production destroy approved by: ${env.DESTROYER}"
                        }
                    }
                    
                    // Environment-specific configuration
                    switch(params.ENVIRONMENT) {
                        case 'production':
                            env.INSTANCE_TYPE = 't3.large'
                            env.MIN_SIZE = '2'
                            env.MAX_SIZE = '10'
                            env.DESIRED_CAPACITY = '3'
                            env.ENABLE_MONITORING = 'true'
                            env.BACKUP_RETENTION = '30'
                            break
                        case 'staging':
                            env.INSTANCE_TYPE = 't3.medium'
                            env.MIN_SIZE = '1'
                            env.MAX_SIZE = '5'
                            env.DESIRED_CAPACITY = '2'
                            env.ENABLE_MONITORING = 'true'
                            env.BACKUP_RETENTION = '7'
                            break
                        default: // development
                            env.INSTANCE_TYPE = 't3.small'
                            env.MIN_SIZE = '1'
                            env.MAX_SIZE = '3'
                            env.DESIRED_CAPACITY = '1'
                            env.ENABLE_MONITORING = 'false'
                            env.BACKUP_RETENTION = '3'
                    }
                }
                
                echo "🏗️ Infrastructure Pipeline Configuration:"
                echo "  • Environment: ${params.ENVIRONMENT}"
                echo "  • Action: ${params.ACTION}"
                echo "  • Instance Type: ${env.INSTANCE_TYPE}"
                echo "  • Capacity: ${env.MIN_SIZE}-${env.MAX_SIZE} (desired: ${env.DESIRED_CAPACITY})"
                echo "  • Monitoring: ${env.ENABLE_MONITORING}"
                echo "  • Backup Retention: ${env.BACKUP_RETENTION} days"
            }
        }
        
        stage('📥 Checkout & Setup') {
            steps {
                // Checkout source code
                checkout scm
                
                // Setup Terraform
                sh """
                    echo "🔧 Setting up Terraform..."
                    
                    # Download and install Terraform if not present
                    if ! command -v terraform &> /dev/null || [[ \$(terraform version | head -n1 | cut -d' ' -f2 | tr -d 'v') != "${TF_VERSION}" ]]; then
                        echo "Installing Terraform ${TF_VERSION}..."
                        wget -q https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_amd64.zip
                        unzip -o terraform_${TF_VERSION}_linux_amd64.zip
                        sudo mv terraform /usr/local/bin/
                        rm -f terraform_${TF_VERSION}_linux_amd64.zip
                    fi
                    
                    # Verify installation
                    terraform version
                    
                    echo "🔧 Setting up Ansible..."
                    pip3 install --user ansible==${ANSIBLE_VERSION} boto3 botocore
                    ansible --version
                """
            }
        }
        
        stage('🛡️ Security Scanning') {
            when {
                expression { params.RUN_SECURITY_SCAN }
            }
            parallel {
                stage('🔍 Terraform Security Scan') {
                    steps {
                        dir('terraform') {
                            script {
                                try {
                                    sh """
                                        echo "🔍 Running Checkov security scan..."
                                        
                                        # Install Checkov if not present
                                        if ! command -v checkov &> /dev/null; then
                                            pip3 install --user checkov==${CHECKOV_VERSION}
                                        fi
                                        
                                        # Run Checkov scan
                                        checkov -d . \\
                                            --framework terraform \\
                                            --output cli \\
                                            --output junitxml \\
                                            --output-file-path . \\
                                            --soft-fail \\
                                            --skip-check CKV_AWS_79,CKV_AWS_23 || true
                                    """
                                    
                                    // Publish Checkov results
                                    publishTestResults testResultsPattern: 'terraform/results_junitxml.xml'
                                    
                                } catch (Exception e) {
                                    echo "⚠️ Security scan failed: ${e.message}"
                                    currentBuild.result = 'UNSTABLE'
                                }
                            }
                        }
                    }
                }
                
                stage('🔍 Ansible Security Scan') {
                    steps {
                        dir('ansible') {
                            script {
                                try {
                                    sh """
                                        echo "🔍 Running Ansible Lint..."
                                        
                                        # Install ansible-lint if not present
                                        if ! command -v ansible-lint &> /dev/null; then
                                            pip3 install --user ansible-lint
                                        fi
                                        
                                        # Run ansible-lint
                                        ansible-lint *.yml --parseable --severity || true
                                    """
                                } catch (Exception e) {
                                    echo "⚠️ Ansible lint failed: ${e.message}"
                                }
                            }
                        }
                    }
                }
            }
        }
        
        stage('🏗️ Terraform Initialize') {
            steps {
                dir('terraform') {
                    withCredentials([
                        aws(credentialsId: 'aws-credentials',
                            accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                            secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')
                    ]) {
                        sh """
                            echo "🚀 Initializing Terraform..."
                            
                            # Initialize Terraform with remote state
                            terraform init \\
                                -backend-config="bucket=${env.TF_STATE_BUCKET}" \\
                                -backend-config="key=${env.TF_STATE_KEY}" \\
                                -backend-config="region=${env.TF_STATE_REGION}" \\
                                -backend-config="encrypt=true" \\
                                -reconfigure
                            
                            # Select workspace
                            terraform workspace select ${params.ENVIRONMENT} || terraform workspace new ${params.ENVIRONMENT}
                            
                            echo "✅ Terraform initialized successfully"
                            echo "📊 Current workspace: \$(terraform workspace show)"
                        """
                    }
                }
            }
        }
        
        stage('📋 Terraform Plan') {
            when {
                anyOf {
                    expression { params.ACTION == 'plan' }
                    expression { params.ACTION == 'apply' }
                    expression { params.ACTION == 'drift-detect' }
                }
            }
            steps {
                dir('terraform') {
                    withCredentials([
                        aws(credentialsId: 'aws-credentials',
                            accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                            secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')
                    ]) {
                        script {
                            // Prepare Terraform variables
                            def tfVars = [
                                "environment=${params.ENVIRONMENT}",
                                "instance_type=${env.INSTANCE_TYPE}",
                                "min_size=${env.MIN_SIZE}",
                                "max_size=${env.MAX_SIZE}",
                                "desired_capacity=${env.DESIRED_CAPACITY}",
                                "enable_monitoring=${env.ENABLE_MONITORING}",
                                "backup_retention_days=${env.BACKUP_RETENTION}",
                                "project_name=devops-microservice"
                            ]
                            
                            // Add custom variables if provided
                            if (params.CUSTOM_VARS) {
                                params.CUSTOM_VARS.split(',').each { customVar ->
                                    if (customVar.contains('=')) {
                                        tfVars.add(customVar.trim())
                                    }
                                }
                            }
                            
                            def varArgs = tfVars.collect { "-var '${it}'" }.join(' ')
                            
                            if (params.ACTION == 'drift-detect') {
                                sh """
                                    echo "🔍 Running drift detection..."
                                    terraform plan \\
                                        ${varArgs} \\
                                        -detailed-exitcode \\
                                        -out=${env.PLAN_FILE}
                                """
                            } else {
                                sh """
                                    echo "📋 Creating Terraform plan..."
                                    terraform plan \\
                                        ${varArgs} \\
                                        -out=${env.PLAN_FILE}
                                    
                                    # Show plan summary
                                    echo "📊 Plan Summary:"
                                    terraform show -no-color ${env.PLAN_FILE} | head -50
                                """
                            }
                        }
                    }
                }
            }
            post {
                always {
                    // Archive the plan file
                    archiveArtifacts artifacts: "terraform/${env.PLAN_FILE}", fingerprint: true
                }
            }
        }
        
        stage('🚀 Terraform Apply') {
            when {
                expression { params.ACTION == 'apply' }
            }
            steps {
                script {
                    // Production approval gate
                    if (env.REQUIRE_APPROVAL == 'true') {
                        timeout(time: 15, unit: 'MINUTES') {
                            input message: "Apply Terraform changes to PRODUCTION?", 
                                  ok: "Apply Changes",
                                  submitterParameter: 'APPROVER'
                        }
                        echo "🎯 Production apply approved by: ${env.APPROVER}"
                    }
                }
                
                dir('terraform') {
                    withCredentials([
                        aws(credentialsId: 'aws-credentials',
                            accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                            secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')
                    ]) {
                        sh """
                            echo "🚀 Applying Terraform changes..."
                            terraform apply -auto-approve ${env.PLAN_FILE}
                            
                            echo "📊 Infrastructure Status:"
                            terraform output -json > terraform_outputs.json
                            cat terraform_outputs.json
                        """
                    }
                }
            }
            post {
                always {
                    archiveArtifacts artifacts: 'terraform/terraform_outputs.json', allowEmptyArchive: true
                }
                success {
                    script {
                        // Store outputs for Ansible
                        env.TERRAFORM_APPLIED = 'true'
                    }
                }
            }
        }
        
        stage('💥 Terraform Destroy') {
            when {
                expression { params.ACTION == 'destroy' }
            }
            steps {
                dir('terraform') {
                    withCredentials([
                        aws(credentialsId: 'aws-credentials',
                            accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                            secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')
                    ]) {
                        script {
                            // Prepare variables for destroy
                            def tfVars = [
                                "environment=${params.ENVIRONMENT}",
                                "instance_type=${env.INSTANCE_TYPE}",
                                "min_size=${env.MIN_SIZE}",
                                "max_size=${env.MAX_SIZE}",
                                "desired_capacity=${env.DESIRED_CAPACITY}",
                                "enable_monitoring=${env.ENABLE_MONITORING}",
                                "backup_retention_days=${env.BACKUP_RETENTION}",
                                "project_name=devops-microservice"
                            ]
                            
                            def varArgs = tfVars.collect { "-var '${it}'" }.join(' ')
                            
                            sh """
                                echo "💥 Destroying infrastructure..."
                                terraform destroy -auto-approve ${varArgs}
                                
                                echo "✅ Infrastructure destroyed successfully"
                            """
                        }
                    }
                }
            }
        }
        
        stage('⚙️ Ansible Configuration') {
            when {
                allOf {
                    expression { params.RUN_ANSIBLE_PLAYBOOK }
                    expression { params.ACTION == 'apply' }
                    expression { env.TERRAFORM_APPLIED == 'true' }
                }
            }
            steps {
                dir('ansible') {
                    withCredentials([
                        aws(credentialsId: 'aws-credentials',
                            accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                            secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')
                    ]) {
                        script {
                            // Generate dynamic inventory from Terraform outputs
                            sh """
                                echo "⚙️ Configuring infrastructure with Ansible..."
                                
                                # Create dynamic inventory from Terraform outputs
                                python3 << 'PYTHON_EOF'
import json
import sys

# Read Terraform outputs
with open('../terraform/terraform_outputs.json', 'r') as f:
    outputs = json.load(f)

# Generate Ansible inventory
inventory = {
    'web_servers': {
        'hosts': [],
        'vars': {
            'ansible_user': 'ec2-user',
            'ansible_ssh_private_key_file': '~/.ssh/id_rsa'
        }
    },
    'app_servers': {
        'hosts': [],
        'vars': {
            'ansible_user': 'ec2-user',
            'ansible_ssh_private_key_file': '~/.ssh/id_rsa'
        }
    },
    'db_servers': {
        'hosts': [],
        'vars': {
            'ansible_user': 'ec2-user',
            'ansible_ssh_private_key_file': '~/.ssh/id_rsa'
        }
    }
}

# Extract instance information from outputs
if 'web_instance_ips' in outputs:
    inventory['web_servers']['hosts'] = outputs['web_instance_ips']['value']

if 'app_instance_ips' in outputs:
    inventory['app_servers']['hosts'] = outputs['app_instance_ips']['value']

if 'db_instance_ips' in outputs:
    inventory['db_servers']['hosts'] = outputs['db_instance_ips']['value']

# Write inventory file
with open('dynamic_inventory.json', 'w') as f:
    json.dump(inventory, f, indent=2)

print("Dynamic inventory generated successfully")
PYTHON_EOF
                                
                                # Run server setup playbook
                                echo "🔧 Running server setup playbook..."
                                ansible-playbook server-setup.yml \\
                                    -i dynamic_inventory.json \\
                                    --extra-vars "environment=${params.ENVIRONMENT}" \\
                                    --timeout 30 \\
                                    -v
                                
                                # Run application-specific configuration if needed
                                if [ "${params.ENVIRONMENT}" != "production" ] || [ "${env.ENABLE_MONITORING}" = "true" ]; then
                                    echo "🔧 Running additional configuration..."
                                    ansible-playbook configure-app.yml \\
                                        -i dynamic_inventory.json \\
                                        --extra-vars "environment=${params.ENVIRONMENT}" \\
                                        -v
                                fi
                            """
                        }
                    }
                }
            }
            post {
                always {
                    archiveArtifacts artifacts: 'ansible/dynamic_inventory.json', allowEmptyArchive: true
                    
                    // Publish Ansible results if available
                    script {
                        if (fileExists('ansible/ansible-results.xml')) {
                            publishTestResults testResultsPattern: 'ansible/ansible-results.xml'
                        }
                    }
                }
            }
        }
        
        stage('🧪 Infrastructure Validation') {
            when {
                expression { params.ACTION == 'apply' }
            }
            steps {
                script {
                    try {
                        sh """
                            echo "🧪 Running infrastructure validation tests..."
                            
                            # Basic connectivity tests
                            if [ -f "ansible/dynamic_inventory.json" ]; then
                                echo "Testing SSH connectivity to instances..."
                                ansible all -i ansible/dynamic_inventory.json -m ping --timeout 30 || true
                                
                                echo "Checking system status..."
                                ansible all -i ansible/dynamic_inventory.json \\
                                    -m shell -a "uptime && df -h && free -m" --timeout 30 || true
                            fi
                            
                            # Application health checks (if applicable)
                            echo "Running application health checks..."
                            # Add specific health check commands here
                        """
                    } catch (Exception e) {
                        echo "⚠️ Infrastructure validation had issues: ${e.message}"
                        currentBuild.result = 'UNSTABLE'
                    }
                }
            }
        }
        
        stage('📊 Cost Analysis') {
            when {
                anyOf {
                    expression { params.ACTION == 'plan' }
                    expression { params.ACTION == 'apply' }
                }
            }
            steps {
                script {
                    try {
                        sh """
                            echo "💰 Analyzing infrastructure costs..."
                            
                            # Install Infracost if not present
                            if ! command -v infracost &> /dev/null; then
                                curl -fsSL https://raw.githubusercontent.com/infracost/infracost/master/scripts/install.sh | sh
                            fi
                            
                            # Generate cost breakdown
                            cd terraform
                            infracost breakdown --path . \\
                                --terraform-workspace ${params.ENVIRONMENT} \\
                                --format json \\
                                --out-file infracost.json || true
                            
                            infracost breakdown --path . \\
                                --terraform-workspace ${params.ENVIRONMENT} \\
                                --format table || true
                        """
                        
                        archiveArtifacts artifacts: 'terraform/infracost.json', allowEmptyArchive: true
                        
                    } catch (Exception e) {
                        echo "⚠️ Cost analysis failed: ${e.message}"
                    }
                }
            }
        }
    }
    
    post {
        always {
            // Clean up temporary files
            sh """
                echo "🧹 Cleaning up temporary files..."
                rm -f terraform/${env.PLAN_FILE} || true
                rm -f ansible/dynamic_inventory.json || true
            """
            
            // Archive important artifacts
            archiveArtifacts artifacts: 'terraform/terraform.tfstate.backup', allowEmptyArchive: true
            
            // Publish build information
            script {
                def buildInfo = [
                    environment: params.ENVIRONMENT,
                    action: params.ACTION,
                    buildNumber: env.BUILD_NUMBER,
                    timestamp: new Date().format("yyyy-MM-dd'T'HH:mm:ss'Z'"),
                    status: currentBuild.result ?: 'SUCCESS',
                    duration: currentBuild.durationString,
                    terraformApplied: env.TERRAFORM_APPLIED ?: 'false',
                    instanceType: env.INSTANCE_TYPE,
                    capacity: "${env.MIN_SIZE}-${env.MAX_SIZE}"
                ]
                
                writeJSON file: 'infrastructure-build-info.json', json: buildInfo
                archiveArtifacts artifacts: 'infrastructure-build-info.json', fingerprint: true
            }
        }
        
        success {
            echo """
🎉 =====================================================
✅ INFRASTRUCTURE PIPELINE SUCCESS!
🌍 Environment: ${params.ENVIRONMENT}
⚡ Action: ${params.ACTION}
🏗️ Instance Type: ${env.INSTANCE_TYPE}
📊 Capacity: ${env.MIN_SIZE}-${env.MAX_SIZE}
⏰ Duration: ${currentBuild.durationString}
=====================================================
            """
            
            script {
                if (params.ACTION == 'apply') {
                    emailext (
                        subject: "✅ Infrastructure Deployment Success: ${params.ENVIRONMENT}",
                        body: """
Infrastructure deployment completed successfully!

Environment: ${params.ENVIRONMENT}
Action: ${params.ACTION}
Instance Type: ${env.INSTANCE_TYPE}
Capacity: ${env.MIN_SIZE}-${env.MAX_SIZE}
Build: ${env.BUILD_URL}
Approved by: ${env.APPROVER ?: 'N/A'}

The infrastructure is now ready for use.
                        """,
                        to: "${env.INFRASTRUCTURE_NOTIFICATION_EMAILS ?: 'devops@company.com'}"
                    )
                }
            }
        }
        
        failure {
            echo """
❌ =====================================================
💥 INFRASTRUCTURE PIPELINE FAILED!
🌍 Environment: ${params.ENVIRONMENT}
⚡ Action: ${params.ACTION}
⏰ Duration: ${currentBuild.durationString}
🔗 Build URL: ${env.BUILD_URL}
=====================================================
            """
            
            emailext (
                subject: "❌ Infrastructure Pipeline Failed: ${params.ENVIRONMENT}",
                body: """
Infrastructure pipeline failed!

Environment: ${params.ENVIRONMENT}
Action: ${params.ACTION}
Build URL: ${env.BUILD_URL}

Please check the build logs for details.
                """,
                to: "${env.FAILURE_NOTIFICATION_EMAILS ?: 'devops@company.com'}"
            )
        }
        
        unstable {
            echo "⚠️ Infrastructure pipeline completed with warnings"
        }
    }
}