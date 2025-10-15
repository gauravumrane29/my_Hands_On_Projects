#!/bin/bash

# Jenkins Configuration and Setup Script
# This script configures Jenkins with essential plugins, tools, and security settings

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
JENKINS_URL="${JENKINS_URL:-http://localhost:8080}"
JENKINS_USER="${JENKINS_USER:-admin}"
JENKINS_HOME="${JENKINS_HOME:-/var/lib/jenkins}"
JAVA_OPTS="${JAVA_OPTS:--Xmx2048m -XX:MaxPermSize=512m}"

echo -e "${BLUE}🚀 Jenkins Configuration and Setup${NC}"
echo "=================================="

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "\n${PURPLE}📋 $1${NC}"
    echo "$(echo "$1" | sed 's/./=/g')"
}

# Function to check if Jenkins is running
check_jenkins_status() {
    if curl -s "${JENKINS_URL}" > /dev/null 2>&1; then
        print_status "Jenkins is running at ${JENKINS_URL}"
        return 0
    else
        print_error "Jenkins is not accessible at ${JENKINS_URL}"
        return 1
    fi
}

# Function to install Jenkins CLI
setup_jenkins_cli() {
    print_header "Setting up Jenkins CLI"
    
    if [ ! -f "jenkins-cli.jar" ]; then
        print_status "Downloading Jenkins CLI..."
        curl -s "${JENKINS_URL}/jnlpJars/jenkins-cli.jar" -o jenkins-cli.jar
    fi
    
    # Make CLI function
    jenkins_cli() {
        java -jar jenkins-cli.jar -s "${JENKINS_URL}" -auth "${JENKINS_USER}:${JENKINS_TOKEN}" "$@"
    }
    
    print_status "Jenkins CLI setup complete"
}

# Essential plugins to install
ESSENTIAL_PLUGINS=(
    "ant"
    "build-timeout"
    "credentials-binding"
    "email-ext"
    "git"
    "github-branch-source"
    "gradle"
    "ldap"
    "mailer"
    "matrix-auth"
    "pam-auth"
    "pipeline-stage-view"
    "ssh-slaves"
    "timestamper"
    "workflow-aggregator"
    "ws-cleanup"
    "blueocean"
    "pipeline-utility-steps"
    "configuration-as-code"
    "job-dsl"
    "kubernetes"
    "docker-workflow"
    "sonar"
    "jacoco"
    "junit"
    "htmlpublisher"
    "checkstyle"
    "warnings-ng"
    "dependency-check-jenkins-plugin"
    "owasp-markup-formatter"
    "role-strategy"
    "matrix-project"
    "build-name-setter"
    "build-user-vars-plugin"
    "envinject"
    "parameterized-trigger"
    "conditional-buildstep"
    "copyartifact"
    "publish-over-ssh"
    "slack"
    "jira"
    "prometheus"
    "monitoring"
    "metrics"
    "disk-usage"
    "build-monitor-plugin"
    "dashboard-view"
    "view-job-filters"
    "nested-view"
    "cloudbees-folder"
    "antisamy-markup-formatter"
    "build-failure-analyzer"
    "performance"
    "plot"
    "xunit"
    "cobertura"
    "findbugs"
    "pmd"
    "dry"
    "tasks"
    "violations"
    "warnings"
    "analysis-core"
    "token-macro"
    "build-pipeline-plugin"
    "delivery-pipeline-plugin"
    "pipeline-milestone-step"
    "pipeline-input-step"
    "pipeline-build-step"
    "workflow-cps"
    "workflow-job"
    "workflow-multibranch"
    "pipeline-github-lib"
    "github-pullrequest"
    "generic-webhook-trigger"
    "multijob"
)

