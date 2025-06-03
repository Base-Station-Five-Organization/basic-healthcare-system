-- Healthcare System Reports
-- SQL queries for various reports in the APEX application

-- Report 1: Daily Appointment Schedule
-- Purpose: Show all appointments for a specific date with patient and provider details
-- Usage: APEX Interactive Report with date parameter

SELECT 
    a.appointment_time,
    a.appointment_time || ' - ' || 
        TO_CHAR(TO_DATE(a.appointment_time, 'HH24:MI') + (a.duration_minutes/1440), 'HH24:MI') as time_slot,
    pkg_patient_mgmt.get_full_name(p.first_name, p.last_name) as patient_name,
    p.phone as patient_phone,
    pkg_patient_mgmt.get_full_name(pr.first_name, pr.last_name) as provider_name,
    pr.department,
    a.appointment_type,
    a.reason_for_visit,
    a.status,
    a.duration_minutes,
    CASE a.status
        WHEN 'Scheduled' THEN 'u-color-warning'
        WHEN 'Confirmed' THEN 'u-color-info'
        WHEN 'In Progress' THEN 'u-color-primary'
        WHEN 'Completed' THEN 'u-color-success'
        WHEN 'Cancelled' THEN 'u-color-danger'
        WHEN 'No Show' THEN 'u-color-danger'
        ELSE 'u-color-neutral'
    END as status_css,
    a.appointment_id,
    a.patient_id,
    a.provider_id
FROM appointments a
JOIN patients p ON a.patient_id = p.patient_id
JOIN providers pr ON a.provider_id = pr.provider_id
WHERE a.appointment_date = :P_DATE  -- APEX page parameter
ORDER BY a.appointment_time;

-- Report 2: Patient Visit History
-- Purpose: Show complete visit history for a patient
-- Usage: Master-Detail report with patient selection

SELECT 
    mr.visit_date,
    TO_CHAR(mr.visit_date, 'Month DD, YYYY') as formatted_visit_date,
    pkg_patient_mgmt.get_full_name(pr.first_name, pr.last_name) as provider_name,
    pr.specialty,
    a.appointment_type,
    mr.chief_complaint,
    SUBSTR(mr.diagnosis, 1, 100) || CASE WHEN LENGTH(mr.diagnosis) > 100 THEN '...' ELSE '' END as diagnosis_summary,
    mr.vital_signs,
    (SELECT COUNT(*) 
     FROM prescriptions p 
     WHERE p.record_id = mr.record_id) as prescriptions_count,
    mr.record_id,
    a.appointment_id
FROM medical_records mr
JOIN providers pr ON mr.provider_id = pr.provider_id
LEFT JOIN appointments a ON mr.appointment_id = a.appointment_id
WHERE mr.patient_id = :P_PATIENT_ID  -- APEX page parameter
ORDER BY mr.visit_date DESC;

-- Report 3: Provider Productivity Report
-- Purpose: Show provider statistics and productivity metrics
-- Usage: Dashboard cards and charts

SELECT 
    pr.provider_id,
    pkg_patient_mgmt.get_full_name(pr.first_name, pr.last_name) as provider_name,
    pr.title,
    pr.specialty,
    pr.department,
    -- Appointment statistics
    COUNT(a.appointment_id) as total_appointments,
    SUM(CASE WHEN a.status = 'Completed' THEN 1 ELSE 0 END) as completed_appointments,
    SUM(CASE WHEN a.status = 'Cancelled' THEN 1 ELSE 0 END) as cancelled_appointments,
    SUM(CASE WHEN a.status = 'No Show' THEN 1 ELSE 0 END) as no_show_appointments,
    -- Calculate completion rate
    ROUND(
        CASE 
            WHEN COUNT(a.appointment_id) > 0 THEN
                (SUM(CASE WHEN a.status = 'Completed' THEN 1 ELSE 0 END) / COUNT(a.appointment_id)) * 100
            ELSE 0
        END, 1
    ) as completion_rate,
    -- Calculate cancellation rate
    ROUND(
        CASE 
            WHEN COUNT(a.appointment_id) > 0 THEN
                (SUM(CASE WHEN a.status = 'Cancelled' THEN 1 ELSE 0 END) / COUNT(a.appointment_id)) * 100
            ELSE 0
        END, 1
    ) as cancellation_rate,
    -- Patient metrics
    COUNT(DISTINCT a.patient_id) as unique_patients,
    -- Time period
    MIN(a.appointment_date) as first_appointment,
    MAX(a.appointment_date) as last_appointment
