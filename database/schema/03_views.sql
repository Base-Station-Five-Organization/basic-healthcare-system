-- Healthcare System Database Views
-- Views for reporting and APEX application pages

-- View for patient summary with calculated fields
CREATE OR REPLACE VIEW v_patient_summary AS
SELECT 
    p.patient_id,
    p.first_name,
    p.last_name,
    pkg_patient_mgmt.get_full_name(p.first_name, p.last_name) as full_name,
    p.date_of_birth,
    pkg_patient_mgmt.get_patient_age(p.patient_id) as age,
    p.gender,
    p.phone,
    p.email,
    p.address,
    p.city,
    p.state,
    p.zip_code,
    p.emergency_contact_name,
    p.emergency_contact_phone,
    p.insurance_provider,
    p.insurance_policy_number,
    p.blood_type,
    p.allergies,
    p.medical_conditions,
    p.is_active,
    p.created_date,
    -- Calculated fields
    (SELECT COUNT(*) 
     FROM appointments a 
     WHERE a.patient_id = p.patient_id 
       AND a.status = 'Completed') as total_visits,
    (SELECT MAX(a.appointment_date) 
     FROM appointments a 
     WHERE a.patient_id = p.patient_id 
       AND a.status = 'Completed') as last_visit_date,
    (SELECT MIN(a.appointment_date) 
     FROM appointments a 
     WHERE a.patient_id = p.patient_id 
       AND a.appointment_date >= TRUNC(SYSDATE)
       AND a.status IN ('Scheduled', 'Confirmed')) as next_appointment_date,
    (SELECT COUNT(*) 
     FROM appointments a 
     WHERE a.patient_id = p.patient_id 
       AND a.appointment_date >= TRUNC(SYSDATE)
       AND a.status IN ('Scheduled', 'Confirmed')) as upcoming_appointments,
    (SELECT COUNT(DISTINCT pr.medication_name) 
     FROM prescriptions pr 
     WHERE pr.patient_id = p.patient_id 
       AND pr.is_active = 'Y') as active_medications
FROM patients p
WHERE p.is_active = 'Y';

-- View for appointment details with patient and provider information
CREATE OR REPLACE VIEW v_appointment_details AS
SELECT 
    a.appointment_id,
    a.appointment_date,
    a.appointment_time,
    a.duration_minutes,
    a.appointment_type,
    a.status,
    a.reason_for_visit,
    a.notes,
    a.created_date,
    a.modified_date,
    -- Patient information
    a.patient_id,
    p.first_name as patient_first_name,
    p.last_name as patient_last_name,
    pkg_patient_mgmt.get_full_name(p.first_name, p.last_name) as patient_name,
    pkg_patient_mgmt.get_patient_age(p.patient_id) as patient_age,
    p.phone as patient_phone,
    p.email as patient_email,
    -- Provider information
    a.provider_id,
    pr.first_name as provider_first_name,
    pr.last_name as provider_last_name,
    pkg_patient_mgmt.get_full_name(pr.first_name, pr.last_name) as provider_name,
    pr.title as provider_title,
    pr.specialty as provider_specialty,
    pr.department as provider_department,
    -- Calculated fields
    CASE 
        WHEN a.appointment_date < TRUNC(SYSDATE) THEN 'Past'
        WHEN a.appointment_date = TRUNC(SYSDATE) THEN 'Today'
        WHEN a.appointment_date = TRUNC(SYSDATE) + 1 THEN 'Tomorrow'
        ELSE 'Future'
    END as appointment_timing,
    TO_CHAR(a.appointment_date, 'Day, Month DD, YYYY') as formatted_date,
    TO_CHAR(TO_DATE(a.appointment_time, 'HH24:MI'), 'HH12:MI AM') as formatted_time,
    CASE a.status
        WHEN 'Scheduled' THEN 'warning'
        WHEN 'Confirmed' THEN 'info'
        WHEN 'In Progress' THEN 'primary'
        WHEN 'Completed' THEN 'success'
        WHEN 'Cancelled' THEN 'danger'
        WHEN 'No Show' THEN 'danger'
        ELSE 'secondary'
    END as status_color
FROM appointments a
JOIN patients p ON a.patient_id = p.patient_id
JOIN providers pr ON a.provider_id = pr.provider_id;

