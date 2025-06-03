-- Clinical Trials Reports for APEX Application
-- Healthcare Management System
-- Created: June 2, 2025

-- Report 1: Clinical Trials Dashboard Summary
SELECT 
    'Clinical Trials Overview' as report_name,
    'Summary of all clinical trials with key metrics' as description,
    q'[
SELECT 
    trial_id,
    trial_name,
    trial_number,
    phase,
    status,
    TO_CHAR(start_date, 'MM/DD/YYYY') as start_date,
    TO_CHAR(end_date, 'MM/DD/YYYY') as end_date,
    target_enrollment,
    current_enrollment,
    enrollment_percentage || '%' as enrollment_pct,
    primary_investigator_name,
    sponsor,
    therapeutic_area,
    CASE 
        WHEN trial_health_score >= 80 THEN 'Excellent'
        WHEN trial_health_score >= 60 THEN 'Good'
        WHEN trial_health_score >= 40 THEN 'Fair'
        ELSE 'Needs Attention'
    END as health_status,
    active_participants,
    serious_adverse_events,
    overdue_visits,
    overdue_milestones
FROM v_trial_dashboard
ORDER BY trial_health_score DESC, enrollment_percentage DESC
    ]' as sql_query
FROM dual

UNION ALL

-- Report 2: Trial Enrollment Progress
SELECT 
    'Trial Enrollment Progress' as report_name,
    'Enrollment tracking and projections for active trials' as description,
    q'[
SELECT 
    ts.trial_name,
    ts.trial_number,
    ts.status,
    ts.target_enrollment,
    ts.current_enrollment,
    ts.enrollment_percentage || '%' as progress,
    ts.enrollments_last_30_days as recent_enrollments,
    CASE 
        WHEN ts.enrollment_percentage >= 100 THEN 'Complete'
        WHEN ts.enrollment_percentage >= 80 THEN 'Near Complete'
        WHEN ts.enrollment_percentage >= 50 THEN 'On Track'
        WHEN ts.enrollment_percentage >= 25 THEN 'Behind'
        ELSE 'Significantly Behind'
    END as enrollment_status,
    TO_CHAR(ts.last_enrollment_date, 'MM/DD/YYYY') as last_enrollment,
    ts.primary_investigator_name,
    ROUND(
        CASE 
            WHEN ts.enrollments_last_30_days > 0 AND ts.enrollment_percentage < 100 THEN
                ((ts.target_enrollment - ts.current_enrollment) / ts.enrollments_last_30_days) * 30
            ELSE NULL
        END, 0
    ) as projected_days_to_complete
FROM v_trial_summary ts
WHERE ts.status IN ('Active', 'Recruiting')
ORDER BY ts.enrollment_percentage DESC
    ]' as sql_query
FROM dual

UNION ALL

-- Report 3: Upcoming Trial Visits
SELECT 
    'Upcoming Trial Visits' as report_name,
    'Trial visits scheduled for the next 30 days' as description,
    q'[
SELECT 
    tv.trial_name,
    tv.patient_name,
    tv.visit_name,
    tv.visit_type,
    TO_CHAR(tv.scheduled_date, 'MM/DD/YYYY') as scheduled_date,
    tv.provider_name,
    tv.visit_status_indicator as status,
    CASE 
        WHEN tv.scheduled_date = TRUNC(SYSDATE) THEN 'TODAY'
        WHEN tv.scheduled_date = TRUNC(SYSDATE) + 1 THEN 'TOMORROW'
        WHEN tv.scheduled_date < TRUNC(SYSDATE) THEN 'OVERDUE'
        ELSE TO_CHAR(tv.scheduled_date - TRUNC(SYSDATE)) || ' days'
    END as time_indicator,
    tv.visit_window_start || ' to ' || tv.visit_window_end as visit_window
FROM v_trial_visits tv
WHERE tv.visit_status = 'Scheduled'
AND tv.scheduled_date BETWEEN TRUNC(SYSDATE) - 7 AND TRUNC(SYSDATE) + 30
ORDER BY tv.scheduled_date, tv.trial_name
    ]' as sql_query
FROM dual

UNION ALL

-- Report 4: Adverse Events Summary
SELECT 
    'Adverse Events Summary' as report_name,
    'Summary of adverse events by trial and severity' as description,
    q'[
SELECT 
    ae.trial_name,
    ae.event_term,
    ae.severity,
    ae.serious,
    ae.relationship_to_study,
    ae.patient_name,
    TO_CHAR(ae.event_date, 'MM/DD/YYYY') as event_date,
    ae.outcome,
    ae.regulatory_status,
    ae.reporting_provider_name,
    CASE 
        WHEN ae.resolution_date IS NOT NULL THEN 
            TO_CHAR(ae.resolution_date, 'MM/DD/YYYY')
        ELSE 'Ongoing'
    END as resolution_date,
    ae.days_to_resolution
FROM v_adverse_events ae
WHERE ae.event_date >= TRUNC(SYSDATE) - 90
ORDER BY ae.event_date DESC, ae.serious DESC, ae.severity
    ]' as sql_query
