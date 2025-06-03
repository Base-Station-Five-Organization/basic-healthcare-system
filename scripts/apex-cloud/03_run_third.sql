-- Healthcare System - Oracle APEX Cloud Setup
-- Part 3: Clinical Trials Extension Tables
-- Run this after Part 2

PROMPT ===============================================;
PROMPT Healthcare System - Part 3: Clinical Trials
PROMPT ===============================================;

-- Create sequences for clinical trials
CREATE SEQUENCE seq_trial_id START WITH 1000 INCREMENT BY 1;
CREATE SEQUENCE seq_participant_id START WITH 10000 INCREMENT BY 1;
CREATE SEQUENCE seq_protocol_id START WITH 500 INCREMENT BY 1;
CREATE SEQUENCE seq_milestone_id START WITH 5000 INCREMENT BY 1;
CREATE SEQUENCE seq_adverse_event_id START WITH 20000 INCREMENT BY 1;
CREATE SEQUENCE seq_trial_visit_id START WITH 30000 INCREMENT BY 1;

PROMPT Clinical trials sequences created;

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

PROMPT Clinical trials table created;

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

PROMPT Trial participants table created;

PROMPT ===============================================;
PROMPT Part 3 Complete - Continue with Part 4
PROMPT ===============================================;