-- View for provider schedule with availability
CREATE OR REPLACE VIEW v_provider_schedule AS
SELECT 
    pr.provider_id,
    pr.first_name,
    pr.last_name,
    pkg_patient_mgmt.get_full_name(pr.first_name, pr.last_name) as provider_name,
    pr.title,
    pr.specialty,
    pr.department,
    cal.schedule_date,
    TO_CHAR(cal.schedule_date, 'Day') as day_of_week,
    -- Count appointments by status
    NVL(appt_stats.total_appointments, 0) as total_appointments,
    NVL(appt_stats.scheduled_count, 0) as scheduled_count,
    NVL(appt_stats.confirmed_count, 0) as confirmed_count,
    NVL(appt_stats.completed_count, 0) as completed_count,
    NVL(appt_stats.cancelled_count, 0) as cancelled_count,
    -- Calculate availability
    CASE 
        WHEN cal.schedule_date < TRUNC(SYSDATE) THEN 'Past'
        WHEN NVL(appt_stats.active_appointments, 0) >= 16 THEN 'Full' -- 8 hours * 2 slots per hour
        WHEN NVL(appt_stats.active_appointments, 0) >= 12 THEN 'Busy'
        WHEN NVL(appt_stats.active_appointments, 0) >= 6 THEN 'Moderate'
        ELSE 'Available'
    END as availability_status
FROM providers pr
CROSS JOIN (
    -- Generate dates for the next 30 days
    SELECT TRUNC(SYSDATE) + LEVEL - 1 as schedule_date
    FROM DUAL
    CONNECT BY LEVEL <= 30
) cal
LEFT JOIN (
    SELECT 
        provider_id,
        appointment_date,
        COUNT(*) as total_appointments,
        SUM(CASE WHEN status IN ('Scheduled', 'Confirmed', 'In Progress') THEN 1 ELSE 0 END) as active_appointments,
        SUM(CASE WHEN status = 'Scheduled' THEN 1 ELSE 0 END) as scheduled_count,
        SUM(CASE WHEN status = 'Confirmed' THEN 1 ELSE 0 END) as confirmed_count,
        SUM(CASE WHEN status = 'Completed' THEN 1 ELSE 0 END) as completed_count,
        SUM(CASE WHEN status = 'Cancelled' THEN 1 ELSE 0 END) as cancelled_count
    FROM appointments
    GROUP BY provider_id, appointment_date
) appt_stats ON pr.provider_id = appt_stats.provider_id 
                AND cal.schedule_date = appt_stats.appointment_date
WHERE pr.is_active = 'Y'
  AND TO_CHAR(cal.schedule_date, 'D') NOT IN ('1', '7') -- Exclude weekends
ORDER BY pr.last_name, pr.first_name, cal.schedule_date;

-- View for medical records with patient information
CREATE OR REPLACE VIEW v_medical_records AS
SELECT 
    mr.record_id,
    mr.visit_date,
    mr.chief_complaint,
    mr.history_of_present_illness,
    mr.physical_examination,
    mr.vital_signs,
    mr.diagnosis,
    mr.treatment_plan,
    mr.follow_up_instructions,
    mr.created_date,
    -- Patient information
    mr.patient_id,
    p.first_name as patient_first_name,
    p.last_name as patient_last_name,
    pkg_patient_mgmt.get_full_name(p.first_name, p.last_name) as patient_name,
    pkg_patient_mgmt.get_patient_age(p.patient_id) as patient_age,
    p.gender as patient_gender,
    p.blood_type,
    p.allergies,
    p.medical_conditions,
    -- Provider information
    mr.provider_id,
    pr.first_name as provider_first_name,
    pr.last_name as provider_last_name,
    pkg_patient_mgmt.get_full_name(pr.first_name, pr.last_name) as provider_name,
    pr.title as provider_title,
    pr.specialty as provider_specialty,
    -- Appointment information
    mr.appointment_id,
    a.appointment_type,
    a.reason_for_visit,
    -- Calculated fields
    TO_CHAR(mr.visit_date, 'Month DD, YYYY') as formatted_visit_date,
    CASE 
        WHEN mr.visit_date >= TRUNC(SYSDATE) - 7 THEN 'Recent'
        WHEN mr.visit_date >= TRUNC(SYSDATE) - 30 THEN 'This Month'
        WHEN mr.visit_date >= TRUNC(SYSDATE) - 90 THEN 'Last 3 Months'
        ELSE 'Older'
    END as visit_recency