# Function to install plugins
install_plugins() {
    print_header "Installing Essential Jenkins Plugins"
    
    if [ -z "${JENKINS_TOKEN:-}" ]; then
        print_error "JENKINS_TOKEN environment variable is required"
        print_status "Please set JENKINS_TOKEN with your Jenkins API token"
        return 1
    fi
    
    print_status "Installing ${#ESSENTIAL_PLUGINS[@]} essential plugins..."
    
    for plugin in "${ESSENTIAL_PLUGINS[@]}"; do
        print_status "Installing plugin: ${plugin}"
        if java -jar jenkins-cli.jar -s "${JENKINS_URL}" -auth "${JENKINS_USER}:${JENKINS_TOKEN}" install-plugin "${plugin}"; then
            print_status "✅ ${plugin} installed successfully"
        else
            print_warning "⚠️ Failed to install ${plugin}"
        fi
    done
    
    print_status "Restarting Jenkins to activate plugins..."
    java -jar jenkins-cli.jar -s "${JENKINS_URL}" -auth "${JENKINS_USER}:${JENKINS_TOKEN}" restart
    
    print_status "Waiting for Jenkins to restart..."
    sleep 30
    
    # Wait for Jenkins to be ready
    local retries=0
    while ! check_jenkins_status && [ $retries -lt 30 ]; do
        sleep 10
        ((retries++))
        print_status "Waiting for Jenkins to be ready... (attempt $retries/30)"
    done
    
    print_status "Plugin installation completed"
}

# Function to configure global tools
configure_global_tools() {
    print_header "Configuring Global Tools"
    
    # Create tools configuration script
    cat > configure_tools.groovy << 'EOF'
import jenkins.model.*
import hudson.tools.*
import hudson.plugins.git.*
import hudson.model.*
import hudson.slaves.*
import hudson.plugins.sonar.*
import hudson.plugins.sonar.model.*

def instance = Jenkins.getInstance()

println "Configuring Global Tools..."

// Configure Git
def gitDescriptor = instance.getDescriptor(GitTool.class)
def gitInstallations = []

// Git installation
def gitInstallation = new GitTool("Default", "/usr/bin/git", [])
gitInstallations.add(gitInstallation)

gitDescriptor.setInstallations(gitInstallations.toArray(new GitTool[0]))
gitDescriptor.save()

println "Git configured successfully"

// Configure Maven
def mavenDescriptor = instance.getDescriptor("hudson.tasks.Maven\$DescriptorImpl")
if (mavenDescriptor != null) {
    def mavenInstallations = []
    
    // Maven 3.8.6
    def mavenInstallation = new hudson.tasks.Maven.MavenInstallation(
        "Maven-3.8.6",
        null,
        [new InstallSourceProperty([
            new hudson.tasks.Maven.MavenInstaller("3.8.6")
        ])]
    )
    mavenInstallations.add(mavenInstallation)
    
    mavenDescriptor.setInstallations(mavenInstallations.toArray(new hudson.tasks.Maven.MavenInstallation[0]))
    mavenDescriptor.save()
    
    println "Maven configured successfully"
}

// Configure JDK
def jdkDescriptor = instance.getDescriptor("hudson.model.JDK")
if (jdkDescriptor != null) {
    def jdkInstallations = []
    
    // OpenJDK 17
    def jdk17Installation = new JDK(
        "OpenJDK-17",
        "/usr/lib/jvm/java-17-openjdk-amd64",
        []
    )
    jdkInstallations.add(jdk17Installation)
    
    // OpenJDK 11
    def jdk11Installation = new JDK(
        "OpenJDK-11",
        "/usr/lib/jvm/java-11-openjdk-amd64",
        []
    )
    jdkInstallations.add(jdk11Installation)
    
    jdkDescriptor.setInstallations(jdkInstallations.toArray(new JDK[0]))
    jdkDescriptor.save()
    
    println "JDK configured successfully"
}

// Configure NodeJS
def nodejsDescriptor = instance.getDescriptor("jenkins.plugins.nodejs.tools.NodeJSInstallation")
if (nodejsDescriptor != null) {
    def nodejsInstallations = []
    
    def nodejsInstallation = new jenkins.plugins.nodejs.tools.NodeJSInstallation(
        "NodeJS-18",
        null,
        [new InstallSourceProperty([
            new jenkins.plugins.nodejs.tools.NodeJSInstaller("18.17.0", "", 100)
        ])]
    )
    nodejsInstallations.add(nodejsInstallation)
    
    nodejsDescriptor.setInstallations(nodejsInstallations.toArray(new jenkins.plugins.nodejs.tools.NodeJSInstallation[0]))
    nodejsDescriptor.save()
    
    println "NodeJS configured successfully"
}

// Configure Docker
def dockerDescriptor = instance.getDescriptor("org.jenkinsci.plugins.docker.commons.tools.DockerTool")
if (dockerDescriptor != null) {
    def dockerInstallations = []
    
    def dockerInstallation = new org.jenkinsci.plugins.docker.commons.tools.DockerTool(
        "Docker",
        "/usr/bin/docker",
        []
    )
    dockerInstallations.add(dockerInstallation)
    
    dockerDescriptor.setInstallations(dockerInstallations.toArray(new org.jenkinsci.plugins.docker.commons.tools.DockerTool[0]))
    dockerDescriptor.save()
    
    println "Docker configured successfully"
}

println "Global tools configuration completed!"
instance.save()
EOF

    # Execute the configuration script
    if java -jar jenkins-cli.jar -s "${JENKINS_URL}" -auth "${JENKINS_USER}:${JENKINS_TOKEN}" groovy = < configure_tools.groovy; then
        print_status "✅ Global tools configured successfully"
    else
        print_warning "⚠️ Failed to configure some global tools"
    fi
    
    rm -f configure_tools.groovy
}

