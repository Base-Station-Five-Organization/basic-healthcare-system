-- Clinical Trials Sample Data
-- Healthcare System Database
-- Created: June 2, 2025

-- Insert sample clinical trials
INSERT INTO clinical_trials (
    trial_name, trial_number, description, phase, status, start_date, end_date,
    target_enrollment, primary_investigator_id, sponsor, study_type, therapeutic_area,
    inclusion_criteria, exclusion_criteria, primary_endpoint, secondary_endpoints,
    estimated_duration_months, budget_amount
) VALUES (
    'Phase II Diabetes Treatment Study',
    'DM-2025-001',
    'A randomized, double-blind, placebo-controlled study to evaluate the efficacy and safety of XYZ-123 in patients with Type 2 diabetes mellitus.',
    'Phase II',
    'Active',
    DATE '2025-01-15',
    DATE '2026-07-15',
    120,
    101, -- Dr. Johnson
    'ABC Pharmaceuticals Inc.',
    'Interventional',
    'Endocrinology',
    'Adults aged 18-75 with Type 2 diabetes, HbA1c between 7.0-10.0%, stable on metformin for at least 3 months',
    'Type 1 diabetes, severe kidney disease, pregnancy, recent heart attack or stroke',
    'Change in HbA1c from baseline to week 24',
    'Change in fasting glucose, body weight, lipid profile, safety parameters',
    18,
    750000.00
);

INSERT INTO clinical_trials (
    trial_name, trial_number, description, phase, status, start_date, end_date,
    target_enrollment, primary_investigator_id, sponsor, study_type, therapeutic_area,
    inclusion_criteria, exclusion_criteria, primary_endpoint, secondary_endpoints,
    estimated_duration_months, budget_amount
) VALUES (
    'Cardiac Rehabilitation Exercise Protocol',
    'CR-2025-002',
    'Observational study comparing different exercise protocols in post-myocardial infarction patients.',
    'Observational',
    'Recruiting',
    DATE '2025-02-01',
    DATE '2025-12-31',
    80,
    102, -- Dr. Smith
    'National Heart Institute',
    'Observational',
    'Cardiology',
    'Post-MI patients within 6 months, aged 40-70, stable condition',
    'Unstable angina, severe heart failure, inability to exercise',
    'Improvement in exercise capacity at 6 months',
    'Quality of life scores, cardiac events, medication adherence',
    12,
    350000.00
);

INSERT INTO clinical_trials (
    trial_name, trial_number, description, phase, status, start_date, end_date,
    target_enrollment, primary_investigator_id, sponsor, study_type, therapeutic_area,
    inclusion_criteria, exclusion_criteria, primary_endpoint, secondary_endpoints,
    estimated_duration_months, budget_amount
) VALUES (
    'Alzheimer Disease Prevention Trial',
    'AD-2025-003',
    'Phase III study of preventive intervention in individuals at risk for Alzheimer disease.',
    'Phase III',
    'Planning',
    DATE '2025-06-01',
    DATE '2028-06-01',
    200,
    103, -- Dr. Williams
    'Neuroscience Research Foundation',
    'Interventional',
    'Neurology',
    'Adults aged 60-85 with family history of AD, normal cognition, positive biomarkers',
    'Dementia diagnosis, severe medical conditions, inability to comply with study procedures',
    'Time to development of mild cognitive impairment or dementia',
    'Cognitive test scores, biomarker changes, brain imaging changes',
    36,
    1200000.00
);

-- Insert sample trial participants
-- For Diabetes Study (Trial ID will be 1000)
INSERT INTO trial_participants (
    trial_id, patient_id, enrollment_date, study_arm, status,
    informed_consent_date, baseline_visit_date, assigned_provider_id
) VALUES (
    1000, 1000, DATE '2025-02-01', 'Treatment Group A', 'Active',
    DATE '2025-01-28', DATE '2025-02-01', 101
);

INSERT INTO trial_participants (
    trial_id, patient_id, enrollment_date, study_arm, status,
    informed_consent_date, baseline_visit_date, assigned_provider_id
) VALUES (
    1000, 1001, DATE '2025-02-05', 'Placebo Group', 'Active',
    DATE '2025-02-03', DATE '2025-02-05', 101
);