FROM medical_records mr
JOIN patients p ON mr.patient_id = p.patient_id
JOIN providers pr ON mr.provider_id = pr.provider_id
LEFT JOIN appointments a ON mr.appointment_id = a.appointment_id;

-- View for active prescriptions
CREATE OR REPLACE VIEW v_active_prescriptions AS
SELECT 
    pr.prescription_id,
    pr.medication_name,
    pr.dosage,
    pr.frequency,
    pr.duration,
    pr.quantity,
    pr.refills_allowed,
    pr.instructions,
    pr.date_prescribed,
    pr.is_active,
    -- Patient information
    pr.patient_id,
    p.first_name as patient_first_name,
    p.last_name as patient_last_name,
    pkg_patient_mgmt.get_full_name(p.first_name, p.last_name) as patient_name,
    pkg_patient_mgmt.get_patient_age(p.patient_id) as patient_age,
    -- Provider information
    pr.provider_id,
    prov.first_name as provider_first_name,
    prov.last_name as provider_last_name,
    pkg_patient_mgmt.get_full_name(prov.first_name, prov.last_name) as provider_name,
    prov.title as provider_title,
    -- Medical record information
    pr.record_id,
    mr.visit_date,
    mr.diagnosis,
    -- Calculated fields
    TO_CHAR(pr.date_prescribed, 'MM/DD/YYYY') as formatted_date_prescribed,
    TRUNC(SYSDATE - pr.date_prescribed) as days_since_prescribed,
    CASE 
        WHEN pr.date_prescribed >= TRUNC(SYSDATE) - 30 THEN 'New'
        WHEN pr.date_prescribed >= TRUNC(SYSDATE) - 90 THEN 'Recent'
        ELSE 'Long-term'
    END as prescription_age
FROM prescriptions pr
JOIN patients p ON pr.patient_id = p.patient_id
JOIN providers prov ON pr.provider_id = prov.provider_id
LEFT JOIN medical_records mr ON pr.record_id = mr.record_id
WHERE pr.is_active = 'Y'
ORDER BY pr.date_prescribed DESC;

-- View for dashboard statistics
CREATE OR REPLACE VIEW v_dashboard_stats AS
SELECT 
    'Today' as metric_period,
    (SELECT COUNT(*) FROM appointments WHERE appointment_date = TRUNC(SYSDATE)) as total_appointments,
    (SELECT COUNT(*) FROM appointments WHERE appointment_date = TRUNC(SYSDATE) AND status = 'Scheduled') as scheduled_appointments,
    (SELECT COUNT(*) FROM appointments WHERE appointment_date = TRUNC(SYSDATE) AND status = 'Completed') as completed_appointments,
    (SELECT COUNT(*) FROM appointments WHERE appointment_date = TRUNC(SYSDATE) AND status = 'Cancelled') as cancelled_appointments,
    (SELECT COUNT(*) FROM medical_records WHERE visit_date = TRUNC(SYSDATE)) as new_records,
    (SELECT COUNT(*) FROM prescriptions WHERE date_prescribed = TRUNC(SYSDATE)) as new_prescriptions,
    (SELECT COUNT(*) FROM patients WHERE created_date >= TRUNC(SYSDATE)) as new_patients
FROM DUAL
UNION ALL
SELECT 
    'This Week' as metric_period,
    (SELECT COUNT(*) FROM appointments WHERE appointment_date >= TRUNC(SYSDATE, 'IW')) as total_appointments,
    (SELECT COUNT(*) FROM appointments WHERE appointment_date >= TRUNC(SYSDATE, 'IW') AND status = 'Scheduled') as scheduled_appointments,
    (SELECT COUNT(*) FROM appointments WHERE appointment_date >= TRUNC(SYSDATE, 'IW') AND status = 'Completed') as completed_appointments,
    (SELECT COUNT(*) FROM appointments WHERE appointment_date >= TRUNC(SYSDATE, 'IW') AND status = 'Cancelled') as cancelled_appointments,
    (SELECT COUNT(*) FROM medical_records WHERE visit_date >= TRUNC(SYSDATE, 'IW')) as new_records,
    (SELECT COUNT(*) FROM prescriptions WHERE date_prescribed >= TRUNC(SYSDATE, 'IW')) as new_prescriptions,
    (SELECT COUNT(*) FROM patients WHERE created_date >= TRUNC(SYSDATE, 'IW')) as new_patients