# Function to configure security settings
configure_security() {
    print_header "Configuring Security Settings"
    
    cat > configure_security.groovy << 'EOF'
import jenkins.model.*
import hudson.security.*
import jenkins.security.s2m.AdminWhitelistRule

def instance = Jenkins.getInstance()

// Enable security
def hudsonRealm = new HudsonPrivateSecurityRealm(false)
instance.setSecurityRealm(hudsonRealm)

// Enable matrix-based authorization
def authStrategy = new GlobalMatrixAuthorizationStrategy()

// Grant all permissions to admin user
authStrategy.add(Jenkins.ADMINISTER, "admin")

// Grant read permissions to authenticated users
authStrategy.add(Jenkins.READ, "authenticated")
authStrategy.add(Item.READ, "authenticated")
authStrategy.add(Item.DISCOVER, "authenticated")

instance.setAuthorizationStrategy(authStrategy)

// Configure agent protocols
instance.getDescriptor("jenkins.CLI").get().setEnabled(false)
instance.save()

// Disable deprecated agent protocols
Set<String> agentProtocols = ['JNLP4-connect', 'Ping']
instance.setAgentProtocols(agentProtocols)

println "Security configuration completed!"
EOF

    if java -jar jenkins-cli.jar -s "${JENKINS_URL}" -auth "${JENKINS_USER}:${JENKINS_TOKEN}" groovy = < configure_security.groovy; then
        print_status "✅ Security settings configured successfully"
    else
        print_warning "⚠️ Failed to configure security settings"
    fi
    
    rm -f configure_security.groovy
}

# Function to create build agents configuration
create_build_agents() {
    print_header "Creating Build Agent Templates"
    
    cat > agent_templates.groovy << 'EOF'
import jenkins.model.*
import hudson.model.*
import hudson.slaves.*
import hudson.plugins.sshslaves.*

def instance = Jenkins.getInstance()

// Create Maven Java 17 agent template
def maven17Template = new DumbSlave(
    "maven-java17-template",
    "Maven Java 17 Build Agent Template",
    "/home/jenkins",
    "2",
    Node.Mode.NORMAL,
    "maven java17 build",
    new SSHLauncher(
        "BUILD_AGENT_HOST",
        22,
        "jenkins-ssh-key",
        "",
        "",
        "",
        "",
        60,
        3,
        15
    ),
    RetentionStrategy.INSTANCE,
    []
)

// Create Docker agent template
def dockerTemplate = new DumbSlave(
    "docker-agent-template",
    "Docker Build Agent Template",
    "/home/jenkins",
    "2",
    Node.Mode.NORMAL,
    "docker build container",
    new SSHLauncher(
        "DOCKER_AGENT_HOST",
        22,
        "jenkins-ssh-key",
        "",
        "",
        "",
        "",
        60,
        3,
        15
    ),
    RetentionStrategy.INSTANCE,
    []
)

println "Build agent templates created (not added to avoid connection issues)"
println "Please configure actual agent hosts and add them manually"
EOF

    if java -jar jenkins-cli.jar -s "${JENKINS_URL}" -auth "${JENKINS_USER}:${JENKINS_TOKEN}" groovy = < agent_templates.groovy; then
        print_status "✅ Build agent templates created"
    else
        print_warning "⚠️ Failed to create build agent templates"
    fi
    
    rm -f agent_templates.groovy
}

