# Oracle APEX Healthcare System Installation Guide

## Prerequisites

Before installing the Healthcare System application, ensure you have:

### Oracle Cloud Infrastructure

- Active Oracle Cloud account
- Autonomous Database (ATP or ADW)### Step 8: Set Up Security

1. **Authentication Scheme**:

   - Go to **Shared Components** > **Authentication Schemes**
   - Create custom scheme or use Database Accounts

2. **Authorization Schemes**:

   - Create roles: Admin, Provider, Staff, Patient, Clinical Research
   - Set page-level authorization

3. **User Management**:
   - Create application users
   - Assign appropriate roles

### Step 9: Configure Application Settingse APEX 21.1 or higher (included with Autonomous Database)

### Database Requirements

- Oracle Database 19c or higher
- Minimum 1GB storage for development
- APEX workspace with development privileges

### Access Requirements

- Admin access to Oracle Cloud Console
- Database admin credentials
- APEX workspace admin credentials

## Installation Steps

### Step 1: Access Your Autonomous Database

1. Log into Oracle Cloud Infrastructure (OCI)
2. Navigate to **Autonomous Database**
3. Select your database instance
4. Click on **Database Actions** or use the **Tools** tab

### Step 2: Run Database Installation Scripts

1. Open **SQL Developer Web** from Database Actions
2. Connect as your database admin user
3. Run the installation scripts in order:

```sql
-- Navigate to your schema or create a new one
-- Example: CREATE USER healthcare IDENTIFIED BY "SecurePassword123!";
-- GRANT CONNECT, RESOURCE, UNLIMITED TABLESPACE TO healthcare;

-- Run installation script
@install.sql
```

Or run individual scripts:

```sql
-- 1. Create core tables and sequences
@database/schema/01_create_tables.sql

-- 2. Create clinical trials tables (NEW)
@database/schema/04_clinical_trials_tables.sql

-- 3. Insert sample data
@database/data/02_sample_data.sql

-- 4. Insert clinical trials sample data (NEW)
@database/data/03_clinical_trials_sample_data.sql

-- 5. Create views
@database/schema/03_views.sql

-- 6. Create packages
@database/packages/pkg_patient_mgmt.sql
@database/packages/pkg_appointment_mgmt.sql
@database/packages/pkg_clinical_trials_mgmt.sql

-- 7. Create triggers
@database/triggers/triggers.sql
@database/triggers/clinical_trials_triggers.sql
```

### Step 3: Access Oracle APEX

#### For Oracle APEX Cloud (apex.oracle.com)

1. Navigate to **https://apex.oracle.com/pls/apex/**
2. Sign in to your workspace: **BASESTATIONFIVE**
3. Go to **SQL Workshop** > **SQL Commands**

#### For Autonomous Database

1. From your Autonomous Database details page
2. Click **Tools** tab
3. Click **Open APEX**
4. Sign in to APEX workspace or create a new one

#### Creating a New Workspace (if needed)

1. Choose **Create Workspace**
2. Enter workspace details:
   - **Workspace Name**: HEALTHCARE
   - **Database User**: healthcare (or your schema name)
   - **Password**: [secure password]
   - **Email**: [your email]

### Step 4: Run Database Scripts in Oracle APEX Cloud

Since you're using Oracle APEX Cloud (apex.oracle.com), follow these steps:

1. **Access SQL Workshop**:

   - In your BASESTATIONFIVE workspace
   - Go to **SQL Workshop** > **SQL Commands**

2. **Run Scripts in Order**:

   **Script 1: Core Tables**

   ```sql
   -- Copy and paste the contents of database/schema/01_create_tables.sql
   -- Execute each section separately due to APEX Cloud limitations
   ```

   **Script 2: Clinical Trials Tables**

   ```sql
   -- Copy and paste the contents of database/schema/04_clinical_trials_tables.sql
   ```

   **Script 3: Sample Data**

   ```sql
   -- Copy and paste the contents of database/data/02_sample_data.sql
   ```

   **Script 4: Clinical Trials Sample Data**

   ```sql
   -- Copy and paste the contents of database/data/03_clinical_trials_sample_data.sql
   ```

   **Script 5: Views**

   ```sql
   -- Copy and paste the contents of database/schema/03_views.sql
   ```

   **Script 6: PL/SQL Packages**

   ```sql
   -- Run each package separately:
   -- 1. database/packages/pkg_patient_mgmt.sql
   -- 2. database/packages/pkg_appointment_mgmt.sql
   -- 3. database/packages/pkg_clinical_trials_mgmt.sql
   ```

   **Script 7: Triggers**

   ```sql
   -- Run each trigger file:
   -- 1. database/triggers/triggers.sql
   -- 2. database/triggers/clinical_trials_triggers.sql
   ```

> **Note**: Oracle APEX Cloud has script size limitations. You may need to run large scripts in sections.

### Step 5: Create APEX Application

1. In APEX workspace, click **Create**
2. Select **New Application**
3. Choose **From Scratch**
4. Configure application:
   - **Name**: Healthcare Management System with Clinical Trials
   - **Schema**: [Your workspace schema]
   - **Authentication**: Database Accounts

### Step 6: Import Application Components

If you have an exported APEX application file:

1. Click **Import**
2. Select application file
3. Follow import wizard
4. Install application

### Step 7: Configure Pages and Components

