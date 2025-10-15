# Copilot Session Debug Commands Reference

**Session Date**: October 15, 2025  
**Project**: Full-Stack DevOps Transformation with Helm Deployment Fixes  
**Context**: Complete transformation from basic setup to production-ready full-stack application

## Table of Contents
1. [Initial Assessment](#initial-assessment)
2. [Deployment Cleanup](#deployment-cleanup)
3. [Template Validation](#template-validation)
4. [Error Detection & Fixes](#error-detection--fixes)
5. [Final Validation](#final-validation)
6. [Quick Reference](#quick-reference)

---

## Initial Assessment

### Check Current Project Structure
```bash
# Purpose: Understand the existing workspace structure
# Context: Initial assessment of deployment configuration
list_dir /home/gaurav/my_Hands_On_Projects/deployment/helm/java-microservice
```
**Result**: Found duplicate files (*-original.yaml) that needed cleanup

### Validate Existing Templates
```bash
# Purpose: Check if current Helm templates have syntax errors
# Context: Baseline validation before making changes
cd /home/gaurav/my_Hands_On_Projects/deployment/helm
helm lint java-microservice
```
**Result**: 1 chart(s) linted, 0 chart(s) failed (initial validation passed)

---

## Deployment Cleanup

### Remove Duplicate Files
```bash
# Purpose: Clean up duplicate *-original.yaml files causing confusion
# Context: User reported multiple files in deployment folder
cd /home/gaurav/my_Hands_On_Projects/deployment/helm/java-microservice/templates
rm -f *-original.yaml
```
**Result**: Removed all duplicate files, leaving only working versions

### Verify Clean Structure
```bash
# Purpose: Confirm cleanup was successful
# Context: Post-cleanup verification
list_dir /home/gaurav/my_Hands_On_Projects/deployment/helm/java-microservice/templates
```
**Result**: Clean directory with 10 template files (no duplicates)

---

## Template Validation

### Test Default Values
```bash
# Purpose: Validate templates render correctly with default configuration
# Context: Ensure templates work after cleanup
cd /home/gaurav/my_Hands_On_Projects/deployment/helm
helm template test java-microservice --debug > /dev/null 2>&1 && echo "✅ All templates valid" || echo "❌ Template errors"
```
**Result**: ✅ All templates valid

### Test Multi-Environment Support
```bash
# Purpose: Validate environment-specific configurations work
# Context: Production readiness check across all environments

# Development environment
helm template test-dev java-microservice -f java-microservice/values-dev.yaml --debug > /dev/null 2>&1 && echo "✅ Development values valid" || echo "❌ Development values errors"

# Staging environment  
helm template test-staging java-microservice -f java-microservice/values-staging.yaml --debug > /dev/null 2>&1 && echo "✅ Staging values valid" || echo "❌ Staging values errors"

# Production environment
helm template test-prod java-microservice -f java-microservice/values-prod.yaml --debug > /dev/null 2>&1 && echo "✅ Production values valid" || echo "❌ Production values errors"
```
**Result**: ✅ All environments validated successfully

---

## Error Detection & Fixes

### Backend Deployment Analysis
```bash
# Purpose: Check for YAML syntax errors in backend deployment
# Context: User reported YAML errors in backend-deployment.yaml
cd /home/gaurav/my_Hands_On_Projects/deployment/helm/java-microservice
yamllint templates/backend-deployment.yaml 2>/dev/null || echo "Checking with Helm template validation..."
```
**Result**: Detected need for Helm-specific validation

### Render Specific Template for Debugging
```bash
# Purpose: Isolate backend deployment template to identify specific issues
# Context: Troubleshooting reported YAML errors
cd /home/gaurav/my_Hands_On_Projects/deployment/helm
helm template test java-microservice --show-only templates/backend-deployment.yaml --debug 2>&1 | head -50
```
**Result**: Identified port conflict - both application and management using port 8080

### Analyze Port Configuration
```bash
# Purpose: Examine rendered template to understand port conflicts
# Context: Debugging port configuration issues
cd /home/gaurav/my_Hands_On_Projects/deployment/helm
helm template test java-microservice --show-only templates/backend-deployment.yaml --debug 2>&1 | grep -A5 -B5 "containerPort\|management" | head -20
```
**Result**: Confirmed duplicate port 8080 usage causing conflicts

### Validate Helper Functions
```bash
# Purpose: Check if template helper functions are working correctly
# Context: Ensuring _helpers.tpl functions render properly
grep_search --query="java-microservice.targetPort" --isRegexp=false --includePattern="deployment/helm/java-microservice/templates/_helpers.tpl"
```
**Result**: Found targetPort helper function, confirmed it defaults to 8080

---

## Error Fixes Applied

### Fix Port Conflict
```yaml
# Purpose: Resolve duplicate port 8080 usage
# Context: Separate application traffic from management endpoints
# Command: replace_string_in_file (via Copilot tools)

# BEFORE (Port Conflict):
ports:
  - name: http
    containerPort: 8080    # Application port
  - name: management  
    containerPort: 8080    # Management port (CONFLICT!)

# AFTER (Fixed):  
ports:
  - name: http
    containerPort: 8080    # Application port
  - name: management
    containerPort: 9090    # Management port (RESOLVED!)
```

### Fix Health Check Configuration
```yaml
# Purpose: Update health checks to use correct management port
# Context: Health checks were pointing to old port after management port change
# Command: replace_string_in_file (via Copilot tools)

# BEFORE (Incorrect Port):
healthcheck:
  livenessProbe:
    httpGet:
      path: /actuator/health/liveness
      port: 8080  # Wrong port!
  readinessProbe:
    httpGet:  
      path: /actuator/health/readiness
      port: 8080  # Wrong port!

# AFTER (Correct Port):
healthcheck:
  livenessProbe:
    httpGet:
      path: /actuator/health/liveness  
      port: 9090  # Correct management port!
  readinessProbe:
    httpGet:
      path: /actuator/health/readiness
      port: 9090  # Correct management port!
```

---

## Final Validation

### Validate Backend Template After Fixes
```bash
# Purpose: Confirm backend deployment template works after port fixes
# Context: Post-fix validation
cd /home/gaurav/my_Hands_On_Projects/deployment/helm
helm template test java-microservice --show-only templates/backend-deployment.yaml --debug > /dev/null 2>&1 && echo "✅ Backend deployment template valid" || echo "❌ Backend deployment template errors"
```
**Result**: ✅ Backend deployment template valid

### Complete Chart Validation
```bash
# Purpose: Ensure all templates work together after changes
# Context: Comprehensive validation of entire Helm chart
cd /home/gaurav/my_Hands_On_Projects/deployment/helm
helm lint java-microservice && echo "✅ Complete chart validation successful"
```
**Result**: ✅ 1 chart(s) linted, 0 chart(s) failed

### Verify Port Configuration
```bash
# Purpose: Confirm correct port configuration in rendered templates
# Context: Final verification of port fix
cd /home/gaurav/my_Hands_On_Projects/deployment/helm
helm template test java-microservice --show-only templates/backend-deployment.yaml | grep -A15 "ports:" | head -20
```
**Result**: Confirmed port 8080 (app) and port 9090 (management) correctly configured

### Verify Health Check Configuration  
```bash
# Purpose: Confirm health checks use correct management port
# Context: Final verification of health check fix
cd /home/gaurav/my_Hands_On_Projects/deployment/helm
helm template test java-microservice --show-only templates/backend-deployment.yaml | grep -A10 -B2 "livenessProbe\|readinessProbe"
```
**Result**: Confirmed health checks correctly use port 9090

---

## Quick Reference

### Essential Debug Commands

#### Template Validation
```bash
# Quick chart lint
helm lint java-microservice

# Render specific template  
helm template test java-microservice --show-only templates/[TEMPLATE-NAME].yaml

# Test with specific values file
helm template test java-microservice -f java-microservice/values-[ENV].yaml

# Debug mode with full output
helm template test java-microservice --debug
```

#### Port Analysis
```bash
# Check port configurations
helm template test java-microservice | grep -A5 -B5 "containerPort\|port:"

# Analyze health check ports
helm template test java-microservice | grep -A10 "livenessProbe\|readinessProbe"
```

#### File Structure Debugging
```bash
# List template files
ls -la /deployment/helm/java-microservice/templates/

# Check for duplicate files
ls -la /deployment/helm/java-microservice/templates/*-original* 2>/dev/null || echo "No duplicates found"

# Validate helper functions
grep -n "define.*java-microservice" /deployment/helm/java-microservice/templates/_helpers.tpl
```

### Common Issues & Solutions

| Issue | Symptoms | Debug Command | Solution |
|-------|----------|---------------|----------|
| Port Conflicts | Duplicate containerPort values | `grep -r "containerPort.*8080"` | Use different ports for app vs management |
| Template Errors | Helm template fails | `helm template --debug` | Check helper function syntax |
| Health Check Issues | Probes fail after port changes | `grep -A5 "livenessProbe"` | Update probe ports to match container ports |
| Duplicate Files | Confusion in templates dir | `ls -la templates/` | Remove *-original.yaml files |
| Environment Issues | Values file errors | `helm template -f values-[env].yaml` | Validate environment-specific configs |

### Architecture Summary

**Final Working Configuration:**
- **Application Port**: 8080 (HTTP traffic, Spring Boot app)
- **Management Port**: 9090 (Health checks, metrics, actuator endpoints)  
- **Service Mapping**: External port 80 → Internal port 8080
- **Health Checks**: Target port 9090 for all probes
- **Multi-Environment**: Separate values files for dev/staging/prod

### Validation Checklist

- [ ] `helm lint` passes with 0 errors
- [ ] All environment values files render correctly  
- [ ] No duplicate containerPort definitions
- [ ] Health checks use management port (9090)
- [ ] Service targetPort matches application port (8080)
- [ ] No duplicate template files in templates/ directory
- [ ] Template helper functions work correctly

---

## Troubleshooting Tips

1. **Always test with `helm template` before deploying**
2. **Use `--debug` flag for detailed error information**
3. **Check both template syntax AND values file compatibility**  
4. **Validate across ALL environment configurations (dev/staging/prod)**
5. **Separate application ports from management/health check ports**
6. **Remove any duplicate or backup files that could cause confusion**

---

**Generated**: October 15, 2025  
**Session Type**: Copilot Full-Stack Transformation & Debug  
**Status**: ✅ Complete - All templates validated and production-ready