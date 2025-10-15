# Jenkins Plugins Installation Guide

## 🚨 Quick Fix for AnsiColor Error

The error you encountered:
```
Invalid option type "ansiColor". Valid option types: [authorizationMatrix, buildDiscarder, ...]
```

**Root Cause:** The AnsiColor plugin is not installed in your Jenkins instance.

**Status:** ✅ **FIXED** - The Jenkinsfile has been updated to comment out the ansiColor option.

---

## 📋 Installation Options

### Option 1: Install AnsiColor Plugin (Recommended for Better Output)

#### Via Jenkins UI:
1. Go to **Jenkins Dashboard**
2. Click **Manage Jenkins** → **Manage Plugins**
3. Click the **Available** tab
4. Search for **AnsiColor**
5. Check the box next to **AnsiColor**
6. Click **Install without restart**
7. Wait for installation to complete
8. Uncomment the line in Jenkinsfile: `ansiColor('xterm')`

#### Via Jenkins CLI:
```bash
java -jar jenkins-cli.jar -s http://localhost:8080/ install-plugin ansicolor
```

#### Via Script Console:
```groovy
// Go to Manage Jenkins → Script Console and run:
import jenkins.model.Jenkins

def pluginParameter = "ansicolor"
def instance = Jenkins.getInstance()
def updateCenter = instance.getUpdateCenter()

updateCenter.getPlugin(pluginParameter).deploy(true)
println("AnsiColor plugin installation started")
```

---

### Option 2: Keep Using Updated Jenkinsfile (Already Done)

The Jenkinsfile has been updated to work without the AnsiColor plugin. The pipeline will run successfully but without colored console output.

**What changed:**
```diff
  options {
      buildDiscarder(logRotator(numToKeepStr: '10'))
      timeout(time: 60, unit: 'MINUTES')
      retry(2)
      skipStagesAfterUnstable()
      timestamps()
-     ansiColor('xterm')
+     // ansiColor('xterm')  // Commented out - requires AnsiColor plugin installation
      parallelsAlwaysFailFast()
  }
```

---

## 🔌 Required Plugins for Full Pipeline Functionality

### Core Pipeline Plugins (Essential)
```
✅ Pipeline (workflow-aggregator)
✅ Git (git)
✅ GitHub (github)
✅ GitHub Branch Source (github-branch-source)
✅ Docker Pipeline (docker-workflow)
✅ Docker Commons (docker-commons)
✅ Kubernetes (kubernetes)
✅ Credentials Binding (credentials-binding)
✅ Credentials (credentials)
```

### Build & Test Plugins
```
🔧 Maven Integration (maven-plugin)
🔧 JUnit (junit)
🔧 JaCoCo (jacoco)
🔧 HTML Publisher (htmlpublisher)
🔧 Workspace Cleanup (ws-cleanup)
```

### Quality & Security Plugins
```
🔒 SonarQube Scanner (sonar)
🔒 OWASP Dependency-Check (dependency-check-jenkins-plugin)
🔒 Checkstyle (checkstyle)
🔒 Warnings Next Generation (warnings-ng)
```

### Deployment & Infrastructure Plugins
```
🚀 Kubernetes CLI (kubernetes-cli)
🚀 Ansible (ansible)
🚀 Terraform (terraform)
🚀 AWS Steps (pipeline-aws)
```

### UI & Notifications
```
💬 Blue Ocean (blueocean)
💬 AnsiColor (ansicolor) - For colored console output
💬 Slack Notification (slack)
💬 Email Extension (email-ext)
💬 Badge (badge)
```

### Configuration & Utilities
```
⚙️ Configuration as Code (configuration-as-code)
⚙️ Job DSL (job-dsl)
⚙️ Pipeline Utility Steps (pipeline-utility-steps)
⚙️ Timestamper (timestamper)
⚙️ Build Timeout (build-timeout)
```

---

## 🚀 Batch Install All Required Plugins

### Method 1: Using Jenkins Script Console

Go to **Manage Jenkins** → **Script Console** and run:

```groovy
def plugins = [
    // Core Pipeline
    'workflow-aggregator',
    'git',
    'github',
    'github-branch-source',
    'docker-workflow',
    'docker-commons',
    'kubernetes',
    'credentials-binding',
    'credentials',
    
    // Build & Test
    'maven-plugin',
    'junit',
    'jacoco',
    'htmlpublisher',
    'ws-cleanup',
    
    // Quality & Security
    'sonar',
    'checkstyle',
    'warnings-ng',
    
    // Deployment
    'kubernetes-cli',
    'ansible',
    'pipeline-aws',
    
    // UI & Notifications
    'blueocean',
    'ansicolor',
    'slack',
    'email-ext',
    'badge',
    
    // Configuration
    'configuration-as-code',
    'job-dsl',
    'pipeline-utility-steps',
    'timestamper',
    'build-timeout'
]

import jenkins.model.Jenkins

def instance = Jenkins.getInstance()
def pm = instance.getPluginManager()
def uc = instance.getUpdateCenter()

println("Starting plugin installation...")

plugins.each { pluginName ->
    if (pm.getPlugin(pluginName)) {
        println("✅ ${pluginName} - Already installed")
    } else {
        println("📥 ${pluginName} - Installing...")
        def plugin = uc.getPlugin(pluginName)
        if (plugin) {
            plugin.deploy(true)
            println("   Scheduled for installation")
        } else {
            println("   ⚠️ Plugin not found in update center")
        }
    }
}

println("\n✨ Plugin installation initiated!")
println("⚠️  Jenkins restart required to complete installation")
println("💡 Go to: Manage Jenkins → Restart Jenkins When Idle")
```

