-- Healthcare System - Appointment Management Package

CREATE OR REPLACE PACKAGE pkg_appointment_mgmt AS
    -- Public type declarations
    TYPE t_appointment_rec IS RECORD (
        appointment_id      NUMBER,
        patient_name        VARCHAR2(101),
        provider_name       VARCHAR2(101),
        appointment_date    DATE,
        appointment_time    VARCHAR2(10),
        duration_minutes    NUMBER,
        appointment_type    VARCHAR2(50),
        status              VARCHAR2(20),
        reason_for_visit    VARCHAR2(500)
    );
    
    TYPE t_appointment_tab IS TABLE OF t_appointment_rec;
    
    TYPE t_time_slot_rec IS RECORD (
        time_slot           VARCHAR2(10),
        is_available        VARCHAR2(1),
        appointment_id      NUMBER
    );
    
    TYPE t_time_slot_tab IS TABLE OF t_time_slot_rec;
    
    -- Public constants
    c_default_appointment_duration CONSTANT NUMBER := 30;
    c_business_start_hour CONSTANT NUMBER := 8;  -- 8 AM
    c_business_end_hour CONSTANT NUMBER := 17;   -- 5 PM
    
    -- Public procedure and function declarations
    FUNCTION validate_appointment_data(
        p_patient_id IN NUMBER,
        p_provider_id IN NUMBER,
        p_appointment_date IN DATE,
        p_appointment_time IN VARCHAR2
    ) RETURN VARCHAR2;
    
    FUNCTION is_time_slot_available(
        p_provider_id IN NUMBER,
        p_appointment_date IN DATE,
        p_appointment_time IN VARCHAR2,
        p_duration_minutes IN NUMBER DEFAULT c_default_appointment_duration,
        p_exclude_appointment_id IN NUMBER DEFAULT NULL
    ) RETURN BOOLEAN;
    
    FUNCTION get_available_time_slots(
        p_provider_id IN NUMBER,
        p_appointment_date IN DATE,
        p_duration_minutes IN NUMBER DEFAULT c_default_appointment_duration
    ) RETURN t_time_slot_tab PIPELINED;
    
    PROCEDURE schedule_appointment(
        p_patient_id IN NUMBER,
        p_provider_id IN NUMBER,
        p_appointment_date IN DATE,
        p_appointment_time IN VARCHAR2,
        p_appointment_type IN VARCHAR2 DEFAULT 'Follow-up',
        p_duration_minutes IN NUMBER DEFAULT c_default_appointment_duration,
        p_reason_for_visit IN VARCHAR2 DEFAULT NULL,
        p_appointment_id OUT NUMBER
    );
    
    PROCEDURE reschedule_appointment(
        p_appointment_id IN NUMBER,
        p_new_date IN DATE,
        p_new_time IN VARCHAR2,
        p_notes IN VARCHAR2 DEFAULT NULL
    );
    
    PROCEDURE cancel_appointment(
        p_appointment_id IN NUMBER,
        p_reason IN VARCHAR2 DEFAULT NULL
    );
    
    PROCEDURE update_appointment_status(
        p_appointment_id IN NUMBER,
        p_status IN VARCHAR2,
        p_notes IN VARCHAR2 DEFAULT NULL
    );
    
    FUNCTION get_appointments_by_date(
        p_appointment_date IN DATE,
        p_provider_id IN NUMBER DEFAULT NULL
    ) RETURN t_appointment_tab PIPELINED;
    
    FUNCTION get_patient_appointments(
        p_patient_id IN NUMBER,
        p_include_past IN VARCHAR2 DEFAULT 'N'
    ) RETURN t_appointment_tab PIPELINED;
    
    PROCEDURE send_appointment_reminder(
        p_appointment_id IN NUMBER
    );
    
END pkg_appointment_mgmt;
/

