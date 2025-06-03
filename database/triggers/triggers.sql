-- Healthcare System Database Triggers
-- Auditing and Data Integrity

-- Create audit table for patients
CREATE TABLE patient_audit (
    audit_id NUMBER PRIMARY KEY,
    patient_id NUMBER,
    operation VARCHAR2(10), -- INSERT, UPDATE, DELETE
    old_values CLOB,
    new_values CLOB,
    changed_by VARCHAR2(50),
    changed_date DATE DEFAULT SYSDATE
);

CREATE SEQUENCE seq_patient_audit START WITH 1 INCREMENT BY 1;

-- Trigger for patient table auditing
CREATE OR REPLACE TRIGGER trg_patients_audit
    BEFORE INSERT OR UPDATE OR DELETE ON patients
    FOR EACH ROW
DECLARE
    l_operation VARCHAR2(10);
    l_old_values CLOB;
    l_new_values CLOB;
BEGIN
    -- Determine operation type
    IF INSERTING THEN
        l_operation := 'INSERT';
        l_new_values := JSON_OBJECT(
            'patient_id' VALUE :NEW.patient_id,
            'first_name' VALUE :NEW.first_name,
            'last_name' VALUE :NEW.last_name,
            'date_of_birth' VALUE TO_CHAR(:NEW.date_of_birth, 'YYYY-MM-DD'),
            'gender' VALUE :NEW.gender,
            'phone' VALUE :NEW.phone,
            'email' VALUE :NEW.email,
            'address' VALUE :NEW.address,
            'city' VALUE :NEW.city,
            'state' VALUE :NEW.state,
            'zip_code' VALUE :NEW.zip_code,
            'is_active' VALUE :NEW.is_active
        );
    ELSIF UPDATING THEN
        l_operation := 'UPDATE';
        l_old_values := JSON_OBJECT(
            'patient_id' VALUE :OLD.patient_id,
            'first_name' VALUE :OLD.first_name,
            'last_name' VALUE :OLD.last_name,
            'date_of_birth' VALUE TO_CHAR(:OLD.date_of_birth, 'YYYY-MM-DD'),
            'gender' VALUE :OLD.gender,
            'phone' VALUE :OLD.phone,
            'email' VALUE :OLD.email,
            'address' VALUE :OLD.address,
            'city' VALUE :OLD.city,
            'state' VALUE :OLD.state,
            'zip_code' VALUE :OLD.zip_code,
            'is_active' VALUE :OLD.is_active
        );
        l_new_values := JSON_OBJECT(
            'patient_id' VALUE :NEW.patient_id,
            'first_name' VALUE :NEW.first_name,
            'last_name' VALUE :NEW.last_name,
            'date_of_birth' VALUE TO_CHAR(:NEW.date_of_birth, 'YYYY-MM-DD'),
            'gender' VALUE :NEW.gender,
            'phone' VALUE :NEW.phone,
            'email' VALUE :NEW.email,
            'address' VALUE :NEW.address,
            'city' VALUE :NEW.city,
            'state' VALUE :NEW.state,
            'zip_code' VALUE :NEW.zip_code,
            'is_active' VALUE :NEW.is_active
        );
    ELSIF DELETING THEN
        l_operation := 'DELETE';
        l_old_values := JSON_OBJECT(
            'patient_id' VALUE :OLD.patient_id,
            'first_name' VALUE :OLD.first_name,
            'last_name' VALUE :OLD.last_name,
            'date_of_birth' VALUE TO_CHAR(:OLD.date_of_birth, 'YYYY-MM-DD'),
            'gender' VALUE :OLD.gender,
            'phone' VALUE :OLD.phone,
            'email' VALUE :OLD.email,
            'is_active' VALUE :OLD.is_active
        );
    END IF;
    
    -- Insert audit record
    INSERT INTO patient_audit (
        audit_id, patient_id, operation, old_values, new_values, changed_by, changed_date
    ) VALUES (
        seq_patient_audit.NEXTVAL,
        COALESCE(:NEW.patient_id, :OLD.patient_id),
        l_operation,
        l_old_values,
        l_new_values,
        USER,
        SYSDATE
    );
END;
/

-- Trigger to automatically update modified_date and modified_by fields
CREATE OR REPLACE TRIGGER trg_patients_modified
    BEFORE UPDATE ON patients
    FOR EACH ROW
BEGIN
    :NEW.modified_date := SYSDATE;
    :NEW.modified_by := USER;
END;
/

-- Trigger to prevent deletion of patients with active appointments
CREATE OR REPLACE TRIGGER trg_patients_delete_check
    BEFORE DELETE ON patients
    FOR EACH ROW
DECLARE
    l_count NUMBER;