FROM DUAL
UNION ALL
SELECT 
    'This Month' as metric_period,
    (SELECT COUNT(*) FROM appointments WHERE appointment_date >= TRUNC(SYSDATE, 'MM')) as total_appointments,
    (SELECT COUNT(*) FROM appointments WHERE appointment_date >= TRUNC(SYSDATE, 'MM') AND status = 'Scheduled') as scheduled_appointments,
    (SELECT COUNT(*) FROM appointments WHERE appointment_date >= TRUNC(SYSDATE, 'MM') AND status = 'Completed') as completed_appointments,
    (SELECT COUNT(*) FROM appointments WHERE appointment_date >= TRUNC(SYSDATE, 'MM') AND status = 'Cancelled') as cancelled_appointments,
    (SELECT COUNT(*) FROM medical_records WHERE visit_date >= TRUNC(SYSDATE, 'MM')) as new_records,
    (SELECT COUNT(*) FROM prescriptions WHERE date_prescribed >= TRUNC(SYSDATE, 'MM')) as new_prescriptions,
    (SELECT COUNT(*) FROM patients WHERE created_date >= TRUNC(SYSDATE, 'MM')) as new_patients
FROM DUAL;

-- Clinical Trials Views

-- View for comprehensive trial information with enrollment metrics
CREATE OR REPLACE VIEW v_trial_summary AS
SELECT 
    ct.trial_id,
    ct.trial_name,
    ct.trial_number,
    ct.description,
    ct.phase,
    ct.status,
    ct.start_date,
    ct.end_date,
    ct.target_enrollment,
    ct.current_enrollment,
    ROUND((ct.current_enrollment / NULLIF(ct.target_enrollment, 0)) * 100, 1) as enrollment_percentage,
    ct.sponsor,
    ct.study_type,
    ct.therapeutic_area,
    ct.estimated_duration_months,
    ct.budget_amount,
    -- Primary investigator information
    pi.first_name || ' ' || pi.last_name as primary_investigator_name,
    pi.email as investigator_email,
    pi.phone as investigator_phone,
    -- Trial progress metrics
    CASE 
        WHEN ct.start_date > SYSDATE THEN 'Not Started'
        WHEN ct.end_date < SYSDATE THEN 'Past End Date'
        WHEN ct.status = 'Completed' THEN 'Completed'
        WHEN ct.status = 'Active' THEN 'In Progress'
        ELSE ct.status
    END as progress_status,
    CASE 
        WHEN ct.start_date IS NOT NULL AND ct.end_date IS NOT NULL THEN
            ROUND(((SYSDATE - ct.start_date) / NULLIF((ct.end_date - ct.start_date), 0)) * 100, 1)
        ELSE NULL
    END as time_progress_percentage,
    -- Enrollment metrics
    (SELECT COUNT(*) FROM trial_participants tp WHERE tp.trial_id = ct.trial_id AND tp.status = 'Active') as active_participants,
    (SELECT COUNT(*) FROM trial_participants tp WHERE tp.trial_id = ct.trial_id AND tp.status = 'Completed') as completed_participants,
    (SELECT COUNT(*) FROM trial_participants tp WHERE tp.trial_id = ct.trial_id AND tp.status = 'Withdrawn') as withdrawn_participants,
    -- Recent activity
    (SELECT MAX(tp.enrollment_date) FROM trial_participants tp WHERE tp.trial_id = ct.trial_id) as last_enrollment_date,
    (SELECT COUNT(*) FROM trial_participants tp WHERE tp.trial_id = ct.trial_id AND tp.enrollment_date >= TRUNC(SYSDATE) - 30) as enrollments_last_30_days,
    ct.is_active,
    ct.created_date,
    ct.modified_date
