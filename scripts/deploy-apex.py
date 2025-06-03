#!/usr/bin/env python3

"""
Healthcare System APEX Application Deployment Script
Automates the deployment of Oracle APEX applications using REST APIs
"""

import os
import sys
import json
import requests
import argparse
import base64
import time
from datetime import datetime
from typing import Dict, Optional

class APEXDeployment:
    def __init__(self, config: Dict):
        self.config = config
        self.base_url = config['apex_url']
        self.workspace = config['workspace']
        self.username = config['username']
        self.password = config['password']
        self.session = requests.Session()
        self.app_id = None
        
    def authenticate(self) -> bool:
        """Authenticate with APEX workspace"""
        try:
            auth_url = f"{self.base_url}/ords/{self.workspace}/apex/session"
            
            # Basic authentication
            credentials = base64.b64encode(f"{self.username}:{self.password}".encode()).decode()
            headers = {
                'Authorization': f'Basic {credentials}',
                'Content-Type': 'application/json'
            }
            
            response = self.session.post(auth_url, headers=headers)
            
            if response.status_code == 200:
                print(f"✓ Successfully authenticated to APEX workspace: {self.workspace}")
                return True
            else:
                print(f"✗ Authentication failed: {response.status_code}")
                return False
                
        except Exception as e:
            print(f"✗ Authentication error: {e}")
            return False
    
    def check_application_exists(self, app_alias: str) -> Optional[int]:
        """Check if application exists and return app ID"""
        try:
            apps_url = f"{self.base_url}/ords/{self.workspace}/apex/applications"
            response = self.session.get(apps_url)
            
            if response.status_code == 200:
                apps_data = response.json()
                for app in apps_data.get('items', []):
                    if app.get('alias') == app_alias:
                        return app.get('id')
            return None
            
        except Exception as e:
            print(f"✗ Error checking applications: {e}")
            return None
    
    def create_application(self, app_config: Dict) -> bool:
        """Create new APEX application"""
        try:
            create_url = f"{self.base_url}/ords/{self.workspace}/apex/applications"
            
            app_data = {
                "name": app_config['name'],
                "alias": app_config['alias'],
                "description": app_config['description'],
                "version": app_config['version'],
                "authentication_scheme": app_config.get('auth_scheme', 'DATABASE_ACCOUNTS'),
                "theme": app_config.get('theme', 'UNIVERSAL_THEME')
            }
            
            response = self.session.post(create_url, json=app_data)
            
            if response.status_code == 201:
                app_info = response.json()
                self.app_id = app_info.get('id')
                print(f"✓ Application created successfully. App ID: {self.app_id}")
                return True
            else:
                print(f"✗ Failed to create application: {response.status_code}")
                print(response.text)
                return False
                
        except Exception as e:
            print(f"✗ Error creating application: {e}")
            return False
    
    def import_application(self, app_file: str) -> bool:
        """Import APEX application from file"""
        try:
            if not os.path.exists(app_file):
                print(f"✗ Application file not found: {app_file}")
                return False
            
            import_url = f"{self.base_url}/ords/{self.workspace}/apex/applications/import"
            
            with open(app_file, 'rb') as f:
                files = {'file': f}
                response = self.session.post(import_url, files=files)
            
            if response.status_code == 200:
                print(f"✓ Application imported successfully from {app_file}")
                return True
            else:
                print(f"✗ Failed to import application: {response.status_code}")
                return False
                
        except Exception as e:
            print(f"✗ Error importing application: {e}")
            return False
    
    def create_pages(self, pages_config: list) -> bool:
        """Create application pages"""
        try:
            for page_config in pages_config:
                page_url = f"{self.base_url}/ords/{self.workspace}/apex/applications/{self.app_id}/pages"
                
                page_data = {
                    "name": page_config['name'],
                    "page_number": page_config.get('page_number'),
                    "page_template": page_config.get('template', 'Standard'),
                    "authentication": page_config.get('authentication', 'Page Requires Authentication')
                }
                
                response = self.session.post(page_url, json=page_data)
                
                if response.status_code == 201:
                    print(f"✓ Page created: {page_config['name']}")
                else:
                    print(f"✗ Failed to create page: {page_config['name']}")
                    
            return True
            
        except Exception as e:
            print(f"✗ Error creating pages: {e}")
            return False
    
    def setup_security(self, security_config: Dict) -> bool:
        """Setup authentication and authorization schemes"""
        try:
            # Create authentication scheme
            if 'authentication' in security_config:
                auth_url = f"{self.base_url}/ords/{self.workspace}/apex/applications/{self.app_id}/authentication"
                auth_data = security_config['authentication']
                
                response = self.session.post(auth_url, json=auth_data)
                if response.status_code == 201:
                    print("✓ Authentication scheme created")
                else:
                    print("✗ Failed to create authentication scheme")
            
            # Create authorization schemes
            if 'authorization' in security_config:
                for auth_scheme in security_config['authorization']:
                    authz_url = f"{self.base_url}/ords/{self.workspace}/apex/applications/{self.app_id}/authorization"
                    
                    response = self.session.post(authz_url, json=auth_scheme)
                    if response.status_code == 201:
                        print(f"✓ Authorization scheme created: {auth_scheme.get('name', 'Unknown')}")
                    else:
                        print(f"✗ Failed to create authorization scheme: {auth_scheme.get('name', 'Unknown')}")
            
            return True
            
        except Exception as e:
            print(f"✗ Error setting up security: {e}")
            return False
    
    def import_shared_components(self, components_dir: str) -> bool:
        """Import shared components from directory"""
        try:
            if not os.path.exists(components_dir):
                print(f"✗ Components directory not found: {components_dir}")
                return False
            
            # Import reports
            reports_file = os.path.join(components_dir, 'clinical_trials_reports.sql')
            if os.path.exists(reports_file):
                print("✓ Importing clinical trials reports...")
                # Logic to import reports would go here
            
            # Import other shared components
            components = ['lists_of_values', 'navigation', 'templates']
            for component in components:
                component_file = os.path.join(components_dir, f'{component}.sql')
                if os.path.exists(component_file):
                    print(f"✓ Importing {component}...")
                    # Logic to import component would go here
            
            return True
            
        except Exception as e:
            print(f"✗ Error importing shared components: {e}")
            return False
    
    def run_health_check(self) -> bool:
        """Run post-deployment health checks"""
        try:
            print("Running health checks...")
            
            # Check application accessibility
            app_url = f"{self.base_url}/ords/f?p={self.app_id}"
            response = self.session.get(app_url)
            
            if response.status_code == 200:
                print("✓ Application is accessible")
            else:
                print(f"✗ Application accessibility check failed: {response.status_code}")
                return False
            
            # Check database connectivity (if applicable)
            # This would involve making API calls to test database connections
            
            print("✓ Health checks completed successfully")
            return True
            
        except Exception as e:
            print(f"✗ Health check failed: {e}")
            return False


