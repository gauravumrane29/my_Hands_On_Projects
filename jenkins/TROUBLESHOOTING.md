# Jenkins Pipeline Troubleshooting Guide

## 🔍 Common Jenkins Pipeline Errors & Solutions

---

## 1. ❌ Tool Configuration Errors

### Error: "Tool type 'maven' does not have an install of 'Maven-3.9' configured"

```
Tool type "maven" does not have an install of "Maven-3.9" configured 
- did you mean "null"? @ line 8, column 15.
maven 'Maven-3.9'
```

**Cause:** Maven tool not configured in Global Tool Configuration

**Solutions:**

**Option A: Use Auto-Installation (Recommended - Already Implemented):**
```groovy
// Tools section removed from Jenkinsfile
// Pipeline now auto-installs tools in "Setup Build Tools" stage
```

**Option B: Configure Tools Manually:**
```bash
1. Manage Jenkins → Global Tool Configuration
2. Maven Installations → Add Maven
   - Name: Maven-3.9
   - Install automatically: ✓
   - Version: 3.9.5
3. Save and re-run pipeline
```

**Status:** ✅ **FIXED** - Auto-installation implemented

---

### Error: "Invalid tool type 'nodejs'"

```
Invalid tool type "nodejs". Valid tool types: [maven, jdk, git, ...]
nodejs 'NodeJS-18'
```

**Cause:** NodeJS plugin not installed

**Solutions:**

**Option A: Use Auto-Installation (Recommended - Already Implemented):**
```groovy
// NodeJS auto-installed in "Setup Build Tools" stage
// No plugin required
```

**Option B: Install NodeJS Plugin:**
```bash
1. Manage Jenkins → Manage Plugins → Available
2. Search "NodeJS" → Install without restart
3. Manage Jenkins → Global Tool Configuration
4. NodeJS Installations → Add NodeJS
   - Name: NodeJS-18
   - Install automatically: ✓
   - Version: 18.17.1
```

**Status:** ✅ **FIXED** - Auto-installation implemented

---

### Error: "Invalid option type 'ansiColor'"

```
org.codehaus.groovy.control.MultipleCompilationErrorsException: startup failed:
WorkflowScript: 12: Invalid option type "ansiColor". Valid option types: [...]
```

**Cause:** AnsiColor plugin not installed

**Solution:**
```bash
# Option 1: Install the plugin
Manage Jenkins → Manage Plugins → Available → Search "AnsiColor" → Install

# Option 2: Comment out the line (Already done in Jenkinsfile)
// ansiColor('xterm')
```

**Status:** ✅ **FIXED** - Line commented out in Jenkinsfile

---

## 2. ❌ Docker Related Errors

### Error: "docker: command not found"

```
/bin/sh: docker: command not found
```

**Cause:** Docker not installed on Jenkins agent or Docker plugin missing

**Solutions:**

**A. Install Docker Pipeline Plugin:**
```
Manage Jenkins → Manage Plugins → Available → "Docker Pipeline" → Install
```

**B. Install Docker on Jenkins Agent:**
```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add Jenkins user to docker group
sudo usermod -aG docker jenkins

# Restart Jenkins
sudo systemctl restart jenkins
```

**C. Verify Docker Access:**
```bash
# Test as Jenkins user
sudo -u jenkins docker ps
```

---

### Error: "Got permission denied while trying to connect to Docker daemon"

```
Got permission denied while trying to connect to the Docker daemon socket at 
unix:///var/run/docker.sock
```

**Cause:** Jenkins user doesn't have permission to access Docker socket

**Solution:**
```bash
# Add Jenkins to docker group
sudo usermod -aG docker jenkins

# Change socket permissions (less secure alternative)
sudo chmod 666 /var/run/docker.sock

# Restart Jenkins
sudo systemctl restart jenkins

# Verify
groups jenkins  # Should show: jenkins docker
```

---