FROM clinical_trials ct
LEFT JOIN providers pi ON ct.primary_investigator_id = pi.provider_id
WHERE ct.is_active = 'Y';

-- View for trial participants with patient and provider details
CREATE OR REPLACE VIEW v_trial_participants AS
SELECT 
    tp.participant_id,
    tp.trial_id,
    tp.patient_id,
    tp.enrollment_date,
    tp.randomization_code,
    tp.study_arm,
    tp.status as participant_status,
    tp.withdrawal_reason,
    tp.withdrawal_date,
    tp.informed_consent_date,
    tp.baseline_visit_date,
    tp.last_visit_date,
    tp.next_visit_date,
    tp.notes,
    -- Patient information
    p.first_name || ' ' || p.last_name as patient_name,
    p.date_of_birth,
    FLOOR(MONTHS_BETWEEN(SYSDATE, p.date_of_birth) / 12) as patient_age,
    p.gender,
    p.phone as patient_phone,
    p.email as patient_email,
    -- Trial information
    ct.trial_name,
    ct.trial_number,
    ct.phase,
    ct.status as trial_status,
    -- Assigned provider information
    ap.first_name || ' ' || ap.last_name as assigned_provider_name,
    ap.specialty as provider_specialty,
    ap.phone as provider_phone,
    ap.email as provider_email,
    -- Participation metrics
    CASE 
        WHEN tp.status = 'Active' AND tp.enrollment_date IS NOT NULL THEN
            TRUNC(SYSDATE - tp.enrollment_date)
        ELSE NULL
    END as days_in_study,
    (SELECT COUNT(*) FROM trial_visits tv WHERE tv.participant_id = tp.participant_id AND tv.status = 'Completed') as completed_visits,
    (SELECT COUNT(*) FROM trial_visits tv WHERE tv.participant_id = tp.participant_id AND tv.status = 'Scheduled') as scheduled_visits,
    (SELECT COUNT(*) FROM adverse_events ae WHERE ae.participant_id = tp.participant_id) as total_adverse_events,
    (SELECT COUNT(*) FROM adverse_events ae WHERE ae.participant_id = tp.participant_id AND ae.serious = 'Y') as serious_adverse_events,
    tp.created_date,
    tp.modified_date
FROM trial_participants tp
JOIN patients p ON tp.patient_id = p.patient_id
JOIN clinical_trials ct ON tp.trial_id = ct.trial_id
LEFT JOIN providers ap ON tp.assigned_provider_id = ap.provider_id;

-- View for trial visits with comprehensive details
CREATE OR REPLACE VIEW v_trial_visits AS
SELECT 
    tv.visit_id,
    tv.participant_id,
    tv.trial_id,
    tv.visit_number,
    tv.visit_name,
    tv.visit_type,
    tv.scheduled_date,
    tv.actual_date,
    tv.visit_window_start,
    tv.visit_window_end,
    tv.status as visit_status,
    tv.visit_notes,
    tv.procedures_completed,
    tv.assessments_completed,
    -- Patient information
    p.first_name || ' ' || p.last_name as patient_name,
    p.patient_id,
    -- Trial information
    ct.trial_name,
    ct.trial_number,
    -- Provider information
    pr.first_name || ' ' || pr.last_name as provider_name,
    pr.specialty,
    -- Visit compliance metrics
    CASE 
        WHEN tv.actual_date IS NOT NULL AND tv.visit_window_start IS NOT NULL AND tv.visit_window_end IS NOT NULL THEN
            CASE 
                WHEN tv.actual_date BETWEEN tv.visit_window_start AND tv.visit_window_end THEN 'Within Window'
                WHEN tv.actual_date < tv.visit_window_start THEN 'Early'
                WHEN tv.actual_date > tv.visit_window_end THEN 'Late'
                ELSE 'Unknown'
            END
        ELSE NULL
    END as visit_compliance,
    CASE 
        WHEN tv.actual_date IS NOT NULL AND tv.scheduled_date IS NOT NULL THEN
            tv.actual_date - tv.scheduled_date
        ELSE NULL
    END as days_from_scheduled,
    -- Status indicators
    CASE 
        WHEN tv.status = 'Scheduled' AND tv.scheduled_date < TRUNC(SYSDATE) THEN 'Overdue'
        WHEN tv.status = 'Scheduled' AND tv.scheduled_date = TRUNC(SYSDATE) THEN 'Due Today'
        WHEN tv.status = 'Scheduled' AND tv.scheduled_date > TRUNC(SYSDATE) THEN 'Upcoming'
        ELSE tv.status
    END as visit_status_indicator,
    tv.created_date,
    tv.modified_date
