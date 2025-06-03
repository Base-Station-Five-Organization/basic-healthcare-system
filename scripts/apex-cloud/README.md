# Oracle APEX Cloud Setup - Complete Guide

## Healthcare Management System with Clinical Trials

### Environment Details

- **URL**: https://apex.oracle.com/pls/apex/
- **Workspace**: BASESTATIONFIVE
- **Date**: June 2, 2025

## Setup Instructions

### Step 1: Access Your Environment

1. Navigate to https://apex.oracle.com/pls/apex/
2. Sign in to workspace: **BASESTATIONFIVE**
3. Go to **SQL Workshop** > **SQL Commands**

### Step 2: Run Scripts in Order

Copy and paste each script below into SQL Commands and execute them one by one:

#### Script 1: Core Tables and Sequences

**File**: `01_run_first.sql`

- Creates sequences and core healthcare tables
- Includes: patients, providers, appointments, lookup tables

#### Script 2: Medical Records and Additional Tables

**File**: `02_run_second.sql`

- Creates medical records and prescriptions tables
- Adds indexes for performance

#### Script 3: Clinical Trials Tables

**File**: `03_run_third.sql`

- Creates clinical trials and participants tables
- Establishes foreign key relationships

#### Script 4: Clinical Trials Support Tables

**File**: `04_run_fourth.sql`

- Creates protocols, milestones, adverse events, and visits tables
- Adds clinical trials indexes

#### Script 5: Core Sample Data

**File**: `05_run_fifth.sql`

- Inserts sample providers, patients, and lookup data
- Creates test records for development

#### Script 6: Clinical Trials Sample Data

**File**: `06_run_sixth.sql`

- Inserts sample trials, participants, and visits
- Creates realistic test scenario

#### Script 7: Core Views

**File**: `07_run_seventh.sql`

- Creates patient, provider, and appointment views
- Establishes reporting foundation

#### Script 8: Clinical Trials Views

**File**: `08_run_eighth.sql`

- Creates comprehensive clinical trials views
- Includes calculated metrics and health scores

#### Script 9: Verification and Testing

**File**: `09_run_final.sql`

- Verifies all objects are created correctly
- Tests basic functionality
- Provides next steps

## Important Notes

### Oracle APEX Cloud Limitations

- **Script Size**: Large scripts may need to be broken into smaller chunks
- **Timeouts**: Complex operations might timeout - run in sections if needed
- **Error Handling**: Check for errors after each script execution

### If You Encounter Errors

1. **ORA-00942 (Table/view does not exist)**: Ensure previous scripts completed successfully
2. **ORA-00001 (Unique constraint violated)**: Script may have been run partially - check data
3. **ORA-01031 (Insufficient privileges)**: Contact workspace administrator
4. **Script timeout**: Break large scripts into smaller sections

### Verification Steps

After running all scripts, verify:

1. All tables exist (should see 15+ tables)
2. Sample data is present (patients, providers, trials)
3. Views are created and accessible
4. No invalid objects in user_objects

## Next Steps After Database Setup

### 1. Create APEX Application

- Application Type: **New Application**
- Name: **Healthcare Management System**
- Schema: **[Your workspace schema]**
- Authentication: **Database Accounts**

### 2. Create Application Pages

Follow the structure in `apex/applications/clinical_trials_structure.md`:

- Dashboard pages
- Interactive reports
- Forms for data entry
- Calendar views for scheduling

### 3. Import Reports

Use the queries from `apex/shared/clinical_trials_reports.sql` to create:

- Enrollment tracking reports
- Safety monitoring dashboards
- Visit compliance reports
- Provider activity summaries

### 4. Set Up Security

- Create user roles (Provider, Coordinator, Safety Officer, etc.)
- Configure page-level authorization
- Set up proper data access controls

## Support Files

All script files are located in:

```
scripts/apex-cloud/
├── 01_run_first.sql      # Core tables
├── 02_run_second.sql     # Medical records
├── 03_run_third.sql      # Clinical trials
├── 04_run_fourth.sql     # Support tables
├── 05_run_fifth.sql      # Sample data
├── 06_run_sixth.sql      # Clinical trials data
├── 07_run_seventh.sql    # Core views
├── 08_run_eighth.sql     # Clinical trials views
└── 09_run_final.sql      # Verification
```

## Additional Documentation

- **Installation Guide**: `docs/installation/INSTALLATION.md`
- **User Guide**: `docs/user-guide/clinical_trials_user_guide.md`
- **APEX Structure**: `apex/applications/clinical_trials_structure.md`
- **Project Overview**: `PROJECT_OVERVIEW.md`

## Contact Information

For questions or issues:

- Review troubleshooting section in INSTALLATION.md
- Check Oracle APEX documentation
- Contact workspace administrator for permission issues

---

**Ready to begin? Start with Script 1 and work through each script in order.**
