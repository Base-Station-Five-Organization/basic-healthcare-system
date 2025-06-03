-- Healthcare System - Oracle APEX Cloud Setup
-- Part 2: Medical Records and Prescriptions Tables
-- Run this after Part 1

PROMPT ===============================================;
PROMPT Healthcare System - Part 2: Medical Records
PROMPT ===============================================;

-- Medical Records table
CREATE TABLE medical_records (
    record_id NUMBER DEFAULT seq_medical_record_id.NEXTVAL PRIMARY KEY,
    patient_id NUMBER NOT NULL,
    provider_id NUMBER NOT NULL,
    visit_date DATE NOT NULL,
    chief_complaint VARCHAR2(500),
    history_of_present_illness CLOB,
    physical_examination CLOB,
    assessment_and_plan CLOB,
    diagnosis_codes VARCHAR2(500),
    vital_signs CLOB,
    medications CLOB,
    allergies VARCHAR2(500),
    lab_results CLOB,
    follow_up_instructions CLOB,
    created_date DATE DEFAULT SYSDATE,
    created_by VARCHAR2(50) DEFAULT USER,
    modified_date DATE DEFAULT SYSDATE,
    modified_by VARCHAR2(50) DEFAULT USER,
    CONSTRAINT fk_medical_record_patient FOREIGN KEY (patient_id) REFERENCES patients(patient_id),
    CONSTRAINT fk_medical_record_provider FOREIGN KEY (provider_id) REFERENCES providers(provider_id)
);

PROMPT Medical records table created;

-- Prescriptions table
CREATE TABLE prescriptions (
    prescription_id NUMBER DEFAULT seq_prescription_id.NEXTVAL PRIMARY KEY,
    patient_id NUMBER NOT NULL,
    provider_id NUMBER NOT NULL,
    medication_name VARCHAR2(200) NOT NULL,
    dosage VARCHAR2(100),
    frequency VARCHAR2(100),
    duration VARCHAR2(100),
    quantity NUMBER,
    refills_remaining NUMBER DEFAULT 0,
    date_prescribed DATE DEFAULT SYSDATE,
    date_filled DATE,
    pharmacy_name VARCHAR2(200),
    pharmacy_phone VARCHAR2(20),
    status VARCHAR2(20) DEFAULT 'Active' CHECK (status IN ('Active', 'Completed', 'Cancelled', 'Expired')),
    special_instructions CLOB,
    created_date DATE DEFAULT SYSDATE,
    created_by VARCHAR2(50) DEFAULT USER,
    modified_date DATE DEFAULT SYSDATE,
    modified_by VARCHAR2(50) DEFAULT USER,
    CONSTRAINT fk_prescription_patient FOREIGN KEY (patient_id) REFERENCES patients(patient_id),
    CONSTRAINT fk_prescription_provider FOREIGN KEY (provider_id) REFERENCES providers(provider_id)
);

PROMPT Prescriptions table created;

-- Appointment Reminders table
CREATE TABLE appointment_reminders (
    reminder_id NUMBER DEFAULT seq_reminder_id.NEXTVAL PRIMARY KEY,
    appointment_id NUMBER NOT NULL,
    reminder_type VARCHAR2(20) CHECK (reminder_type IN ('Email', 'SMS', 'Phone')),
    reminder_date DATE NOT NULL,
    status VARCHAR2(20) DEFAULT 'Pending' CHECK (status IN ('Pending', 'Sent', 'Failed')),
    message_content CLOB,
    sent_date DATE,
    created_date DATE DEFAULT SYSDATE,
    CONSTRAINT fk_reminder_appointment FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id)
);

PROMPT Appointment reminders table created;

-- Create indexes for performance
CREATE INDEX idx_patients_name ON patients(last_name, first_name);
CREATE INDEX idx_appointments_date ON appointments(appointment_date);
CREATE INDEX idx_appointments_patient ON appointments(patient_id);
CREATE INDEX idx_appointments_provider ON appointments(provider_id);
CREATE INDEX idx_medical_records_patient ON medical_records(patient_id);
CREATE INDEX idx_medical_records_date ON medical_records(visit_date);
CREATE INDEX idx_prescriptions_patient ON prescriptions(patient_id);

PROMPT Indexes created;

PROMPT ===============================================;
PROMPT Part 2 Complete - Continue with Part 3
PROMPT ===============================================;
