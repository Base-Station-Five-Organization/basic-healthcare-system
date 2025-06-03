# Azure DevOps Pipeline Troubleshooting Guide

## Healthcare Management System CI/CD Pipeline

This guide helps resolve common issues with the Azure DevOps pipeline for the Healthcare Management System.

## 🚨 Quick Fixes for Common Errors

### 1. **Pipeline Fails to Start**

#### Error Messages:

- "Variable group 'healthcare-system-variables' not found"
- "Pipeline template not found"

#### Solutions:

```bash
# Check variable group exists
az pipelines variable-group list --organization https://dev.azure.com/YourOrg --project YourProject

# Create variable group if missing
az pipelines variable-group create \
  --name healthcare-system-variables \
  --variables APEX_WORKSPACE=HEALTHCARE_DEV \
  --organization https://dev.azure.com/YourOrg \
  --project YourProject
```

### 2. **Oracle Cloud CLI Task Fails**

#### Error Messages:

- "Task 'OracleCloudInfrastructureCLI@1' not found"
- "OCI authentication failed"

#### Solutions:

1. **Install Oracle Cloud Infrastructure Extension**:

   - Go to Azure DevOps Marketplace
   - Search for "Oracle Cloud Infrastructure"
   - Install the extension

2. **Configure Service Connection**:

   ```yaml
   # In Project Settings > Service Connections
   Name: OCI-Dev
   Type: Oracle Cloud Infrastructure
   Authentication: API Key
   ```

3. **Verify Credentials**:
   ```bash
   # Test OCI CLI locally
   oci iam user get --user-id <your-user-ocid>
   ```

### 3. **SQL Linting Failures**

#### Error Messages:

- "sqlfluff command not found"
- "SQL syntax errors detected"

#### Solutions:

```yaml
# Fix in pipeline - add error handling
- script: |
    pip install sqlfluff || echo "Failed to install sqlfluff"
    # Continue with best effort linting
    find database/ -name "*.sql" -exec sqlfluff lint {} \; || true
  displayName: "SQL Linting (Best Effort)"
```

### 4. **Database Deployment Fails**

#### Error Messages:

- "ORA-12154: TNS:could not resolve the connect identifier"
- "ORA-01017: invalid username/password"

#### Solutions:

1. **Check Connection String Format**:

   ```bash
   # Correct format examples:
   DB_CONNECTION_STRING="hostname:1521/service_name"
   DB_CONNECTION_STRING="(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=hostname)(PORT=1521))(CONNECT_DATA=(SERVICE_NAME=service_name)))"
   ```

2. **Validate Credentials**:

   ```bash
   # Test connection locally
   sqlplus ${DB_USERNAME}/${DB_PASSWORD}@${DB_CONNECTION_STRING}
   ```

3. **Network Connectivity**:
   ```bash
   # Test network connectivity
   telnet hostname 1521
   ```

### 5. **APEX Deployment Issues**

#### Error Messages:

- "APEX workspace not found"
- "Application import failed"

#### Solutions:

1. **Verify APEX Workspace**:

   ```sql
   -- Check workspace exists
   SELECT workspace_name FROM apex_workspaces
   WHERE workspace_name = 'HEALTHCARE_DEV';
   ```

2. **Check User Permissions**:
   ```sql
   -- Verify user has developer role
   SELECT username, developer_role FROM apex_workspace_apex_users
   WHERE workspace_name = 'HEALTHCARE_DEV';
   ```

## 🔧 Environment-Specific Issues

### Development Environment

```yaml
# Common dev issues in azure-pipelines.yml
variables:
  - name: targetEnvironment
    value: "dev"

# Add debugging
- script: |
    echo "Environment: $(targetEnvironment)"
    echo "Variables available:"
    env | grep -E "(APEX|DB)" | sort
  displayName: "Debug Environment Variables"
```

### Staging Environment

```yaml
# Staging-specific validations
- script: |
    echo "Running staging validations..."
    # Check if staging database is accessible
    python3 scripts/health-check.py --environment staging --quick-check
  displayName: "Staging Environment Validation"
```

### Production Environment

```yaml
# Production safety checks
- script: |
    echo "Production deployment safety checks..."
    # Verify backup exists
    if [ ! -f "backup_$(date +%Y%m%d).sql" ]; then
      echo "ERROR: No recent backup found for production deployment"
      exit 1
    fi
  displayName: "Production Safety Checks"
```

## 📋 Variable Group Configuration

### Required Variables