FROM providers pr
LEFT JOIN appointments a ON pr.provider_id = a.provider_id
    AND a.appointment_date BETWEEN :P_START_DATE AND :P_END_DATE  -- APEX parameters
WHERE pr.is_active = 'Y'
GROUP BY pr.provider_id, pr.first_name, pr.last_name, pr.title, pr.specialty, pr.department
ORDER BY total_appointments DESC;

-- Report 4: Appointment Status Summary
-- Purpose: Dashboard summary of appointment statuses
-- Usage: Chart region or cards

SELECT 
    status,
    COUNT(*) as appointment_count,
    ROUND((COUNT(*) * 100.0) / SUM(COUNT(*)) OVER (), 1) as percentage,
    CASE status
        WHEN 'Scheduled' THEN '#ffc107'
        WHEN 'Confirmed' THEN '#17a2b8'
        WHEN 'In Progress' THEN '#007bff'
        WHEN 'Completed' THEN '#28a745'
        WHEN 'Cancelled' THEN '#dc3545'
        WHEN 'No Show' THEN '#6c757d'
        ELSE '#343a40'
    END as color_code
FROM appointments
WHERE appointment_date BETWEEN :P_START_DATE AND :P_END_DATE
GROUP BY status
ORDER BY appointment_count DESC;

-- Report 5: Patient Demographics Report
-- Purpose: Patient demographics for analytics
-- Usage: Charts and statistics

SELECT 
    -- Age groups
    CASE 
        WHEN pkg_patient_mgmt.get_patient_age(patient_id) < 18 THEN 'Under 18'
        WHEN pkg_patient_mgmt.get_patient_age(patient_id) BETWEEN 18 AND 30 THEN '18-30'
        WHEN pkg_patient_mgmt.get_patient_age(patient_id) BETWEEN 31 AND 50 THEN '31-50'
        WHEN pkg_patient_mgmt.get_patient_age(patient_id) BETWEEN 51 AND 65 THEN '51-65'
        ELSE 'Over 65'
    END as age_group,
    gender,
    COUNT(*) as patient_count,
    ROUND(AVG(pkg_patient_mgmt.get_patient_age(patient_id)), 1) as avg_age
FROM patients
WHERE is_active = 'Y'
GROUP BY 
    CASE 
        WHEN pkg_patient_mgmt.get_patient_age(patient_id) < 18 THEN 'Under 18'
        WHEN pkg_patient_mgmt.get_patient_age(patient_id) BETWEEN 18 AND 30 THEN '18-30'
        WHEN pkg_patient_mgmt.get_patient_age(patient_id) BETWEEN 31 AND 50 THEN '31-50'
        WHEN pkg_patient_mgmt.get_patient_age(patient_id) BETWEEN 51 AND 65 THEN '51-65'
        ELSE 'Over 65'
    END,
    gender
ORDER BY age_group, gender;

-- Report 6: Monthly Appointment Trends
-- Purpose: Show appointment trends over time
-- Usage: Line chart or area chart

SELECT 
    TO_CHAR(appointment_date, 'YYYY-MM') as month_year,
    TO_CHAR(appointment_date, 'Month YYYY') as month_name,
    COUNT(*) as total_appointments,
    SUM(CASE WHEN status = 'Completed' THEN 1 ELSE 0 END) as completed,
    SUM(CASE WHEN status = 'Cancelled' THEN 1 ELSE 0 END) as cancelled,
    SUM(CASE WHEN status = 'No Show' THEN 1 ELSE 0 END) as no_shows,
    ROUND(AVG(duration_minutes), 0) as avg_duration
FROM appointments
WHERE appointment_date >= ADD_MONTHS(SYSDATE, -12)  -- Last 12 months
GROUP BY TO_CHAR(appointment_date, 'YYYY-MM'), TO_CHAR(appointment_date, 'Month YYYY')
ORDER BY TO_CHAR(appointment_date, 'YYYY-MM');

