# DevOps Implementation Guide

## Healthcare Management System with Clinical Trials

This guide provides comprehensive instructions for implementing a DevOps pipeline for the Oracle APEX Healthcare Management System.

## 🚀 Overview

The DevOps pipeline automates:

- **Code Quality Checks**: SQL linting, security scanning, documentation validation
- **Database Testing**: Schema validation, dependency checking, data integrity tests
- **Automated Deployment**: Multi-environment deployment with rollback capabilities
- **Application Testing**: Smoke tests, integration tests, health checks
- **Monitoring & Alerts**: Post-deployment monitoring and notifications

## 📁 DevOps Structure

```
basic-healthcare-system/
├── .github/workflows/
│   └── ci-cd-pipeline.yml          # GitHub Actions pipeline
├── azure-pipelines.yml             # Azure DevOps pipeline
├── docker-compose.yml              # Local development/testing
├── config/                         # Environment configurations
│   ├── dev.json                    # Development environment
│   ├── staging.json                # Staging environment
│   └── prod.json                   # Production environment
├── scripts/
│   ├── deploy-database.sh          # Database deployment script
│   ├── deploy-apex.py              # APEX application deployment
│   ├── run-tests.py                # Comprehensive test suite
│   └── health-check.py             # System health monitoring
└── docs/devops/
    └── DEVOPS_GUIDE.md             # This guide
```

## 🔧 Setup Instructions

### 1. GitHub Actions Setup

1. **Fork/Clone Repository**

   ```bash
   git clone https://github.com/your-org/basic-healthcare-system.git
   cd basic-healthcare-system
   ```

2. **Configure Secrets**
   Go to Repository Settings > Secrets and add:

   ```
   # Oracle Cloud Infrastructure
   OCI_CLI_USER=ocid1.user.oc1...[your-user-ocid]
   OCI_CLI_TENANCY=ocid1.tenancy.oc1...[your-tenancy-ocid]
   OCI_CLI_FINGERPRINT=[your-api-key-fingerprint]
   OCI_CLI_KEY_CONTENT=[your-private-key-content]
   OCI_CLI_REGION=us-ashburn-1

   # APEX Configuration
   APEX_WORKSPACE=BASESTATIONFIVE
   APEX_USERNAME=[your-apex-username]
   APEX_PASSWORD=[your-apex-password]

   # Database Configuration
   DB_CONNECTION_STRING=[your-db-connection-string]
   DB_USERNAME=[your-db-username]
   DB_PASSWORD=[your-db-password]
   ```

3. **Enable Actions**
   - Go to Actions tab in your repository
   - Enable GitHub Actions if not already enabled
   - The pipeline will trigger on pushes to main/develop branches

### 2. Azure DevOps Setup

1. **Create Project**

   - Create new Azure DevOps project
   - Import repository or connect to GitHub

2. **Configure Variable Groups**

   ```
   Group: healthcare-system-variables
   Variables:
   - APEX_WORKSPACE: BASESTATIONFIVE
   - APEX_USERNAME: [your-username]
   - APEX_PASSWORD: [your-password] (mark as secret)
   - DB_CONNECTION_STRING: [connection-string] (mark as secret)
   ```

3. **Setup Service Connections**
   - Oracle Cloud Infrastructure connection
   - Azure subscription (if using Azure resources)

### 3. Local Development Setup

1. **Install Dependencies**

   ```bash
   # Install Oracle Instant Client
   # macOS with Homebrew
   brew install oracle/instantclient/instantclient-basic

   # Install Python dependencies
   pip install cx_Oracle requests sqlfluff
   ```

2. **Setup Environment**

   ```bash
   # Copy sample configuration
   cp config/dev.json.sample config/dev.json

   # Edit configuration with your settings
   vim config/dev.json
   ```

3. **Test Local Deployment**

   ```bash
   # Make scripts executable
   chmod +x scripts/deploy-database.sh
   chmod +x scripts/deploy-apex.py
   chmod +x scripts/run-tests.py

   # Test database deployment
   ./scripts/deploy-database.sh dev

   # Run test suite
   python scripts/run-tests.py --environment dev
   ```

## 🏗 Pipeline Stages

### Stage 1: Code Quality & Security

- **SQL Linting**: Validates SQL syntax and style
- **Security Scanning**: Checks for sensitive data exposure
- **Documentation Check**: Ensures required documentation exists

### Stage 2: Database Testing

- **Schema Validation**: Validates SQL syntax against Oracle database
- **Dependency Check**: Verifies foreign key relationships and dependencies
- **Integration Tests**: Tests database objects and relationships

### Stage 3: Build & Package

- **Artifact Creation**: Packages deployment scripts and configurations
- **Version Management**: Tags builds with Git commit information
- **Checksum Generation**: Creates integrity checksums for all artifacts

### Stage 4: Deploy to Development

- **Automated Deployment**: Runs all 9 installation scripts in order
- **APEX Application Setup**: Creates or updates APEX application
- **Smoke Tests**: Basic functionality and connectivity tests

### Stage 5: Deploy to Staging