INSERT INTO trial_participants (
    trial_id, patient_id, enrollment_date, study_arm, status,
    informed_consent_date, baseline_visit_date, assigned_provider_id
) VALUES (
    1000, 1002, DATE '2025-02-10', 'Treatment Group B', 'Active',
    DATE '2025-02-08', DATE '2025-02-10', 102
);

-- For Cardiac Study (Trial ID will be 1001)
INSERT INTO trial_participants (
    trial_id, patient_id, enrollment_date, study_arm, status,
    informed_consent_date, baseline_visit_date, assigned_provider_id
) VALUES (
    1001, 1003, DATE '2025-02-15', 'Standard Exercise Protocol', 'Active',
    DATE '2025-02-12', DATE '2025-02-15', 102
);

INSERT INTO trial_participants (
    trial_id, patient_id, enrollment_date, study_arm, status,
    informed_consent_date, baseline_visit_date, assigned_provider_id
) VALUES (
    1001, 1004, DATE '2025-02-20', 'Intensive Exercise Protocol', 'Active',
    DATE '2025-02-18', DATE '2025-02-20', 103
);

-- Insert sample study protocols
INSERT INTO study_protocols (
    trial_id, protocol_version, protocol_date, title, is_current,
    objectives, methodology, statistical_plan, approved_date, approved_by
) VALUES (
    1000, 'V1.0', DATE '2024-12-01',
    'Phase II Study Protocol for XYZ-123 in Type 2 Diabetes',
    'Y',
    'To evaluate the efficacy and safety of XYZ-123 compared to placebo in patients with Type 2 diabetes mellitus.',
    'Randomized, double-blind, placebo-controlled, parallel-group design. Patients will be randomized 1:1:1 to receive XYZ-123 low dose, XYZ-123 high dose, or placebo.',
    'Primary analysis will use ANCOVA with baseline HbA1c as covariate. Sample size calculated for 80% power to detect 0.7% difference in HbA1c.',
    DATE '2024-12-15', 'IRB Committee'
);

INSERT INTO study_protocols (
    trial_id, protocol_version, protocol_date, title, is_current,
    objectives, methodology, statistical_plan, approved_date, approved_by
) VALUES (
    1001, 'V1.0', DATE '2025-01-10',
    'Cardiac Rehabilitation Exercise Protocol Comparison Study',
    'Y',
    'To compare the effectiveness of different exercise protocols in post-MI patients.',
    'Prospective observational study with patients allocated to exercise protocols based on clinical assessment.',
    'Descriptive statistics and regression analysis to compare outcomes between groups.',
    DATE '2025-01-20', 'Cardiology Review Board'
);

-- Insert sample trial milestones
-- Diabetes Study Milestones
INSERT INTO trial_milestones (
    trial_id, milestone_name, description, planned_date, milestone_type,
    responsible_provider_id, completion_percentage, status
) VALUES (
    1000, 'First Patient Enrolled', 'Enrollment of first patient in the study',
    DATE '2025-01-15', 'Enrollment', 101, 100, 'Completed'
);

INSERT INTO trial_milestones (
    trial_id, milestone_name, description, planned_date, milestone_type,
    responsible_provider_id, completion_percentage, status
) VALUES (
    1000, '50% Enrollment Target', 'Reach 50% of target enrollment (60 patients)',
    DATE '2025-06-01', 'Enrollment', 101, 25, 'In Progress'
);

INSERT INTO trial_milestones (
    trial_id, milestone_name, description, planned_date, milestone_type,
    responsible_provider_id, completion_percentage, status
) VALUES (
    1000, 'Interim Safety Analysis', 'Review safety data from first 30 patients',
    DATE '2025-08-01', 'Analysis', 101, 0, 'Planned'
);

-- Cardiac Study Milestones
INSERT INTO trial_milestones (
    trial_id, milestone_name, description, planned_date, milestone_type,
    responsible_provider_id, completion_percentage, status
) VALUES (
    1001, 'Study Initiation', 'First patient consent and enrollment',
    DATE '2025-02-01', 'Enrollment', 102, 100, 'Completed'
);

INSERT INTO trial_milestones (
    trial_id, milestone_name, description, planned_date, milestone_type,
    responsible_provider_id, completion_percentage, status
) VALUES (
    1001, 'Database Lock', 'Complete data collection and database lock',
    DATE '2025-11-30', 'Data Collection', 102, 0, 'Planned'
);

