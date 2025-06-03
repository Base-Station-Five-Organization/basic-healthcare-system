-- Healthcare System Installation Script
-- Run this script to set up the complete database schema

SET SERVEROUTPUT ON
SET VERIFY OFF

PROMPT ===============================================
PROMPT Healthcare System Database Installation
PROMPT ===============================================
PROMPT

-- Check Oracle version
PROMPT Checking Oracle Database version...
SELECT banner FROM v$version WHERE banner LIKE 'Oracle%';

-- Check APEX version
PROMPT Checking Oracle APEX version...
SELECT version_no FROM apex_release;

PROMPT
PROMPT Starting installation...
PROMPT

-- 1. Create tables and sequences
PROMPT 1. Creating tables and sequences...
@@01_create_tables.sql

PROMPT Tables created successfully.
PROMPT

-- 2. Insert sample data
PROMPT 2. Inserting lookup data and sample records...
@@../data/02_sample_data.sql

PROMPT Sample data inserted successfully.
PROMPT

-- 3. Create views
PROMPT 3. Creating database views...
@@03_views.sql

PROMPT Views created successfully.
PROMPT

-- 4. Clinical Trials Extension
PROMPT 4. Installing Clinical Trials Extension...
@@04_clinical_trials_tables.sql

PROMPT Clinical trials tables created successfully.

@@../data/03_clinical_trials_sample_data.sql

PROMPT Clinical trials sample data inserted.
PROMPT

-- 5. Create packages
PROMPT 5. Creating PL/SQL packages...
@@../packages/pkg_patient_mgmt.sql

PROMPT Patient management package created.

@@../packages/pkg_appointment_mgmt.sql

PROMPT Appointment management package created.

@@../packages/pkg_clinical_trials_mgmt.sql

PROMPT Clinical trials management package created.
PROMPT

-- 6. Create triggers
PROMPT 6. Creating database triggers...
@@../triggers/triggers.sql

PROMPT Triggers created successfully.

@@../triggers/clinical_trials_triggers.sql

PROMPT Clinical trials triggers created successfully.
PROMPT

-- 7. Grant permissions (adjust as needed for your environment)
PROMPT 7. Setting up permissions...

-- Create application user (modify as needed)
-- CREATE USER healthcare_app IDENTIFIED BY "SecurePass123!";
-- GRANT CONNECT, RESOURCE TO healthcare_app;
-- GRANT CREATE VIEW TO healthcare_app;

-- Grant permissions on tables to APEX workspace (modify schema name as needed)
DECLARE
    l_schema VARCHAR2(30) := USER; -- Current schema
BEGIN
    FOR rec IN (SELECT table_name FROM user_tables WHERE table_name IN (
        'PATIENTS', 'PROVIDERS', 'APPOINTMENTS', 'MEDICAL_RECORDS', 
        'PRESCRIPTIONS', 'APPOINTMENT_TYPES', 'SPECIALTIES', 'APPOINTMENT_REMINDERS',
        'CLINICAL_TRIALS', 'TRIAL_PARTICIPANTS', 'STUDY_PROTOCOLS', 'TRIAL_MILESTONES',
        'ADVERSE_EVENTS', 'TRIAL_VISITS'
    )) LOOP
        EXECUTE IMMEDIATE 'GRANT SELECT, INSERT, UPDATE, DELETE ON ' || rec.table_name || ' TO APEX_PUBLIC_USER';
    END LOOP;
    
    FOR rec IN (SELECT view_name FROM user_views WHERE view_name LIKE 'V_%') LOOP
        EXECUTE IMMEDIATE 'GRANT SELECT ON ' || rec.view_name || ' TO APEX_PUBLIC_USER';
    END LOOP;
    
    DBMS_OUTPUT.PUT_LINE('Permissions granted to APEX_PUBLIC_USER');
END;
/

-- 7. Create application roles and users
PROMPT 7. Creating application security...

-- Create application roles
-- You can create these manually in APEX or use SQL
-- CREATE ROLE healthcare_admin;
-- CREATE ROLE healthcare_provider;
-- CREATE ROLE healthcare_staff;
-- CREATE ROLE healthcare_patient;

