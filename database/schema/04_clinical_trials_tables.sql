-- Clinical Trials Extension for Healthcare System
-- Oracle APEX Application
-- Created: June 2, 2025

-- Create sequences for clinical trials primary keys
CREATE SEQUENCE seq_trial_id START WITH 1000 INCREMENT BY 1;
CREATE SEQUENCE seq_participant_id START WITH 10000 INCREMENT BY 1;
CREATE SEQUENCE seq_protocol_id START WITH 500 INCREMENT BY 1;
CREATE SEQUENCE seq_milestone_id START WITH 5000 INCREMENT BY 1;
CREATE SEQUENCE seq_adverse_event_id START WITH 20000 INCREMENT BY 1;
CREATE SEQUENCE seq_trial_visit_id START WITH 30000 INCREMENT BY 1;

-- Clinical Trials table
CREATE TABLE clinical_trials (
    trial_id NUMBER DEFAULT seq_trial_id.NEXTVAL PRIMARY KEY,
    trial_name VARCHAR2(200) NOT NULL,
    trial_number VARCHAR2(50) UNIQUE NOT NULL,
    description CLOB,
    phase VARCHAR2(20) CHECK (phase IN ('Phase I', 'Phase II', 'Phase III', 'Phase IV', 'Observational')),
    status VARCHAR2(20) DEFAULT 'Planning' CHECK (status IN ('Planning', 'Active', 'Recruiting', 'Suspended', 'Completed', 'Terminated')),
    start_date DATE,
    end_date DATE,
    target_enrollment NUMBER,
    current_enrollment NUMBER DEFAULT 0,
    primary_investigator_id NUMBER,
    sponsor VARCHAR2(200),
    study_type VARCHAR2(50) CHECK (study_type IN ('Interventional', 'Observational', 'Expanded Access')),
    therapeutic_area VARCHAR2(100),
    inclusion_criteria CLOB,
    exclusion_criteria CLOB,
    primary_endpoint CLOB,
    secondary_endpoints CLOB,
    estimated_duration_months NUMBER,
    budget_amount NUMBER(12,2),
    created_date DATE DEFAULT SYSDATE,
    created_by VARCHAR2(50) DEFAULT USER,
    modified_date DATE DEFAULT SYSDATE,
    modified_by VARCHAR2(50) DEFAULT USER,
    is_active VARCHAR2(1) DEFAULT 'Y' CHECK (is_active IN ('Y', 'N')),
    CONSTRAINT fk_trial_investigator FOREIGN KEY (primary_investigator_id) REFERENCES providers(provider_id)
);

-- Trial Participants table
CREATE TABLE trial_participants (
    participant_id NUMBER DEFAULT seq_participant_id.NEXTVAL PRIMARY KEY,
    trial_id NUMBER NOT NULL,
    patient_id NUMBER NOT NULL,
    enrollment_date DATE DEFAULT SYSDATE,
    randomization_code VARCHAR2(50),
    study_arm VARCHAR2(100),
    status VARCHAR2(20) DEFAULT 'Active' CHECK (status IN ('Screening', 'Active', 'Completed', 'Withdrawn', 'Lost to Follow-up', 'Terminated')),
    withdrawal_reason VARCHAR2(200),
    withdrawal_date DATE,
    informed_consent_date DATE,
    baseline_visit_date DATE,
    last_visit_date DATE,
    next_visit_date DATE,
    assigned_provider_id NUMBER,
    notes CLOB,
    created_date DATE DEFAULT SYSDATE,
    created_by VARCHAR2(50) DEFAULT USER,
    modified_date DATE DEFAULT SYSDATE,
    modified_by VARCHAR2(50) DEFAULT USER,
    CONSTRAINT fk_participant_trial FOREIGN KEY (trial_id) REFERENCES clinical_trials(trial_id),
    CONSTRAINT fk_participant_patient FOREIGN KEY (patient_id) REFERENCES patients(patient_id),
    CONSTRAINT fk_participant_provider FOREIGN KEY (assigned_provider_id) REFERENCES providers(provider_id),
    CONSTRAINT uk_trial_patient UNIQUE (trial_id, patient_id)
);

