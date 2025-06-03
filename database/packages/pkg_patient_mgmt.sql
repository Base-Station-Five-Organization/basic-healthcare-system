-- Healthcare System PL/SQL Package
-- Patient Management Functions and Procedures

CREATE OR REPLACE PACKAGE pkg_patient_mgmt AS
    -- Public type declarations
    TYPE t_patient_rec IS RECORD (
        patient_id      NUMBER,
        full_name       VARCHAR2(101),
        age             NUMBER,
        phone           VARCHAR2(20),
        email           VARCHAR2(100),
        next_appointment DATE
    );
    
    TYPE t_patient_tab IS TABLE OF t_patient_rec;
    
    -- Public procedure and function declarations
    FUNCTION get_patient_age(p_patient_id IN NUMBER) RETURN NUMBER;
    
    FUNCTION get_full_name(p_first_name IN VARCHAR2, p_last_name IN VARCHAR2) RETURN VARCHAR2;
    
    FUNCTION validate_patient_data(
        p_first_name IN VARCHAR2,
        p_last_name IN VARCHAR2,
        p_date_of_birth IN DATE,
        p_phone IN VARCHAR2,
        p_email IN VARCHAR2
    ) RETURN VARCHAR2;
    
    PROCEDURE create_patient(
        p_first_name IN VARCHAR2,
        p_last_name IN VARCHAR2,
        p_date_of_birth IN DATE,
        p_gender IN VARCHAR2,
        p_phone IN VARCHAR2,
        p_email IN VARCHAR2,
        p_address IN VARCHAR2 DEFAULT NULL,
        p_city IN VARCHAR2 DEFAULT NULL,
        p_state IN VARCHAR2 DEFAULT NULL,
        p_zip_code IN VARCHAR2 DEFAULT NULL,
        p_patient_id OUT NUMBER
    );
    
    PROCEDURE update_patient(
        p_patient_id IN NUMBER,
        p_first_name IN VARCHAR2 DEFAULT NULL,
        p_last_name IN VARCHAR2 DEFAULT NULL,
        p_phone IN VARCHAR2 DEFAULT NULL,
        p_email IN VARCHAR2 DEFAULT NULL,
        p_address IN VARCHAR2 DEFAULT NULL,
        p_city IN VARCHAR2 DEFAULT NULL,
        p_state IN VARCHAR2 DEFAULT NULL,
        p_zip_code IN VARCHAR2 DEFAULT NULL
    );
    
    FUNCTION search_patients(
        p_search_term IN VARCHAR2,
        p_max_rows IN NUMBER DEFAULT 50
    ) RETURN t_patient_tab PIPELINED;
    
    FUNCTION get_patient_summary(p_patient_id IN NUMBER) RETURN t_patient_rec;
    
END pkg_patient_mgmt;
/

