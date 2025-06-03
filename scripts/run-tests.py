#!/usr/bin/env python3

"""
Healthcare System Test Suite
Comprehensive testing for database schema, APEX application, and business logic
"""

import os
import sys
import json
import argparse
import time
from datetime import datetime
from typing import Dict, List, Tuple, Optional

# Try to import optional dependencies
try:
    import cx_Oracle
    HAS_ORACLE = True
except ImportError:
    HAS_ORACLE = False
    print("⚠️ cx_Oracle module not available, database tests will be skipped")

try:
    import requests
    HAS_REQUESTS = True
except ImportError:
    HAS_REQUESTS = False
    print("⚠️ requests module not available, some tests will be skipped")

class HealthcareSystemTests:
    def __init__(self, config: Dict):
        self.config = config
        self.db_connection = None
        self.test_results = []
        
    def connect_database(self) -> bool:
        """Establish database connection"""
        if not HAS_ORACLE:
            print("⚠️ cx_Oracle not available, skipping database connection")
            return False
            
        try:
            dsn = cx_Oracle.makedsn(
                self.config['database']['host'],
                self.config['database']['port'],
                service_name=self.config['database']['service_name']
            )
            
            self.db_connection = cx_Oracle.connect(
                user=self.config['database']['username'],
                password=self.config['database']['password'],
                dsn=dsn
            )
            
            print("✓ Database connection established")
            return True
            
        except Exception as e:
            print(f"✗ Database connection failed: {e}")
            return False
    
    def run_test(self, test_name: str, test_function) -> bool:
        """Run a single test and record results"""
        print(f"Running test: {test_name}")
        start_time = time.time()
        
        try:
            result = test_function()
            execution_time = time.time() - start_time
            
            self.test_results.append({
                'test_name': test_name,
                'status': 'PASS' if result else 'FAIL',
                'execution_time': execution_time,
                'timestamp': datetime.now().isoformat()
            })
            
            if result:
                print(f"  ✓ PASS ({execution_time:.2f}s)")
            else:
                print(f"  ✗ FAIL ({execution_time:.2f}s)")
                
            return result
            
        except Exception as e:
            execution_time = time.time() - start_time
            
            self.test_results.append({
                'test_name': test_name,
                'status': 'ERROR',
                'error': str(e),
                'execution_time': execution_time,
                'timestamp': datetime.now().isoformat()
            })
            
            print(f"  ✗ ERROR ({execution_time:.2f}s): {e}")
            return False
    
    def test_database_connectivity(self) -> bool:
        """Test basic database connectivity"""
        cursor = self.db_connection.cursor()
        cursor.execute("SELECT 'CONNECTION_TEST' FROM dual")
        result = cursor.fetchone()
        cursor.close()
        return result[0] == 'CONNECTION_TEST'
    
    def test_core_tables_exist(self) -> bool:
        """Test that all core tables exist"""
        required_tables = [
            'PATIENTS', 'PROVIDERS', 'APPOINTMENTS', 'MEDICAL_RECORDS', 
            'PRESCRIPTIONS', 'APPOINTMENT_TYPES', 'SPECIALTIES'
        ]
        
        cursor = self.db_connection.cursor()
        cursor.execute("""
            SELECT table_name 
            FROM user_tables 
            WHERE table_name IN ({})
        """.format(','.join([f"'{t}'" for t in required_tables])))
        
        existing_tables = [row[0] for row in cursor.fetchall()]
        cursor.close()
        
        missing_tables = set(required_tables) - set(existing_tables)
        if missing_tables:
            print(f"    Missing tables: {missing_tables}")
            return False
        
        return True
    
    def test_clinical_trials_tables_exist(self) -> bool:
        """Test that clinical trials tables exist"""
        required_tables = [
            'CLINICAL_TRIALS', 'TRIAL_PARTICIPANTS', 'ADVERSE_EVENTS',
            'TRIAL_VISITS', 'TRIAL_MILESTONES', 'STUDY_PROTOCOLS'
        ]
        
        cursor = self.db_connection.cursor()
        cursor.execute("""
            SELECT table_name 
            FROM user_tables 
            WHERE table_name IN ({})
        """.format(','.join([f"'{t}'" for t in required_tables])))
        
        existing_tables = [row[0] for row in cursor.fetchall()]
        cursor.close()
        
        missing_tables = set(required_tables) - set(existing_tables)
        if missing_tables:
            print(f"    Missing clinical trials tables: {missing_tables}")
            return False
        
        return True
    
    def test_sequences_exist(self) -> bool:
        """Test that required sequences exist"""
        required_sequences = [
            'SEQ_PATIENT_ID', 'SEQ_PROVIDER_ID', 'SEQ_APPOINTMENT_ID',
            'SEQ_TRIAL_ID', 'SEQ_PARTICIPANT_ID'
        ]
        
        cursor = self.db_connection.cursor()
        cursor.execute("""
            SELECT sequence_name 
            FROM user_sequences 
            WHERE sequence_name IN ({})
        """.format(','.join([f"'{s}'" for s in required_sequences])))
        
        existing_sequences = [row[0] for row in cursor.fetchall()]
        cursor.close()
        
        missing_sequences = set(required_sequences) - set(existing_sequences)
        if missing_sequences:
            print(f"    Missing sequences: {missing_sequences}")
            return False
        
        return True
    
    def test_foreign_key_constraints(self) -> bool:
        """Test that foreign key constraints are properly defined"""
        cursor = self.db_connection.cursor()
        cursor.execute("""
            SELECT constraint_name, table_name, r_constraint_name
            FROM user_constraints 
            WHERE constraint_type = 'R'
        """)
        
        foreign_keys = cursor.fetchall()
        cursor.close()
        
        # Should have foreign keys for major relationships
        expected_fk_count = 15  # Minimum expected foreign keys
        actual_fk_count = len(foreign_keys)
        
        if actual_fk_count < expected_fk_count:
            print(f"    Expected at least {expected_fk_count} foreign keys, found {actual_fk_count}")
            return False
        
        return True
    
    def test_sample_data_exists(self) -> bool:
        """Test that sample data has been loaded"""
        test_queries = [
            ("SELECT COUNT(*) FROM patients", 5),
            ("SELECT COUNT(*) FROM providers", 5),
            ("SELECT COUNT(*) FROM appointment_types", 3),
            ("SELECT COUNT(*) FROM specialties", 5),
            ("SELECT COUNT(*) FROM clinical_trials", 2)
        ]
        
        cursor = self.db_connection.cursor()
        
        for query, min_expected in test_queries:
            cursor.execute(query)
            count = cursor.fetchone()[0]
            
            if count < min_expected:
                print(f"    Insufficient data: {query} returned {count}, expected at least {min_expected}")
                cursor.close()
                return False
        
        cursor.close()
        return True
    
    def test_views_exist(self) -> bool:
        """Test that required views exist and are valid"""
        required_views = [
            'V_PATIENT_SUMMARY', 'V_APPOINTMENT_DETAILS', 'V_TRIAL_SUMMARY',
            'V_TRIAL_PARTICIPANTS', 'V_ADVERSE_EVENTS'
        ]
        
        cursor = self.db_connection.cursor()
        
        for view_name in required_views:
            try:
                cursor.execute(f"SELECT COUNT(*) FROM {view_name}")
                cursor.fetchone()
            except Exception as e:
                print(f"    View {view_name} is invalid or missing: {e}")
                cursor.close()
                return False
        
        cursor.close()
        return True
    
    def test_data_integrity(self) -> bool:
        """Test data integrity constraints"""
        integrity_tests = [
            # Test patient-appointment relationship
            """
            SELECT COUNT(*) FROM appointments a 
            LEFT JOIN patients p ON a.patient_id = p.patient_id 
            WHERE p.patient_id IS NULL
            """,
            # Test provider-appointment relationship
            """
            SELECT COUNT(*) FROM appointments a 
            LEFT JOIN providers pr ON a.provider_id = pr.provider_id 
            WHERE pr.provider_id IS NULL
            """,
            # Test trial-participant relationship
            """
            SELECT COUNT(*) FROM trial_participants tp 
            LEFT JOIN clinical_trials ct ON tp.trial_id = ct.trial_id 
            WHERE ct.trial_id IS NULL
            """
        ]
        
        cursor = self.db_connection.cursor()
        
        for test_query in integrity_tests:
            cursor.execute(test_query)
            orphan_count = cursor.fetchone()[0]
            
            if orphan_count > 0:
                print(f"    Data integrity violation: {orphan_count} orphaned records found")
                cursor.close()
                return False
        
        cursor.close()
        return True
    
    def test_apex_application_accessible(self) -> bool:
        """Test APEX application accessibility"""
        if 'apex_url' not in self.config:
            print("    APEX URL not configured, skipping test")
            return True
        
        try:
            response = requests.get(self.config['apex_url'], timeout=10)
            return response.status_code == 200
        except Exception as e:
            print(f"    APEX accessibility test failed: {e}")
            return False
    
    def test_business_logic(self) -> bool:
        """Test business logic functions"""
        cursor = self.db_connection.cursor()
        
        # Test patient age calculation
        try:
            cursor.execute("""
                SELECT pkg_patient_mgmt.get_patient_age(
                    (SELECT patient_id FROM patients WHERE ROWNUM = 1)
                ) FROM dual
            """)
            age = cursor.fetchone()[0]
            
            if age is None or age < 0 or age > 150:
                print(f"    Invalid age calculation: {age}")
                cursor.close()
                return False
                
        except Exception as e:
            print(f"    Business logic test failed: {e}")
            cursor.close()
            return False
        
        cursor.close()
        return True
    
    def run_all_tests(self) -> Dict:
        """Run all test suites"""
        print("Healthcare System Test Suite")
        print("=" * 40)
        
        # Database connectivity tests
        print("\n1. Database Connectivity Tests")
        if not self.connect_database():
            return {'status': 'FAILED', 'reason': 'Database connection failed'}
        
        # Core schema tests
        print("\n2. Schema Tests")
        self.run_test("Core tables exist", self.test_core_tables_exist)
        self.run_test("Clinical trials tables exist", self.test_clinical_trials_tables_exist)
        self.run_test("Sequences exist", self.test_sequences_exist)
        self.run_test("Foreign key constraints", self.test_foreign_key_constraints)
        
        # Data tests
        print("\n3. Data Tests")
        self.run_test("Sample data loaded", self.test_sample_data_exists)
        self.run_test("Views are valid", self.test_views_exist)
        self.run_test("Data integrity", self.test_data_integrity)
        
        # Application tests
        print("\n4. Application Tests")
        self.run_test("APEX application accessible", self.test_apex_application_accessible)
        self.run_test("Business logic functions", self.test_business_logic)
        
        # Generate summary
        total_tests = len(self.test_results)
        passed_tests = len([t for t in self.test_results if t['status'] == 'PASS'])
        failed_tests = total_tests - passed_tests
        
        print(f"\n{'=' * 40}")
        print(f"Test Summary: {passed_tests}/{total_tests} tests passed")
        
        if failed_tests > 0:
            print(f"Failed tests:")
            for test in self.test_results:
                if test['status'] != 'PASS':
                    print(f"  - {test['test_name']}: {test['status']}")
        
        # Close database connection
        if self.db_connection:
            self.db_connection.close()
        
        return {
            'status': 'PASSED' if failed_tests == 0 else 'FAILED',
            'total_tests': total_tests,
            'passed_tests': passed_tests,
            'failed_tests': failed_tests,
            'test_results': self.test_results
        }
    
    def save_results(self, output_file: str):
        """Save test results to file"""
        results = {
            'test_run': {
                'timestamp': datetime.now().isoformat(),
                'environment': self.config.get('environment', 'unknown'),
                'total_tests': len(self.test_results),
                'passed_tests': len([t for t in self.test_results if t['status'] == 'PASS']),
                'failed_tests': len([t for t in self.test_results if t['status'] != 'PASS'])
            },
            'test_results': self.test_results
        }
        
        os.makedirs(os.path.dirname(output_file), exist_ok=True)
        
        with open(output_file, 'w') as f:
            json.dump(results, f, indent=2)
        
        print(f"Test results saved to: {output_file}")