### Error: "Cannot connect to Docker daemon"

```
Cannot connect to the Docker daemon at unix:///var/run/docker.sock. 
Is the docker daemon running?
```

**Solution:**
```bash
# Start Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Check Docker status
sudo systemctl status docker

# Test Docker
docker run hello-world
```

---

## 3. ❌ Kubernetes Related Errors

### Error: "kubectl: command not found"

```
/bin/sh: kubectl: command not found
```

**Cause:** kubectl not installed on Jenkins agent

**Solution:**
```bash
# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Verify installation
kubectl version --client

# Configure kubeconfig
mkdir -p ~/.kube
# Copy your kubeconfig file to ~/.kube/config
```

---

### Error: "The connection to the server localhost:8080 was refused"

```
The connection to the server localhost:8080 was refused - did you specify the 
right host or port?
```

**Cause:** kubeconfig not configured or invalid

**Solution:**
```bash
# Check kubeconfig
kubectl config view

# Set correct context
kubectl config use-context <your-context>

# Or set KUBECONFIG environment variable in Jenkinsfile
environment {
    KUBECONFIG = '/var/lib/jenkins/.kube/config'
}

# Verify access
kubectl get nodes
```

---

## 4. ❌ Maven & Build Errors

### Error: "mvn: command not found"

```
/bin/sh: mvn: command not found
```

**Cause:** Maven not installed or not in PATH

**Solution:**

**A. Install Maven Plugin:**
```
Manage Jenkins → Global Tool Configuration → Maven → Add Maven
Name: Maven-3.9
Install automatically: Yes
```

**B. Use Maven Wrapper (Recommended):**
```groovy
// In Jenkinsfile, use ./mvnw instead of mvn
sh './mvnw clean package'
```

**C. Install Maven on Agent:**
```bash
# Install Maven
sudo apt-get install maven  # Ubuntu/Debian
sudo yum install maven      # CentOS/RHEL

# Verify
mvn -version
```

---

### Error: "Failed to execute goal ... The build could not read 1 project"

```
Failed to execute goal on project: Could not resolve dependencies
```

**Cause:** Maven dependencies not accessible

**Solution:**
```bash
# Clean Maven cache
rm -rf ~/.m2/repository

# Or in Jenkinsfile
sh 'mvn clean install -U'  # -U forces update

# Check Maven settings
cat ~/.m2/settings.xml
```

---

## 5. ❌ Git & SCM Errors

### Error: "Permission denied (publickey)"

```
git@github.com: Permission denied (publickey).
fatal: Could not read from remote repository.
```

**Cause:** SSH keys not configured

**Solution:**
```bash
# Generate SSH key
ssh-keygen -t ed25519 -C "jenkins@your-server.com"

# Add to GitHub
cat ~/.ssh/id_ed25519.pub
# Copy and add to GitHub: Settings → SSH and GPG keys

# Or use HTTPS with credentials in Jenkins
# Manage Jenkins → Credentials → Add GitHub token
```

---

### Error: "Couldn't find any revision to build"

```
ERROR: Couldn't find any revision to build. Verify the repository and branch 
configuration for this job.
```

**Cause:** Branch doesn't exist or wrong repository URL

**Solution:**
```groovy
// Check branch name in Jenkinsfile
checkout scm  // Uses branch from Jenkins job config

// Or specify branch explicitly
git branch: 'main', url: 'https://github.com/user/repo.git'

// Verify in Jenkins job configuration:
// Branch Specifier: */main  (or */master)
```

---

## 6. ❌ Credentials & Secrets Errors

### Error: "Credentials ... could not be found"

```
Could not find credentials matching 'docker-hub-credentials'
```

**Cause:** Credential ID doesn't exist in Jenkins