-- Study Protocols table
CREATE TABLE study_protocols (
    protocol_id NUMBER DEFAULT seq_protocol_id.NEXTVAL PRIMARY KEY,
    trial_id NUMBER NOT NULL,
    protocol_version VARCHAR2(20) NOT NULL,
    protocol_date DATE NOT NULL,
    title VARCHAR2(200) NOT NULL,
    objectives CLOB,
    methodology CLOB,
    statistical_plan CLOB,
    safety_monitoring CLOB,
    data_management_plan CLOB,
    quality_assurance CLOB,
    regulatory_info CLOB,
    document_path VARCHAR2(500),
    is_current VARCHAR2(1) DEFAULT 'Y' CHECK (is_current IN ('Y', 'N')),
    approved_date DATE,
    approved_by VARCHAR2(100),
    created_date DATE DEFAULT SYSDATE,
    created_by VARCHAR2(50) DEFAULT USER,
    CONSTRAINT fk_protocol_trial FOREIGN KEY (trial_id) REFERENCES clinical_trials(trial_id)
);

-- Trial Milestones table
CREATE TABLE trial_milestones (
    milestone_id NUMBER DEFAULT seq_milestone_id.NEXTVAL PRIMARY KEY,
    trial_id NUMBER NOT NULL,
    milestone_name VARCHAR2(200) NOT NULL,
    description CLOB,
    planned_date DATE,
    actual_date DATE,
    status VARCHAR2(20) DEFAULT 'Planned' CHECK (status IN ('Planned', 'In Progress', 'Completed', 'Delayed', 'Cancelled')),
    milestone_type VARCHAR2(50) CHECK (milestone_type IN ('Regulatory', 'Enrollment', 'Data Collection', 'Analysis', 'Reporting', 'Other')),
    responsible_provider_id NUMBER,
    completion_percentage NUMBER(5,2) DEFAULT 0,
    notes CLOB,
    created_date DATE DEFAULT SYSDATE,
    created_by VARCHAR2(50) DEFAULT USER,
    modified_date DATE DEFAULT SYSDATE,
    modified_by VARCHAR2(50) DEFAULT USER,
    CONSTRAINT fk_milestone_trial FOREIGN KEY (trial_id) REFERENCES clinical_trials(trial_id),
    CONSTRAINT fk_milestone_provider FOREIGN KEY (responsible_provider_id) REFERENCES providers(provider_id)
);

-- Adverse Events table
CREATE TABLE adverse_events (
    adverse_event_id NUMBER DEFAULT seq_adverse_event_id.NEXTVAL PRIMARY KEY,
    participant_id NUMBER NOT NULL,
    trial_id NUMBER NOT NULL,
    event_date DATE NOT NULL,
    event_term VARCHAR2(200) NOT NULL,
    description CLOB,
    severity VARCHAR2(20) CHECK (severity IN ('Mild', 'Moderate', 'Severe', 'Life-threatening', 'Fatal')),
    relationship_to_study VARCHAR2(30) CHECK (relationship_to_study IN ('Unrelated', 'Unlikely', 'Possible', 'Probable', 'Definite')),
    outcome VARCHAR2(30) CHECK (outcome IN ('Recovered', 'Recovering', 'Not Recovered', 'Recovered with Sequelae', 'Fatal', 'Unknown')),
    serious VARCHAR2(1) DEFAULT 'N' CHECK (serious IN ('Y', 'N')),
    expected VARCHAR2(1) DEFAULT 'N' CHECK (expected IN ('Y', 'N')),
    reported_date DATE DEFAULT SYSDATE,
    resolution_date DATE,
    reporting_provider_id NUMBER NOT NULL,
    regulatory_reported VARCHAR2(1) DEFAULT 'N' CHECK (regulatory_reported IN ('Y', 'N')),
    regulatory_report_date DATE,
    follow_up_required VARCHAR2(1) DEFAULT 'N' CHECK (follow_up_required IN ('Y', 'N')),
    action_taken CLOB,
    created_date DATE DEFAULT SYSDATE,
    created_by VARCHAR2(50) DEFAULT USER,
    modified_date DATE DEFAULT SYSDATE,
    modified_by VARCHAR2(50) DEFAULT USER,
    CONSTRAINT fk_ae_participant FOREIGN KEY (participant_id) REFERENCES trial_participants(participant_id),
    CONSTRAINT fk_ae_trial FOREIGN KEY (trial_id) REFERENCES clinical_trials(trial_id),
    CONSTRAINT fk_ae_provider FOREIGN KEY (reporting_provider_id) REFERENCES providers(provider_id)
);

