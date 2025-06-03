-- Healthcare System - Oracle APEX Cloud Setup
-- Part 7: Views (Part 1)
-- Run this after Part 6

PROMPT ===============================================;
PROMPT Healthcare System - Part 7: Views Part 1
PROMPT ===============================================;

-- Patient summary view
CREATE OR REPLACE VIEW v_patient_summary AS
SELECT 
    p.patient_id,
    p.first_name,
    p.last_name,
    p.first_name || ' ' || p.last_name as full_name,
    p.date_of_birth,
    FLOOR(MONTHS_BETWEEN(SYSDATE, p.date_of_birth) / 12) as age,
    p.gender,
    p.phone,
    p.email,
    p.address || ', ' || p.city || ', ' || p.state || ' ' || p.zip_code as full_address,
    p.insurance_provider,
    p.insurance_policy_number,
    p.emergency_contact_name,
    p.emergency_contact_phone,
    p.is_active,
    -- Count of appointments
    (SELECT COUNT(*) FROM appointments a WHERE a.patient_id = p.patient_id) as total_appointments,
    -- Last appointment date
    (SELECT MAX(a.appointment_date) FROM appointments a WHERE a.patient_id = p.patient_id) as last_appointment_date,
    -- Next appointment date  
    (SELECT MIN(a.appointment_date) FROM appointments a 
     WHERE a.patient_id = p.patient_id AND a.appointment_date >= TRUNC(SYSDATE)) as next_appointment_date
FROM patients p;

-- Provider summary view
CREATE OR REPLACE VIEW v_provider_summary AS
SELECT 
    pr.provider_id,
    pr.first_name,
    pr.last_name,
    pr.first_name || ' ' || pr.last_name as full_name,
    pr.title,
    pr.specialty,
    pr.license_number,
    pr.phone,
    pr.email,
    pr.department,
    pr.hire_date,
    pr.is_active,
    -- Count of appointments
    (SELECT COUNT(*) FROM appointments a WHERE a.provider_id = pr.provider_id) as total_appointments,
    -- Count of patients
    (SELECT COUNT(DISTINCT a.patient_id) FROM appointments a WHERE a.provider_id = pr.provider_id) as total_patients,
    -- Today's appointments
    (SELECT COUNT(*) FROM appointments a 
     WHERE a.provider_id = pr.provider_id AND TRUNC(a.appointment_date) = TRUNC(SYSDATE)) as todays_appointments
FROM providers pr;

-- Appointment details view
CREATE OR REPLACE VIEW v_appointment_details AS
SELECT 
    a.appointment_id,
    a.patient_id,
    a.provider_id,
    a.appointment_date,
    a.start_time,
    a.end_time,
    a.appointment_type,
    a.status,
    a.reason_for_visit,
    a.notes,
    -- Patient information
    p.first_name as patient_first_name,
    p.last_name as patient_last_name,
    p.first_name || ' ' || p.last_name as patient_name,
    p.phone as patient_phone,
    p.email as patient_email,
    -- Provider information
    pr.first_name as provider_first_name,
    pr.last_name as provider_last_name,
    pr.first_name || ' ' || pr.last_name as provider_name,
    pr.title as provider_title,
    pr.specialty as provider_specialty,
    -- Calculated fields
    EXTRACT(HOUR FROM a.start_time) || ':' || 
    LPAD(EXTRACT(MINUTE FROM a.start_time), 2, '0') as start_time_display,
    EXTRACT(HOUR FROM a.end_time) || ':' || 
    LPAD(EXTRACT(MINUTE FROM a.end_time), 2, '0') as end_time_display,
    CASE 
        WHEN a.appointment_date < TRUNC(SYSDATE) THEN 'Past'
        WHEN a.appointment_date = TRUNC(SYSDATE) THEN 'Today'
        WHEN a.appointment_date = TRUNC(SYSDATE) + 1 THEN 'Tomorrow'
        ELSE 'Future'
    END as appointment_timing
FROM appointments a
JOIN patients p ON a.patient_id = p.patient_id
JOIN providers pr ON a.provider_id = pr.provider_id;

PROMPT Core views created;

PROMPT ===============================================;
PROMPT Part 7 Complete - Continue with Part 8
PROMPT ===============================================;
