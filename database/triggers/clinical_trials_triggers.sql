-- Clinical Trials Triggers for Healthcare System
-- Oracle APEX Application
-- Created: June 2, 2025

-- Trigger for clinical trials audit trail
CREATE OR REPLACE TRIGGER trg_clinical_trials_audit
    BEFORE UPDATE ON clinical_trials
    FOR EACH ROW
BEGIN
    -- Update modification tracking
    :NEW.modified_date := SYSDATE;
    :NEW.modified_by := NVL(SYS_CONTEXT('APEX$SESSION', 'APP_USER'), USER);
    
    -- Log status changes
    IF :OLD.status != :NEW.status THEN
        INSERT INTO audit_log (
            table_name, operation_type, record_id, 
            old_values, new_values, changed_by, changed_date
        ) VALUES (
            'CLINICAL_TRIALS', 'STATUS_CHANGE', :NEW.trial_id,
            'Status: ' || :OLD.status,
            'Status: ' || :NEW.status,
            :NEW.modified_by, :NEW.modified_date
        );
    END IF;
END;
/

-- Trigger for trial participants audit trail
CREATE OR REPLACE TRIGGER trg_trial_participants_audit
    BEFORE INSERT OR UPDATE ON trial_participants
    FOR EACH ROW
BEGIN
    IF INSERTING THEN
        :NEW.created_date := SYSDATE;
        :NEW.created_by := NVL(SYS_CONTEXT('APEX$SESSION', 'APP_USER'), USER);
        :NEW.modified_date := SYSDATE;
        :NEW.modified_by := :NEW.created_by;
    ELSIF UPDATING THEN
        :NEW.modified_date := SYSDATE;
        :NEW.modified_by := NVL(SYS_CONTEXT('APEX$SESSION', 'APP_USER'), USER);
        
        -- Log status changes
        IF :OLD.status != :NEW.status THEN
            INSERT INTO audit_log (
                table_name, operation_type, record_id,
                old_values, new_values, changed_by, changed_date
            ) VALUES (
                'TRIAL_PARTICIPANTS', 'STATUS_CHANGE', :NEW.participant_id,
                'Status: ' || :OLD.status,
                'Status: ' || :NEW.status,
                :NEW.modified_by, :NEW.modified_date
            );
        END IF;
    END IF;
END;
/

-- Trigger to update trial enrollment count
CREATE OR REPLACE TRIGGER trg_update_trial_enrollment
    AFTER INSERT OR UPDATE OR DELETE ON trial_participants
    FOR EACH ROW
DECLARE
    v_trial_id NUMBER;
    v_enrollment_count NUMBER;
BEGIN
    -- Determine which trial to update
    IF INSERTING OR UPDATING THEN
        v_trial_id := :NEW.trial_id;
    ELSE -- DELETING
        v_trial_id := :OLD.trial_id;
    END IF;
    
    -- Calculate current enrollment for active participants
    SELECT COUNT(*)
    INTO v_enrollment_count
    FROM trial_participants
    WHERE trial_id = v_trial_id
    AND status IN ('Screening', 'Active');
    
    -- Update trial enrollment count
    UPDATE clinical_trials
    SET current_enrollment = v_enrollment_count,
        modified_date = SYSDATE,
        modified_by = NVL(SYS_CONTEXT('APEX$SESSION', 'APP_USER'), USER)
    WHERE trial_id = v_trial_id;
END;
/

-- Trigger for adverse events audit trail and validation
CREATE OR REPLACE TRIGGER trg_adverse_events_audit
    BEFORE INSERT OR UPDATE ON adverse_events
    FOR EACH ROW
BEGIN
    IF INSERTING THEN
        :NEW.created_date := SYSDATE;
        :NEW.created_by := NVL(SYS_CONTEXT('APEX$SESSION', 'APP_USER'), USER);
        :NEW.modified_date := SYSDATE;
        :NEW.modified_by := :NEW.created_by;
        
        -- Set reported date if not provided
        IF :NEW.reported_date IS NULL THEN
            :NEW.reported_date := SYSDATE;
        END IF;
        
        -- Auto-set regulatory reporting flag for serious events
        IF :NEW.serious = 'Y' THEN
            :NEW.follow_up_required := 'Y';
        END IF;
        
    ELSIF UPDATING THEN
        :NEW.modified_date := SYSDATE;
        :NEW.modified_by := NVL(SYS_CONTEXT('APEX$SESSION', 'APP_USER'), USER);
        
        -- Log severity changes
        IF :OLD.severity != :NEW.severity THEN
            INSERT INTO audit_log (
                table_name, operation_type, record_id,
                old_values, new_values, changed_by, changed_date
            ) VALUES (
                'ADVERSE_EVENTS', 'SEVERITY_CHANGE', :NEW.adverse_event_id,
                'Severity: ' || :OLD.severity || ', Serious: ' || :OLD.serious,
                'Severity: ' || :NEW.severity || ', Serious: ' || :NEW.serious,
                :NEW.modified_by, :NEW.modified_date
            );
        END IF;
    END IF;
    
    -- Validation: Event date cannot be in the future
    IF :NEW.event_date > SYSDATE THEN
        RAISE_APPLICATION_ERROR(-20100, 'Adverse event date cannot be in the future');
    END IF;
    
    -- Validation: Resolution date must be after event date
    IF :NEW.resolution_date IS NOT NULL AND :NEW.resolution_date < :NEW.event_date THEN
        RAISE_APPLICATION_ERROR(-20101, 'Resolution date cannot be before event date');
    END IF;
    