PROMPT
PROMPT ===============================================
PROMPT Installation completed successfully!
PROMPT ===============================================
PROMPT
PROMPT Next steps:
PROMPT 1. Log into Oracle APEX
PROMPT 2. Create a new workspace or use existing
PROMPT 3. Import the APEX application
PROMPT 4. Configure authentication scheme
PROMPT 5. Set up user roles and access control
PROMPT
PROMPT Tables created:
SELECT table_name, num_rows 
FROM user_tables 
WHERE table_name IN ('PATIENTS', 'PROVIDERS', 'APPOINTMENTS', 'MEDICAL_RECORDS', 'PRESCRIPTIONS')
ORDER BY table_name;

PROMPT
PROMPT Views created:
SELECT view_name 
FROM user_views 
WHERE view_name LIKE 'V_%'
ORDER BY view_name;

PROMPT
PROMPT Packages created:
SELECT object_name, object_type, status 
FROM user_objects 
WHERE object_type IN ('PACKAGE', 'PACKAGE BODY')
  AND object_name LIKE 'PKG_%'
ORDER BY object_name, object_type;

PROMPT
PROMPT Sample data summary:
SELECT 'Patients' as entity, COUNT(*) as count FROM patients
UNION ALL
SELECT 'Providers' as entity, COUNT(*) as count FROM providers
UNION ALL
SELECT 'Appointments' as entity, COUNT(*) as count FROM appointments
UNION ALL
SELECT 'Appointment Types' as entity, COUNT(*) as count FROM appointment_types
UNION ALL
SELECT 'Specialties' as entity, COUNT(*) as count FROM specialties;

PROMPT
PROMPT Installation log completed.
PROMPT Check for any errors above before proceeding.

-- 5. Clinical Trials Extension
PROMPT 5. Installing Clinical Trials Extension...
PROMPT Creating clinical trials tables...
@@04_clinical_trials_tables.sql

PROMPT Clinical trials tables created successfully.
PROMPT

PROMPT Creating clinical trials management package...
@@../packages/pkg_clinical_trials_mgmt.sql

PROMPT Clinical trials package created successfully.
PROMPT

PROMPT Creating clinical trials triggers...
@@../triggers/clinical_trials_triggers.sql

PROMPT Clinical trials triggers created successfully.
PROMPT

PROMPT Inserting clinical trials sample data...
@@../data/03_clinical_trials_sample_data.sql

PROMPT Clinical trials sample data inserted successfully.
PROMPT

PROMPT
PROMPT ===============================================
PROMPT Installation completed successfully!
PROMPT ===============================================
PROMPT
PROMPT Next steps:
PROMPT 1. Log into Oracle APEX
PROMPT 2. Create a new workspace or use existing
PROMPT 3. Import the APEX application
PROMPT 4. Configure authentication scheme
PROMPT 5. Set up user roles and access control
PROMPT
PROMPT Tables created:
SELECT table_name, num_rows 
FROM user_tables 
WHERE table_name IN ('PATIENTS', 'PROVIDERS', 'APPOINTMENTS', 'MEDICAL_RECORDS', 'PRESCRIPTIONS')
ORDER BY table_name;

PROMPT
PROMPT Views created:
SELECT view_name 
FROM user_views 
WHERE view_name LIKE 'V_%'
ORDER BY view_name;

PROMPT
PROMPT Packages created:
SELECT object_name, object_type, status 
FROM user_objects 
WHERE object_type IN ('PACKAGE', 'PACKAGE BODY')
  AND object_name LIKE 'PKG_%'
ORDER BY object_name, object_type;

PROMPT
PROMPT Sample data summary:
SELECT 'Patients' as entity, COUNT(*) as count FROM patients
UNION ALL
SELECT 'Providers' as entity, COUNT(*) as count FROM providers
UNION ALL
SELECT 'Appointments' as entity, COUNT(*) as count FROM appointments
UNION ALL
SELECT 'Appointment Types' as entity, COUNT(*) as count FROM appointment_types
UNION ALL
SELECT 'Specialties' as entity, COUNT(*) as count FROM specialties;

PROMPT
PROMPT Installation log completed.
PROMPT Check for any errors above before proceeding.
