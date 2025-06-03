-- Clinical Trials Management Package
-- Oracle APEX Healthcare System
-- Created: June 2, 2025

-- Package Specification
CREATE OR REPLACE PACKAGE pkg_clinical_trials_mgmt AS
    
    -- Custom exceptions
    trial_not_found EXCEPTION;
    participant_already_enrolled EXCEPTION;
    invalid_enrollment_criteria EXCEPTION;
    trial_not_recruiting EXCEPTION;
    milestone_conflict EXCEPTION;
    
    -- Type definitions
    TYPE t_trial_summary IS RECORD (
        trial_id NUMBER,
        trial_name VARCHAR2(200),
        status VARCHAR2(20),
        current_enrollment NUMBER,
        target_enrollment NUMBER,
        enrollment_percentage NUMBER
    );
    
    TYPE t_trial_summary_tab IS TABLE OF t_trial_summary;
    
    -- Trial management functions
    FUNCTION create_trial(
        p_trial_name VARCHAR2,
        p_trial_number VARCHAR2,
        p_description CLOB,
        p_phase VARCHAR2,
        p_start_date DATE,
        p_end_date DATE,
        p_target_enrollment NUMBER,
        p_primary_investigator_id NUMBER,
        p_sponsor VARCHAR2,
        p_study_type VARCHAR2,
        p_therapeutic_area VARCHAR2
    ) RETURN NUMBER;
    
    FUNCTION update_trial_status(
        p_trial_id NUMBER,
        p_new_status VARCHAR2,
        p_reason VARCHAR2 DEFAULT NULL
    ) RETURN BOOLEAN;
    
    FUNCTION get_trial_enrollment_status(
        p_trial_id NUMBER
    ) RETURN t_trial_summary;
    
    FUNCTION get_active_trials(
        p_investigator_id NUMBER DEFAULT NULL
    ) RETURN t_trial_summary_tab PIPELINED;
    
    -- Participant management functions
    FUNCTION enroll_participant(
        p_trial_id NUMBER,
        p_patient_id NUMBER,
        p_study_arm VARCHAR2,
        p_assigned_provider_id NUMBER,
        p_randomization_code VARCHAR2 DEFAULT NULL
    ) RETURN NUMBER;
    
    FUNCTION withdraw_participant(
        p_participant_id NUMBER,
        p_withdrawal_reason VARCHAR2,
        p_withdrawal_date DATE DEFAULT SYSDATE
    ) RETURN BOOLEAN;
    
    FUNCTION update_participant_status(
        p_participant_id NUMBER,
        p_new_status VARCHAR2,
        p_notes VARCHAR2 DEFAULT NULL
    ) RETURN BOOLEAN;
    
    FUNCTION check_enrollment_eligibility(
        p_trial_id NUMBER,
        p_patient_id NUMBER
    ) RETURN BOOLEAN;
    
    -- Visit management functions
    FUNCTION schedule_visit(
        p_participant_id NUMBER,
        p_visit_number NUMBER,
        p_visit_name VARCHAR2,
        p_visit_type VARCHAR2,
        p_scheduled_date DATE,
        p_provider_id NUMBER
    ) RETURN NUMBER;
    
    FUNCTION complete_visit(
        p_visit_id NUMBER,
        p_actual_date DATE,
        p_visit_notes CLOB,
        p_procedures_completed CLOB DEFAULT NULL
    ) RETURN BOOLEAN;
    
    FUNCTION get_upcoming_visits(
        p_provider_id NUMBER DEFAULT NULL,
        p_days_ahead NUMBER DEFAULT 30
    ) RETURN SYS_REFCURSOR;
    
    -- Adverse event management
    FUNCTION report_adverse_event(
        p_participant_id NUMBER,
        p_event_term VARCHAR2,
        p_description CLOB,
        p_severity VARCHAR2,
        p_relationship_to_study VARCHAR2,
        p_serious VARCHAR2,
        p_reporting_provider_id NUMBER
    ) RETURN NUMBER;
    
    FUNCTION update_adverse_event(
        p_adverse_event_id NUMBER,
        p_outcome VARCHAR2,
        p_resolution_date DATE DEFAULT NULL,
        p_action_taken CLOB DEFAULT NULL
    ) RETURN BOOLEAN;
    
    -- Milestone management
    FUNCTION create_milestone(
        p_trial_id NUMBER,
        p_milestone_name VARCHAR2,
        p_description CLOB,
        p_planned_date DATE,
        p_milestone_type VARCHAR2,
        p_responsible_provider_id NUMBER
    ) RETURN NUMBER;
    
    FUNCTION update_milestone_progress(
        p_milestone_id NUMBER,
        p_completion_percentage NUMBER,
        p_notes CLOB DEFAULT NULL
    ) RETURN BOOLEAN;
    
    FUNCTION complete_milestone(
        p_milestone_id NUMBER,
        p_actual_date DATE DEFAULT SYSDATE,
        p_notes CLOB DEFAULT NULL
    ) RETURN BOOLEAN;
    
    -- Reporting functions
    FUNCTION get_trial_statistics(
        p_trial_id NUMBER
    ) RETURN SYS_REFCURSOR;
    
    FUNCTION get_enrollment_report(
        p_start_date DATE DEFAULT TRUNC(SYSDATE, 'MM'),
        p_end_date DATE DEFAULT SYSDATE
    ) RETURN SYS_REFCURSOR;
    
    FUNCTION get_adverse_events_summary(
        p_trial_id NUMBER DEFAULT NULL,
        p_start_date DATE DEFAULT TRUNC(SYSDATE, 'MM'),
        p_end_date DATE DEFAULT SYSDATE
    ) RETURN SYS_REFCURSOR;
    