-- Report 7: Top Diagnoses Report
-- Purpose: Most common diagnoses and conditions
-- Usage: Interactive report with filtering

SELECT 
    TRIM(UPPER(
        CASE 
            WHEN INSTR(mr.diagnosis, ',') > 0 THEN SUBSTR(mr.diagnosis, 1, INSTR(mr.diagnosis, ',') - 1)
            WHEN INSTR(mr.diagnosis, ';') > 0 THEN SUBSTR(mr.diagnosis, 1, INSTR(mr.diagnosis, ';') - 1)
            WHEN INSTR(mr.diagnosis, '.') > 0 THEN SUBSTR(mr.diagnosis, 1, INSTR(mr.diagnosis, '.') - 1)
            ELSE mr.diagnosis
        END
    )) as primary_diagnosis,
    COUNT(*) as occurrence_count,
    COUNT(DISTINCT mr.patient_id) as unique_patients,
    ROUND((COUNT(*) * 100.0) / SUM(COUNT(*)) OVER (), 1) as percentage,
    MIN(mr.visit_date) as first_occurrence,
    MAX(mr.visit_date) as last_occurrence
FROM medical_records mr
WHERE mr.diagnosis IS NOT NULL
  AND LENGTH(TRIM(mr.diagnosis)) > 0
  AND mr.visit_date >= :P_START_DATE
  AND mr.visit_date <= :P_END_DATE
GROUP BY TRIM(UPPER(
    CASE 
        WHEN INSTR(mr.diagnosis, ',') > 0 THEN SUBSTR(mr.diagnosis, 1, INSTR(mr.diagnosis, ',') - 1)
        WHEN INSTR(mr.diagnosis, ';') > 0 THEN SUBSTR(mr.diagnosis, 1, INSTR(mr.diagnosis, ';') - 1)
        WHEN INSTR(mr.diagnosis, '.') > 0 THEN SUBSTR(mr.diagnosis, 1, INSTR(mr.diagnosis, '.') - 1)
        ELSE mr.diagnosis
    END
))
HAVING COUNT(*) >= 2  -- Only show diagnoses that appear at least twice
ORDER BY occurrence_count DESC
FETCH FIRST 20 ROWS ONLY;

-- Report 8: Prescription Analysis
-- Purpose: Most prescribed medications and trends
-- Usage: Interactive report and charts

SELECT 
    pr.medication_name,
    COUNT(*) as prescription_count,
    COUNT(DISTINCT pr.patient_id) as unique_patients,
    COUNT(DISTINCT pr.provider_id) as prescribing_providers,
    ROUND(AVG(pr.quantity), 0) as avg_quantity,
    ROUND(AVG(pr.refills_allowed), 1) as avg_refills,
    MIN(pr.date_prescribed) as first_prescribed,
    MAX(pr.date_prescribed) as last_prescribed,
    SUM(CASE WHEN pr.is_active = 'Y' THEN 1 ELSE 0 END) as currently_active
FROM prescriptions pr
WHERE pr.date_prescribed >= :P_START_DATE
  AND pr.date_prescribed <= :P_END_DATE
GROUP BY pr.medication_name
HAVING COUNT(*) >= 2
ORDER BY prescription_count DESC
FETCH FIRST 25 ROWS ONLY;

-- Report 9: Patient Risk Assessment
-- Purpose: Identify high-risk patients based on various factors
-- Usage: Interactive report with alerts

SELECT 
    p.patient_id,
    pkg_patient_mgmt.get_full_name(p.first_name, p.last_name) as patient_name,
    pkg_patient_mgmt.get_patient_age(p.patient_id) as age,
    p.phone,
    p.email,
    -- Risk factors
    CASE WHEN pkg_patient_mgmt.get_patient_age(p.patient_id) >= 65 THEN 1 ELSE 0 END as elderly_risk,
    CASE WHEN p.medical_conditions IS NOT NULL AND LENGTH(p.medical_conditions) > 0 THEN 1 ELSE 0 END as chronic_conditions,
    CASE WHEN p.allergies IS NOT NULL AND LENGTH(p.allergies) > 0 THEN 1 ELSE 0 END as has_allergies,
    active_meds.medication_count,
    recent_visits.visit_count as recent_visits,
    missed_appts.missed_count as missed_appointments,
    -- Calculate risk score
    (CASE WHEN pkg_patient_mgmt.get_patient_age(p.patient_id) >= 65 THEN 2 ELSE 0 END +
     CASE WHEN p.medical_conditions IS NOT NULL AND LENGTH(p.medical_conditions) > 0 THEN 2 ELSE 0 END +
     CASE WHEN p.allergies IS NOT NULL AND LENGTH(p.allergies) > 0 THEN 1 ELSE 0 END +
     CASE WHEN NVL(active_meds.medication_count, 0) >= 5 THEN 2 ELSE 0 END +
     CASE WHEN NVL(recent_visits.visit_count, 0) >= 5 THEN 1 ELSE 0 END +
     CASE WHEN NVL(missed_appts.missed_count, 0) >= 2 THEN 2 ELSE 0 END) as risk_score,
    -- Last visit
    last_visit.last_visit_date,
    next_appt.next_appointment_date