BEGIN
    -- Check for future appointments
    SELECT COUNT(*)
    INTO l_count
    FROM appointments
    WHERE patient_id = :OLD.patient_id
      AND appointment_date >= TRUNC(SYSDATE)
      AND status IN ('Scheduled', 'Confirmed');
    
    IF l_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20010, 
            'Cannot delete patient with future appointments. Cancel appointments first.');
    END IF;
END;
/

-- Trigger for appointment validation
CREATE OR REPLACE TRIGGER trg_appointments_validation
    BEFORE INSERT OR UPDATE ON appointments
    FOR EACH ROW
DECLARE
    l_patient_active VARCHAR2(1);
    l_provider_active VARCHAR2(1);
    l_conflicts NUMBER;
BEGIN
    -- Check if patient is active
    SELECT is_active
    INTO l_patient_active
    FROM patients
    WHERE patient_id = :NEW.patient_id;
    
    IF l_patient_active = 'N' THEN
        RAISE_APPLICATION_ERROR(-20011, 'Cannot schedule appointment for inactive patient');
    END IF;
    
    -- Check if provider is active
    SELECT is_active
    INTO l_provider_active
    FROM providers
    WHERE provider_id = :NEW.provider_id;
    
    IF l_provider_active = 'N' THEN
        RAISE_APPLICATION_ERROR(-20012, 'Cannot schedule appointment with inactive provider');
    END IF;
    
    -- Check for appointment conflicts (only for active appointments)
    IF :NEW.status NOT IN ('Cancelled', 'No Show') THEN
        SELECT COUNT(*)
        INTO l_conflicts
        FROM appointments
        WHERE provider_id = :NEW.provider_id
          AND appointment_date = :NEW.appointment_date
          AND appointment_time = :NEW.appointment_time
          AND status NOT IN ('Cancelled', 'No Show')
          AND (:OLD.appointment_id IS NULL OR appointment_id != :OLD.appointment_id);
        
        IF l_conflicts > 0 THEN
            RAISE_APPLICATION_ERROR(-20013, 
                'Time slot conflict: Provider already has an appointment at this time');
        END IF;
    END IF;
    
    -- Validate appointment date is not in the past
    IF :NEW.appointment_date < TRUNC(SYSDATE) AND INSERTING THEN
        RAISE_APPLICATION_ERROR(-20014, 'Cannot schedule appointment in the past');
    END IF;
    
    -- Set default duration if not provided
    IF :NEW.duration_minutes IS NULL THEN
        :NEW.duration_minutes := 30;
    END IF;
    
    -- Auto-update modified fields on update
    IF UPDATING THEN
        :NEW.modified_date := SYSDATE;
        :NEW.modified_by := USER;
    END IF;
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        IF l_patient_active IS NULL THEN
            RAISE_APPLICATION_ERROR(-20015, 'Invalid patient ID');
        ELSIF l_provider_active IS NULL THEN
            RAISE_APPLICATION_ERROR(-20016, 'Invalid provider ID');
        END IF;
END;
/

-- Trigger to automatically update appointment status
CREATE OR REPLACE TRIGGER trg_appointments_auto_status
    BEFORE INSERT OR UPDATE ON appointments
    FOR EACH ROW
BEGIN
    -- Auto-complete appointments that are past their scheduled time
    IF :NEW.appointment_date < TRUNC(SYSDATE) 
       AND :NEW.status = 'Scheduled' 
       AND UPDATING THEN
        :NEW.status := 'Completed';
    END IF;
    
    -- Set created fields for new appointments
    IF INSERTING THEN
        :NEW.created_date := SYSDATE;
        :NEW.created_by := USER;
        :NEW.modified_date := SYSDATE;
        :NEW.modified_by := USER;
    END IF;
END;
/

-- Trigger for medical records validation
CREATE OR REPLACE TRIGGER trg_medical_records_validation
    BEFORE INSERT OR UPDATE ON medical_records
    FOR EACH ROW
DECLARE
    l_patient_exists NUMBER;
    l_provider_exists NUMBER;
    l_appointment_exists NUMBER;