| Variable Name          | Description             | Example Value                    | Secret  |
| ---------------------- | ----------------------- | -------------------------------- | ------- |
| `APEX_WORKSPACE`       | APEX workspace name     | `HEALTHCARE_DEV`                 | No      |
| `APEX_USERNAME`        | APEX developer username | `apex_dev_user`                  | No      |
| `APEX_PASSWORD`        | APEX user password      | `SecurePass123!`                 | **Yes** |
| `DB_CONNECTION_STRING` | Database connection     | `host:1521/service`              | No      |
| `DB_USERNAME`          | Database username       | `healthcare_user`                | No      |
| `DB_PASSWORD`          | Database password       | `DbPass123!`                     | **Yes** |
| `OCI_CLI_USER`         | OCI user OCID           | `ocid1.user.oc1...`              | No      |
| `OCI_CLI_TENANCY`      | OCI tenancy OCID        | `ocid1.tenancy.oc1...`           | No      |
| `OCI_CLI_FINGERPRINT`  | API key fingerprint     | `aa:bb:cc:dd:...`                | No      |
| `OCI_CLI_KEY_CONTENT`  | Private key content     | `-----BEGIN PRIVATE KEY-----...` | **Yes** |
| `OCI_CLI_REGION`       | OCI region              | `us-ashburn-1`                   | No      |

### Creating Variable Groups

```bash
# Using Azure CLI
az pipelines variable-group create \
  --name healthcare-system-variables \
  --variables \
    APEX_WORKSPACE=HEALTHCARE_DEV \
    APEX_USERNAME=apex_dev_user \
    DB_CONNECTION_STRING=myhost:1521/xe \
    DB_USERNAME=healthcare_user \
  --organization https://dev.azure.com/YourOrg \
  --project YourProject

# Add secret variables separately
az pipelines variable-group variable create \
  --group-id <group-id> \
  --name APEX_PASSWORD \
  --value "SecurePass123!" \
  --secret true
```

## 🔍 Debugging Steps

### 1. Enable Verbose Logging

```yaml
# Add to any script step
- script: |
    set -x  # Enable bash debugging
    echo "Starting deployment step..."
    # Your deployment commands here
  displayName: "Deploy with Verbose Logging"
```

### 2. Artifact Inspection

```yaml
# Add artifact inspection step
- script: |
    echo "Inspecting build artifacts..."
    find $(Pipeline.Workspace) -type f -name "*.sql" | head -20
    ls -la $(Pipeline.Workspace)/healthcare-system/
  displayName: "Inspect Artifacts"
```

### 3. Network Connectivity Tests

```yaml
# Add network tests
- script: |
    echo "Testing network connectivity..."
    # Test database connectivity
    nc -zv hostname 1521
    # Test APEX connectivity
    curl -I https://apex.oracle.com/pls/apex/
  displayName: "Network Connectivity Tests"
```

## 🚀 Performance Optimization

### Parallel Jobs

```yaml
# Enable parallel execution where possible
jobs:
  - job: DatabaseDeploy
    # ...
  - job: APEXDeploy
    dependsOn: DatabaseDeploy
    # ...
  - job: TestExecution
    dependsOn: DatabaseDeploy
    # Run tests in parallel with APEX deployment
```

### Caching

```yaml
# Cache dependencies
- task: Cache@2
  inputs:
    key: 'python | "$(Agent.OS)" | requirements.txt'
    restoreKeys: |
      python | "$(Agent.OS)"
    path: $(Pipeline.Workspace)/.pip
  displayName: "Cache pip packages"
```

## 📞 Getting Help

### Azure DevOps Logs

1. Go to Pipeline run
2. Click on failed job
3. Review logs in detail
4. Look for specific error messages

### Local Testing

```bash
# Test scripts locally before pipeline run
cd /path/to/repository
python3 scripts/deploy-apex.py --environment dev --dry-run
bash scripts/deploy-database.sh dev --validate-only
```

### Support Contacts

- **Pipeline Issues**: DevOps Team
- **Database Issues**: DBA Team
- **APEX Issues**: Application Development Team
- **Oracle Cloud Issues**: Cloud Infrastructure Team

## 📚 Additional Resources

- [Azure DevOps Documentation](https://docs.microsoft.com/en-us/azure/devops/)
- [Oracle APEX Documentation](https://docs.oracle.com/en/database/oracle/application-express/)
- [Oracle Cloud Infrastructure CLI](https://docs.oracle.com/en-us/iaas/tools/oci-cli/)
- [Healthcare System Documentation](../installation/INSTALLATION.md)
