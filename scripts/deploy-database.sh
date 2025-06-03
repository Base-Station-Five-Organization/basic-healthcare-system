#!/bin/bash

# Healthcare System Database Deployment Script
# Supports Oracle APEX Cloud and Autonomous Database
# Usage: ./deploy-database.sh [environment]

set -e

ENVIRONMENT=${1:-dev}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# Load environment configuration
load_config() {
    local config_file="${BASE_DIR}/config/${ENVIRONMENT}.env"
    
    if [[ -f "$config_file" ]]; then
        log "Loading configuration for environment: $ENVIRONMENT"
        source "$config_file"
    else
        error "Configuration file not found: $config_file"
    fi
    
    # Validate required environment variables
    required_vars=("DB_CONNECTION_STRING" "DB_USERNAME" "DB_PASSWORD")
    for var in "${required_vars[@]}"; do
        if [[ -z "${!var}" ]]; then
            error "Required environment variable $var is not set"
        fi
    done
}

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    # Check if sqlplus is available
    if ! command -v sqlplus &> /dev/null; then
        error "Oracle SQL*Plus is not installed or not in PATH"
    fi
    
    # Check if required directories exist
    if [[ ! -d "${BASE_DIR}/scripts/apex-cloud" ]]; then
        error "Scripts directory not found: ${BASE_DIR}/scripts/apex-cloud"
    fi
    
    success "Prerequisites check passed"
}

# Test database connectivity
test_connection() {
    log "Testing database connectivity..."
    
    local test_result
    test_result=$(sqlplus -s "${DB_USERNAME}/${DB_PASSWORD}@${DB_CONNECTION_STRING}" <<EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SET HEADING OFF
SELECT 'CONNECTION_SUCCESS' FROM dual;
EXIT;
EOF
)
    
    if [[ "$test_result" == *"CONNECTION_SUCCESS"* ]]; then
        success "Database connection successful"
    else
        error "Database connection failed"
    fi
}

# Execute SQL script with error handling
execute_sql_script() {
    local script_file="$1"
    local script_name="$(basename "$script_file")"
    
    log "Executing script: $script_name"
    
    # Create log file for this script execution
    local log_file="${BASE_DIR}/logs/deploy_${ENVIRONMENT}_$(date +'%Y%m%d_%H%M%S')_${script_name}.log"
    mkdir -p "$(dirname "$log_file")"
    
    # Execute the script
    local exit_code=0
    sqlplus "${DB_USERNAME}/${DB_PASSWORD}@${DB_CONNECTION_STRING}" @"$script_file" > "$log_file" 2>&1 || exit_code=$?
    
    # Check for errors in the log
    if [[ $exit_code -ne 0 ]] || grep -q "ORA-" "$log_file"; then
        error "Script execution failed: $script_name. Check log: $log_file"
    else
        success "Script executed successfully: $script_name"
    fi
}

# Deploy database schema
deploy_database() {
    log "Starting database deployment for environment: $ENVIRONMENT"
    
    # Array of scripts in execution order
    local scripts=(
        "01_run_first.sql"
        "02_run_second.sql"
        "03_run_third.sql"
        "04_run_fourth.sql"
        "05_run_fifth.sql"
        "06_run_sixth.sql"
        "07_run_seventh.sql"
        "08_run_eighth.sql"
        "09_run_final.sql"
    )
    
    # Execute scripts in order
    for script in "${scripts[@]}"; do
        local script_path="${BASE_DIR}/scripts/apex-cloud/$script"
        
        if [[ -f "$script_path" ]]; then
            execute_sql_script "$script_path"
        else
            warning "Script not found: $script_path"
        fi
    done
    
    success "Database deployment completed successfully"
}