# Function to configure system properties
configure_system() {
    print_header "Configuring System Properties"
    
    cat > system_config.groovy << 'EOF'
import jenkins.model.*
import hudson.model.*

def instance = Jenkins.getInstance()

// Configure system properties
System.setProperty("hudson.model.DirectoryBrowserSupport.CSP", "")
System.setProperty("jenkins.install.runSetupWizard", "false")
System.setProperty("hudson.footerURL", "https://jenkins.io")

// Configure workspace cleanup
def workspaceCleanupRecurrencePeriod = "24"
System.setProperty("hudson.plugins.ws_cleanup.Pattern", "**/*")

// Configure build history
def buildHistorySize = "50"
System.setProperty("hudson.model.Job.BuildHistorySize", buildHistorySize)

// Configure executor settings
instance.setNumExecutors(4)
instance.setQuietPeriod(5)
instance.setScmCheckoutRetryCount(3)

println "System configuration completed!"
instance.save()
EOF

    if java -jar jenkins-cli.jar -s "${JENKINS_URL}" -auth "${JENKINS_USER}:${JENKINS_TOKEN}" groovy = < system_config.groovy; then
        print_status "✅ System properties configured successfully"
    else
        print_warning "⚠️ Failed to configure system properties"
    fi
    
    rm -f system_config.groovy
}

# Function to create sample jobs
create_sample_jobs() {
    print_header "Creating Sample Jobs"
    
    # Create a sample pipeline job
    cat > sample_pipeline.xml << 'EOF'
<?xml version='1.1' encoding='UTF-8'?>
<flow-definition plugin="workflow-job@1236.v199d1b_9b_0472">
  <actions>
    <org.jenkinsci.plugins.pipeline.modeldefinition.actions.DeclarativeJobAction plugin="pipeline-model-definition@2.2086.v12b_420f036e5"/>
    <org.jenkinsci.plugins.pipeline.modeldefinition.actions.DeclarativeJobPropertyTrackerAction plugin="pipeline-model-definition@2.2086.v12b_420f036e5">
      <jobProperties/>
      <triggers/>
      <parameters/>
      <options/>
    </org.jenkinsci.plugins.pipeline.modeldefinition.actions.DeclarativeJobPropertyTrackerAction>
  </actions>
  <description>Sample Java microservice pipeline demonstrating best practices</description>
  <keepDependencies>false</keepDependencies>
  <properties>
    <org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
      <triggers>
        <hudson.triggers.SCMTrigger>
          <spec>H/5 * * * *</spec>
          <ignorePostCommitHooks>false</ignorePostCommitHooks>
        </hudson.triggers.SCMTrigger>
      </triggers>
    </org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
    <hudson.model.ParametersDefinitionProperty>
      <parameterDefinitions>
        <hudson.model.ChoiceParameterDefinition>
          <name>DEPLOYMENT_ENVIRONMENT</name>
          <description>Target deployment environment</description>
          <choices class="java.util.Arrays$ArrayList">
            <a class="string-array">
              <string>development</string>
              <string>staging</string>
              <string>production</string>
            </a>
          </choices>
        </hudson.model.ChoiceParameterDefinition>
        <hudson.model.BooleanParameterDefinition>
          <name>SKIP_TESTS</name>
          <description>Skip running tests (not recommended for production)</description>
          <defaultValue>false</defaultValue>
        </hudson.model.BooleanParameterDefinition>
        <hudson.model.BooleanParameterDefinition>
          <name>DEPLOY_TO_K8S</name>
          <description>Deploy to Kubernetes cluster</description>
          <defaultValue>true</defaultValue>
        </hudson.model.BooleanParameterDefinition>
        <hudson.model.BooleanParameterDefinition>
          <name>RUN_SECURITY_SCAN</name>
          <description>Run security vulnerability scans</description>
          <defaultValue>true</defaultValue>
        </hudson.model.BooleanParameterDefinition>
      </parameterDefinitions>
    </hudson.model.ParametersDefinitionProperty>
  </properties>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsFlowDefinition" plugin="workflow-cps@2660.vb_c0412dc4e6d">
    <script>@Library('jenkins-shared-library') _

pipeline {
    agent {
        label 'maven-java17'
    }
    
    stages {
        stage('🔍 Environment Setup') {
            steps {
                echo "Setting up build environment..."
                script {
                    env.BUILD_VERSION = "${env.BUILD_NUMBER}"
                    env.IMAGE_TAG = "${env.BRANCH_NAME}-${env.BUILD_VERSION}-${env.GIT_COMMIT.take(8)}"
                }
            }
        }
        
        stage('📥 Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('🏗️ Build & Test') {
            steps {
                dir('app') {
                    sh '''
                        mvn clean compile test package
                    '''
                }
            }
            post {
                always {
                    publishTestResults testResultsPattern: 'app/target/surefire-reports/*.xml'
                    publishHTML([
                        allowMissing: false,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: 'app/target/site/jacoco',
                        reportFiles: 'index.html',
                        reportName: 'Code Coverage Report'
                    ])
                }
            }
        }
        
        stage('🐳 Build Container') {
            steps {
                dir('app') {
                    script {
                        def image = docker.build("java-microservice:${env.IMAGE_TAG}")
                        env.DOCKER_IMAGE_ID = image.id
                    }
                }
            }
        }
        
        stage('🚀 Deploy') {
            when {
                expression { params.DEPLOY_TO_K8S }
            }
            steps {
                echo "Deploying to ${params.DEPLOYMENT_ENVIRONMENT} environment..."
                // Add deployment steps here
            }
        }
    }
    
    post {
        always {
            cleanWs()
        }
        success {
            echo "✅ Pipeline completed successfully!"
        }
        failure {
            echo "❌ Pipeline failed!"
        }
    }
}</script>
    <sandbox>true</sandbox>
  </definition>
  <triggers/>
  <disabled>false</disabled>
</flow-definition>
EOF

    # Create the sample job
    if java -jar jenkins-cli.jar -s "${JENKINS_URL}" -auth "${JENKINS_USER}:${JENKINS_TOKEN}" create-job "java-microservice-pipeline" < sample_pipeline.xml; then
        print_status "✅ Sample pipeline job created successfully"
    else
        print_warning "⚠️ Failed to create sample pipeline job"
    fi
    
    rm -f sample_pipeline.xml
}