BEGIN
    -- Validate patient exists
    SELECT COUNT(*)
    INTO l_patient_exists
    FROM patients
    WHERE patient_id = :NEW.patient_id;
    
    IF l_patient_exists = 0 THEN
        RAISE_APPLICATION_ERROR(-20017, 'Invalid patient ID in medical record');
    END IF;
    
    -- Validate provider exists
    SELECT COUNT(*)
    INTO l_provider_exists
    FROM providers
    WHERE provider_id = :NEW.provider_id;
    
    IF l_provider_exists = 0 THEN
        RAISE_APPLICATION_ERROR(-20018, 'Invalid provider ID in medical record');
    END IF;
    
    -- Validate appointment exists if provided
    IF :NEW.appointment_id IS NOT NULL THEN
        SELECT COUNT(*)
        INTO l_appointment_exists
        FROM appointments
        WHERE appointment_id = :NEW.appointment_id
          AND patient_id = :NEW.patient_id
          AND provider_id = :NEW.provider_id;
        
        IF l_appointment_exists = 0 THEN
            RAISE_APPLICATION_ERROR(-20019, 
                'Invalid appointment ID or appointment does not match patient/provider');
        END IF;
    END IF;
    
    -- Set created fields for new records
    IF INSERTING THEN
        :NEW.created_date := SYSDATE;
        :NEW.created_by := USER;
    END IF;
END;
/

-- Trigger for prescription validation
CREATE OR REPLACE TRIGGER trg_prescriptions_validation
    BEFORE INSERT OR UPDATE ON prescriptions
    FOR EACH ROW
DECLARE
    l_patient_exists NUMBER;
    l_provider_exists NUMBER;
    l_record_exists NUMBER;
BEGIN
    -- Validate patient exists
    SELECT COUNT(*)
    INTO l_patient_exists
    FROM patients
    WHERE patient_id = :NEW.patient_id;
    
    IF l_patient_exists = 0 THEN
        RAISE_APPLICATION_ERROR(-20020, 'Invalid patient ID in prescription');
    END IF;
    
    -- Validate provider exists
    SELECT COUNT(*)
    INTO l_provider_exists
    FROM providers
    WHERE provider_id = :NEW.provider_id;
    
    IF l_provider_exists = 0 THEN
        RAISE_APPLICATION_ERROR(-20021, 'Invalid provider ID in prescription');
    END IF;
    
    -- Validate medical record exists if provided
    IF :NEW.record_id IS NOT NULL THEN
        SELECT COUNT(*)
        INTO l_record_exists
        FROM medical_records
        WHERE record_id = :NEW.record_id
          AND patient_id = :NEW.patient_id;
        
        IF l_record_exists = 0 THEN
            RAISE_APPLICATION_ERROR(-20022, 
                'Invalid medical record ID or record does not belong to patient');
        END IF;
    END IF;
    
    -- Set created fields for new prescriptions
    IF INSERTING THEN
        :NEW.created_date := SYSDATE;
        :NEW.created_by := USER;
        :NEW.date_prescribed := SYSDATE;
    END IF;
    
    -- Validate quantity and refills
    IF :NEW.quantity IS NOT NULL AND :NEW.quantity <= 0 THEN
        RAISE_APPLICATION_ERROR(-20023, 'Prescription quantity must be positive');
    END IF;
    
    IF :NEW.refills_allowed IS NOT NULL AND :NEW.refills_allowed < 0 THEN
        RAISE_APPLICATION_ERROR(-20024, 'Refills allowed cannot be negative');
    END IF;
END;
/

-- Create table for appointment reminders (referenced in package)
CREATE TABLE appointment_reminders (
    reminder_id NUMBER PRIMARY KEY,
    appointment_id NUMBER NOT NULL REFERENCES appointments(appointment_id),
    reminder_type VARCHAR2(20) NOT NULL, -- EMAIL, SMS, PHONE
    recipient_email VARCHAR2(100),
    recipient_phone VARCHAR2(20),
    message CLOB,
    sent_date DATE,
    status VARCHAR2(20) DEFAULT 'PENDING', -- PENDING, SENT, FAILED
    created_date DATE DEFAULT SYSDATE
);

CREATE SEQUENCE seq_reminder_id START WITH 1 INCREMENT BY 1;

-- Trigger for appointment reminders
CREATE OR REPLACE TRIGGER trg_appointment_reminders
    BEFORE INSERT ON appointment_reminders
    FOR EACH ROW
BEGIN
    IF :NEW.reminder_id IS NULL THEN
        :NEW.reminder_id := seq_reminder_id.NEXTVAL;
    END IF;
END;
/

-- Add comments to triggers
COMMENT ON TRIGGER trg_patients_audit IS 'Audit trigger for patients table - tracks all changes';
COMMENT ON TRIGGER trg_patients_modified IS 'Auto-update modified_date and modified_by fields';
COMMENT ON TRIGGER trg_patients_delete_check IS 'Prevent deletion of patients with future appointments';
COMMENT ON TRIGGER trg_appointments_validation IS 'Validate appointment data and check for conflicts';
COMMENT ON TRIGGER trg_appointments_auto_status IS 'Auto-update appointment status and timestamps';
COMMENT ON TRIGGER trg_medical_records_validation IS 'Validate medical record references';
COMMENT ON TRIGGER trg_prescriptions_validation IS 'Validate prescription data and references';