def load_test_config(environment: str) -> Dict:
    """Load test configuration"""
    config_file = f"config/{environment}.json"
    
    if not os.path.exists(config_file):
        # Fallback to environment variables
        return {
            'environment': environment,
            'database': {
                'host': os.environ.get('DB_HOST', 'localhost'),
                'port': int(os.environ.get('DB_PORT', '1521')),
                'service_name': os.environ.get('DB_SERVICE_NAME', 'XE'),
                'username': os.environ.get('DB_USERNAME', 'healthcare'),
                'password': os.environ.get('DB_PASSWORD', 'password')
            },
            'apex_url': os.environ.get('APEX_URL')
        }
    
    with open(config_file, 'r') as f:
        return json.load(f)


def main():
    parser = argparse.ArgumentParser(description='Run Healthcare System Tests')
    parser.add_argument('--environment', '-e', default='test',
                       help='Test environment (test, dev, staging)')
    parser.add_argument('--test-type', '-t', default='all',
                       choices=['all', 'smoke', 'integration', 'performance'],
                       help='Type of tests to run')
    parser.add_argument('--output', '-o', default='test-results/test-results.json',
                       help='Output file for test results')
    
    args = parser.parse_args()
    
    try:
        # Load configuration
        config = load_test_config(args.environment)
        
        # Initialize test suite
        test_suite = HealthcareSystemTests(config)
        
        # Run tests based on type
        if args.test_type in ['all', 'smoke', 'integration']:
            results = test_suite.run_all_tests()
        else:
            print(f"Test type '{args.test_type}' not yet implemented")
            return False
        
        # Save results
        test_suite.save_results(args.output)
        
        # Return appropriate exit code
        return results['status'] == 'PASSED'
        
    except Exception as e:
        print(f"Test execution failed: {e}")
        return False


if __name__ == '__main__':
    success = main()
    sys.exit(0 if success else 1)