-- Insert sample trial visits
-- Visits for Patient 1000 (Diabetes Study)
INSERT INTO trial_visits (
    participant_id, trial_id, visit_number, visit_name, visit_type,
    scheduled_date, actual_date, status, provider_id,
    visit_notes, procedures_completed
) VALUES (
    10000, 1000, 1, 'Baseline Visit', 'Baseline',
    DATE '2025-02-01', DATE '2025-02-01', 'Completed', 101,
    'Patient completed all baseline assessments. Vital signs stable.',
    'Physical exam, laboratory tests, ECG, medication review'
);

INSERT INTO trial_visits (
    participant_id, trial_id, visit_number, visit_name, visit_type,
    scheduled_date, status, provider_id
) VALUES (
    10000, 1000, 2, 'Week 4 Follow-up', 'Treatment',
    DATE '2025-03-01', 'Scheduled', 101
);

INSERT INTO trial_visits (
    participant_id, trial_id, visit_number, visit_name, visit_type,
    scheduled_date, status, provider_id
) VALUES (
    10000, 1000, 3, 'Week 12 Follow-up', 'Treatment',
    DATE '2025-04-26', 'Scheduled', 101
);

-- Visits for Patient 1001 (Diabetes Study)
INSERT INTO trial_visits (
    participant_id, trial_id, visit_number, visit_name, visit_type,
    scheduled_date, actual_date, status, provider_id,
    visit_notes, procedures_completed
) VALUES (
    10001, 1000, 1, 'Baseline Visit', 'Baseline',
    DATE '2025-02-05', DATE '2025-02-05', 'Completed', 101,
    'Patient enrolled in placebo group. All baseline procedures completed.',
    'Physical exam, laboratory tests, ECG, randomization'
);

-- Visits for Patient 1003 (Cardiac Study)
INSERT INTO trial_visits (
    participant_id, trial_id, visit_number, visit_name, visit_type,
    scheduled_date, actual_date, status, provider_id,
    visit_notes, procedures_completed
) VALUES (
    10003, 1001, 1, 'Baseline Assessment', 'Baseline',
    DATE '2025-02-15', DATE '2025-02-15', 'Completed', 102,
    'Post-MI patient 3 months out. Good functional capacity for exercise program.',
    'Exercise stress test, echocardiogram, quality of life questionnaire'
);

INSERT INTO trial_visits (
    participant_id, trial_id, visit_number, visit_name, visit_type,
    scheduled_date, status, provider_id
) VALUES (
    10003, 1001, 2, 'Month 1 Follow-up', 'Follow-up',
    DATE '2025-03-15', 'Scheduled', 102
);

-- Insert sample adverse events
INSERT INTO adverse_events (
    participant_id, trial_id, event_date, event_term, description,
    severity, relationship_to_study, serious, reporting_provider_id,
    outcome
) VALUES (
    10000, 1000, DATE '2025-02-15', 'Headache', 'Patient reported mild headache lasting 2 hours',
    'Mild', 'Possible', 'N', 101, 'Recovered'
);

INSERT INTO adverse_events (
    participant_id, trial_id, event_date, event_term, description,
    severity, relationship_to_study, serious, reporting_provider_id,
    outcome, resolution_date
) VALUES (
    10001, 1000, DATE '2025-02-20', 'Nausea', 'Patient experienced nausea 2 hours after study medication',
    'Moderate', 'Probable', 'N', 101, 'Recovered', DATE '2025-02-21'
);

INSERT INTO adverse_events (
    participant_id, trial_id, event_date, event_term, description,
    severity, relationship_to_study, serious, reporting_provider_id,
    outcome, follow_up_required
) VALUES (
    10003, 1001, DATE '2025-02-28', 'Chest Pain', 'Mild chest discomfort during exercise session',
    'Mild', 'Unlikely', 'N', 102, 'Recovered', 'Y'
);

-- Update trial enrollment counts
UPDATE clinical_trials SET current_enrollment = 3 WHERE trial_id = 1000;
UPDATE clinical_trials SET current_enrollment = 2 WHERE trial_id = 1001;
UPDATE clinical_trials SET current_enrollment = 0 WHERE trial_id = 1002;