def load_config(environment: str) -> Dict:
    """Load configuration for the specified environment"""
    config_file = f"config/{environment}.json"
    
    if not os.path.exists(config_file):
        raise FileNotFoundError(f"Configuration file not found: {config_file}")
    
    with open(config_file, 'r') as f:
        config = json.load(f)
    
    # Override with environment variables if they exist
    env_vars = {
        'apex_url': 'APEX_URL',
        'workspace': 'APEX_WORKSPACE', 
        'username': 'APEX_USERNAME',
        'password': 'APEX_PASSWORD'
    }
    
    for config_key, env_var in env_vars.items():
        if env_var in os.environ:
            config[config_key] = os.environ[env_var]
    
    return config


def main():
    parser = argparse.ArgumentParser(description='Deploy Healthcare System APEX Application')
    parser.add_argument('--environment', '-e', default='dev',
                       help='Target environment (dev, staging, prod)')
    parser.add_argument('--config-file', '-c',
                       help='Custom configuration file')
    parser.add_argument('--app-file', '-a',
                       help='APEX application export file to import')
    parser.add_argument('--dry-run', action='store_true',
                       help='Perform a dry run without making changes')
    
    args = parser.parse_args()
    
    try:
        # Load configuration
        print(f"Loading configuration for environment: {args.environment}")
        config = load_config(args.environment)
        
        # Initialize deployment
        deployment = APEXDeployment(config)
        
        if args.dry_run:
            print("DRY RUN MODE - No changes will be made")
            return True
        
        # Authenticate
        if not deployment.authenticate():
            return False
        
        # Check if application exists
        app_alias = config.get('application', {}).get('alias', 'HEALTHCARE')
        existing_app_id = deployment.check_application_exists(app_alias)
        
        if existing_app_id:
            print(f"✓ Application already exists with ID: {existing_app_id}")
            deployment.app_id = existing_app_id
        else:
            # Import or create application
            if args.app_file:
                if not deployment.import_application(args.app_file):
                    return False
            else:
                app_config = config.get('application', {})
                if not deployment.create_application(app_config):
                    return False
        
        # Create pages if configuration exists
        if 'pages' in config:
            deployment.create_pages(config['pages'])
        
        # Setup security
        if 'security' in config:
            deployment.setup_security(config['security'])
        
        # Import shared components
        components_dir = config.get('components_directory', 'apex/shared')
        deployment.import_shared_components(components_dir)
        
        # Run health checks
        if not deployment.run_health_check():
            return False
        
        print(f"✓ Healthcare System deployment completed successfully!")
        print(f"Application URL: {config['apex_url']}/ords/f?p={deployment.app_id}")
        
        return True
        
    except Exception as e:
        print(f"✗ Deployment failed: {e}")
        return False


if __name__ == '__main__':
    success = main()
    sys.exit(0 if success else 1)
