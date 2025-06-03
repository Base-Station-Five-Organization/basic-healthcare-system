-- Healthcare System - Oracle APEX Cloud Setup
-- Part 1: Core Tables and Sequences
-- Run this first in SQL Workshop > SQL Commands

SET SERVEROUTPUT ON;

PROMPT ===============================================;
PROMPT Healthcare System - Part 1: Core Tables
PROMPT BASESTATIONFIVE Workspace Setup
PROMPT ===============================================;

-- Create sequences first
CREATE SEQUENCE seq_patient_id START WITH 1000 INCREMENT BY 1;
CREATE SEQUENCE seq_provider_id START WITH 100 INCREMENT BY 1;
CREATE SEQUENCE seq_appointment_id START WITH 5000 INCREMENT BY 1;
CREATE SEQUENCE seq_medical_record_id START WITH 10000 INCREMENT BY 1;
CREATE SEQUENCE seq_prescription_id START WITH 20000 INCREMENT BY 1;
CREATE SEQUENCE seq_reminder_id START WITH 30000 INCREMENT BY 1;

PROMPT Sequences created successfully;

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
    state VARCHAR2(2),
    zip_code VARCHAR2(10),
    emergency_contact_name VARCHAR2(100),
    emergency_contact_phone VARCHAR2(20),
    insurance_provider VARCHAR2(100),
    insurance_policy_number VARCHAR2(50),
    created_date DATE DEFAULT SYSDATE,
    modified_date DATE DEFAULT SYSDATE,
    is_active VARCHAR2(1) DEFAULT 'Y' CHECK (is_active IN ('Y', 'N'))
);

PROMPT Patients table created;

-- Providers table
CREATE TABLE providers (
    provider_id NUMBER DEFAULT seq_provider_id.NEXTVAL PRIMARY KEY,
    first_name VARCHAR2(50) NOT NULL,
    last_name VARCHAR2(50) NOT NULL,
    title VARCHAR2(20),
    specialty VARCHAR2(100),
    license_number VARCHAR2(50),
    phone VARCHAR2(20),
    email VARCHAR2(100),
    department VARCHAR2(100),
    hire_date DATE DEFAULT SYSDATE,
    is_active VARCHAR2(1) DEFAULT 'Y' CHECK (is_active IN ('Y', 'N')),
    created_date DATE DEFAULT SYSDATE,
    modified_date DATE DEFAULT SYSDATE
);

PROMPT Providers table created;

-- Lookup tables
CREATE TABLE appointment_types (
    type_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    type_name VARCHAR2(50) NOT NULL UNIQUE,
    duration_minutes NUMBER DEFAULT 30,
    description VARCHAR2(200),
    is_active VARCHAR2(1) DEFAULT 'Y' CHECK (is_active IN ('Y', 'N'))
);

CREATE TABLE specialties (
    specialty_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    specialty_name VARCHAR2(100) NOT NULL UNIQUE,
    description VARCHAR2(200),
    is_active VARCHAR2(1) DEFAULT 'Y' CHECK (is_active IN ('Y', 'N'))
);

CREATE TABLE lookup_values (
    lookup_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    lookup_type VARCHAR2(50) NOT NULL,
    lookup_value VARCHAR2(100) NOT NULL,
    display_order NUMBER DEFAULT 1,
    is_active VARCHAR2(1) DEFAULT 'Y' CHECK (is_active IN ('Y', 'N')),
    UNIQUE (lookup_type, lookup_value)
);

PROMPT Lookup tables created;

-- Appointments table
CREATE TABLE appointments (
    appointment_id NUMBER DEFAULT seq_appointment_id.NEXTVAL PRIMARY KEY,
    patient_id NUMBER NOT NULL,
    provider_id NUMBER NOT NULL,
    appointment_date DATE NOT NULL,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP NOT NULL,
    appointment_type VARCHAR2(50),
    status VARCHAR2(20) DEFAULT 'Scheduled' CHECK (status IN ('Scheduled', 'Confirmed', 'Completed', 'Cancelled', 'No-show')),
    reason_for_visit VARCHAR2(500),
    notes CLOB,
    created_date DATE DEFAULT SYSDATE,
    created_by VARCHAR2(50) DEFAULT USER,
    modified_date DATE DEFAULT SYSDATE,
    modified_by VARCHAR2(50) DEFAULT USER,
    CONSTRAINT fk_appointment_patient FOREIGN KEY (patient_id) REFERENCES patients(patient_id),
    CONSTRAINT fk_appointment_provider FOREIGN KEY (provider_id) REFERENCES providers(provider_id)
);

PROMPT Appointments table created;

PROMPT ===============================================;
PROMPT Part 1 Complete - Continue with Part 2
PROMPT ===============================================;
