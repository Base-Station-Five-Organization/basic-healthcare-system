-- Healthcare System - Oracle APEX Cloud Setup
-- Part 5: Sample Data
-- Run this after Part 4

PROMPT ===============================================;
PROMPT Healthcare System - Part 5: Sample Data
PROMPT ===============================================;

-- Insert appointment types
INSERT INTO appointment_types (type_name, duration_minutes, description) VALUES
('General Consultation', 30, 'Standard consultation appointment');
INSERT INTO appointment_types (type_name, duration_minutes, description) VALUES
('Follow-up', 15, 'Follow-up appointment');
INSERT INTO appointment_types (type_name, duration_minutes, description) VALUES
('Physical Exam', 45, 'Comprehensive physical examination');
INSERT INTO appointment_types (type_name, duration_minutes, description) VALUES
('Procedure', 60, 'Medical procedure appointment');

-- Insert specialties
INSERT INTO specialties (specialty_name, description) VALUES
('Internal Medicine', 'General internal medicine');
INSERT INTO specialties (specialty_name, description) VALUES
('Cardiology', 'Heart and cardiovascular system');
INSERT INTO specialties (specialty_name, description) VALUES
('Endocrinology', 'Hormones and metabolism');
INSERT INTO specialties (specialty_name, description) VALUES
('Neurology', 'Nervous system disorders');

-- Insert lookup values
INSERT INTO lookup_values (lookup_type, lookup_value, display_order) VALUES
('APPOINTMENT_STATUS', 'Scheduled', 1);
INSERT INTO lookup_values (lookup_type, lookup_value, display_order) VALUES
('APPOINTMENT_STATUS', 'Confirmed', 2);
INSERT INTO lookup_values (lookup_type, lookup_value, display_order) VALUES
('APPOINTMENT_STATUS', 'Completed', 3);
INSERT INTO lookup_values (lookup_type, lookup_value, display_order) VALUES
('APPOINTMENT_STATUS', 'Cancelled', 4);
INSERT INTO lookup_values (lookup_type, lookup_value, display_order) VALUES
('APPOINTMENT_STATUS', 'No-show', 5);

-- Insert sample providers
INSERT INTO providers (first_name, last_name, title, specialty, license_number, phone, email, department) VALUES
('John', 'Smith', 'MD', 'Internal Medicine', 'MD12345', '555-0101', 'j.smith@hospital.com', 'Internal Medicine');

INSERT INTO providers (first_name, last_name, title, specialty, license_number, phone, email, department) VALUES
('Sarah', 'Johnson', 'MD', 'Cardiology', 'MD12346', '555-0102', 's.johnson@hospital.com', 'Cardiology');

INSERT INTO providers (first_name, last_name, title, specialty, license_number, phone, email, department) VALUES
('Michael', 'Brown', 'MD', 'Endocrinology', 'MD12347', '555-0103', 'm.brown@hospital.com', 'Endocrinology');

INSERT INTO providers (first_name, last_name, title, specialty, license_number, phone, email, department) VALUES
('Emily', 'Davis', 'MD', 'Neurology', 'MD12348', '555-0104', 'e.davis@hospital.com', 'Neurology');

-- Insert sample patients
INSERT INTO patients (first_name, last_name, date_of_birth, gender, phone, email, address, city, state, zip_code, 
                     emergency_contact_name, emergency_contact_phone, insurance_provider, insurance_policy_number) VALUES
('Robert', 'Wilson', DATE '1975-03-15', 'Male', '555-1001', 'r.wilson@email.com', '123 Main St', 'Springfield', 'IL', '62701',
 'Mary Wilson', '555-1002', 'Blue Cross', 'BC123456789');

INSERT INTO patients (first_name, last_name, date_of_birth, gender, phone, email, address, city, state, zip_code,
                     emergency_contact_name, emergency_contact_phone, insurance_provider, insurance_policy_number) VALUES
('Jennifer', 'Garcia', DATE '1988-07-22', 'Female', '555-1003', 'j.garcia@email.com', '456 Oak Ave', 'Springfield', 'IL', '62702',
 'Carlos Garcia', '555-1004', 'Aetna', 'AE987654321');

INSERT INTO patients (first_name, last_name, date_of_birth, gender, phone, email, address, city, state, zip_code,
                     emergency_contact_name, emergency_contact_phone, insurance_provider, insurance_policy_number) VALUES
('David', 'Martinez', DATE '1965-11-08', 'Male', '555-1005', 'd.martinez@email.com', '789 Pine St', 'Springfield', 'IL', '62703',
 'Lisa Martinez', '555-1006', 'Cigna', 'CG456789123');

PROMPT Sample data inserted;

PROMPT ===============================================;
PROMPT Part 5 Complete - Continue with Part 6
PROMPT ===============================================;