---

### Method 2: Using Docker (Recommended)

If you're using the Docker setup script:

```bash
cd /home/gaurav/my_Hands_On_Projects/jenkins
./setup-jenkins-docker.sh
```

This automatically installs all required plugins via the `jenkins.yaml` configuration file.

---

### Method 3: Using Jenkins CLI

```bash
# Download Jenkins CLI
wget http://localhost:8080/jnlpJars/jenkins-cli.jar

# Install plugins
java -jar jenkins-cli.jar -s http://localhost:8080/ install-plugin \
  workflow-aggregator git github docker-workflow kubernetes \
  credentials-binding maven-plugin junit jacoco sonar \
  blueocean ansicolor slack configuration-as-code \
  -restart
```

---

### Method 4: Using plugins.txt File

Create a `plugins.txt` file:

```txt
workflow-aggregator:latest
git:latest
github:latest
github-branch-source:latest
docker-workflow:latest
docker-commons:latest
kubernetes:latest
credentials-binding:latest
credentials:latest
maven-plugin:latest
junit:latest
jacoco:latest
htmlpublisher:latest
ws-cleanup:latest
sonar:latest
checkstyle:latest
warnings-ng:latest
kubernetes-cli:latest
ansible:latest
pipeline-aws:latest
blueocean:latest
ansicolor:latest
slack:latest
email-ext:latest
badge:latest
configuration-as-code:latest
job-dsl:latest
pipeline-utility-steps:latest
timestamper:latest
build-timeout:latest
```

Then install using jenkins-plugin-cli:

```bash
jenkins-plugin-cli --plugin-file plugins.txt
```

---

## 🔍 Verify Plugin Installation

### Check Installed Plugins via UI:
1. Go to **Manage Jenkins** → **Manage Plugins**
2. Click the **Installed** tab
3. Search for plugin names

### Check via Script Console:
```groovy
Jenkins.instance.pluginManager.plugins.findAll { 
    it.shortName in ['ansicolor', 'docker-workflow', 'kubernetes', 'sonar', 'blueocean']
}.each {
    println("${it.shortName}: ${it.version} - ${it.isEnabled() ? 'Enabled' : 'Disabled'}")
}
```

### Check via CLI:
```bash
java -jar jenkins-cli.jar -s http://localhost:8080/ list-plugins | grep -E "(ansicolor|docker|kubernetes|sonar)"
```

---

## 🎨 Enable AnsiColor in Jenkinsfile

After installing the AnsiColor plugin, you can uncomment the line in the Jenkinsfile:

**Line 12 in `/home/gaurav/my_Hands_On_Projects/jenkins/Jenkinsfile`:**

```diff
  options {
      buildDiscarder(logRotator(numToKeepStr: '10'))
      timeout(time: 60, unit: 'MINUTES')
      retry(2)
      skipStagesAfterUnstable()
      timestamps()
-     // ansiColor('xterm')  // Commented out - requires AnsiColor plugin installation
+     ansiColor('xterm')  // Enabled - provides colored console output
      parallelsAlwaysFailFast()
  }
```

Or use it per-stage:

```groovy
stage('Build') {
    steps {
        ansiColor('xterm') {
            sh './mvnw clean package'
        }
    }
}
```

---

## 🐛 Troubleshooting

### Plugin Installation Fails

**Issue:** Plugin download fails or times out

**Solution:**
```bash
# Update plugin center data
curl -X POST http://localhost:8080/pluginManager/checkUpdates

# Or restart Jenkins
systemctl restart jenkins  # For system service
docker-compose restart jenkins  # For Docker
```

---

### Plugins Show as Installed but Not Working

**Issue:** Plugins are installed but features not available

**Solution:**
1. Restart Jenkins: **Manage Jenkins** → **Restart Jenkins When Idle**
2. Check plugin dependencies: **Manage Jenkins** → **Manage Plugins** → Look for warnings
3. Update all plugins to latest versions

---

### Jenkins Won't Start After Plugin Installation

**Issue:** Jenkins fails to start or shows errors

**Solution:**
```bash
# Remove problematic plugin
cd $JENKINS_HOME/plugins
rm -rf <plugin-name>*

# Restart Jenkins
systemctl restart jenkins

# Check logs
tail -f /var/log/jenkins/jenkins.log
```

---

## 📚 Additional Resources

- **Jenkins Plugin Index:** https://plugins.jenkins.io/
- **AnsiColor Plugin:** https://plugins.jenkins.io/ansicolor/
- **Docker Pipeline Plugin:** https://plugins.jenkins.io/docker-workflow/
- **Kubernetes Plugin:** https://plugins.jenkins.io/kubernetes/
- **Blue Ocean:** https://plugins.jenkins.io/blueocean/

---

## ✅ Current Status

| Item | Status | Action Required |
|------|--------|-----------------|
| **Jenkinsfile Updated** | ✅ Fixed | None - Pipeline will work |
| **AnsiColor Plugin** | ⚠️ Optional | Install for colored output |
| **Core Plugins** | ⚠️ Check | Verify installation |
| **Pipeline Ready** | ✅ Yes | Run your pipeline! |

---

## 🎯 Recommended Next Steps

1. **Immediate:** Run your pipeline - it should work now ✅
2. **Soon:** Install AnsiColor plugin for better console visibility
3. **Later:** Review and install other recommended plugins for full functionality
4. **Optional:** Use Docker setup script for automated plugin installation

---

*Last Updated: October 15, 2025*  
*Related Files: [`Jenkinsfile`](Jenkinsfile), [`jenkins.yaml`](jenkins.yaml), [`setup-jenkins-docker.sh`](setup-jenkins-docker.sh)*