**Solution:**
```bash
# Add credentials in Jenkins:
1. Manage Jenkins → Manage Credentials
2. Click "Jenkins" store → "Global credentials"
3. Click "Add Credentials"
4. Select type (Username/Password, Secret text, SSH key, etc.)
5. Enter ID exactly as used in Jenkinsfile: 'docker-hub-credentials'
6. Save

# Verify credential ID in Jenkinsfile matches:
environment {
    REGISTRY = credentials('docker-hub-credentials')  // Must match exactly
}
```

---

### Error: "AWS credentials not found"

```
Unable to load AWS credentials from any provider in the chain
```

**Cause:** AWS credentials not configured

**Solution:**
```bash
# Add AWS credentials in Jenkins:
1. Manage Jenkins → Manage Credentials
2. Add Credentials → AWS Credentials
3. ID: 'aws-credentials'
4. Access Key ID: YOUR_ACCESS_KEY
5. Secret Access Key: YOUR_SECRET_KEY

# Or use in Jenkinsfile:
withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', 
                  credentialsId: 'aws-credentials']]) {
    sh 'aws s3 ls'
}
```

---

## 7. ❌ Helm Errors

### Error: "helm: command not found"

```
/bin/sh: helm: command not found
```

**Cause:** Helm not installed

**Solution:**
```bash
# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Verify
helm version

# Add Helm to PATH if needed
export PATH=$PATH:/usr/local/bin
```

---

### Error: "Error: INSTALLATION FAILED: Kubernetes cluster unreachable"

```
Error: INSTALLATION FAILED: Kubernetes cluster unreachable: Get "http://localhost:8080/version": 
dial tcp 127.0.0.1:8080: connect: connection refused
```

**Cause:** kubeconfig not set or invalid

**Solution:**
```bash
# Set kubeconfig in Jenkinsfile
environment {
    KUBECONFIG = '/var/lib/jenkins/.kube/config'
}

# Or use withCredentials
withKubeConfig([credentialsId: 'kubeconfig-credentials']) {
    sh 'helm upgrade --install myapp ./chart'
}
```

---

## 8. ❌ Node.js & npm Errors

### Error: "npm: command not found"

```
/bin/sh: npm: command not found
```

**Cause:** Node.js not installed

**Solution:**

**A. Install NodeJS Plugin:**
```
Manage Jenkins → Global Tool Configuration → NodeJS → Add NodeJS
Name: NodeJS-18
Version: 18.x
Install automatically: Yes
```

**B. Use in Jenkinsfile:**
```groovy
tools {
    nodejs 'NodeJS-18'
}
```

**C. Install manually on agent:**
```bash
# Install Node.js
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Verify
node --version
npm --version
```

---

## 9. ❌ Resource & Performance Errors

### Error: "java.lang.OutOfMemoryError: Java heap space"

```
java.lang.OutOfMemoryError: Java heap space
```

**Cause:** Insufficient memory for Jenkins or build

**Solution:**

**A. Increase Jenkins heap:**
```bash
# Edit Jenkins service file
sudo systemctl edit jenkins

# Add:
[Service]
Environment="JAVA_OPTS=-Xmx4096m -XX:MaxPermSize=1024m"

# Restart
sudo systemctl restart jenkins
```

**B. Increase Maven memory in Jenkinsfile:**
```groovy
environment {
    MAVEN_OPTS = '-Xmx2048m -XX:MaxPermSize=512m'
}
```

---

### Error: "Build timeout"

```
ERROR: Build timed out (after 60 minutes). Marking the build as failed.
```

**Cause:** Build exceeds timeout limit

**Solution:**
```groovy
// Increase timeout in Jenkinsfile
options {
    timeout(time: 120, unit: 'MINUTES')  // Increase to 2 hours
}

// Or remove timeout for long builds
```

---

## 10. ❌ Plugin-Specific Errors

### Error: "No such DSL method 'ansiColor'"

**Cause:** Plugin not installed

**Solution:**
See [PLUGIN_INSTALLATION.md](PLUGIN_INSTALLATION.md) for installation instructions.

