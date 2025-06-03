#!/usr/bin/env python3
"""
Pipeline Validation Script
Validates the Azure DevOps pipeline configuration and dependencies
"""

import os
import sys
import json
from pathlib import Path

def validate_pipeline_file():
    """Validate the Azure pipeline YAML file"""
    print("🔍 Validating azure-pipelines.yml...")
    
    pipeline_file = Path("azure-pipelines.yml")
    if not pipeline_file.exists():
        print("❌ azure-pipelines.yml not found")
        return False
    
    try:
        with open(pipeline_file, 'r') as f:
            content = f.read()
        
        # Basic validation checks
        required_sections = ['trigger', 'variables', 'stages']
        for section in required_sections:
            if section not in content:
                print(f"❌ Missing required section: {section}")
                return False
        
        # Check for required stages
        required_stages = ['PreflightChecks', 'Validate', 'Build']
        for stage in required_stages:
            if stage not in content:
                print(f"❌ Missing required stage: {stage}")
                return False
        
        print("✅ Pipeline file validation passed")
        return True
        
    except Exception as e:
        print(f"❌ Pipeline validation failed: {e}")
        return False

def validate_scripts():
    """Validate required scripts exist and are executable"""
    print("🔍 Validating deployment scripts...")
    
    required_scripts = [
        "scripts/deploy-database.sh",
        "scripts/deploy-apex.py", 
        "scripts/run-tests.py",
        "scripts/health-check.py",
        "scripts/backup-production.py"
    ]
    
    all_valid = True
    for script in required_scripts:
        script_path = Path(script)
        if not script_path.exists():
            print(f"❌ Missing script: {script}")
            all_valid = False
        elif not os.access(script_path, os.X_OK):
            print(f"⚠️ Script not executable: {script}")
            # Make it executable
            os.chmod(script_path, 0o755)
            print(f"✅ Made {script} executable")
    
    if all_valid:
        print("✅ All required scripts exist")
    
    return all_valid

def validate_config_files():
    """Validate configuration files exist"""
    print("🔍 Validating configuration files...")
    
    required_configs = [
        "config/dev.json",
        "config/staging.json", 
        "config/prod.json"
    ]
    
    all_valid = True
    for config in required_configs:
        config_path = Path(config)
        if not config_path.exists():
            print(f"❌ Missing config file: {config}")
            all_valid = False
        else:
            try:
                with open(config_path, 'r') as f:
                    json.load(f)
                print(f"✅ Valid JSON: {config}")
            except json.JSONDecodeError as e:
                print(f"❌ Invalid JSON in {config}: {e}")
                all_valid = False
    
    return all_valid

def validate_database_files():
    """Validate database schema files exist"""
    print("🔍 Validating database schema files...")
    
    required_files = [
        "database/schema/01_create_tables.sql",
        "database/schema/04_clinical_trials_tables.sql",
        "database/packages/pkg_patient_mgmt.sql",
        "database/packages/pkg_clinical_trials_mgmt.sql"
    ]
    
    all_valid = True
    for file_path in required_files:
        if not Path(file_path).exists():
            print(f"❌ Missing database file: {file_path}")
            all_valid = False
    
    if all_valid:
        print("✅ All required database files exist")
    
    return all_valid

def check_requirements():
    """Check if requirements.txt exists and is valid"""
    print("🔍 Checking requirements.txt...")
    
    req_file = Path("requirements.txt")
    if not req_file.exists():
        print("❌ requirements.txt not found")
        return False
    
    try:
        with open(req_file, 'r') as f:
            content = f.read()
        
        # Check for key dependencies
        required_deps = ['cx-Oracle', 'requests', 'sqlfluff']
        for dep in required_deps:
            if dep not in content:
                print(f"⚠️ Missing dependency: {dep}")
        
        print("✅ requirements.txt exists")
        return True
        
    except Exception as e:
        print(f"❌ Error reading requirements.txt: {e}")
        return False

def main():
    """Main validation function"""
    print("🚀 Healthcare System Pipeline Validation")
    print("=" * 50)
    
    validations = [
        ("Pipeline Configuration", validate_pipeline_file),
        ("Deployment Scripts", validate_scripts),
        ("Configuration Files", validate_config_files), 
        ("Database Schema Files", validate_database_files),
        ("Python Requirements", check_requirements)
    ]
    
    results = {}
    for name, validator in validations:
        print(f"\n📋 {name}")
        results[name] = validator()
    
    # Summary
    print("\n" + "=" * 50)
    print("📊 Validation Summary:")
    
    passed = sum(1 for result in results.values() if result)
    total = len(results)
    
    for name, result in results.items():
        status = "✅ PASS" if result else "❌ FAIL"
        print(f"  {name}: {status}")
    
    print(f"\nOverall: {passed}/{total} validations passed")
    
    if passed == total:
        print("🎉 All validations passed! Pipeline is ready for deployment.")
        return True
    else:
        print("💥 Some validations failed. Please fix the issues before running the pipeline.")
        return False

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