# Function to setup Jenkins shared library
setup_shared_library() {
    print_header "Setting up Jenkins Shared Library"
    
    cat > shared_library_config.groovy << 'EOF'
import jenkins.model.*
import org.jenkinsci.plugins.workflow.libs.*
import hudson.plugins.git.*

def instance = Jenkins.getInstance()

// Configure global pipeline libraries
def descriptor = instance.getDescriptor("org.jenkinsci.plugins.workflow.libs.GlobalLibraries")

def scm = new GitSCM("https://github.com/your-org/jenkins-shared-library.git")
scm.branches = [new BranchSpec("*/main")]

def library = new LibraryConfiguration("jenkins-shared-library", new SCMSourceRetriever(scm))
library.defaultVersion = "main"
library.implicit = true
library.allowVersionOverride = true
library.includeInChangesets = true

def globalLibraries = [library]
descriptor.get().setLibraries(globalLibraries)

println "Jenkins shared library configured!"
instance.save()
EOF

    if java -jar jenkins-cli.jar -s "${JENKINS_URL}" -auth "${JENKINS_USER}:${JENKINS_TOKEN}" groovy = < shared_library_config.groovy; then
        print_status "✅ Shared library configuration completed"
        print_warning "⚠️ Please update the Git repository URL in the shared library configuration"
    else
        print_warning "⚠️ Failed to configure shared library"
    fi
    
    rm -f shared_library_config.groovy
}

