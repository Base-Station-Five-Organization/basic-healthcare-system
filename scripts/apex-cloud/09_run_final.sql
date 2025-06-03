-- Healthcare System - Oracle APEX Cloud Setup
-- Part 9: Verification and Final Steps
-- Run this after Part 8

PROMPT ===============================================;
PROMPT Healthcare System - Part 9: Verification
PROMPT ===============================================;

-- Verify all tables exist
PROMPT Checking tables...;
SELECT 'Core Tables' as category, table_name 
FROM user_tables 
WHERE table_name IN ('PATIENTS', 'PROVIDERS', 'APPOINTMENTS', 'MEDICAL_RECORDS', 'PRESCRIPTIONS')
UNION ALL
SELECT 'Clinical Trials Tables' as category, table_name 
FROM user_tables 
WHERE table_name IN ('CLINICAL_TRIALS', 'TRIAL_PARTICIPANTS', 'ADVERSE_EVENTS', 'TRIAL_VISITS', 'TRIAL_MILESTONES')
ORDER BY category, table_name;

-- Check data counts
PROMPT Checking data counts...;
SELECT 'Patients' as table_name, COUNT(*) as record_count FROM patients
UNION ALL
SELECT 'Providers', COUNT(*) FROM providers
UNION ALL
SELECT 'Clinical Trials', COUNT(*) FROM clinical_trials
UNION ALL
SELECT 'Trial Participants', COUNT(*) FROM trial_participants
UNION ALL
SELECT 'Appointment Types', COUNT(*) FROM appointment_types
UNION ALL
SELECT 'Specialties', COUNT(*) FROM specialties;

-- Verify views
PROMPT Checking views...;
SELECT view_name 
FROM user_views 
WHERE view_name LIKE 'V_%'
ORDER BY view_name;

-- Test basic functionality
PROMPT Testing basic queries...;

-- Test patient summary
SELECT patient_id, full_name, age, total_appointments
FROM v_patient_summary
WHERE ROWNUM <= 3;

-- Test trial summary
SELECT trial_id, trial_name, enrollment_percentage, trial_health_score
FROM v_trial_summary
WHERE ROWNUM <= 3;

-- Check for any invalid objects
PROMPT Checking for invalid objects...;
SELECT object_name, object_type, status
FROM user_objects
WHERE status != 'VALID'
ORDER BY object_type, object_name;

PROMPT ===============================================;
PROMPT Database Setup Complete!
PROMPT ===============================================;
PROMPT;
PROMPT Next Steps:;
PROMPT 1. Create APEX Application;
PROMPT 2. Set up authentication and authorization;
PROMPT 3. Create pages based on clinical_trials_structure.md;
PROMPT 4. Import reports from clinical_trials_reports.sql;
PROMPT;
PROMPT For detailed instructions, see:;
PROMPT - docs/installation/INSTALLATION.md;
PROMPT - docs/user-guide/clinical_trials_user_guide.md;
PROMPT - apex/applications/clinical_trials_structure.md;
PROMPT ===============================================;