# Verify deployment
verify_deployment() {
    log "Verifying deployment..."
    
    local verification_script="${BASE_DIR}/scripts/verify-deployment.sql"
    
    # Create verification script if it doesn't exist
    cat > "$verification_script" << 'EOF'
-- Deployment Verification Script
SET PAGESIZE 50
SET FEEDBACK ON
SET HEADING ON

PROMPT ===============================================
PROMPT Healthcare System Deployment Verification
PROMPT ===============================================

-- Check core tables
PROMPT Checking core tables...
SELECT table_name, num_rows 
FROM user_tables 
WHERE table_name IN ('PATIENTS', 'PROVIDERS', 'APPOINTMENTS', 'MEDICAL_RECORDS', 'PRESCRIPTIONS')
ORDER BY table_name;

-- Check clinical trials tables
PROMPT Checking clinical trials tables...
SELECT table_name, num_rows 
FROM user_tables 
WHERE table_name IN ('CLINICAL_TRIALS', 'TRIAL_PARTICIPANTS', 'ADVERSE_EVENTS', 'TRIAL_VISITS', 'TRIAL_MILESTONES')
ORDER BY table_name;

-- Check views
PROMPT Checking views...
SELECT view_name 
FROM user_views 
WHERE view_name LIKE 'V_%'
ORDER BY view_name;

-- Check sequences
PROMPT Checking sequences...
SELECT sequence_name, last_number 
FROM user_sequences 
ORDER BY sequence_name;

-- Check for invalid objects
PROMPT Checking for invalid objects...
SELECT object_type, object_name, status 
FROM user_objects 
WHERE status != 'VALID'
ORDER BY object_type, object_name;

PROMPT ===============================================
PROMPT Verification completed
PROMPT ===============================================
EOF
    
    execute_sql_script "$verification_script"
    success "Deployment verification completed"
}

# Backup current state (for production deployments)
backup_production() {
    if [[ "$ENVIRONMENT" == "production" ]]; then
        log "Creating production backup..."
        
        local backup_file="backup_${ENVIRONMENT}_$(date +'%Y%m%d_%H%M%S').sql"
        local backup_path="${BASE_DIR}/backups/$backup_file"
        
        mkdir -p "$(dirname "$backup_path")"
        
        # Export schema
        expdp "${DB_USERNAME}/${DB_PASSWORD}@${DB_CONNECTION_STRING}" \
            directory=DATA_PUMP_DIR \
            dumpfile="$backup_file" \
            schemas="$DB_USERNAME" \
            logfile="${backup_file%.sql}.log"
        
        success "Production backup created: $backup_path"
    fi
}

# Rollback function
rollback() {
    local backup_file="$1"
    
    if [[ -z "$backup_file" ]]; then
        error "Backup file not specified for rollback"
    fi
    
    warning "Starting rollback process..."
    
    # Import from backup
    impdp "${DB_USERNAME}/${DB_PASSWORD}@${DB_CONNECTION_STRING}" \
        directory=DATA_PUMP_DIR \
        dumpfile="$backup_file" \
        schemas="$DB_USERNAME" \
        table_exists_action=replace
    
    success "Rollback completed"
}

# Main execution
main() {
    log "Healthcare System Database Deployment"
    log "Environment: $ENVIRONMENT"
    log "Started at: $(date)"
    
    # Load configuration
    load_config
    
    # Check prerequisites
    check_prerequisites
    
    # Test database connection
    test_connection
    
    # Backup production before deployment
    if [[ "$ENVIRONMENT" == "production" ]]; then
        backup_production
    fi
    
    # Deploy database
    deploy_database
    
    # Verify deployment
    verify_deployment
    
    success "Healthcare System deployment completed successfully!"
    log "Deployment finished at: $(date)"
}

# Handle command line arguments
case "${1:-deploy}" in
    "deploy")
        main
        ;;
    "verify")
        load_config
        verify_deployment
        ;;
    "rollback")
        load_config
        rollback "$2"
        ;;
    "test")
        load_config
        test_connection
        ;;
    *)
        echo "Usage: $0 [deploy|verify|rollback|test] [environment]"
        echo "  deploy   - Deploy database schema (default)"
        echo "  verify   - Verify existing deployment"
        echo "  rollback - Rollback to backup file"
        echo "  test     - Test database connectivity"
        exit 1
        ;;
esac