FROM dual

UNION ALL

-- Report 5: Trial Milestones Status
SELECT 
    'Trial Milestones Status' as report_name,
    'Progress tracking for trial milestones and deliverables' as description,
    q'[
SELECT 
    tm.trial_name,
    tm.milestone_name,
    tm.milestone_type,
    TO_CHAR(tm.planned_date, 'MM/DD/YYYY') as planned_date,
    CASE 
        WHEN tm.actual_date IS NOT NULL THEN 
            TO_CHAR(tm.actual_date, 'MM/DD/YYYY')
        ELSE NULL
    END as actual_date,
    tm.milestone_status,
    tm.completion_percentage || '%' as progress,
    tm.responsible_provider_name,
    CASE 
        WHEN tm.milestone_status_indicator = 'Overdue' THEN 
            tm.days_overdue || ' days overdue'
        WHEN tm.milestone_status_indicator = 'Due Today' THEN 
            'Due Today'
        WHEN tm.milestone_status_indicator = 'Upcoming' AND tm.planned_date <= TRUNC(SYSDATE) + 30 THEN
            (tm.planned_date - TRUNC(SYSDATE)) || ' days remaining'
        ELSE tm.milestone_status_indicator
    END as status_detail,
    tm.days_variance_from_planned
FROM v_trial_milestones tm
WHERE tm.milestone_status != 'Cancelled'
AND (tm.planned_date >= TRUNC(SYSDATE) - 30 OR tm.milestone_status != 'Completed')
ORDER BY 
    CASE tm.milestone_status_indicator 
        WHEN 'Overdue' THEN 1 
        WHEN 'Due Today' THEN 2 
        WHEN 'Upcoming' THEN 3 
        ELSE 4 
    END,
    tm.planned_date
    ]' as sql_query
FROM dual

UNION ALL

-- Report 6: Provider Clinical Trials Activity
SELECT 
    'Provider Clinical Trials Activity' as report_name,
    'Provider involvement and activity in clinical trials' as description,
    q'[
SELECT 
    pt.provider_name,
    pt.specialty,
    pt.department,
    pt.active_trials_as_pi as "Active Trials (PI)",
    pt.total_trials_as_pi as "Total Trials (PI)",
    pt.active_participants_managed as "Active Participants",
    pt.total_participants_managed as "Total Participants",
    pt.upcoming_visits_week as "Visits This Week",
    pt.visits_completed_month as "Visits Last Month",
    pt.adverse_events_reported_month as "AEs Reported (Month)",
    pt.active_milestones as "Active Milestones",
    CASE 
        WHEN pt.active_trials_as_pi > 0 THEN 'Primary Investigator'
        WHEN pt.active_participants_managed > 0 THEN 'Participant Manager'
        WHEN pt.upcoming_visits_week > 0 THEN 'Visit Provider'
        ELSE 'Support Role'
    END as primary_role
FROM v_provider_trials pt
ORDER BY 
    pt.active_trials_as_pi DESC,
    pt.active_participants_managed DESC,
    pt.provider_name
    ]' as sql_query
FROM dual

UNION ALL

-- Report 7: Trial Enrollment by Month
SELECT 
    'Trial Enrollment by Month' as report_name,
    'Monthly enrollment trends across all trials' as description,
    q'[
SELECT 
    TO_CHAR(tp.enrollment_date, 'YYYY-MM') as enrollment_month,
    COUNT(*) as total_enrollments,
    COUNT(DISTINCT tp.trial_id) as active_trials,
    COUNT(DISTINCT tp.patient_id) as unique_patients,
    ct.therapeutic_area,
    COUNT(CASE WHEN tp.status = 'Active' THEN 1 END) as still_active,
    COUNT(CASE WHEN tp.status = 'Withdrawn' THEN 1 END) as withdrawn,
    ROUND(
        COUNT(CASE WHEN tp.status = 'Active' THEN 1 END) / 
        NULLIF(COUNT(*), 0) * 100, 1
    ) as retention_rate_pct
FROM trial_participants tp
JOIN clinical_trials ct ON tp.trial_id = ct.trial_id
WHERE tp.enrollment_date >= TRUNC(SYSDATE) - 365
GROUP BY TO_CHAR(tp.enrollment_date, 'YYYY-MM'), ct.therapeutic_area
ORDER BY enrollment_month DESC, ct.therapeutic_area
    ]' as sql_query
FROM dual

UNION ALL

-- Report 8: Trial Safety Dashboard
SELECT 
    'Trial Safety Dashboard' as report_name,
    'Safety monitoring across all active trials' as description,
    q'[