FROM trial_visits tv
JOIN trial_participants tp ON tv.participant_id = tp.participant_id
JOIN patients p ON tp.patient_id = p.patient_id
JOIN clinical_trials ct ON tv.trial_id = ct.trial_id
LEFT JOIN providers pr ON tv.provider_id = pr.provider_id;

-- View for adverse events with participant and trial context
CREATE OR REPLACE VIEW v_adverse_events AS
SELECT 
    ae.adverse_event_id,
    ae.participant_id,
    ae.trial_id,
    ae.event_date,
    ae.event_term,
    ae.description,
    ae.severity,
    ae.relationship_to_study,
    ae.outcome,
    ae.serious,
    ae.expected,
    ae.reported_date,
    ae.resolution_date,
    ae.regulatory_reported,
    ae.regulatory_report_date,
    ae.follow_up_required,
    ae.action_taken,
    -- Patient information
    p.first_name || ' ' || p.last_name as patient_name,
    p.patient_id,
    p.date_of_birth,
    FLOOR(MONTHS_BETWEEN(ae.event_date, p.date_of_birth) / 12) as patient_age_at_event,
    p.gender,
    -- Trial information
    ct.trial_name,
    ct.trial_number,
    ct.phase,
    -- Reporting provider information
    rp.first_name || ' ' || rp.last_name as reporting_provider_name,
    rp.specialty as reporter_specialty,
    -- Event metrics
    CASE 
        WHEN ae.resolution_date IS NOT NULL THEN
            ae.resolution_date - ae.event_date
        ELSE 
            TRUNC(SYSDATE) - ae.event_date
    END as days_to_resolution,
    CASE 
        WHEN ae.serious = 'Y' AND ae.regulatory_reported = 'N' THEN 'Pending Regulatory Report'
        WHEN ae.serious = 'Y' AND ae.regulatory_reported = 'Y' THEN 'Reported to Regulatory'
        WHEN ae.follow_up_required = 'Y' AND ae.outcome NOT IN ('Recovered', 'Fatal') THEN 'Follow-up Required'
        ELSE 'Standard Monitoring'
    END as regulatory_status,
    ae.created_date,
    ae.modified_date
FROM adverse_events ae
JOIN trial_participants tp ON ae.participant_id = tp.participant_id
JOIN patients p ON tp.patient_id = p.patient_id
JOIN clinical_trials ct ON ae.trial_id = ct.trial_id
JOIN providers rp ON ae.reporting_provider_id = rp.provider_id;

-- View for trial milestones with progress tracking
CREATE OR REPLACE VIEW v_trial_milestones AS
SELECT 
    tm.milestone_id,
    tm.trial_id,
    tm.milestone_name,
    tm.description,
    tm.planned_date,
    tm.actual_date,
    tm.status as milestone_status,
    tm.milestone_type,
    tm.completion_percentage,
    tm.notes,
    -- Trial information
    ct.trial_name,
    ct.trial_number,
    ct.status as trial_status,
    -- Responsible provider information
    rp.first_name || ' ' || rp.last_name as responsible_provider_name,
    rp.email as provider_email,
    -- Progress metrics
    CASE 
        WHEN tm.actual_date IS NOT NULL THEN 'Completed'
        WHEN tm.planned_date < TRUNC(SYSDATE) AND tm.status != 'Completed' THEN 'Overdue'
        WHEN tm.planned_date = TRUNC(SYSDATE) AND tm.status != 'Completed' THEN 'Due Today'
        WHEN tm.planned_date > TRUNC(SYSDATE) THEN 'Upcoming'
        ELSE tm.status
    END as milestone_status_indicator,
    CASE 
        WHEN tm.actual_date IS NOT NULL AND tm.planned_date IS NOT NULL THEN
            tm.actual_date - tm.planned_date
        ELSE NULL
    END as days_variance_from_planned,
    CASE 
        WHEN tm.planned_date IS NOT NULL THEN
            GREATEST(0, TRUNC(SYSDATE) - tm.planned_date)
        ELSE NULL
    END as days_overdue,
    tm.created_date,
    tm.modified_date