- **Environment Promotion**: Deploys tested artifacts to staging
- **Integration Tests**: Comprehensive testing of all features
- **User Acceptance Testing**: Automated UAT scenarios

### Stage 6: Deploy to Production

- **Production Backup**: Creates full backup before deployment
- **Blue-Green Deployment**: Zero-downtime deployment strategy
- **Health Checks**: Comprehensive post-deployment validation
- **Rollback Plan**: Automated rollback if issues detected

## 🔄 Deployment Environments

### Development Environment

- **Purpose**: Feature development and initial testing
- **Auto-Deploy**: Yes (on develop branch)
- **Data**: Sample/test data only
- **Backup**: Not required

### Staging Environment

- **Purpose**: Pre-production testing and validation
- **Auto-Deploy**: Yes (on main branch)
- **Data**: Sanitized production-like data
- **Backup**: Required before deployment

### Production Environment

- **Purpose**: Live healthcare system
- **Auto-Deploy**: Manual approval required
- **Data**: Real patient data (HIPAA compliant)
- **Backup**: Required with rollback plan

## 📊 Monitoring & Observability

### Health Checks

```python
# Example health check endpoints
GET /health/database     # Database connectivity
GET /health/apex        # APEX application status
GET /health/clinical    # Clinical trials functionality
```

### Key Metrics

- **Database Performance**: Query response times, connection pool status
- **Application Availability**: APEX page load times, error rates
- **Business Metrics**: Patient registrations, appointment bookings, trial enrollments

### Alerting

- **Critical**: Database down, application inaccessible
- **Warning**: Performance degradation, high error rates
- **Info**: Successful deployments, scheduled maintenance

## 🔐 Security Considerations

### Secrets Management

- Use environment-specific secret stores
- Rotate credentials regularly
- Never commit secrets to version control

### Database Security

- Use least-privilege database accounts
- Enable audit logging for all environments
- Encrypt sensitive data at rest and in transit

### HIPAA Compliance

- Ensure audit trails for all data access
- Implement proper access controls
- Regular security assessments

## 🚨 Incident Response

### Deployment Failures

1. **Automatic Rollback**: Triggered on health check failures
2. **Manual Rollback**: Use rollback scripts for manual intervention
3. **Root Cause Analysis**: Examine logs and metrics

### Production Issues

1. **Immediate Response**: Use rollback to last known good state
2. **Communication**: Notify stakeholders via automated alerts
3. **Post-Incident**: Conduct blameless post-mortems

## 🧪 Testing Strategy

### Unit Tests

- Database function tests
- PL/SQL package validation
- View query validation

### Integration Tests

- End-to-end user workflows
- API integration testing
- Cross-module functionality

### Performance Tests

- Database query performance
- APEX page load times
- Concurrent user scenarios

### Security Tests

- SQL injection testing
- Authentication bypass attempts
- Authorization validation

## 📈 Continuous Improvement

### Metrics Collection

- Deployment frequency
- Lead time for changes
- Mean time to recovery (MTTR)
- Change failure rate

### Optimization Areas

- Build time reduction
- Test execution speed
- Deployment automation
- Monitoring coverage

## 🔧 Troubleshooting

### Common Issues

#### Pipeline Failures

```bash
# Check logs
cat logs/deploy_dev_20250603_140530_01_run_first.sql.log

# Validate configuration
python scripts/validate-config.py --environment dev

# Test connectivity
./scripts/deploy-database.sh test
```

#### Database Issues

```sql
-- Check for invalid objects
SELECT object_name, object_type, status
FROM user_objects
WHERE status != 'VALID';

-- Verify foreign keys
SELECT constraint_name, table_name, r_constraint_name
FROM user_constraints
WHERE constraint_type = 'R' AND status != 'ENABLED';
```

#### APEX Issues

```bash
# Test APEX connectivity
python scripts/deploy-apex.py --dry-run --environment dev

# Check application status
curl -I https://apex.oracle.com/pls/apex/f?p=APPLICATION_ID
```

## 📞 Support

### Documentation

- [Installation Guide](../installation/INSTALLATION.md)
- [APEX Cloud Setup](../installation/APEX_CLOUD_SETUP.md)
- [Clinical Trials User Guide](../user-guide/clinical_trials_user_guide.md)

### Getting Help

1. Check troubleshooting section above
2. Review pipeline logs in your CI/CD platform
3. Consult Oracle APEX documentation
4. Contact your Oracle administrator

### Best Practices

- Test all changes in development first
- Use feature branches for new development
- Monitor deployment metrics
- Regular backup validation
- Keep documentation updated

---

## 🎯 Next Steps

1. **Setup Your Pipeline**: Choose GitHub Actions or Azure DevOps
2. **Configure Environments**: Set up dev, staging, and production
3. **Test Deployment**: Run a complete deployment cycle
4. **Monitor & Optimize**: Set up monitoring and continuous improvement

This DevOps implementation provides a robust, automated approach to managing your healthcare system deployment while maintaining the security and compliance requirements for healthcare applications.