CREATE OR REPLACE PACKAGE BODY pkg_appointment_mgmt AS

    FUNCTION validate_appointment_data(
        p_patient_id IN NUMBER,
        p_provider_id IN NUMBER,
        p_appointment_date IN DATE,
        p_appointment_time IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_errors VARCHAR2(4000);
        l_count NUMBER;
        l_hour NUMBER;
        l_minute NUMBER;
    BEGIN
        -- Validate patient exists
        SELECT COUNT(*)
        INTO l_count
        FROM patients
        WHERE patient_id = p_patient_id AND is_active = 'Y';
        
        IF l_count = 0 THEN
            l_errors := l_errors || 'Invalid or inactive patient ID. ';
        END IF;
        
        -- Validate provider exists
        SELECT COUNT(*)
        INTO l_count
        FROM providers
        WHERE provider_id = p_provider_id AND is_active = 'Y';
        
        IF l_count = 0 THEN
            l_errors := l_errors || 'Invalid or inactive provider ID. ';
        END IF;
        
        -- Validate appointment date
        IF p_appointment_date IS NULL THEN
            l_errors := l_errors || 'Appointment date is required. ';
        ELSIF p_appointment_date < TRUNC(SYSDATE) THEN
            l_errors := l_errors || 'Appointment date cannot be in the past. ';
        ELSIF p_appointment_date > SYSDATE + 365 THEN
            l_errors := l_errors || 'Appointment date cannot be more than 1 year in advance. ';
        END IF;
        
        -- Validate appointment time format (HH24:MI)
        IF p_appointment_time IS NULL THEN
            l_errors := l_errors || 'Appointment time is required. ';
        ELSIF NOT REGEXP_LIKE(p_appointment_time, '^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$') THEN
            l_errors := l_errors || 'Invalid time format. Use HH:MM (24-hour format). ';
        ELSE
            -- Extract hour and minute
            l_hour := TO_NUMBER(SUBSTR(p_appointment_time, 1, INSTR(p_appointment_time, ':') - 1));
            l_minute := TO_NUMBER(SUBSTR(p_appointment_time, INSTR(p_appointment_time, ':') + 1));
            
            -- Validate business hours
            IF l_hour < c_business_start_hour OR l_hour >= c_business_end_hour THEN
                l_errors := l_errors || 'Appointment time must be during business hours (' || 
                           c_business_start_hour || ':00 - ' || c_business_end_hour || ':00). ';
            END IF;
            
            -- Validate minute intervals (15-minute slots)
            IF MOD(l_minute, 15) != 0 THEN
                l_errors := l_errors || 'Appointment time must be in 15-minute intervals (00, 15, 30, 45). ';
            END IF;
        END IF;
        
        RETURN TRIM(l_errors);
    END validate_appointment_data;

    FUNCTION is_time_slot_available(
        p_provider_id IN NUMBER,
        p_appointment_date IN DATE,
        p_appointment_time IN VARCHAR2,
        p_duration_minutes IN NUMBER DEFAULT c_default_appointment_duration,
        p_exclude_appointment_id IN NUMBER DEFAULT NULL
    ) RETURN BOOLEAN IS
        l_count NUMBER;
        l_start_time DATE;
        l_end_time DATE;
    BEGIN
        -- Convert appointment time to datetime
        l_start_time := TO_DATE(TO_CHAR(p_appointment_date, 'YYYY-MM-DD') || ' ' || p_appointment_time, 'YYYY-MM-DD HH24:MI');
        l_end_time := l_start_time + (p_duration_minutes / (24 * 60));
        
        -- Check for conflicting appointments
        SELECT COUNT(*)
        INTO l_count
        FROM appointments a
        WHERE a.provider_id = p_provider_id
          AND a.appointment_date = p_appointment_date
          AND a.status NOT IN ('Cancelled', 'No Show')
          AND (p_exclude_appointment_id IS NULL OR a.appointment_id != p_exclude_appointment_id)
          AND (
              -- New appointment overlaps with existing appointment
              (TO_DATE(TO_CHAR(a.appointment_date, 'YYYY-MM-DD') || ' ' || a.appointment_time, 'YYYY-MM-DD HH24:MI') < l_end_time
               AND 
               TO_DATE(TO_CHAR(a.appointment_date, 'YYYY-MM-DD') || ' ' || a.appointment_time, 'YYYY-MM-DD HH24:MI') + 
               (NVL(a.duration_minutes, c_default_appointment_duration) / (24 * 60)) > l_start_time)
          );
        
        RETURN l_count = 0;
    END is_time_slot_available;

    FUNCTION get_available_time_slots(
        p_provider_id IN NUMBER,
        p_appointment_date IN DATE,
        p_duration_minutes IN NUMBER DEFAULT c_default_appointment_duration
    ) RETURN t_time_slot_tab PIPELINED IS
        
        l_slot t_time_slot_rec;
        l_time_slot VARCHAR2(10);
        l_hour NUMBER;
        l_minute NUMBER;
        
    BEGIN
        -- Generate 15-minute time slots during business hours
        FOR l_hour IN c_business_start_hour..(c_business_end_hour - 1) LOOP
            FOR l_minute IN 0..3 LOOP -- 0, 15, 30, 45 minutes
                l_time_slot := LPAD(l_hour, 2, '0') || ':' || LPAD(l_minute * 15, 2, '0');
                
                l_slot.time_slot := l_time_slot;
                l_slot.is_available := CASE 
                    WHEN is_time_slot_available(p_provider_id, p_appointment_date, l_time_slot, p_duration_minutes) 
                    THEN 'Y' 
                    ELSE 'N' 
                END;
                
                -- Get appointment ID if slot is occupied
                IF l_slot.is_available = 'N' THEN
                    BEGIN
                        SELECT appointment_id
                        INTO l_slot.appointment_id
                        FROM appointments
                        WHERE provider_id = p_provider_id
                          AND appointment_date = p_appointment_date
                          AND appointment_time = l_time_slot
                          AND status NOT IN ('Cancelled', 'No Show')
                          AND ROWNUM = 1;
                    EXCEPTION
                        WHEN NO_DATA_FOUND THEN
                            l_slot.appointment_id := NULL;
                    END;
                ELSE
                    l_slot.appointment_id := NULL;
                END IF;
                
                PIPE ROW(l_slot);
            END LOOP;
        END LOOP;
        
        RETURN;
    END get_available_time_slots;

    PROCEDURE schedule_appointment(
        p_patient_id IN NUMBER,
        p_provider_id IN NUMBER,
        p_appointment_date IN DATE,
        p_appointment_time IN VARCHAR2,
        p_appointment_type IN VARCHAR2 DEFAULT 'Follow-up',
        p_duration_minutes IN NUMBER DEFAULT c_default_appointment_duration,
        p_reason_for_visit IN VARCHAR2 DEFAULT NULL,
        p_appointment_id OUT NUMBER
    ) IS
        l_validation_errors VARCHAR2(4000);
    BEGIN
        -- Validate input data
        l_validation_errors := validate_appointment_data(
            p_patient_id => p_patient_id,
            p_provider_id => p_provider_id,
            p_appointment_date => p_appointment_date,
            p_appointment_time => p_appointment_time
        );
        
        IF l_validation_errors IS NOT NULL THEN
            RAISE_APPLICATION_ERROR(-20001, 'Validation errors: ' || l_validation_errors);
        END IF;
        
        -- Check if time slot is available
        IF NOT is_time_slot_available(p_provider_id, p_appointment_date, p_appointment_time, p_duration_minutes) THEN
            RAISE_APPLICATION_ERROR(-20002, 'Time slot is not available');
        END IF;
        
        -- Insert new appointment
        INSERT INTO appointments (
            patient_id, provider_id, appointment_date, appointment_time,
            duration_minutes, appointment_type, status, reason_for_visit
        ) VALUES (
            p_patient_id, p_provider_id, p_appointment_date, p_appointment_time,
            p_duration_minutes, p_appointment_type, 'Scheduled', p_reason_for_visit
        ) RETURNING appointment_id INTO p_appointment_id;
        
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END schedule_appointment;

    PROCEDURE reschedule_appointment(
        p_appointment_id IN NUMBER,
        p_new_date IN DATE,
        p_new_time IN VARCHAR2,
        p_notes IN VARCHAR2 DEFAULT NULL
    ) IS
        l_patient_id NUMBER;
        l_provider_id NUMBER;
        l_duration NUMBER;
        l_validation_errors VARCHAR2(4000);
    BEGIN
        -- Get appointment details
        SELECT patient_id, provider_id, NVL(duration_minutes, c_default_appointment_duration)
        INTO l_patient_id, l_provider_id, l_duration
        FROM appointments
        WHERE appointment_id = p_appointment_id;
        
        -- Validate new appointment data
        l_validation_errors := validate_appointment_data(
            p_patient_id => l_patient_id,
            p_provider_id => l_provider_id,
            p_appointment_date => p_new_date,
            p_appointment_time => p_new_time
        );
        
        IF l_validation_errors IS NOT NULL THEN
            RAISE_APPLICATION_ERROR(-20001, 'Validation errors: ' || l_validation_errors);
        END IF;
        
        -- Check if new time slot is available (excluding current appointment)
        IF NOT is_time_slot_available(l_provider_id, p_new_date, p_new_time, l_duration, p_appointment_id) THEN
            RAISE_APPLICATION_ERROR(-20002, 'New time slot is not available');
        END IF;
        
        -- Update appointment
        UPDATE appointments
        SET appointment_date = p_new_date,
            appointment_time = p_new_time,
            notes = NVL(p_notes, notes),
            modified_date = SYSDATE,
            modified_by = USER
        WHERE appointment_id = p_appointment_id;
        
        COMMIT;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20003, 'Appointment not found');
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END reschedule_appointment;

    PROCEDURE cancel_appointment(
        p_appointment_id IN NUMBER,
        p_reason IN VARCHAR2 DEFAULT NULL
    ) IS
    BEGIN
        UPDATE appointments
        SET status = 'Cancelled',
            notes = CASE 
                WHEN p_reason IS NOT NULL THEN 
                    NVL(notes, '') || CASE WHEN notes IS NOT NULL THEN '; ' ELSE '' END || 
                    'Cancelled: ' || p_reason
                ELSE notes
            END,
            modified_date = SYSDATE,
            modified_by = USER
        WHERE appointment_id = p_appointment_id
          AND status NOT IN ('Completed', 'Cancelled');
        
        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20004, 'Appointment not found or cannot be cancelled');
        END IF;
        
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END cancel_appointment;

    PROCEDURE update_appointment_status(
        p_appointment_id IN NUMBER,
        p_status IN VARCHAR2,
        p_notes IN VARCHAR2 DEFAULT NULL
    ) IS
    BEGIN
        -- Validate status
        IF p_status NOT IN ('Scheduled', 'Confirmed', 'In Progress', 'Completed', 'Cancelled', 'No Show') THEN
            RAISE_APPLICATION_ERROR(-20005, 'Invalid appointment status');
        END IF;
        
        UPDATE appointments
        SET status = p_status,
            notes = NVL(p_notes, notes),
            modified_date = SYSDATE,
            modified_by = USER
        WHERE appointment_id = p_appointment_id;
        
        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20003, 'Appointment not found');
        END IF;
        
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END update_appointment_status;

    FUNCTION get_appointments_by_date(
        p_appointment_date IN DATE,
        p_provider_id IN NUMBER DEFAULT NULL
    ) RETURN t_appointment_tab PIPELINED IS
        
        l_appointment t_appointment_rec;
        
        CURSOR c_appointments IS
            SELECT a.appointment_id,
                   pkg_patient_mgmt.get_full_name(p.first_name, p.last_name) as patient_name,
                   pkg_patient_mgmt.get_full_name(pr.first_name, pr.last_name) as provider_name,
                   a.appointment_date,
                   a.appointment_time,
                   a.duration_minutes,
                   a.appointment_type,
                   a.status,
                   a.reason_for_visit
            FROM appointments a
            JOIN patients p ON a.patient_id = p.patient_id
            JOIN providers pr ON a.provider_id = pr.provider_id
            WHERE a.appointment_date = p_appointment_date
              AND (p_provider_id IS NULL OR a.provider_id = p_provider_id)
            ORDER BY a.appointment_time;
    BEGIN
        FOR rec IN c_appointments LOOP
            l_appointment.appointment_id := rec.appointment_id;
            l_appointment.patient_name := rec.patient_name;
            l_appointment.provider_name := rec.provider_name;
            l_appointment.appointment_date := rec.appointment_date;
            l_appointment.appointment_time := rec.appointment_time;
            l_appointment.duration_minutes := rec.duration_minutes;
            l_appointment.appointment_type := rec.appointment_type;
            l_appointment.status := rec.status;
            l_appointment.reason_for_visit := rec.reason_for_visit;
            
            PIPE ROW(l_appointment);
        END LOOP;
        
        RETURN;
    END get_appointments_by_date;

    FUNCTION get_patient_appointments(
        p_patient_id IN NUMBER,
        p_include_past IN VARCHAR2 DEFAULT 'N'
    ) RETURN t_appointment_tab PIPELINED IS
        
        l_appointment t_appointment_rec;
        
        CURSOR c_appointments IS
            SELECT a.appointment_id,
                   pkg_patient_mgmt.get_full_name(p.first_name, p.last_name) as patient_name,
                   pkg_patient_mgmt.get_full_name(pr.first_name, pr.last_name) as provider_name,
                   a.appointment_date,
                   a.appointment_time,
                   a.duration_minutes,
                   a.appointment_type,
                   a.status,
                   a.reason_for_visit
            FROM appointments a
            JOIN patients p ON a.patient_id = p.patient_id
            JOIN providers pr ON a.provider_id = pr.provider_id
            WHERE a.patient_id = p_patient_id
              AND (p_include_past = 'Y' OR a.appointment_date >= TRUNC(SYSDATE))
            ORDER BY a.appointment_date DESC, a.appointment_time DESC;
    BEGIN
        FOR rec IN c_appointments LOOP
            l_appointment.appointment_id := rec.appointment_id;
            l_appointment.patient_name := rec.patient_name;
            l_appointment.provider_name := rec.provider_name;
            l_appointment.appointment_date := rec.appointment_date;
            l_appointment.appointment_time := rec.appointment_time;
            l_appointment.duration_minutes := rec.duration_minutes;
            l_appointment.appointment_type := rec.appointment_type;
            l_appointment.status := rec.status;
            l_appointment.reason_for_visit := rec.reason_for_visit;
            
            PIPE ROW(l_appointment);
        END LOOP;
        
        RETURN;
    END get_patient_appointments;

    PROCEDURE send_appointment_reminder(
        p_appointment_id IN NUMBER
    ) IS
        l_patient_name VARCHAR2(101);
        l_provider_name VARCHAR2(101);
        l_appointment_date DATE;
        l_appointment_time VARCHAR2(10);
        l_patient_email VARCHAR2(100);
    BEGIN
        -- Get appointment details
        SELECT pkg_patient_mgmt.get_full_name(p.first_name, p.last_name),
               pkg_patient_mgmt.get_full_name(pr.first_name, pr.last_name),
               a.appointment_date,
               a.appointment_time,
               p.email
        INTO l_patient_name, l_provider_name, l_appointment_date, l_appointment_time, l_patient_email
        FROM appointments a
        JOIN patients p ON a.patient_id = p.patient_id
        JOIN providers pr ON a.provider_id = pr.provider_id
        WHERE a.appointment_id = p_appointment_id
          AND a.status IN ('Scheduled', 'Confirmed');
        
        -- Log reminder (in a real system, this would send email/SMS)
        INSERT INTO appointment_reminders (
            appointment_id,
            reminder_type,
            recipient_email,
            message,
            sent_date,
            status
        ) VALUES (
            p_appointment_id,
            'EMAIL',
            l_patient_email,
            'Reminder: You have an appointment with ' || l_provider_name || 
            ' on ' || TO_CHAR(l_appointment_date, 'MM/DD/YYYY') || 
            ' at ' || l_appointment_time,
            SYSDATE,
            'SENT'
        );
        
        COMMIT;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20003, 'Appointment not found or not eligible for reminder');
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END send_appointment_reminder;

END pkg_appointment_mgmt;
/