FROM patients p
LEFT JOIN (
    SELECT patient_id, COUNT(*) as medication_count
    FROM prescriptions
    WHERE is_active = 'Y'
    GROUP BY patient_id
) active_meds ON p.patient_id = active_meds.patient_id
LEFT JOIN (
    SELECT patient_id, COUNT(*) as visit_count
    FROM medical_records
    WHERE visit_date >= SYSDATE - 90  -- Last 90 days
    GROUP BY patient_id
) recent_visits ON p.patient_id = recent_visits.patient_id
LEFT JOIN (
    SELECT patient_id, COUNT(*) as missed_count
    FROM appointments
    WHERE status = 'No Show'
      AND appointment_date >= SYSDATE - 365  -- Last year
    GROUP BY patient_id
) missed_appts ON p.patient_id = missed_appts.patient_id
LEFT JOIN (
    SELECT patient_id, MAX(visit_date) as last_visit_date
    FROM medical_records
    GROUP BY patient_id
) last_visit ON p.patient_id = last_visit.patient_id
LEFT JOIN (
    SELECT patient_id, MIN(appointment_date) as next_appointment_date
    FROM appointments
    WHERE appointment_date >= TRUNC(SYSDATE)
      AND status IN ('Scheduled', 'Confirmed')
    GROUP BY patient_id
) next_appt ON p.patient_id = next_appt.patient_id
WHERE p.is_active = 'Y'
ORDER BY risk_score DESC, patient_name;

-- Report 10: Financial Summary (if billing data available)
-- Purpose: Basic financial metrics
-- Usage: Dashboard cards

SELECT 
    'This Month' as period,
    COUNT(DISTINCT a.appointment_id) as appointments,
    SUM(CASE WHEN a.status = 'Completed' THEN 1 ELSE 0 END) as completed_appointments,
    COUNT(DISTINCT a.patient_id) as unique_patients,
    COUNT(DISTINCT mr.record_id) as medical_records_created,
    COUNT(DISTINCT pr.prescription_id) as prescriptions_written
FROM appointments a
LEFT JOIN medical_records mr ON a.appointment_id = mr.appointment_id
LEFT JOIN prescriptions pr ON mr.record_id = pr.record_id
WHERE a.appointment_date >= TRUNC(SYSDATE, 'MM')
  AND a.appointment_date < TRUNC(ADD_MONTHS(SYSDATE, 1), 'MM')

UNION ALL

SELECT 
    'Last Month' as period,
    COUNT(DISTINCT a.appointment_id) as appointments,
    SUM(CASE WHEN a.status = 'Completed' THEN 1 ELSE 0 END) as completed_appointments,
    COUNT(DISTINCT a.patient_id) as unique_patients,
    COUNT(DISTINCT mr.record_id) as medical_records_created,
    COUNT(DISTINCT pr.prescription_id) as prescriptions_written
FROM appointments a
LEFT JOIN medical_records mr ON a.appointment_id = mr.appointment_id
LEFT JOIN prescriptions pr ON mr.record_id = pr.record_id
WHERE a.appointment_date >= TRUNC(ADD_MONTHS(SYSDATE, -1), 'MM')
  AND a.appointment_date < TRUNC(SYSDATE, 'MM');

-- Note: These reports use APEX bind variables (e.g., :P_DATE, :P_PATIENT_ID) 
-- that should be defined as page parameters in your APEX application.