END;
/

-- Trigger for trial visits audit trail
CREATE OR REPLACE TRIGGER trg_trial_visits_audit
    BEFORE INSERT OR UPDATE ON trial_visits
    FOR EACH ROW
BEGIN
    IF INSERTING THEN
        :NEW.created_date := SYSDATE;
        :NEW.created_by := NVL(SYS_CONTEXT('APEX$SESSION', 'APP_USER'), USER);
        :NEW.modified_date := SYSDATE;
        :NEW.modified_by := :NEW.created_by;
    ELSIF UPDATING THEN
        :NEW.modified_date := SYSDATE;
        :NEW.modified_by := NVL(SYS_CONTEXT('APEX$SESSION', 'APP_USER'), USER);
        
        -- Log visit completion
        IF :OLD.status != :NEW.status AND :NEW.status = 'Completed' THEN
            INSERT INTO audit_log (
                table_name, operation_type, record_id,
                old_values, new_values, changed_by, changed_date
            ) VALUES (
                'TRIAL_VISITS', 'VISIT_COMPLETED', :NEW.visit_id,
                'Scheduled: ' || TO_CHAR(:NEW.scheduled_date, 'DD-MON-YYYY'),
                'Completed: ' || TO_CHAR(:NEW.actual_date, 'DD-MON-YYYY'),
                :NEW.modified_by, :NEW.modified_date
            );
        END IF;
    END IF;
    
    -- Update participant's last visit date when visit is completed
    IF :NEW.status = 'Completed' AND :NEW.actual_date IS NOT NULL THEN
        UPDATE trial_participants
        SET last_visit_date = :NEW.actual_date,
            modified_date = SYSDATE,
            modified_by = :NEW.modified_by
        WHERE participant_id = :NEW.participant_id;
    END IF;
END;
/

-- Trigger for trial milestones audit trail
CREATE OR REPLACE TRIGGER trg_trial_milestones_audit
    BEFORE INSERT OR UPDATE ON trial_milestones
    FOR EACH ROW
BEGIN
    IF INSERTING THEN
        :NEW.created_date := SYSDATE;
        :NEW.created_by := NVL(SYS_CONTEXT('APEX$SESSION', 'APP_USER'), USER);
        :NEW.modified_date := SYSDATE;
        :NEW.modified_by := :NEW.created_by;
    ELSIF UPDATING THEN
        :NEW.modified_date := SYSDATE;
        :NEW.modified_by := NVL(SYS_CONTEXT('APEX$SESSION', 'APP_USER'), USER);
        
        -- Log milestone completion
        IF :OLD.status != :NEW.status AND :NEW.status = 'Completed' THEN
            INSERT INTO audit_log (
                table_name, operation_type, record_id,
                old_values, new_values, changed_by, changed_date
            ) VALUES (
                'TRIAL_MILESTONES', 'MILESTONE_COMPLETED', :NEW.milestone_id,
                'Planned: ' || TO_CHAR(:NEW.planned_date, 'DD-MON-YYYY'),
                'Completed: ' || TO_CHAR(:NEW.actual_date, 'DD-MON-YYYY'),
                :NEW.modified_by, :NEW.modified_date
            );
        END IF;
        
        -- Log progress updates
        IF :OLD.completion_percentage != :NEW.completion_percentage THEN
            INSERT INTO audit_log (
                table_name, operation_type, record_id,
                old_values, new_values, changed_by, changed_date
            ) VALUES (
                'TRIAL_MILESTONES', 'PROGRESS_UPDATE', :NEW.milestone_id,
                'Progress: ' || :OLD.completion_percentage || '%',
                'Progress: ' || :NEW.completion_percentage || '%',
                :NEW.modified_by, :NEW.modified_date
            );
        END IF;
    END IF;
    
    -- Validation: Actual date cannot be before planned date by more than 30 days
    IF :NEW.actual_date IS NOT NULL AND :NEW.planned_date IS NOT NULL THEN
        IF :NEW.actual_date < (:NEW.planned_date - 30) THEN
            RAISE_APPLICATION_ERROR(-20102, 'Milestone completion date is significantly before planned date. Please verify.');
        END IF;
    END IF;
END;
/

-- Trigger for study protocols audit trail
CREATE OR REPLACE TRIGGER trg_study_protocols_audit
    BEFORE INSERT OR UPDATE ON study_protocols
    FOR EACH ROW
BEGIN
    IF INSERTING THEN
        :NEW.created_date := SYSDATE;
        :NEW.created_by := NVL(SYS_CONTEXT('APEX$SESSION', 'APP_USER'), USER);
    END IF;
    
    -- Ensure only one current protocol per trial
    IF :NEW.is_current = 'Y' THEN
        UPDATE study_protocols
        SET is_current = 'N'
        WHERE trial_id = :NEW.trial_id
        AND protocol_id != NVL(:NEW.protocol_id, -1);
    END IF;
