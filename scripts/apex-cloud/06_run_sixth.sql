-- Healthcare System - Oracle APEX Cloud Setup
-- Part 6: Clinical Trials Sample Data
-- Run this after Part 5

PROMPT ===============================================;
PROMPT Healthcare System - Part 6: Clinical Trials Sample Data
PROMPT ===============================================;

-- Insert sample clinical trials
INSERT INTO clinical_trials (
    trial_name, trial_number, description, phase, status, start_date, end_date,
    target_enrollment, primary_investigator_id, sponsor, study_type, therapeutic_area,
    inclusion_criteria, exclusion_criteria, primary_endpoint, estimated_duration_months, budget_amount
) VALUES (
    'Diabetes Management Study Phase III',
    'DMS-2025-001',
    'A randomized, double-blind, placebo-controlled study to evaluate the efficacy and safety of new diabetes medication.',
    'Phase III',
    'Active',
    DATE '2025-01-15',
    DATE '2026-01-15',
    120,
    103, -- Dr. Brown (Endocrinology)
    'PharmaCorp Inc.',
    'Interventional',
    'Endocrinology',
    'Adults aged 18-75 with Type 2 diabetes, HbA1c 7-10%',
    'Pregnancy, severe renal disease, recent cardiovascular events',
    'Change in HbA1c from baseline at 24 weeks',
    12,
    2500000.00
);

INSERT INTO clinical_trials (
    trial_name, trial_number, description, phase, status, start_date, end_date,
    target_enrollment, primary_investigator_id, sponsor, study_type, therapeutic_area,
    inclusion_criteria, exclusion_criteria, primary_endpoint, estimated_duration_months, budget_amount
) VALUES (
    'Cardiac Rehabilitation Exercise Protocol Study',
    'CRE-2025-002',
    'Observational study comparing different exercise protocols in post-MI patients.',
    'Observational',
    'Recruiting',
    DATE '2025-02-01',
    DATE '2025-08-01',
    60,
    102, -- Dr. Johnson (Cardiology)
    'Heart Foundation',
    'Observational',
    'Cardiology',
    'Post-MI patients within 6 months, stable condition',
    'Unstable angina, severe heart failure, unable to exercise',
    'Improvement in exercise capacity at 16 weeks',
    6,
    750000.00
);

INSERT INTO clinical_trials (
    trial_name, trial_number, description, phase, status, start_date, end_date,
    target_enrollment, primary_investigator_id, sponsor, study_type, therapeutic_area,
    inclusion_criteria, exclusion_criteria, primary_endpoint, estimated_duration_months, budget_amount
) VALUES (
    'Neurological Disorder Prevention Study',
    'NDP-2025-003',
    'Phase II study of neuroprotective agent in early-stage neurological disorders.',
    'Phase II',
    'Planning',
    DATE '2025-06-01',
    DATE '2026-12-01',
    80,
    104, -- Dr. Davis (Neurology)
    'NeuroScience Labs',
    'Interventional',
    'Neurology',
    'Adults 45-70 with early cognitive symptoms, MMSE 24-28',
    'Severe dementia, psychiatric disorders, substance abuse',
    'Cognitive decline prevention at 18 months',
    18,
    3200000.00
);

PROMPT Clinical trials inserted;

-- Insert sample trial participants
INSERT INTO trial_participants (
    trial_id, patient_id, enrollment_date, study_arm, status,
    informed_consent_date, baseline_visit_date, assigned_provider_id
) VALUES (
    1000, 1000, DATE '2025-01-20', 'Treatment Group A', 'Active',
    DATE '2025-01-18', DATE '2025-01-20', 103
);

INSERT INTO trial_participants (
    trial_id, patient_id, enrollment_date, study_arm, status,
    informed_consent_date, baseline_visit_date, assigned_provider_id
) VALUES (
    1000, 1002, DATE '2025-01-25', 'Placebo Group', 'Active',
    DATE '2025-01-23', DATE '2025-01-25', 103
);

INSERT INTO trial_participants (
    trial_id, patient_id, enrollment_date, study_arm, status,
    informed_consent_date, baseline_visit_date, assigned_provider_id
) VALUES (
    1001, 1001, DATE '2025-02-05', 'Standard Protocol', 'Active',
    DATE '2025-02-03', DATE '2025-02-05', 102
);

PROMPT Trial participants inserted;

-- Insert sample trial visits
INSERT INTO trial_visits (
    participant_id, trial_id, visit_number, visit_name, visit_type,
    scheduled_date, visit_window_start, visit_window_end, status, provider_id
) VALUES (
    10000, 1000, 1, 'Baseline Visit', 'Baseline',
    DATE '2025-01-20', DATE '2025-01-17', DATE '2025-01-23', 'Completed', 103
);

INSERT INTO trial_visits (
    participant_id, trial_id, visit_number, visit_name, visit_type,
    scheduled_date, visit_window_start, visit_window_end, status, provider_id
) VALUES (
    10000, 1000, 2, 'Week 4 Follow-up', 'Treatment',
    DATE '2025-02-17', DATE '2025-02-14', DATE '2025-02-20', 'Scheduled', 103
);

PROMPT Trial visits inserted;

-- Insert sample adverse events
INSERT INTO adverse_events (
    participant_id, trial_id, event_date, event_term, description,
    severity, relationship_to_study, serious, reporting_provider_id,
    outcome, follow_up_required
) VALUES (
    10000, 1000, DATE '2025-01-28', 'Mild Nausea', 'Patient reported mild nausea after taking study medication',
    'Mild', 'Possible', 'N', 103, 'Recovered', 'N'
);

PROMPT Sample adverse events inserted;

-- Insert sample milestones
INSERT INTO trial_milestones (
    trial_id, milestone_name, description, planned_date, milestone_type,
    responsible_provider_id, completion_percentage, status
) VALUES (
    1000, 'First Patient Enrolled', 'Enrollment of first patient in the study',
    DATE '2025-01-15', 'Enrollment', 103, 100, 'Completed'
);

INSERT INTO trial_milestones (
    trial_id, milestone_name, description, planned_date, milestone_type,
    responsible_provider_id, completion_percentage, status
) VALUES (
    1000, '50% Enrollment Target', 'Reach 50% of target enrollment (60 patients)',
    DATE '2025-06-01', 'Enrollment', 103, 25, 'In Progress'
);

PROMPT Trial milestones inserted;

-- Update trial enrollment counts
UPDATE clinical_trials SET current_enrollment = 2 WHERE trial_id = 1000;
UPDATE clinical_trials SET current_enrollment = 1 WHERE trial_id = 1001;
UPDATE clinical_trials SET current_enrollment = 0 WHERE trial_id = 1002;

PROMPT ===============================================;
PROMPT Part 6 Complete - Continue with Part 7
PROMPT ===============================================;