FROM trial_milestones tm
JOIN clinical_trials ct ON tm.trial_id = ct.trial_id
LEFT JOIN providers rp ON tm.responsible_provider_id = rp.provider_id;

-- View for comprehensive trial dashboard metrics
CREATE OR REPLACE VIEW v_trial_dashboard AS
SELECT 
    ct.trial_id,
    ct.trial_name,
    ct.trial_number,
    ct.status,
    ct.phase,
    ct.start_date,
    ct.end_date,
    ct.target_enrollment,
    ct.current_enrollment,
    ROUND((ct.current_enrollment / NULLIF(ct.target_enrollment, 0)) * 100, 1) as enrollment_percentage,
    -- Enrollment metrics
    (SELECT COUNT(*) FROM trial_participants tp WHERE tp.trial_id = ct.trial_id AND tp.status = 'Active') as active_participants,
    (SELECT COUNT(*) FROM trial_participants tp WHERE tp.trial_id = ct.trial_id AND tp.enrollment_date >= TRUNC(SYSDATE) - 30) as recent_enrollments,
    -- Visit metrics
    (SELECT COUNT(*) FROM trial_visits tv WHERE tv.trial_id = ct.trial_id AND tv.status = 'Scheduled' AND tv.scheduled_date <= TRUNC(SYSDATE) + 7) as upcoming_visits_week,
    (SELECT COUNT(*) FROM trial_visits tv WHERE tv.trial_id = ct.trial_id AND tv.status = 'Scheduled' AND tv.scheduled_date < TRUNC(SYSDATE)) as overdue_visits,
    -- Safety metrics
    (SELECT COUNT(*) FROM adverse_events ae WHERE ae.trial_id = ct.trial_id AND ae.serious = 'Y') as serious_adverse_events,
    (SELECT COUNT(*) FROM adverse_events ae WHERE ae.trial_id = ct.trial_id AND ae.event_date >= TRUNC(SYSDATE) - 30) as recent_adverse_events,
    -- Milestone metrics
    (SELECT COUNT(*) FROM trial_milestones tm WHERE tm.trial_id = ct.trial_id AND tm.status = 'Completed') as completed_milestones,
    (SELECT COUNT(*) FROM trial_milestones tm WHERE tm.trial_id = ct.trial_id AND tm.planned_date < TRUNC(SYSDATE) AND tm.status != 'Completed') as overdue_milestones,
    -- Provider information
    pi.first_name || ' ' || pi.last_name as primary_investigator_name,
    -- Overall health score (simple calculation)
    CASE 
        WHEN ct.status NOT IN ('Active', 'Recruiting') THEN 0
        ELSE 
            GREATEST(0, LEAST(100, 
                ROUND(
                    (CASE WHEN ct.target_enrollment > 0 THEN (ct.current_enrollment / ct.target_enrollment) * 40 ELSE 0 END) +
                    (CASE WHEN (SELECT COUNT(*) FROM trial_visits tv WHERE tv.trial_id = ct.trial_id AND tv.status = 'Scheduled' AND tv.scheduled_date < TRUNC(SYSDATE)) = 0 THEN 30 ELSE 15 END) +
                    (CASE WHEN (SELECT COUNT(*) FROM adverse_events ae WHERE ae.trial_id = ct.trial_id AND ae.serious = 'Y' AND ae.event_date >= TRUNC(SYSDATE) - 30) = 0 THEN 30 ELSE 10 END), 0)
            ))
    END as trial_health_score
FROM clinical_trials ct
LEFT JOIN providers pi ON ct.primary_investigator_id = pi.provider_id
WHERE ct.is_active = 'Y';