SELECT 
    ct.trial_name,
    ct.current_enrollment,
    COUNT(DISTINCT ae.adverse_event_id) as total_aes,
    COUNT(DISTINCT CASE WHEN ae.serious = 'Y' THEN ae.adverse_event_id END) as serious_aes,
    COUNT(DISTINCT CASE WHEN ae.severity = 'Severe' THEN ae.adverse_event_id END) as severe_aes,
    COUNT(DISTINCT CASE WHEN ae.relationship_to_study IN ('Probable', 'Definite') THEN ae.adverse_event_id END) as related_aes,
    ROUND(
        COUNT(DISTINCT ae.adverse_event_id) / 
        NULLIF(ct.current_enrollment, 0), 2
    ) as ae_rate_per_participant,
    ROUND(
        COUNT(DISTINCT CASE WHEN ae.serious = 'Y' THEN ae.adverse_event_id END) / 
        NULLIF(ct.current_enrollment, 0) * 100, 1
    ) as serious_ae_rate_pct,
    COUNT(DISTINCT CASE WHEN ae.event_date >= TRUNC(SYSDATE) - 30 THEN ae.adverse_event_id END) as aes_last_30_days,
    ct.primary_investigator_name
FROM clinical_trials ct
LEFT JOIN adverse_events ae ON ct.trial_id = ae.trial_id
WHERE ct.status IN ('Active', 'Recruiting')
GROUP BY 
    ct.trial_name, ct.current_enrollment, ct.primary_investigator_name, ct.trial_id
ORDER BY serious_ae_rate_pct DESC NULLS LAST, ae_rate_per_participant DESC NULLS LAST
    ]' as sql_query
FROM dual

UNION ALL

-- Report 9: Trial Visit Compliance
SELECT 
    'Trial Visit Compliance' as report_name,
    'Visit compliance and scheduling metrics by trial' as description,
    q'[
SELECT 
    tv.trial_name,
    COUNT(*) as total_visits,
    COUNT(CASE WHEN tv.visit_status = 'Completed' THEN 1 END) as completed_visits,
    COUNT(CASE WHEN tv.visit_status = 'Scheduled' THEN 1 END) as scheduled_visits,
    COUNT(CASE WHEN tv.visit_status = 'Missed' THEN 1 END) as missed_visits,
    COUNT(CASE WHEN tv.visit_status_indicator = 'Overdue' THEN 1 END) as overdue_visits,
    ROUND(
        COUNT(CASE WHEN tv.visit_status = 'Completed' THEN 1 END) / 
        NULLIF(COUNT(CASE WHEN tv.visit_status IN ('Completed', 'Missed') THEN 1 END), 0) * 100, 1
    ) as completion_rate_pct,
    COUNT(CASE WHEN tv.visit_compliance = 'Within Window' THEN 1 END) as within_window,
    COUNT(CASE WHEN tv.visit_compliance = 'Early' THEN 1 END) as early_visits,
    COUNT(CASE WHEN tv.visit_compliance = 'Late' THEN 1 END) as late_visits,
    ROUND(
        COUNT(CASE WHEN tv.visit_compliance = 'Within Window' THEN 1 END) / 
        NULLIF(COUNT(CASE WHEN tv.visit_compliance IS NOT NULL THEN 1 END), 0) * 100, 1
    ) as window_compliance_pct
FROM v_trial_visits tv
GROUP BY tv.trial_name, tv.trial_id
ORDER BY completion_rate_pct DESC, window_compliance_pct DESC
    ]' as sql_query
FROM dual

UNION ALL

-- Report 10: Trial Budget and Resource Utilization
SELECT 
    'Trial Budget and Resource Utilization' as report_name,
    'Budget tracking and resource allocation for trials' as description,
    q'[
SELECT 
    ct.trial_name,
    ct.phase,
    ct.therapeutic_area,
    TO_CHAR(ct.budget_amount, '$999,999,999.99') as total_budget,
    ct.target_enrollment,
    ct.current_enrollment,
    ROUND(ct.budget_amount / NULLIF(ct.target_enrollment, 0), 2) as budget_per_target_participant,
    ROUND(ct.budget_amount / NULLIF(ct.current_enrollment, 0), 2) as budget_per_enrolled_participant,
    ct.estimated_duration_months,
    ROUND(ct.budget_amount / NULLIF(ct.estimated_duration_months, 0), 2) as monthly_budget,
    CASE 
        WHEN ct.start_date IS NOT NULL AND ct.end_date IS NOT NULL THEN
            ROUND(MONTHS_BETWEEN(SYSDATE, ct.start_date), 1)
        ELSE NULL
    END as months_active,
    ct.sponsor,
    ct.primary_investigator_name,
    COUNT(DISTINCT tp.participant_id) as actual_participants,
    COUNT(DISTINCT tv.visit_id) as total_visits_conducted
FROM clinical_trials ct
LEFT JOIN trial_participants tp ON ct.trial_id = tp.trial_id
LEFT JOIN trial_visits tv ON ct.trial_id = tv.trial_id AND tv.status = 'Completed'
WHERE ct.is_active = 'Y'
GROUP BY 
    ct.trial_name, ct.phase, ct.therapeutic_area, ct.budget_amount,
    ct.target_enrollment, ct.current_enrollment, ct.estimated_duration_months,
    ct.start_date, ct.end_date, ct.sponsor, ct.primary_investigator_name, ct.trial_id
ORDER BY ct.budget_amount DESC
    ]' as sql_query
FROM dual;
