# Oracle APEX Cloud Setup Guide

## For BASESTATIONFIVE Workspace

This guide provides step-by-step instructions for setting up the Healthcare Management System with Clinical Trials on Oracle APEX Cloud.

## Environment Details

- **URL**: https://apex.oracle.com/pls/apex/
- **Workspace**: BASESTATIONFIVE
- **System**: Healthcare Management with Clinical Trials Extension

## Prerequisites

- Access to BASESTATIONFIVE workspace on Oracle APEX Cloud
- Administrative privileges in the workspace
- Familiarity with Oracle SQL

## Step-by-Step Installation

### Step 1: Access SQL Workshop

1. Navigate to https://apex.oracle.com/pls/apex/
2. Sign in to workspace: **BASESTATIONFIVE**
3. Go to **SQL Workshop** > **SQL Commands**

### Step 2: Create Tables and Sequences

Copy and paste the following scripts one at a time into SQL Commands:

#### Script 1: Core Healthcare Tables

```sql
-- You'll need to copy the contents from database/schema/01_create_tables.sql
-- Due to APEX Cloud limitations, run this in sections
```

#### Script 2: Clinical Trials Tables

```sql
-- Copy contents from database/schema/04_clinical_trials_tables.sql
```

### Step 3: Insert Sample Data

#### Script 3: Core Sample Data

```sql
-- Copy contents from database/data/02_sample_data.sql
```

#### Script 4: Clinical Trials Sample Data

```sql
-- Copy contents from database/data/03_clinical_trials_sample_data.sql
```

### Step 4: Create Views

```sql
-- Copy contents from database/schema/03_views.sql
```

### Step 5: Create PL/SQL Packages

Run each package separately:

#### Package 1: Patient Management

```sql
-- Copy contents from database/packages/pkg_patient_mgmt.sql
```

#### Package 2: Appointment Management

```sql
-- Copy contents from database/packages/pkg_appointment_mgmt.sql
```

#### Package 3: Clinical Trials Management

```sql
-- Copy contents from database/packages/pkg_clinical_trials_mgmt.sql
```

### Step 6: Create Triggers

#### Core Triggers

```sql
-- Copy contents from database/triggers/triggers.sql
```

#### Clinical Trials Triggers

```sql
-- Copy contents from database/triggers/clinical_trials_triggers.sql
```

### Step 7: Verify Installation

Run these verification queries:

```sql
-- Check tables exist
SELECT table_name FROM user_tables
WHERE table_name IN ('PATIENTS', 'CLINICAL_TRIALS', 'TRIAL_PARTICIPANTS')
ORDER BY table_name;

-- Check sample data
SELECT COUNT(*) as patient_count FROM patients;
SELECT COUNT(*) as trial_count FROM clinical_trials;
SELECT COUNT(*) as participant_count FROM trial_participants;

-- Test a package function
SELECT pkg_clinical_trials_mgmt.get_trial_enrollment_status(1000) FROM dual;
```

## Next Steps

After database setup is complete:

1. **Create APEX Application**
2. **Configure Pages** (see clinical_trials_structure.md for detailed page designs)
3. **Set up Security**
4. **Import Reports** (see apex/shared/clinical_trials_reports.sql)

## Support

Refer to:

- Main installation guide: `docs/installation/INSTALLATION.md`
- Clinical trials user guide: `docs/user-guide/clinical_trials_user_guide.md`
- APEX structure guide: `apex/applications/clinical_trials_structure.md`

## Files You'll Need to Copy

Make sure you have access to these files from your local system:

- `database/schema/01_create_tables.sql`
- `database/schema/04_clinical_trials_tables.sql`
- `database/data/02_sample_data.sql`
- `database/data/03_clinical_trials_sample_data.sql`
- `database/schema/03_views.sql`
- `database/packages/pkg_patient_mgmt.sql`
- `database/packages/pkg_appointment_mgmt.sql`
- `database/packages/pkg_clinical_trials_mgmt.sql`
- `database/triggers/triggers.sql`
- `database/triggers/clinical_trials_triggers.sql`