-- Trial Visits table
CREATE TABLE trial_visits (
    visit_id NUMBER DEFAULT seq_trial_visit_id.NEXTVAL PRIMARY KEY,
    participant_id NUMBER NOT NULL,
    trial_id NUMBER NOT NULL,
    visit_number NUMBER NOT NULL,
    visit_name VARCHAR2(100),
    visit_type VARCHAR2(50) CHECK (visit_type IN ('Screening', 'Baseline', 'Treatment', 'Follow-up', 'End of Study', 'Unscheduled')),
    scheduled_date DATE,
    actual_date DATE,
    visit_window_start DATE,
    visit_window_end DATE,
    status VARCHAR2(20) DEFAULT 'Scheduled' CHECK (status IN ('Scheduled', 'Completed', 'Missed', 'Cancelled', 'Rescheduled')),
    provider_id NUMBER,
    visit_notes CLOB,
    procedures_completed CLOB,
    assessments_completed CLOB,
    concomitant_medications CLOB,
    vital_signs CLOB,
    laboratory_results CLOB,
    created_date DATE DEFAULT SYSDATE,
    created_by VARCHAR2(50) DEFAULT USER,
    modified_date DATE DEFAULT SYSDATE,
    modified_by VARCHAR2(50) DEFAULT USER,
    CONSTRAINT fk_visit_participant FOREIGN KEY (participant_id) REFERENCES trial_participants(participant_id),
    CONSTRAINT fk_visit_trial FOREIGN KEY (trial_id) REFERENCES clinical_trials(trial_id),
    CONSTRAINT fk_visit_provider FOREIGN KEY (provider_id) REFERENCES providers(provider_id)
);

-- Create indexes for performance
CREATE INDEX idx_trials_status ON clinical_trials(status);
CREATE INDEX idx_trials_phase ON clinical_trials(phase);
CREATE INDEX idx_trials_investigator ON clinical_trials(primary_investigator_id);
CREATE INDEX idx_participants_trial ON trial_participants(trial_id);
CREATE INDEX idx_participants_patient ON trial_participants(patient_id);
CREATE INDEX idx_participants_status ON trial_participants(status);
CREATE INDEX idx_protocols_trial ON study_protocols(trial_id);
CREATE INDEX idx_protocols_current ON study_protocols(is_current);
CREATE INDEX idx_milestones_trial ON trial_milestones(trial_id);
CREATE INDEX idx_milestones_status ON trial_milestones(status);
CREATE INDEX idx_ae_participant ON adverse_events(participant_id);
CREATE INDEX idx_ae_trial ON adverse_events(trial_id);
CREATE INDEX idx_ae_severity ON adverse_events(severity);
CREATE INDEX idx_ae_serious ON adverse_events(serious);
CREATE INDEX idx_visits_participant ON trial_visits(participant_id);
CREATE INDEX idx_visits_trial ON trial_visits(trial_id);
CREATE INDEX idx_visits_date ON trial_visits(actual_date);

-- Add comments for documentation
COMMENT ON TABLE clinical_trials IS 'Master table for clinical trials information';
COMMENT ON TABLE trial_participants IS 'Patients enrolled in clinical trials';
COMMENT ON TABLE study_protocols IS 'Study protocols and versions for each trial';
COMMENT ON TABLE trial_milestones IS 'Key milestones and deliverables for trials';
COMMENT ON TABLE adverse_events IS 'Adverse events reported during trials';
COMMENT ON TABLE trial_visits IS 'Scheduled and completed visits for trial participants';