END pkg_clinical_trials_mgmt;
/

-- Package Body
CREATE OR REPLACE PACKAGE BODY pkg_clinical_trials_mgmt AS
    
    -- Create new clinical trial
    FUNCTION create_trial(
        p_trial_name VARCHAR2,
        p_trial_number VARCHAR2,
        p_description CLOB,
        p_phase VARCHAR2,
        p_start_date DATE,
        p_end_date DATE,
        p_target_enrollment NUMBER,
        p_primary_investigator_id NUMBER,
        p_sponsor VARCHAR2,
        p_study_type VARCHAR2,
        p_therapeutic_area VARCHAR2
    ) RETURN NUMBER IS
        v_trial_id NUMBER;
    BEGIN
        -- Validate input parameters
        IF p_trial_name IS NULL OR p_trial_number IS NULL THEN
            RAISE_APPLICATION_ERROR(-20001, 'Trial name and number are required');
        END IF;
        
        IF p_end_date < p_start_date THEN
            RAISE_APPLICATION_ERROR(-20002, 'End date cannot be before start date');
        END IF;
        
        -- Insert new trial
        INSERT INTO clinical_trials (
            trial_name, trial_number, description, phase, start_date, end_date,
            target_enrollment, primary_investigator_id, sponsor, study_type, therapeutic_area
        ) VALUES (
            p_trial_name, p_trial_number, p_description, p_phase, p_start_date, p_end_date,
            p_target_enrollment, p_primary_investigator_id, p_sponsor, p_study_type, p_therapeutic_area
        ) RETURNING trial_id INTO v_trial_id;
        
        COMMIT;
        RETURN v_trial_id;
        
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            RAISE_APPLICATION_ERROR(-20003, 'Trial number already exists');
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END create_trial;
    
    -- Update trial status
    FUNCTION update_trial_status(
        p_trial_id NUMBER,
        p_new_status VARCHAR2,
        p_reason VARCHAR2 DEFAULT NULL
    ) RETURN BOOLEAN IS
        v_count NUMBER;
    BEGIN
        -- Check if trial exists
        SELECT COUNT(*) INTO v_count 
        FROM clinical_trials 
        WHERE trial_id = p_trial_id;
        
        IF v_count = 0 THEN
            RAISE trial_not_found;
        END IF;
        
        -- Update status
        UPDATE clinical_trials 
        SET status = p_new_status,
            modified_date = SYSDATE,
            modified_by = USER
        WHERE trial_id = p_trial_id;
        
        COMMIT;
        RETURN TRUE;
        
    EXCEPTION
        WHEN trial_not_found THEN
            RAISE_APPLICATION_ERROR(-20004, 'Trial not found');
        WHEN OTHERS THEN
            ROLLBACK;
            RETURN FALSE;
    END update_trial_status;
    
    -- Get trial enrollment status
    FUNCTION get_trial_enrollment_status(
        p_trial_id NUMBER
    ) RETURN t_trial_summary IS
        v_result t_trial_summary;
    BEGIN
        SELECT trial_id, trial_name, status, current_enrollment, target_enrollment,
               ROUND((current_enrollment / NULLIF(target_enrollment, 0)) * 100, 2)
        INTO v_result.trial_id, v_result.trial_name, v_result.status,
             v_result.current_enrollment, v_result.target_enrollment, v_result.enrollment_percentage
        FROM clinical_trials
        WHERE trial_id = p_trial_id;
        
        RETURN v_result;
        
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE trial_not_found;
    END get_trial_enrollment_status;
    
    -- Get active trials
    FUNCTION get_active_trials(
        p_investigator_id NUMBER DEFAULT NULL
    ) RETURN t_trial_summary_tab PIPELINED IS
        CURSOR c_trials IS
            SELECT trial_id, trial_name, status, current_enrollment, target_enrollment,
                   ROUND((current_enrollment / NULLIF(target_enrollment, 0)) * 100, 2) as enrollment_percentage
            FROM clinical_trials
            WHERE status IN ('Active', 'Recruiting')
            AND (p_investigator_id IS NULL OR primary_investigator_id = p_investigator_id)
            ORDER BY trial_name;
        
        v_trial t_trial_summary;
    BEGIN
        FOR rec IN c_trials LOOP
            v_trial.trial_id := rec.trial_id;
            v_trial.trial_name := rec.trial_name;
            v_trial.status := rec.status;
            v_trial.current_enrollment := rec.current_enrollment;
            v_trial.target_enrollment := rec.target_enrollment;
            v_trial.enrollment_percentage := rec.enrollment_percentage;
            
            PIPE ROW(v_trial);
        END LOOP;
        
        RETURN;
    END get_active_trials;
    
    -- Enroll participant in trial
    FUNCTION enroll_participant(
        p_trial_id NUMBER,
        p_patient_id NUMBER,
        p_study_arm VARCHAR2,
        p_assigned_provider_id NUMBER,
        p_randomization_code VARCHAR2 DEFAULT NULL
    ) RETURN NUMBER IS
        v_participant_id NUMBER;
        v_trial_status VARCHAR2(20);
        v_current_enrollment NUMBER;
        v_target_enrollment NUMBER;
    BEGIN
        -- Check if trial is recruiting
        SELECT status, current_enrollment, target_enrollment
        INTO v_trial_status, v_current_enrollment, v_target_enrollment
        FROM clinical_trials
        WHERE trial_id = p_trial_id;
        
        IF v_trial_status NOT IN ('Active', 'Recruiting') THEN
            RAISE trial_not_recruiting;
        END IF;
        
        -- Check if enrollment limit reached
        IF v_current_enrollment >= v_target_enrollment THEN
            RAISE_APPLICATION_ERROR(-20005, 'Trial enrollment limit reached');
        END IF;
        
        -- Check eligibility
        IF NOT check_enrollment_eligibility(p_trial_id, p_patient_id) THEN
            RAISE invalid_enrollment_criteria;
        END IF;
        
        -- Enroll participant
        INSERT INTO trial_participants (
            trial_id, patient_id, study_arm, assigned_provider_id, randomization_code
        ) VALUES (
            p_trial_id, p_patient_id, p_study_arm, p_assigned_provider_id, p_randomization_code
        ) RETURNING participant_id INTO v_participant_id;
        
        -- Update trial enrollment count
        UPDATE clinical_trials 
        SET current_enrollment = current_enrollment + 1
        WHERE trial_id = p_trial_id;
        
        COMMIT;
        RETURN v_participant_id;
        
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            RAISE participant_already_enrolled;
        WHEN NO_DATA_FOUND THEN
            RAISE trial_not_found;
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END enroll_participant;
    
    -- Check enrollment eligibility (simplified)
    FUNCTION check_enrollment_eligibility(
        p_trial_id NUMBER,
        p_patient_id NUMBER
    ) RETURN BOOLEAN IS
        v_patient_age NUMBER;
        v_count NUMBER;
    BEGIN
        -- Check if patient is already enrolled
        SELECT COUNT(*) INTO v_count
        FROM trial_participants
        WHERE trial_id = p_trial_id AND patient_id = p_patient_id;
        
        IF v_count > 0 THEN
            RETURN FALSE;
        END IF;
        
        -- Additional eligibility checks would go here
        -- For now, return TRUE if not already enrolled
        RETURN TRUE;
        
    END check_enrollment_eligibility;
    
    -- Withdraw participant
    FUNCTION withdraw_participant(
        p_participant_id NUMBER,
        p_withdrawal_reason VARCHAR2,
        p_withdrawal_date DATE DEFAULT SYSDATE
    ) RETURN BOOLEAN IS
        v_trial_id NUMBER;
    BEGIN
        -- Get trial ID for enrollment count update
        SELECT trial_id INTO v_trial_id
        FROM trial_participants
        WHERE participant_id = p_participant_id;
        
        -- Update participant status
        UPDATE trial_participants
        SET status = 'Withdrawn',
            withdrawal_reason = p_withdrawal_reason,
            withdrawal_date = p_withdrawal_date,
            modified_date = SYSDATE,
            modified_by = USER
        WHERE participant_id = p_participant_id;
        
        -- Update trial enrollment count
        UPDATE clinical_trials
        SET current_enrollment = current_enrollment - 1
        WHERE trial_id = v_trial_id;
        
        COMMIT;
        RETURN TRUE;
        
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            ROLLBACK;
            RETURN FALSE;
    END withdraw_participant;
    
    -- Update participant status
    FUNCTION update_participant_status(
        p_participant_id NUMBER,
        p_new_status VARCHAR2,
        p_notes VARCHAR2 DEFAULT NULL
    ) RETURN BOOLEAN IS
    BEGIN
        UPDATE trial_participants
        SET status = p_new_status,
            notes = COALESCE(p_notes, notes),
            modified_date = SYSDATE,
            modified_by = USER
        WHERE participant_id = p_participant_id;
        
        IF SQL%ROWCOUNT = 0 THEN
            RETURN FALSE;
        END IF;
        
        COMMIT;
        RETURN TRUE;
        
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RETURN FALSE;
    END update_participant_status;
    
    -- Schedule visit
    FUNCTION schedule_visit(
        p_participant_id NUMBER,
        p_visit_number NUMBER,
        p_visit_name VARCHAR2,
        p_visit_type VARCHAR2,
        p_scheduled_date DATE,
        p_provider_id NUMBER
    ) RETURN NUMBER IS
        v_visit_id NUMBER;
        v_trial_id NUMBER;
        v_window_start DATE;
        v_window_end DATE;
    BEGIN
        -- Get trial ID
        SELECT trial_id INTO v_trial_id
        FROM trial_participants
        WHERE participant_id = p_participant_id;
        
        -- Calculate visit window (±3 days for most visits)
        v_window_start := p_scheduled_date - 3;
        v_window_end := p_scheduled_date + 3;
        
        INSERT INTO trial_visits (
            participant_id, trial_id, visit_number, visit_name, visit_type,
            scheduled_date, visit_window_start, visit_window_end, provider_id
        ) VALUES (
            p_participant_id, v_trial_id, p_visit_number, p_visit_name, p_visit_type,
            p_scheduled_date, v_window_start, v_window_end, p_provider_id
        ) RETURNING visit_id INTO v_visit_id;
        
        COMMIT;
        RETURN v_visit_id;
        
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END schedule_visit;
    
    -- Complete visit
    FUNCTION complete_visit(
        p_visit_id NUMBER,
        p_actual_date DATE,
        p_visit_notes CLOB,
        p_procedures_completed CLOB DEFAULT NULL
    ) RETURN BOOLEAN IS
    BEGIN
        UPDATE trial_visits
        SET status = 'Completed',
            actual_date = p_actual_date,
            visit_notes = p_visit_notes,
            procedures_completed = COALESCE(p_procedures_completed, procedures_completed),
            modified_date = SYSDATE,
            modified_by = USER
        WHERE visit_id = p_visit_id;
        
        IF SQL%ROWCOUNT = 0 THEN
            RETURN FALSE;
        END IF;
        
        COMMIT;
        RETURN TRUE;
        
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RETURN FALSE;
    END complete_visit;
    
    -- Get upcoming visits
    FUNCTION get_upcoming_visits(
        p_provider_id NUMBER DEFAULT NULL,
        p_days_ahead NUMBER DEFAULT 30
    ) RETURN SYS_REFCURSOR IS
        v_cursor SYS_REFCURSOR;
    BEGIN
        OPEN v_cursor FOR
            SELECT tv.visit_id, tv.participant_id, tv.trial_id, tv.visit_name, tv.visit_type,
                   tv.scheduled_date, tv.visit_window_start, tv.visit_window_end,
                   ct.trial_name, p.first_name || ' ' || p.last_name as patient_name,
                   pr.first_name || ' ' || pr.last_name as provider_name
            FROM trial_visits tv
            JOIN trial_participants tp ON tv.participant_id = tp.participant_id
            JOIN clinical_trials ct ON tv.trial_id = ct.trial_id
            JOIN patients p ON tp.patient_id = p.patient_id
            LEFT JOIN providers pr ON tv.provider_id = pr.provider_id
            WHERE tv.status = 'Scheduled'
            AND tv.scheduled_date BETWEEN SYSDATE AND SYSDATE + p_days_ahead
            AND (p_provider_id IS NULL OR tv.provider_id = p_provider_id)
            ORDER BY tv.scheduled_date;
        
        RETURN v_cursor;
    END get_upcoming_visits;
    
    -- Report adverse event
    FUNCTION report_adverse_event(
        p_participant_id NUMBER,
        p_event_term VARCHAR2,
        p_description CLOB,
        p_severity VARCHAR2,
        p_relationship_to_study VARCHAR2,
        p_serious VARCHAR2,
        p_reporting_provider_id NUMBER
    ) RETURN NUMBER IS
        v_ae_id NUMBER;
        v_trial_id NUMBER;
    BEGIN
        -- Get trial ID
        SELECT trial_id INTO v_trial_id
        FROM trial_participants
        WHERE participant_id = p_participant_id;
        
        INSERT INTO adverse_events (
            participant_id, trial_id, event_date, event_term, description,
            severity, relationship_to_study, serious, reporting_provider_id
        ) VALUES (
            p_participant_id, v_trial_id, SYSDATE, p_event_term, p_description,
            p_severity, p_relationship_to_study, p_serious, p_reporting_provider_id
        ) RETURNING adverse_event_id INTO v_ae_id;
        
        COMMIT;
        RETURN v_ae_id;
        
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END report_adverse_event;
    
    -- Update adverse event
    FUNCTION update_adverse_event(
        p_adverse_event_id NUMBER,
        p_outcome VARCHAR2,
        p_resolution_date DATE DEFAULT NULL,
        p_action_taken CLOB DEFAULT NULL
    ) RETURN BOOLEAN IS
    BEGIN
        UPDATE adverse_events
        SET outcome = p_outcome,
            resolution_date = p_resolution_date,
            action_taken = COALESCE(p_action_taken, action_taken),
            modified_date = SYSDATE,
            modified_by = USER
        WHERE adverse_event_id = p_adverse_event_id;
        
        IF SQL%ROWCOUNT = 0 THEN
            RETURN FALSE;
        END IF;
        
        COMMIT;
        RETURN TRUE;
        
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RETURN FALSE;
    END update_adverse_event;
    
    -- Create milestone
    FUNCTION create_milestone(
        p_trial_id NUMBER,
        p_milestone_name VARCHAR2,
        p_description CLOB,
        p_planned_date DATE,
        p_milestone_type VARCHAR2,
        p_responsible_provider_id NUMBER
    ) RETURN NUMBER IS
        v_milestone_id NUMBER;
    BEGIN
        INSERT INTO trial_milestones (
            trial_id, milestone_name, description, planned_date,
            milestone_type, responsible_provider_id
        ) VALUES (
            p_trial_id, p_milestone_name, p_description, p_planned_date,
            p_milestone_type, p_responsible_provider_id
        ) RETURNING milestone_id INTO v_milestone_id;
        
        COMMIT;
        RETURN v_milestone_id;
        
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END create_milestone;
    
    -- Update milestone progress
    FUNCTION update_milestone_progress(
        p_milestone_id NUMBER,
        p_completion_percentage NUMBER,
        p_notes CLOB DEFAULT NULL
    ) RETURN BOOLEAN IS
    BEGIN
        UPDATE trial_milestones
        SET completion_percentage = p_completion_percentage,
            notes = COALESCE(p_notes, notes),
            status = CASE 
                        WHEN p_completion_percentage = 100 THEN 'Completed'
                        WHEN p_completion_percentage > 0 THEN 'In Progress'
                        ELSE status
                     END,
            modified_date = SYSDATE,
            modified_by = USER
        WHERE milestone_id = p_milestone_id;
        
        IF SQL%ROWCOUNT = 0 THEN
            RETURN FALSE;
        END IF;
        
        COMMIT;
        RETURN TRUE;
        
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RETURN FALSE;
    END update_milestone_progress;
    
    -- Complete milestone
    FUNCTION complete_milestone(
        p_milestone_id NUMBER,
        p_actual_date DATE DEFAULT SYSDATE,
        p_notes CLOB DEFAULT NULL
    ) RETURN BOOLEAN IS
    BEGIN
        UPDATE trial_milestones
        SET status = 'Completed',
            actual_date = p_actual_date,
            completion_percentage = 100,
            notes = COALESCE(p_notes, notes),
            modified_date = SYSDATE,
            modified_by = USER
        WHERE milestone_id = p_milestone_id;
        
        IF SQL%ROWCOUNT = 0 THEN
            RETURN FALSE;
        END IF;
        
        COMMIT;
        RETURN TRUE;
        
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RETURN FALSE;
    END complete_milestone;
    
    -- Get trial statistics
    FUNCTION get_trial_statistics(
        p_trial_id NUMBER
    ) RETURN SYS_REFCURSOR IS
        v_cursor SYS_REFCURSOR;
    BEGIN
        OPEN v_cursor FOR
            SELECT 
                ct.trial_name,
                ct.status,
                ct.phase,
                ct.current_enrollment,
                ct.target_enrollment,
                ROUND((ct.current_enrollment / NULLIF(ct.target_enrollment, 0)) * 100, 1) as enrollment_percentage,
                COUNT(DISTINCT tp.participant_id) as total_participants,
                COUNT(DISTINCT CASE WHEN tp.status = 'Active' THEN tp.participant_id END) as active_participants,
                COUNT(DISTINCT tv.visit_id) as total_visits,
                COUNT(DISTINCT CASE WHEN tv.status = 'Completed' THEN tv.visit_id END) as completed_visits,
                COUNT(DISTINCT ae.adverse_event_id) as total_adverse_events,
                COUNT(DISTINCT CASE WHEN ae.serious = 'Y' THEN ae.adverse_event_id END) as serious_adverse_events
            FROM clinical_trials ct
            LEFT JOIN trial_participants tp ON ct.trial_id = tp.trial_id
            LEFT JOIN trial_visits tv ON tp.participant_id = tv.participant_id
            LEFT JOIN adverse_events ae ON tp.participant_id = ae.participant_id
            WHERE ct.trial_id = p_trial_id
            GROUP BY ct.trial_name, ct.status, ct.phase, ct.current_enrollment, ct.target_enrollment;
        
        RETURN v_cursor;
    END get_trial_statistics;
    
    -- Get enrollment report
    FUNCTION get_enrollment_report(
        p_start_date DATE DEFAULT TRUNC(SYSDATE, 'MM'),
        p_end_date DATE DEFAULT SYSDATE
    ) RETURN SYS_REFCURSOR IS
        v_cursor SYS_REFCURSOR;
    BEGIN
        OPEN v_cursor FOR
            SELECT 
                ct.trial_name,
                ct.trial_number,
                COUNT(tp.participant_id) as enrolled_count,
                TO_CHAR(tp.enrollment_date, 'YYYY-MM') as enrollment_month
            FROM clinical_trials ct
            LEFT JOIN trial_participants tp ON ct.trial_id = tp.trial_id
                AND tp.enrollment_date BETWEEN p_start_date AND p_end_date
            GROUP BY ct.trial_name, ct.trial_number, TO_CHAR(tp.enrollment_date, 'YYYY-MM')
            ORDER BY ct.trial_name, enrollment_month;
        
        RETURN v_cursor;
    END get_enrollment_report;
    
    -- Get adverse events summary
    FUNCTION get_adverse_events_summary(
        p_trial_id NUMBER DEFAULT NULL,
        p_start_date DATE DEFAULT TRUNC(SYSDATE, 'MM'),
        p_end_date DATE DEFAULT SYSDATE
    ) RETURN SYS_REFCURSOR IS
        v_cursor SYS_REFCURSOR;
    BEGIN
        OPEN v_cursor FOR
            SELECT 
                ct.trial_name,
                ae.severity,
                ae.serious,
                COUNT(*) as event_count,
                COUNT(DISTINCT ae.participant_id) as affected_participants
            FROM adverse_events ae
            JOIN trial_participants tp ON ae.participant_id = tp.participant_id
            JOIN clinical_trials ct ON ae.trial_id = ct.trial_id
            WHERE ae.event_date BETWEEN p_start_date AND p_end_date
            AND (p_trial_id IS NULL OR ae.trial_id = p_trial_id)
            GROUP BY ct.trial_name, ae.severity, ae.serious
            ORDER BY ct.trial_name, ae.severity;
        
        RETURN v_cursor;
    END get_adverse_events_summary;
    
END pkg_clinical_trials_mgmt;
/