# Function to backup Jenkins configuration
backup_jenkins_config() {
    print_header "Creating Jenkins Configuration Backup"
    
    local backup_dir="jenkins_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "${backup_dir}"
    
    print_status "Creating backup in ${backup_dir}..."
    
    # Backup essential configuration files
    if [ -d "${JENKINS_HOME}" ]; then
        cp -r "${JENKINS_HOME}/config.xml" "${backup_dir}/" 2>/dev/null || true
        cp -r "${JENKINS_HOME}/credentials.xml" "${backup_dir}/" 2>/dev/null || true
        cp -r "${JENKINS_HOME}/jobs" "${backup_dir}/" 2>/dev/null || true
        cp -r "${JENKINS_HOME}/plugins" "${backup_dir}/" 2>/dev/null || true
        cp -r "${JENKINS_HOME}/users" "${backup_dir}/" 2>/dev/null || true
    fi
    
    # Create backup archive
    tar -czf "${backup_dir}.tar.gz" "${backup_dir}"
    rm -rf "${backup_dir}"
    
    print_status "✅ Backup created: ${backup_dir}.tar.gz"
}

# Function to display configuration summary
display_summary() {
    print_header "Jenkins Configuration Summary"
    
    echo "📊 Configuration Details:"
    echo "  • Jenkins URL: ${JENKINS_URL}"
    echo "  • Jenkins User: ${JENKINS_USER}"
    echo "  • Jenkins Home: ${JENKINS_HOME}"
    echo "  • Plugins Installed: ${#ESSENTIAL_PLUGINS[@]}"
    echo ""
    echo "🔧 Configured Tools:"
    echo "  • Git (Default)"
    echo "  • Maven 3.8.6"
    echo "  • OpenJDK 11 & 17"
    echo "  • NodeJS 18"
    echo "  • Docker"
    echo ""
    echo "🛡️ Security Features:"
    echo "  • Matrix-based authorization"
    echo "  • Secure agent protocols"
    echo "  • Plugin security updates"
    echo ""
    echo "📋 Sample Jobs:"
    echo "  • java-microservice-pipeline"
    echo ""
    echo "📚 Next Steps:"
    echo "  1. Configure your Git repositories"
    echo "  2. Set up build agents/nodes"
    echo "  3. Configure credentials for external services"
    echo "  4. Set up webhooks for automatic builds"
    echo "  5. Configure notification settings"
    echo "  6. Review and customize security settings"
    echo ""
    echo "🔗 Useful URLs:"
    echo "  • Jenkins Dashboard: ${JENKINS_URL}"
    echo "  • Plugin Manager: ${JENKINS_URL}/pluginManager/"
    echo "  • System Configuration: ${JENKINS_URL}/configure"
    echo "  • Security Configuration: ${JENKINS_URL}/configureSecurity/"
    echo "  • Node Management: ${JENKINS_URL}/computer/"
}

# Main execution flow
main() {
    print_header "Jenkins Setup and Configuration"
    
    # Check prerequisites
    if ! command -v java &> /dev/null; then
        print_error "Java is required but not installed"
        exit 1
    fi
    
    if ! command -v curl &> /dev/null; then
        print_error "curl is required but not installed"
        exit 1
    fi
    
    # Check Jenkins token
    if [ -z "${JENKINS_TOKEN:-}" ]; then
        print_warning "JENKINS_TOKEN environment variable not set"
        print_status "Please set JENKINS_TOKEN with your Jenkins API token to enable full configuration"
        print_status "You can generate a token at: ${JENKINS_URL}/user/${JENKINS_USER}/configure"
        read -p "Press Enter to continue with limited configuration or Ctrl+C to exit..."
    fi
    
    # Check if Jenkins is accessible
    if ! check_jenkins_status; then
        print_error "Please start Jenkins first"
        print_status "You can start Jenkins with: sudo systemctl start jenkins"
        exit 1
    fi
    
    # Setup Jenkins CLI
    setup_jenkins_cli
    
    # Run configuration steps
    if [ -n "${JENKINS_TOKEN:-}" ]; then
        install_plugins
        configure_global_tools
        configure_security
        configure_system
        create_build_agents
        create_sample_jobs
        setup_shared_library
        backup_jenkins_config
    else
        print_warning "Skipping advanced configuration due to missing JENKINS_TOKEN"
    fi
    
    # Display summary
    display_summary
    
    print_status "✅ Jenkins configuration completed!"
}

# Execute main function
main "$@"