CREATE OR REPLACE PACKAGE BODY pkg_patient_mgmt AS

    FUNCTION get_patient_age(p_patient_id IN NUMBER) RETURN NUMBER IS
        l_age NUMBER;
    BEGIN
        SELECT TRUNC((SYSDATE - date_of_birth) / 365.25)
        INTO l_age
        FROM patients
        WHERE patient_id = p_patient_id;
        
        RETURN l_age;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
        WHEN OTHERS THEN
            RAISE;
    END get_patient_age;

    FUNCTION get_full_name(p_first_name IN VARCHAR2, p_last_name IN VARCHAR2) RETURN VARCHAR2 IS
    BEGIN
        RETURN TRIM(p_first_name || ' ' || p_last_name);
    END get_full_name;

    FUNCTION validate_patient_data(
        p_first_name IN VARCHAR2,
        p_last_name IN VARCHAR2,
        p_date_of_birth IN DATE,
        p_phone IN VARCHAR2,
        p_email IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_errors VARCHAR2(4000);
    BEGIN
        -- Validate required fields
        IF p_first_name IS NULL OR LENGTH(TRIM(p_first_name)) = 0 THEN
            l_errors := l_errors || 'First name is required. ';
        END IF;
        
        IF p_last_name IS NULL OR LENGTH(TRIM(p_last_name)) = 0 THEN
            l_errors := l_errors || 'Last name is required. ';
        END IF;
        
        IF p_date_of_birth IS NULL THEN
            l_errors := l_errors || 'Date of birth is required. ';
        ELSIF p_date_of_birth > SYSDATE THEN
            l_errors := l_errors || 'Date of birth cannot be in the future. ';
        ELSIF TRUNC((SYSDATE - p_date_of_birth) / 365.25) > 150 THEN
            l_errors := l_errors || 'Invalid date of birth - age cannot exceed 150 years. ';
        END IF;
        
        -- Validate phone format (basic validation)
        IF p_phone IS NOT NULL AND NOT REGEXP_LIKE(p_phone, '^[0-9\-\(\) ]+$') THEN
            l_errors := l_errors || 'Invalid phone number format. ';
        END IF;
        
        -- Validate email format
        IF p_email IS NOT NULL AND NOT REGEXP_LIKE(p_email, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$') THEN
            l_errors := l_errors || 'Invalid email format. ';
        END IF;
        
        RETURN TRIM(l_errors);
    END validate_patient_data;

    PROCEDURE create_patient(
        p_first_name IN VARCHAR2,
        p_last_name IN VARCHAR2,
        p_date_of_birth IN DATE,
        p_gender IN VARCHAR2,
        p_phone IN VARCHAR2,
        p_email IN VARCHAR2,
        p_address IN VARCHAR2 DEFAULT NULL,
        p_city IN VARCHAR2 DEFAULT NULL,
        p_state IN VARCHAR2 DEFAULT NULL,
        p_zip_code IN VARCHAR2 DEFAULT NULL,
        p_patient_id OUT NUMBER
    ) IS
        l_validation_errors VARCHAR2(4000);
    BEGIN
        -- Validate input data
        l_validation_errors := validate_patient_data(
            p_first_name => p_first_name,
            p_last_name => p_last_name,
            p_date_of_birth => p_date_of_birth,
            p_phone => p_phone,
            p_email => p_email
        );
        
        IF l_validation_errors IS NOT NULL THEN
            RAISE_APPLICATION_ERROR(-20001, 'Validation errors: ' || l_validation_errors);
        END IF;
        
        -- Insert new patient
        INSERT INTO patients (
            first_name, last_name, date_of_birth, gender,
            phone, email, address, city, state, zip_code
        ) VALUES (
            TRIM(p_first_name), TRIM(p_last_name), p_date_of_birth, p_gender,
            p_phone, p_email, p_address, p_city, p_state, p_zip_code
        ) RETURNING patient_id INTO p_patient_id;
        
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END create_patient;

    PROCEDURE update_patient(
        p_patient_id IN NUMBER,
        p_first_name IN VARCHAR2 DEFAULT NULL,
        p_last_name IN VARCHAR2 DEFAULT NULL,
        p_phone IN VARCHAR2 DEFAULT NULL,
        p_email IN VARCHAR2 DEFAULT NULL,
        p_address IN VARCHAR2 DEFAULT NULL,
        p_city IN VARCHAR2 DEFAULT NULL,
        p_state IN VARCHAR2 DEFAULT NULL,
        p_zip_code IN VARCHAR2 DEFAULT NULL
    ) IS
        l_count NUMBER;
    BEGIN
        -- Check if patient exists
        SELECT COUNT(*)
        INTO l_count
        FROM patients
        WHERE patient_id = p_patient_id;
        
        IF l_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20002, 'Patient not found with ID: ' || p_patient_id);
        END IF;
        
        -- Update patient information
        UPDATE patients
        SET first_name = NVL(p_first_name, first_name),
            last_name = NVL(p_last_name, last_name),
            phone = NVL(p_phone, phone),
            email = NVL(p_email, email),
            address = NVL(p_address, address),
            city = NVL(p_city, city),
            state = NVL(p_state, state),
            zip_code = NVL(p_zip_code, zip_code),
            modified_date = SYSDATE,
            modified_by = USER
        WHERE patient_id = p_patient_id;
        
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END update_patient;

    FUNCTION search_patients(
        p_search_term IN VARCHAR2,
        p_max_rows IN NUMBER DEFAULT 50
    ) RETURN t_patient_tab PIPELINED IS
        
        l_patient t_patient_rec;
        l_search_term VARCHAR2(200) := '%' || UPPER(TRIM(p_search_term)) || '%';
        
        CURSOR c_patients IS
            SELECT p.patient_id,
                   get_full_name(p.first_name, p.last_name) as full_name,
                   get_patient_age(p.patient_id) as age,
                   p.phone,
                   p.email,
                   (SELECT MIN(a.appointment_date)
                    FROM appointments a
                    WHERE a.patient_id = p.patient_id
                      AND a.appointment_date >= SYSDATE
                      AND a.status IN ('Scheduled', 'Confirmed')) as next_appointment
            FROM patients p
            WHERE p.is_active = 'Y'
              AND (UPPER(p.first_name || ' ' || p.last_name) LIKE l_search_term
                   OR UPPER(p.phone) LIKE l_search_term
                   OR UPPER(p.email) LIKE l_search_term)
            ORDER BY p.last_name, p.first_name
            FETCH FIRST p_max_rows ROWS ONLY;
    BEGIN
        FOR rec IN c_patients LOOP
            l_patient.patient_id := rec.patient_id;
            l_patient.full_name := rec.full_name;
            l_patient.age := rec.age;
            l_patient.phone := rec.phone;
            l_patient.email := rec.email;
            l_patient.next_appointment := rec.next_appointment;
            
            PIPE ROW(l_patient);
        END LOOP;
        
        RETURN;
    END search_patients;

    FUNCTION get_patient_summary(p_patient_id IN NUMBER) RETURN t_patient_rec IS
        l_patient t_patient_rec;
    BEGIN
        SELECT patient_id,
               get_full_name(first_name, last_name),
               get_patient_age(patient_id),
               phone,
               email,
               NULL
        INTO l_patient.patient_id,
             l_patient.full_name,
             l_patient.age,
             l_patient.phone,
             l_patient.email,
             l_patient.next_appointment
        FROM patients
        WHERE patient_id = p_patient_id;
        
        -- Get next appointment
        BEGIN
            SELECT MIN(appointment_date)
            INTO l_patient.next_appointment
            FROM appointments
            WHERE patient_id = p_patient_id
              AND appointment_date >= SYSDATE
              AND status IN ('Scheduled', 'Confirmed');
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                l_patient.next_appointment := NULL;
        END;
        
        RETURN l_patient;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20003, 'Patient not found with ID: ' || p_patient_id);
    END get_patient_summary;

END pkg_patient_mgmt;
/