-- View for provider involvement in clinical trials
CREATE OR REPLACE VIEW v_provider_trials AS
SELECT 
    p.provider_id,
    p.first_name || ' ' || p.last_name as provider_name,
    p.specialty,
    p.department,
    -- Primary investigator trials
    (SELECT COUNT(*) FROM clinical_trials ct WHERE ct.primary_investigator_id = p.provider_id AND ct.status IN ('Active', 'Recruiting')) as active_trials_as_pi,
    (SELECT COUNT(*) FROM clinical_trials ct WHERE ct.primary_investigator_id = p.provider_id) as total_trials_as_pi,
    -- Participant management
    (SELECT COUNT(DISTINCT tp.participant_id) FROM trial_participants tp WHERE tp.assigned_provider_id = p.provider_id AND tp.status = 'Active') as active_participants_managed,
    (SELECT COUNT(DISTINCT tp.participant_id) FROM trial_participants tp WHERE tp.assigned_provider_id = p.provider_id) as total_participants_managed,
    -- Visit activity
    (SELECT COUNT(*) FROM trial_visits tv WHERE tv.provider_id = p.provider_id AND tv.scheduled_date >= TRUNC(SYSDATE) AND tv.scheduled_date <= TRUNC(SYSDATE) + 7) as upcoming_visits_week,
    (SELECT COUNT(*) FROM trial_visits tv WHERE tv.provider_id = p.provider_id AND tv.status = 'Completed' AND tv.actual_date >= TRUNC(SYSDATE) - 30) as visits_completed_month,
    -- Adverse event reporting
    (SELECT COUNT(*) FROM adverse_events ae WHERE ae.reporting_provider_id = p.provider_id AND ae.event_date >= TRUNC(SYSDATE) - 30) as adverse_events_reported_month,
    -- Milestone responsibility
    (SELECT COUNT(*) FROM trial_milestones tm WHERE tm.responsible_provider_id = p.provider_id AND tm.status NOT IN ('Completed', 'Cancelled')) as active_milestones,
    p.is_active
FROM providers p
WHERE p.is_active = 'Y'
AND (
    EXISTS (SELECT 1 FROM clinical_trials ct WHERE ct.primary_investigator_id = p.provider_id) OR
    EXISTS (SELECT 1 FROM trial_participants tp WHERE tp.assigned_provider_id = p.provider_id) OR
    EXISTS (SELECT 1 FROM trial_visits tv WHERE tv.provider_id = p.provider_id) OR
    EXISTS (SELECT 1 FROM adverse_events ae WHERE ae.reporting_provider_id = p.provider_id) OR
    EXISTS (SELECT 1 FROM trial_milestones tm WHERE tm.responsible_provider_id = p.provider_id)
);

-- Create indexes on views for better performance
CREATE INDEX idx_appointments_date_status ON appointments(appointment_date, status);
CREATE INDEX idx_appointments_provider_date ON appointments(provider_id, appointment_date);
CREATE INDEX idx_medical_records_visit_date ON medical_records(visit_date);
CREATE INDEX idx_prescriptions_date_active ON prescriptions(date_prescribed, is_active);

-- Add comments to views
COMMENT ON VIEW v_patient_summary IS 'Patient summary with calculated fields for demographics and visit statistics';
COMMENT ON VIEW v_appointment_details IS 'Comprehensive appointment view with patient and provider details';
COMMENT ON VIEW v_provider_schedule IS 'Provider availability and schedule view with appointment statistics';
COMMENT ON VIEW v_medical_records IS 'Medical records with patient and provider information';
COMMENT ON VIEW v_active_prescriptions IS 'Active prescriptions with patient and provider details';
COMMENT ON VIEW v_dashboard_stats IS 'Dashboard statistics for different time periods';
COMMENT ON VIEW v_trial_summary IS 'Comprehensive trial information with enrollment and progress metrics';
COMMENT ON VIEW v_trial_participants IS 'Trial participants with patient details and participation metrics';
COMMENT ON VIEW v_trial_visits IS 'Trial visits with compliance and scheduling information';
COMMENT ON VIEW v_adverse_events IS 'Adverse events with patient, trial, and regulatory context';
COMMENT ON VIEW v_trial_milestones IS 'Trial milestones with progress tracking and deadline monitoring';
COMMENT ON VIEW v_trial_dashboard IS 'Dashboard metrics for trial monitoring and management';
COMMENT ON VIEW v_provider_trials IS 'Provider involvement and activity in clinical trials';
