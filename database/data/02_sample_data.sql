-- Healthcare System - Sample Data
-- Insert lookup data and sample records

-- Insert appointment types
INSERT INTO appointment_types (type_id, type_name, default_duration, description) VALUES
(1, 'Initial Consultation', 60, 'First-time patient visit for comprehensive evaluation');
INSERT INTO appointment_types (type_id, type_name, default_duration, description) VALUES
(2, 'Follow-up', 30, 'Follow-up visit for ongoing care');
INSERT INTO appointment_types (type_id, type_name, default_duration, description) VALUES
(3, 'Annual Physical', 45, 'Annual comprehensive physical examination');
INSERT INTO appointment_types (type_id, type_name, default_duration, description) VALUES
(4, 'Urgent Care', 20, 'Urgent medical care for non-emergency conditions');
INSERT INTO appointment_types (type_id, type_name, default_duration, description) VALUES
(5, 'Specialist Consultation', 45, 'Consultation with medical specialist');
INSERT INTO appointment_types (type_id, type_name, default_duration, description) VALUES
(6, 'Preventive Care', 30, 'Preventive care and screening');
INSERT INTO appointment_types (type_id, type_name, default_duration, description) VALUES
(7, 'Telemedicine', 20, 'Virtual consultation via video/phone');

-- Insert medical specialties
INSERT INTO specialties (specialty_id, specialty_name, description) VALUES
(1, 'Family Medicine', 'Primary care for patients of all ages');
INSERT INTO specialties (specialty_id, specialty_name, description) VALUES
(2, 'Internal Medicine', 'Internal medicine and adult primary care');
INSERT INTO specialties (specialty_id, specialty_name, description) VALUES
(3, 'Cardiology', 'Heart and cardiovascular system disorders');
INSERT INTO specialties (specialty_id, specialty_name, description) VALUES
(4, 'Dermatology', 'Skin, hair, and nail disorders');
INSERT INTO specialties (specialty_id, specialty_name, description) VALUES
(5, 'Orthopedics', 'Musculoskeletal system disorders');
INSERT INTO specialties (specialty_id, specialty_name, description) VALUES
(6, 'Pediatrics', 'Medical care for infants, children, and adolescents');
INSERT INTO specialties (specialty_id, specialty_name, description) VALUES
(7, 'Neurology', 'Nervous system disorders');
INSERT INTO specialties (specialty_id, specialty_name, description) VALUES
(8, 'Oncology', 'Cancer diagnosis and treatment');
INSERT INTO specialties (specialty_id, specialty_name, description) VALUES
(9, 'Psychiatry', 'Mental health and psychiatric disorders');
INSERT INTO specialties (specialty_id, specialty_name, description) VALUES
(10, 'Emergency Medicine', 'Emergency and urgent medical care');

-- Insert sample providers
INSERT INTO providers (first_name, last_name, title, specialty, license_number, phone, email, department) VALUES
('Sarah', 'Johnson', 'Dr.', 'Family Medicine', 'MD123456', '555-0101', 'sarah.johnson@healthsystem.com', 'Primary Care');
INSERT INTO providers (first_name, last_name, title, specialty, license_number, phone, email, department) VALUES
('Michael', 'Chen', 'Dr.', 'Cardiology', 'MD234567', '555-0102', 'michael.chen@healthsystem.com', 'Cardiology');
INSERT INTO providers (first_name, last_name, title, specialty, license_number, phone, email, department) VALUES
('Emily', 'Rodriguez', 'Dr.', 'Pediatrics', 'MD345678', '555-0103', 'emily.rodriguez@healthsystem.com', 'Pediatrics');
INSERT INTO providers (first_name, last_name, title, specialty, license_number, phone, email, department) VALUES
('David', 'Thompson', 'Dr.', 'Orthopedics', 'MD456789', '555-0104', 'david.thompson@healthsystem.com', 'Orthopedics');
INSERT INTO providers (first_name, last_name, title, specialty, license_number, phone, email, department) VALUES
('Lisa', 'Anderson', 'Nurse Practitioner', 'Family Medicine', 'NP567890', '555-0105', 'lisa.anderson@healthsystem.com', 'Primary Care');
INSERT INTO providers (first_name, last_name, title, specialty, license_number, phone, email, department) VALUES
('Robert', 'Wilson', 'Dr.', 'Internal Medicine', 'MD678901', '555-0106', 'robert.wilson@healthsystem.com', 'Internal Medicine');

-- Insert sample patients
INSERT INTO patients (first_name, last_name, date_of_birth, gender, phone, email, address, city, state, zip_code, 
                     emergency_contact_name, emergency_contact_phone, insurance_provider, insurance_policy_number, 
                     blood_type, allergies) VALUES
