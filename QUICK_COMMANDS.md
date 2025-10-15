# Quick Command Reference

**Essential commands used in this Copilot session for future debugging**

## Helm Validation Commands
```bash
# Quick chart validation
cd /deployment/helm && helm lint java-microservice

# Test specific template
helm template test java-microservice --show-only templates/backend-deployment.yaml

# Test all environments
helm template test-dev java-microservice -f java-microservice/values-dev.yaml
helm template test-staging java-microservice -f java-microservice/values-staging.yaml  
helm template test-prod java-microservice -f java-microservice/values-prod.yaml

# Debug mode
helm template test java-microservice --debug
```

## Port Debugging
```bash
# Check port configurations
helm template test java-microservice | grep -A5 -B5 "containerPort\|port:"

# Analyze health check ports  
helm template test java-microservice | grep -A10 "livenessProbe\|readinessProbe"
```

## File Structure
```bash
# List templates
ls -la deployment/helm/java-microservice/templates/

# Check for duplicates
ls -la deployment/helm/java-microservice/templates/*-original* 2>/dev/null || echo "Clean"
```

## Issues Fixed
1. **Port Conflict**: Changed management port from 8080 to 9090
2. **Health Checks**: Updated probe ports to 9090  
3. **Duplicate Files**: Removed *-original.yaml files
4. **Template Validation**: All environments now working

**See [copilot-session-debug-commands.md](copilot-session-debug-commands.md) for complete details**