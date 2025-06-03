-- Healthcare System - Oracle APEX Cloud Setup
-- Part 8: Clinical Trials Views
-- Run this after Part 7

PROMPT ===============================================;
PROMPT Healthcare System - Part 8: Clinical Trials Views
PROMPT ===============================================;

-- Trial summary view
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
    CASE 
        WHEN ct.target_enrollment > 0 THEN 
            ROUND((ct.current_enrollment / ct.target_enrollment) * 100, 1)
        ELSE 0
    END as enrollment_percentage,
    ct.sponsor,
    ct.study_type,
    ct.therapeutic_area,
    ct.estimated_duration_months,
    ct.budget_amount,
    -- Primary investigator information
    pi.first_name || ' ' || pi.last_name as primary_investigator_name,
    pi.email as primary_investigator_email,
    -- Calculated metrics
    (SELECT COUNT(*) FROM trial_participants tp 
     WHERE tp.trial_id = ct.trial_id AND tp.status = 'Active') as active_participants,
    (SELECT COUNT(*) FROM adverse_events ae 
     WHERE ae.trial_id = ct.trial_id AND ae.serious = 'Y' 
     AND ae.event_date >= TRUNC(SYSDATE) - 30) as serious_adverse_events_last_30_days,
    (SELECT COUNT(*) FROM trial_visits tv 
     WHERE tv.trial_id = ct.trial_id AND tv.status = 'Scheduled' 
     AND tv.scheduled_date < TRUNC(SYSDATE)) as overdue_visits,
    (SELECT COUNT(*) FROM trial_milestones tm 
     WHERE tm.trial_id = ct.trial_id AND tm.status != 'Completed' 
     AND tm.planned_date < TRUNC(SYSDATE)) as overdue_milestones,
    -- Recent enrollment activity
    (SELECT COUNT(*) FROM trial_participants tp 
     WHERE tp.trial_id = ct.trial_id 
     AND tp.enrollment_date >= TRUNC(SYSDATE) - 30) as enrollments_last_30_days,
    (SELECT MAX(tp.enrollment_date) FROM trial_participants tp 
     WHERE tp.trial_id = ct.trial_id) as last_enrollment_date,
    -- Trial health score (0-100)
    CASE 
        WHEN ct.status NOT IN ('Active', 'Recruiting') THEN 0
        ELSE GREATEST(0, LEAST(100,
            (CASE WHEN ct.target_enrollment > 0 THEN 
                (ct.current_enrollment / ct.target_enrollment) * 40 
             ELSE 0 END) +
            (CASE WHEN (SELECT COUNT(*) FROM trial_milestones tm 
                       WHERE tm.trial_id = ct.trial_id AND tm.status != 'Completed' 
                       AND tm.planned_date < TRUNC(SYSDATE)) = 0 THEN 30 ELSE 0 END) +
            (CASE WHEN (SELECT COUNT(*) FROM adverse_events ae 
                       WHERE ae.trial_id = ct.trial_id AND ae.serious = 'Y' 
                       AND ae.event_date >= TRUNC(SYSDATE) - 30) = 0 THEN 30 ELSE 10 END)
        ))
    END as trial_health_score
FROM clinical_trials ct
LEFT JOIN providers pi ON ct.primary_investigator_id = pi.provider_id;

-- Trial participants view
CREATE OR REPLACE VIEW v_trial_participants AS
SELECT 
    tp.participant_id,
    tp.trial_id,
    tp.patient_id,
    tp.enrollment_date,
    tp.randomization_code,
    tp.study_arm,
    tp.status,
    tp.withdrawal_reason,
    tp.withdrawal_date,
    tp.informed_consent_date,
    tp.baseline_visit_date,
    tp.last_visit_date,
    tp.next_visit_date,
    tp.notes,
    -- Trial information
    ct.trial_name,
    ct.trial_number,
    ct.phase,
    ct.status as trial_status,
    -- Patient information
    p.first_name as patient_first_name,
    p.last_name as patient_last_name,
    p.first_name || ' ' || p.last_name as patient_name,
    p.date_of_birth,
    FLOOR(MONTHS_BETWEEN(SYSDATE, p.date_of_birth) / 12) as patient_age,
    p.gender,
    p.phone as patient_phone,
    -- Assigned provider
    pr.first_name || ' ' || pr.last_name as assigned_provider_name,
    -- Participation metrics
    (SELECT COUNT(*) FROM trial_visits tv 
     WHERE tv.participant_id = tp.participant_id) as total_visits,
    (SELECT COUNT(*) FROM trial_visits tv 
     WHERE tv.participant_id = tp.participant_id AND tv.status = 'Completed') as completed_visits,
    (SELECT COUNT(*) FROM adverse_events ae 
     WHERE ae.participant_id = tp.participant_id) as adverse_events_count,
    (SELECT COUNT(*) FROM adverse_events ae 
     WHERE ae.participant_id = tp.participant_id AND ae.serious = 'Y') as serious_adverse_events_count,
    -- Days in study
    CASE 
        WHEN tp.status = 'Active' THEN TRUNC(SYSDATE) - TRUNC(tp.enrollment_date)
        WHEN tp.withdrawal_date IS NOT NULL THEN TRUNC(tp.withdrawal_date) - TRUNC(tp.enrollment_date)
        ELSE TRUNC(SYSDATE) - TRUNC(tp.enrollment_date)
    END as days_in_study
FROM trial_participants tp
JOIN clinical_trials ct ON tp.trial_id = ct.trial_id
JOIN patients p ON tp.patient_id = p.patient_id
LEFT JOIN providers pr ON tp.assigned_provider_id = pr.provider_id;

PROMPT Clinical trials views created;

PROMPT ===============================================;
PROMPT Part 8 Complete - Continue with Part 9
PROMPT ===============================================;
