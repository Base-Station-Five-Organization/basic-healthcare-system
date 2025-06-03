-- Healthcare System - Oracle APEX Cloud Setup
-- Part 4: Clinical Trials Support Tables
-- Run this after Part 3

PROMPT ===============================================;
PROMPT Healthcare System - Part 4: Clinical Trials Support
PROMPT ===============================================;

-- Study Protocols table
CREATE TABLE study_protocols (
    protocol_id NUMBER DEFAULT seq_protocol_id.NEXTVAL PRIMARY KEY,
    trial_id NUMBER NOT NULL,
    version_number VARCHAR2(20) NOT NULL,
    effective_date DATE DEFAULT SYSDATE,
    protocol_title VARCHAR2(500),
    is_current VARCHAR2(1) DEFAULT 'Y' CHECK (is_current IN ('Y', 'N')),
    summary_of_changes CLOB,
    protocol_text CLOB,
    approval_date DATE,
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
    event_id NUMBER DEFAULT seq_adverse_event_id.NEXTVAL PRIMARY KEY,
    participant_id NUMBER NOT NULL,
    trial_id NUMBER NOT NULL,
    event_date DATE NOT NULL,
    event_term VARCHAR2(200) NOT NULL,
    description CLOB,
    severity VARCHAR2(20) CHECK (severity IN ('Mild', 'Moderate', 'Severe', 'Life-threatening', 'Fatal')),
    relationship_to_study VARCHAR2(50) CHECK (relationship_to_study IN ('Unrelated', 'Unlikely', 'Possible', 'Probable', 'Definite')),
    serious VARCHAR2(1) CHECK (serious IN ('Y', 'N')),
    expected VARCHAR2(1) CHECK (expected IN ('Y', 'N')),
    outcome VARCHAR2(50) CHECK (outcome IN ('Recovered', 'Recovering', 'Not Recovered', 'Recovered with Sequelae', 'Fatal', 'Unknown')),
    action_taken VARCHAR2(200),
    follow_up_required VARCHAR2(1) DEFAULT 'N' CHECK (follow_up_required IN ('Y', 'N')),
    resolution_date DATE,
    reporting_provider_id NUMBER NOT NULL,
    reported_to_sponsor_date DATE,
    reported_to_regulatory_date DATE,
    created_date DATE DEFAULT SYSDATE,
    created_by VARCHAR2(50) DEFAULT USER,
    modified_date DATE DEFAULT SYSDATE,
    modified_by VARCHAR2(50) DEFAULT USER,
    CONSTRAINT fk_adverse_event_participant FOREIGN KEY (participant_id) REFERENCES trial_participants(participant_id),
    CONSTRAINT fk_adverse_event_trial FOREIGN KEY (trial_id) REFERENCES clinical_trials(trial_id),
    CONSTRAINT fk_adverse_event_provider FOREIGN KEY (reporting_provider_id) REFERENCES providers(provider_id)
);

-- Trial Visits table
CREATE TABLE trial_visits (
    visit_id NUMBER DEFAULT seq_trial_visit_id.NEXTVAL PRIMARY KEY,
    participant_id NUMBER NOT NULL,
    trial_id NUMBER NOT NULL,
    visit_number NUMBER,
    visit_name VARCHAR2(100) NOT NULL,
    visit_type VARCHAR2(50) CHECK (visit_type IN ('Screening', 'Baseline', 'Treatment', 'Follow-up', 'Safety', 'End of Study', 'Unscheduled')),
    scheduled_date DATE,
    actual_date DATE,
    visit_window_start DATE,
    visit_window_end DATE,
    status VARCHAR2(20) DEFAULT 'Scheduled' CHECK (status IN ('Scheduled', 'Completed', 'Missed', 'Cancelled')),
    visit_notes CLOB,
    procedures_completed CLOB,
    provider_id NUMBER,
    created_date DATE DEFAULT SYSDATE,
    created_by VARCHAR2(50) DEFAULT USER,
    modified_date DATE DEFAULT SYSDATE,
    modified_by VARCHAR2(50) DEFAULT USER,
    CONSTRAINT fk_visit_participant FOREIGN KEY (participant_id) REFERENCES trial_participants(participant_id),
    CONSTRAINT fk_visit_trial FOREIGN KEY (trial_id) REFERENCES clinical_trials(trial_id),
    CONSTRAINT fk_visit_provider FOREIGN KEY (provider_id) REFERENCES providers(provider_id)
);

PROMPT Clinical trials support tables created;

-- Create indexes for clinical trials tables
CREATE INDEX idx_trial_participants_trial ON trial_participants(trial_id);
CREATE INDEX idx_trial_participants_patient ON trial_participants(patient_id);
CREATE INDEX idx_adverse_events_trial ON adverse_events(trial_id);
CREATE INDEX idx_adverse_events_participant ON adverse_events(participant_id);
CREATE INDEX idx_trial_visits_participant ON trial_visits(participant_id);
CREATE INDEX idx_trial_visits_date ON trial_visits(scheduled_date);
CREATE INDEX idx_trial_milestones_trial ON trial_milestones(trial_id);
CREATE INDEX idx_trial_milestones_date ON trial_milestones(planned_date);

PROMPT Clinical trials indexes created;

PROMPT ===============================================;
PROMPT Part 4 Complete - Continue with Part 5
PROMPT ===============================================;