Create the following pages manually or import:

#### Core Healthcare Pages

**Dashboard (Home Page)**

- Page Type: **Dashboard**
- Regions:
  - Today's Appointments (Chart)
  - Patient Statistics (Cards)
  - Recent Activities (Report)
  - Clinical Trials Summary (NEW)

**Patient Management**

- Page Type: **Interactive Report**
- Source: `v_patient_summary`
- Features: Search, Filter, Export

**Appointment Scheduling**

- Page Type: **Calendar**
- Source: `v_appointment_details`
- Features: Drag & Drop, Create/Edit

**Medical Records**

- Page Type: **Interactive Report**
- Source: `v_medical_records`
- Features: Master-Detail

**Provider Management**

- Page Type: **Interactive Report**
- Source: `providers`
- Features: CRUD operations

#### Clinical Trials Pages (NEW)

**Clinical Trials Dashboard**

- Page Type: **Dashboard**
- Source: `v_trial_dashboard`
- Features: Trial metrics, enrollment progress, safety alerts

**Trial Management**

- Page Type: **Interactive Report**
- Source: `v_trial_summary`
- Features: Create/edit trials, status management

**Participant Management**

- Page Type: **Form with Report**
- Source: `v_trial_participants`
- Features: Enrollment, status tracking

**Visit Scheduling**

- Page Type: **Calendar**
- Source: `v_trial_visits`
- Features: Protocol-driven scheduling

**Adverse Event Reporting**

- Page Type: **Form**
- Source: `adverse_events`
- Features: Safety reporting, regulatory workflows

**Safety Monitoring**

- Page Type: **Dashboard**
- Source: `v_adverse_events`
- Features: Safety metrics, trend analysis

### Step 8: Set Up Security

1. **Authentication Scheme**:

   - Go to **Shared Components** > **Authentication Schemes**
   - Create custom scheme or use Database Accounts

2. **Authorization Schemes**:

   - Create roles: Admin, Provider, Staff, Patient
   - Set page-level authorization

3. **User Management**:
   - Create application users
   - Assign appropriate roles

### Step 9: Configure Application Settings

1. **Application Properties**:

   - Set application name and version
   - Configure error handling
   - Set security attributes

2. **Globalization**:

   - Set date format: MM/DD/YYYY
   - Set time format: HH12:MI AM

3. **Theme and UI**:
   - Select Universal Theme
   - Customize colors and branding

## Quick Start Guide for Oracle APEX Cloud

Since you're using Oracle APEX Cloud at https://apex.oracle.com/pls/apex/ with workspace BASESTATIONFIVE, here's a streamlined approach:

### 1. Prepare Your Environment

1. Log into https://apex.oracle.com/pls/apex/
2. Sign in to workspace: **BASESTATIONFIVE**
3. Go to **SQL Workshop** > **SQL Commands**

### 2. Copy and Run Scripts

I'll provide the key scripts below that you can copy and paste directly into SQL Commands.

## Verification

After installation, verify the system works:

### Database Verification

```sql
-- Check all tables have data
SELECT table_name, num_rows
FROM user_tables
WHERE table_name IN ('PATIENTS', 'PROVIDERS', 'APPOINTMENTS');

-- Test package functions
SELECT pkg_patient_mgmt.get_patient_age(1000) FROM dual;

-- Verify views
SELECT COUNT(*) FROM v_patient_summary;
```

### APEX Application Verification

1. Access application URL
2. Login with test credentials
3. Navigate through all pages
4. Test create/edit functions
5. Verify reports display data

## Post-Installation Configuration

### Data Setup

1. **Load Real Data**: Replace sample data with actual patient information
2. **Configure Providers**: Add real healthcare providers and their schedules
3. **Set Up Appointments**: Import existing appointments or start fresh

### Security Configuration

1. **SSL/TLS**: Ensure HTTPS is enabled
2. **User Accounts**: Create actual user accounts
3. **Access Control**: Configure proper authorization
4. **Audit Settings**: Enable auditing for compliance

### Integration Setup

1. **Email Configuration**: Set up email for appointment reminders
2. **External Systems**: Configure integration with existing systems
3. **Backup Strategy**: Set up regular database backups

## Troubleshooting

### Common Issues

#### Script Errors

- **Invalid identifier**: Check schema name and object existence
- **Insufficient privileges**: Ensure proper grants are applied
- **ORA-00942**: Table or view does not exist - run scripts in order

#### APEX Issues

- **Page not found**: Check page alias and authorization
- **No data found**: Verify database connection and data existence
- **Authentication failed**: Check authentication scheme configuration

### Support Resources

- Oracle APEX Documentation
- Oracle Cloud Support
- APEX Community Forums

## Security Considerations

### HIPAA Compliance

- Enable database encryption
- Set up audit logging
- Implement proper access controls
- Regular security assessments

### Data Protection

- Encrypt sensitive data
- Secure communication channels
- Regular backups
- Disaster recovery plan

## Maintenance

### Regular Tasks

- Monitor database performance
- Update APEX to latest version
- Review and update security settings
- Backup and recovery testing

### Updates and Patches

- Apply Oracle security patches
- Update APEX applications
- Test changes in development environment

---

## Contact Information

For support or questions about this installation:

- Documentation: See `docs/` directory
- Issues: Check troubleshooting section
- Support: Contact your Oracle administrator