END;
/

-- Trigger to validate trial dates
CREATE OR REPLACE TRIGGER trg_validate_trial_dates
    BEFORE INSERT OR UPDATE ON clinical_trials
    FOR EACH ROW
BEGIN
    -- Validation: End date must be after start date
    IF :NEW.end_date IS NOT NULL AND :NEW.start_date IS NOT NULL THEN
        IF :NEW.end_date <= :NEW.start_date THEN
            RAISE_APPLICATION_ERROR(-20103, 'Trial end date must be after start date');
        END IF;
    END IF;
    
    -- Validation: Target enrollment must be positive
    IF :NEW.target_enrollment IS NOT NULL AND :NEW.target_enrollment <= 0 THEN
        RAISE_APPLICATION_ERROR(-20104, 'Target enrollment must be greater than zero');
    END IF;
    
    -- Set creation/modification tracking
    IF INSERTING THEN
        :NEW.created_date := SYSDATE;
        :NEW.created_by := NVL(SYS_CONTEXT('APEX$SESSION', 'APP_USER'), USER);
        :NEW.modified_date := SYSDATE;
        :NEW.modified_by := :NEW.created_by;
    ELSIF UPDATING THEN
        :NEW.modified_date := SYSDATE;
        :NEW.modified_by := NVL(SYS_CONTEXT('APEX$SESSION', 'APP_USER'), USER);
    END IF;
END;
/

-- Trigger to validate visit scheduling
CREATE OR REPLACE TRIGGER trg_validate_visit_schedule
    BEFORE INSERT OR UPDATE ON trial_visits
    FOR EACH ROW
DECLARE
    v_participant_status VARCHAR2(20);
    v_trial_status VARCHAR2(20);
BEGIN
    -- Check if participant is active
    SELECT tp.status, ct.status
    INTO v_participant_status, v_trial_status
    FROM trial_participants tp
    JOIN clinical_trials ct ON tp.trial_id = ct.trial_id
    WHERE tp.participant_id = :NEW.participant_id;
    
    -- Only allow visit scheduling for active participants in active trials
    IF INSERTING AND v_participant_status NOT IN ('Active', 'Screening') THEN
        RAISE_APPLICATION_ERROR(-20105, 'Cannot schedule visits for inactive participants');
    END IF;
    
    IF INSERTING AND v_trial_status NOT IN ('Active', 'Recruiting') THEN
        RAISE_APPLICATION_ERROR(-20106, 'Cannot schedule visits for inactive trials');
    END IF;
    
    -- Validation: Actual date must be within visit window or reasonable range
    IF :NEW.actual_date IS NOT NULL THEN
        IF :NEW.visit_window_start IS NOT NULL AND :NEW.visit_window_end IS NOT NULL THEN
            IF :NEW.actual_date NOT BETWEEN :NEW.visit_window_start AND :NEW.visit_window_end THEN
                -- Allow some flexibility but warn if significantly outside window
                IF :NEW.actual_date NOT BETWEEN (:NEW.visit_window_start - 7) AND (:NEW.visit_window_end + 7) THEN
                    RAISE_APPLICATION_ERROR(-20107, 'Visit date is significantly outside the acceptable window');
                END IF;
            END IF;
        END IF;
    END IF;
END;
/

-- Create notification trigger for serious adverse events
CREATE OR REPLACE TRIGGER trg_notify_serious_ae
    AFTER INSERT OR UPDATE ON adverse_events
    FOR EACH ROW
WHEN (NEW.serious = 'Y')
DECLARE
    v_trial_name VARCHAR2(200);
    v_patient_name VARCHAR2(100);
    v_investigator_email VARCHAR2(100);
BEGIN
    -- Get trial and patient information for notification
    SELECT ct.trial_name, 
           p.first_name || ' ' || p.last_name,
           pr.email
    INTO v_trial_name, v_patient_name, v_investigator_email
    FROM clinical_trials ct
    JOIN trial_participants tp ON ct.trial_id = tp.trial_id
    JOIN patients p ON tp.patient_id = p.patient_id
    LEFT JOIN providers pr ON ct.primary_investigator_id = pr.provider_id
    WHERE tp.participant_id = :NEW.participant_id;
    
    -- Insert notification record (would trigger email in real system)
    INSERT INTO system_notifications (
        notification_type, recipient_email, subject, message,
        priority, created_date, status
    ) VALUES (
        'SERIOUS_AE_ALERT',
        v_investigator_email,
        'URGENT: Serious Adverse Event Reported - ' || v_trial_name,
        'A serious adverse event has been reported for participant ' || v_patient_name || 
        ' in trial ' || v_trial_name || '. Event: ' || :NEW.event_term || 
        '. Please review immediately and take appropriate action.',
        'HIGH',
        SYSDATE,
        'PENDING'
    );
    
EXCEPTION
    WHEN OTHERS THEN
        -- Don't fail the main transaction if notification fails
        NULL;
END;
/
