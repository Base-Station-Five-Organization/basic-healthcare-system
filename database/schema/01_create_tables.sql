-- Healthcare System Database Schema
-- Oracle APEX Application
-- Created: June 2, 2025

-- Create sequences for primary keys
CREATE SEQUENCE seq_patient_id START WITH 1000 INCREMENT BY 1;
CREATE SEQUENCE seq_provider_id START WITH 100 INCREMENT BY 1;
CREATE SEQUENCE seq_appointment_id START WITH 10000 INCREMENT BY 1;
CREATE SEQUENCE seq_medical_record_id START WITH 100000 INCREMENT BY 1;
CREATE SEQUENCE seq_prescription_id START WITH 50000 INCREMENT BY 1;

-- Patients table
CREATE TABLE patients (
    patient_id NUMBER DEFAULT seq_patient_id.NEXTVAL PRIMARY KEY,
    first_name VARCHAR2(50) NOT NULL,
    last_name VARCHAR2(50) NOT NULL,
    date_of_birth DATE NOT NULL,
    gender VARCHAR2(10) CHECK (gender IN ('Male', 'Female', 'Other')),
    phone VARCHAR2(20),
    email VARCHAR2(100),
    address VARCHAR2(200),
    city VARCHAR2(50),
    state VARCHAR2(50),
    zip_code VARCHAR2(10),
    emergency_contact_name VARCHAR2(100),
    emergency_contact_phone VARCHAR2(20),
    insurance_provider VARCHAR2(100),
    insurance_policy_number VARCHAR2(50),
    blood_type VARCHAR2(5),
    allergies CLOB,
    medical_conditions CLOB,
    created_date DATE DEFAULT SYSDATE,
    created_by VARCHAR2(50) DEFAULT USER,
    modified_date DATE DEFAULT SYSDATE,
    modified_by VARCHAR2(50) DEFAULT USER,
    is_active VARCHAR2(1) DEFAULT 'Y' CHECK (is_active IN ('Y', 'N'))
);

-- Healthcare providers table
CREATE TABLE providers (
    provider_id NUMBER DEFAULT seq_provider_id.NEXTVAL PRIMARY KEY,
    first_name VARCHAR2(50) NOT NULL,
    last_name VARCHAR2(50) NOT NULL,
    title VARCHAR2(20), -- Dr., Nurse, etc.
    specialty VARCHAR2(100),
    license_number VARCHAR2(50),
    phone VARCHAR2(20),
    email VARCHAR2(100),
    department VARCHAR2(50),
    hire_date DATE,
    is_active VARCHAR2(1) DEFAULT 'Y' CHECK (is_active IN ('Y', 'N')),
    created_date DATE DEFAULT SYSDATE,
    created_by VARCHAR2(50) DEFAULT USER
);

-- Appointments table
CREATE TABLE appointments (
    appointment_id NUMBER DEFAULT seq_appointment_id.NEXTVAL PRIMARY KEY,
    patient_id NUMBER NOT NULL REFERENCES patients(patient_id),
    provider_id NUMBER NOT NULL REFERENCES providers(provider_id),
    appointment_date DATE NOT NULL,
    appointment_time VARCHAR2(10) NOT NULL, -- Format: HH24:MI
    duration_minutes NUMBER DEFAULT 30,
    appointment_type VARCHAR2(50), -- Consultation, Follow-up, Emergency, etc.
    status VARCHAR2(20) DEFAULT 'Scheduled' CHECK (status IN ('Scheduled', 'Confirmed', 'In Progress', 'Completed', 'Cancelled', 'No Show')),
    reason_for_visit VARCHAR2(500),
    notes CLOB,
    created_date DATE DEFAULT SYSDATE,
    created_by VARCHAR2(50) DEFAULT USER,
    modified_date DATE DEFAULT SYSDATE,
    modified_by VARCHAR2(50) DEFAULT USER
);

-- Medical records table
CREATE TABLE medical_records (
    record_id NUMBER DEFAULT seq_medical_record_id.NEXTVAL PRIMARY KEY,
    patient_id NUMBER NOT NULL REFERENCES patients(patient_id),
    provider_id NUMBER NOT NULL REFERENCES providers(provider_id),
    appointment_id NUMBER REFERENCES appointments(appointment_id),
    visit_date DATE NOT NULL,
    chief_complaint VARCHAR2(500),
    history_of_present_illness CLOB,
    physical_examination CLOB,
    vital_signs VARCHAR2(200), -- JSON format: {"bp":"120/80","hr":"72","temp":"98.6","resp":"16"}
    diagnosis CLOB,
    treatment_plan CLOB,
    follow_up_instructions CLOB,
    created_date DATE DEFAULT SYSDATE,
    created_by VARCHAR2(50) DEFAULT USER
);

-- Prescriptions table
CREATE TABLE prescriptions (
    prescription_id NUMBER DEFAULT seq_prescription_id.NEXTVAL PRIMARY KEY,
    patient_id NUMBER NOT NULL REFERENCES patients(patient_id),
    provider_id NUMBER NOT NULL REFERENCES providers(provider_id),
    record_id NUMBER REFERENCES medical_records(record_id),
    medication_name VARCHAR2(200) NOT NULL,
    dosage VARCHAR2(100),
    frequency VARCHAR2(100),
    duration VARCHAR2(100),
    quantity NUMBER,
    refills_allowed NUMBER DEFAULT 0,
    instructions CLOB,
    date_prescribed DATE DEFAULT SYSDATE,
    is_active VARCHAR2(1) DEFAULT 'Y' CHECK (is_active IN ('Y', 'N')),
    created_date DATE DEFAULT SYSDATE,
    created_by VARCHAR2(50) DEFAULT USER
);

-- Lookup table for appointment types
CREATE TABLE appointment_types (
    type_id NUMBER PRIMARY KEY,
    type_name VARCHAR2(50) NOT NULL,
    default_duration NUMBER DEFAULT 30,
    description VARCHAR2(200),
    is_active VARCHAR2(1) DEFAULT 'Y' CHECK (is_active IN ('Y', 'N'))
);

-- Lookup table for specialties
CREATE TABLE specialties (
    specialty_id NUMBER PRIMARY KEY,
    specialty_name VARCHAR2(100) NOT NULL,
    description VARCHAR2(200),
    is_active VARCHAR2(1) DEFAULT 'Y' CHECK (is_active IN ('Y', 'N'))
);

-- Add indexes for better performance
CREATE INDEX idx_patients_name ON patients(last_name, first_name);
CREATE INDEX idx_patients_dob ON patients(date_of_birth);
CREATE INDEX idx_appointments_date ON appointments(appointment_date);
CREATE INDEX idx_appointments_patient ON appointments(patient_id);
CREATE INDEX idx_appointments_provider ON appointments(provider_id);
CREATE INDEX idx_medical_records_patient ON medical_records(patient_id);
CREATE INDEX idx_medical_records_date ON medical_records(visit_date);
CREATE INDEX idx_prescriptions_patient ON prescriptions(patient_id);

-- Add comments to tables
COMMENT ON TABLE patients IS 'Patient demographics and contact information';
COMMENT ON TABLE providers IS 'Healthcare providers including doctors, nurses, and staff';
COMMENT ON TABLE appointments IS 'Patient appointments with healthcare providers';
COMMENT ON TABLE medical_records IS 'Electronic health records for patient visits';
COMMENT ON TABLE prescriptions IS 'Medication prescriptions for patients';
COMMENT ON TABLE appointment_types IS 'Lookup table for appointment types';
COMMENT ON TABLE specialties IS 'Lookup table for medical specialties';