('John', 'Smith', DATE '1985-03-15', 'Male', '555-1001', 'john.smith@email.com', '123 Main St', 
 'Springfield', 'IL', '62701', 'Jane Smith', '555-1002', 'Blue Cross Blue Shield', 'BC123456789', 
 'O+', 'Penicillin allergy');

INSERT INTO patients (first_name, last_name, date_of_birth, gender, phone, email, address, city, state, zip_code, 
                     emergency_contact_name, emergency_contact_phone, insurance_provider, insurance_policy_number, 
                     blood_type) VALUES
('Mary', 'Johnson', DATE '1978-07-22', 'Female', '555-2001', 'mary.johnson@email.com', '456 Oak Ave', 
 'Springfield', 'IL', '62702', 'Bob Johnson', '555-2002', 'Aetna', 'AE987654321', 'A-');

INSERT INTO patients (first_name, last_name, date_of_birth, gender, phone, email, address, city, state, zip_code, 
                     emergency_contact_name, emergency_contact_phone, insurance_provider, insurance_policy_number, 
                     blood_type, medical_conditions) VALUES
('Robert', 'Davis', DATE '1960-12-08', 'Male', '555-3001', 'robert.davis@email.com', '789 Pine St', 
 'Springfield', 'IL', '62703', 'Susan Davis', '555-3002', 'Medicare', 'MC456789123', 'B+', 
 'Hypertension, Type 2 Diabetes');

INSERT INTO patients (first_name, last_name, date_of_birth, gender, phone, email, address, city, state, zip_code, 
                     emergency_contact_name, emergency_contact_phone, insurance_provider, insurance_policy_number, 
                     blood_type) VALUES
('Jennifer', 'Brown', DATE '1992-09-03', 'Female', '555-4001', 'jennifer.brown@email.com', '321 Elm Dr', 
 'Springfield', 'IL', '62704', 'Michael Brown', '555-4002', 'Cigna', 'CG789123456', 'AB+');

INSERT INTO patients (first_name, last_name, date_of_birth, gender, phone, email, address, city, state, zip_code, 
                     emergency_contact_name, emergency_contact_phone, insurance_provider, insurance_policy_number, 
                     blood_type, allergies) VALUES
('William', 'Miller', DATE '2010-05-18', 'Male', '555-5001', 'sarah.miller@email.com', '654 Maple Ln', 
 'Springfield', 'IL', '62705', 'Sarah Miller', '555-5001', 'UnitedHealth', 'UH321654987', 'O-', 
 'Latex allergy, Food allergies (nuts)');

-- Insert sample appointments
INSERT INTO appointments (patient_id, provider_id, appointment_date, appointment_time, appointment_type, 
                         status, reason_for_visit) VALUES
(1000, 100, DATE '2025-06-05', '09:00', 'Annual Physical', 'Scheduled', 'Annual physical examination');

INSERT INTO appointments (patient_id, provider_id, appointment_date, appointment_time, appointment_type, 
                         status, reason_for_visit) VALUES
(1001, 100, DATE '2025-06-05', '10:30', 'Follow-up', 'Scheduled', 'Follow-up for blood pressure check');

INSERT INTO appointments (patient_id, provider_id, appointment_date, appointment_time, appointment_type, 
                         status, reason_for_visit) VALUES
(1002, 105, DATE '2025-06-06', '14:00', 'Initial Consultation', 'Confirmed', 'New patient consultation for diabetes management');

INSERT INTO appointments (patient_id, provider_id, appointment_date, appointment_time, appointment_type, 
                         status, reason_for_visit) VALUES
(1003, 102, DATE '2025-06-07', '11:15', 'Specialist Consultation', 'Scheduled', 'Pediatric wellness check');

INSERT INTO appointments (patient_id, provider_id, appointment_date, appointment_time, appointment_type, 
                         status, reason_for_visit) VALUES
(1004, 103, DATE '2025-06-08', '15:30', 'Urgent Care', 'Scheduled', 'Knee pain after sports injury');

COMMIT;

-- Display summary of inserted data
SELECT 'Appointment Types' as category, COUNT(*) as count FROM appointment_types
UNION ALL
SELECT 'Specialties' as category, COUNT(*) as count FROM specialties
UNION ALL
SELECT 'Providers' as category, COUNT(*) as count FROM providers
UNION ALL
SELECT 'Patients' as category, COUNT(*) as count FROM patients
UNION ALL
SELECT 'Appointments' as category, COUNT(*) as count FROM appointments;