-- Insert some lookup data for clinical trials
-- Trial phases (if not using check constraints)
INSERT INTO lookup_values (lookup_type, lookup_value, display_order, is_active)
SELECT 'TRIAL_PHASE', 'Phase I', 1, 'Y' FROM dual
UNION ALL SELECT 'TRIAL_PHASE', 'Phase II', 2, 'Y' FROM dual
UNION ALL SELECT 'TRIAL_PHASE', 'Phase III', 3, 'Y' FROM dual
UNION ALL SELECT 'TRIAL_PHASE', 'Phase IV', 4, 'Y' FROM dual
UNION ALL SELECT 'TRIAL_PHASE', 'Observational', 5, 'Y' FROM dual;

-- Trial statuses
INSERT INTO lookup_values (lookup_type, lookup_value, display_order, is_active)
SELECT 'TRIAL_STATUS', 'Planning', 1, 'Y' FROM dual
UNION ALL SELECT 'TRIAL_STATUS', 'Active', 2, 'Y' FROM dual
UNION ALL SELECT 'TRIAL_STATUS', 'Recruiting', 3, 'Y' FROM dual
UNION ALL SELECT 'TRIAL_STATUS', 'Suspended', 4, 'Y' FROM dual
UNION ALL SELECT 'TRIAL_STATUS', 'Completed', 5, 'Y' FROM dual
UNION ALL SELECT 'TRIAL_STATUS', 'Terminated', 6, 'Y' FROM dual;

-- Study types
INSERT INTO lookup_values (lookup_type, lookup_value, display_order, is_active)
SELECT 'STUDY_TYPE', 'Interventional', 1, 'Y' FROM dual
UNION ALL SELECT 'STUDY_TYPE', 'Observational', 2, 'Y' FROM dual
UNION ALL SELECT 'STUDY_TYPE', 'Expanded Access', 3, 'Y' FROM dual;

-- Adverse event severities
INSERT INTO lookup_values (lookup_type, lookup_value, display_order, is_active)
SELECT 'AE_SEVERITY', 'Mild', 1, 'Y' FROM dual
UNION ALL SELECT 'AE_SEVERITY', 'Moderate', 2, 'Y' FROM dual
UNION ALL SELECT 'AE_SEVERITY', 'Severe', 3, 'Y' FROM dual
UNION ALL SELECT 'AE_SEVERITY', 'Life-threatening', 4, 'Y' FROM dual
UNION ALL SELECT 'AE_SEVERITY', 'Fatal', 5, 'Y' FROM dual;

-- Relationship to study
INSERT INTO lookup_values (lookup_type, lookup_value, display_order, is_active)
SELECT 'AE_RELATIONSHIP', 'Unrelated', 1, 'Y' FROM dual
UNION ALL SELECT 'AE_RELATIONSHIP', 'Unlikely', 2, 'Y' FROM dual
UNION ALL SELECT 'AE_RELATIONSHIP', 'Possible', 3, 'Y' FROM dual
UNION ALL SELECT 'AE_RELATIONSHIP', 'Probable', 4, 'Y' FROM dual
UNION ALL SELECT 'AE_RELATIONSHIP', 'Definite', 5, 'Y' FROM dual;

-- Therapeutic areas
INSERT INTO lookup_values (lookup_type, lookup_value, display_order, is_active)
SELECT 'THERAPEUTIC_AREA', 'Cardiology', 1, 'Y' FROM dual
UNION ALL SELECT 'THERAPEUTIC_AREA', 'Endocrinology', 2, 'Y' FROM dual
UNION ALL SELECT 'THERAPEUTIC_AREA', 'Neurology', 3, 'Y' FROM dual
UNION ALL SELECT 'THERAPEUTIC_AREA', 'Oncology', 4, 'Y' FROM dual
UNION ALL SELECT 'THERAPEUTIC_AREA', 'Psychiatry', 5, 'Y' FROM dual
UNION ALL SELECT 'THERAPEUTIC_AREA', 'Gastroenterology', 6, 'Y' FROM dual
UNION ALL SELECT 'THERAPEUTIC_AREA', 'Pulmonology', 7, 'Y' FROM dual
UNION ALL SELECT 'THERAPEUTIC_AREA', 'Rheumatology', 8, 'Y' FROM dual;

COMMIT;

-- Add some comments
COMMENT ON TABLE clinical_trials IS 'Sample data includes diabetes, cardiac, and neurology trials in various phases';
COMMENT ON TABLE trial_participants IS 'Sample participants enrolled across multiple active trials';
COMMENT ON TABLE adverse_events IS 'Sample adverse events showing different severities and relationships';