---

### Error: "No SonarQube installations defined"

```
ERROR: No SonarQube installations defined
```

**Cause:** SonarQube not configured in Jenkins

**Solution:**
```bash
1. Manage Jenkins → Configure System
2. Scroll to "SonarQube servers"
3. Click "Add SonarQube"
4. Name: SonarQube
5. Server URL: http://your-sonarqube:9000
6. Server authentication token: Add from SonarQube
7. Save
```

---

## 🔧 General Debugging Techniques

### Enable Debug Logging

Add to Jenkinsfile:
```groovy
stage('Debug') {
    steps {
        sh '''
            echo "=== Environment Variables ==="
            env | sort
            
            echo "=== System Info ==="
            uname -a
            
            echo "=== Installed Tools ==="
            which java && java -version || echo "Java not found"
            which mvn && mvn -version || echo "Maven not found"
            which docker && docker --version || echo "Docker not found"
            which kubectl && kubectl version --client || echo "kubectl not found"
            which helm && helm version || echo "Helm not found"
            which node && node --version || echo "Node not found"
            which npm && npm --version || echo "npm not found"
            
            echo "=== Current Directory ==="
            pwd
            ls -la
        '''
    }
}
```

---

### Check Jenkins Logs

```bash
# System service
sudo journalctl -u jenkins -f

# Docker
docker logs -f jenkins

# Log file
tail -f /var/log/jenkins/jenkins.log
```

---

### Run Commands in Script Console

Go to **Manage Jenkins** → **Script Console**:

```groovy
// Check Java version
println(System.getProperty("java.version"))

// Check Jenkins version
println(Jenkins.VERSION)

// List installed plugins
Jenkins.instance.pluginManager.plugins.each {
    println("${it.shortName}: ${it.version}")
}

// Check environment variables
System.getenv().each { k, v ->
    println("${k} = ${v}")
}
```

---

## 📚 Useful Commands

### Jenkins Service Management
```bash
# Start/Stop/Restart
sudo systemctl start jenkins
sudo systemctl stop jenkins
sudo systemctl restart jenkins

# Check status
sudo systemctl status jenkins

# Enable auto-start
sudo systemctl enable jenkins
```

### Docker Cleanup
```bash
# Remove unused images
docker image prune -a -f

# Remove unused containers
docker container prune -f

# Clean everything
docker system prune -a -f --volumes
```

### Maven Cleanup
```bash
# Clean local repository
rm -rf ~/.m2/repository

# Clean workspace
mvn clean

# Force update dependencies
mvn clean install -U
```

---

## 🆘 Getting Help

### Check Jenkins Logs
```bash
# Location
/var/log/jenkins/jenkins.log

# Or via Docker
docker logs jenkins
```

### Jenkins Documentation
- **Official Docs:** https://www.jenkins.io/doc/
- **Pipeline Syntax:** https://www.jenkins.io/doc/book/pipeline/syntax/
- **Plugins:** https://plugins.jenkins.io/

### Project Documentation
- **README:** [README.md](README.md)
- **Plugin Guide:** [PLUGIN_INSTALLATION.md](PLUGIN_INSTALLATION.md)
- **Cleanup Analysis:** [JENKINS_CLEANUP_ANALYSIS.md](JENKINS_CLEANUP_ANALYSIS.md)

---

## ✅ Quick Checklist

Before running pipeline, verify:

- [ ] Jenkins is running and accessible
- [ ] Required plugins are installed
- [ ] Credentials are configured
- [ ] Tools (Docker, kubectl, helm, mvn) are installed
- [ ] Agent has necessary permissions
- [ ] Network connectivity to required services
- [ ] Sufficient disk space and memory

---

*Last Updated: October 15, 2025*  
*Related: [`Jenkinsfile`](Jenkinsfile), [`PLUGIN_INSTALLATION.md`](PLUGIN_INSTALLATION.md)*
