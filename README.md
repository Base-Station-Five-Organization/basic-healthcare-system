# Basic Healthcare System - Oracle APEX

A comprehensive healthcare management system built with Oracle APEX, designed to manage patients, appointments, medical records, and healthcare providers.

## Features

### Core Healthcare Management

- **Patient Management**: Registration, profile management, medical history
- **Appointment Scheduling**: Book, reschedule, and manage appointments
- **Medical Records**: Electronic health records with secure access
- **Provider Management**: Doctor and staff management
- **Prescription Management**: Medication tracking and management
- **Reports & Analytics**: Healthcare analytics and reporting

### Clinical Trials Extension

- **Trial Management**: Comprehensive clinical trial setup and management
- **Participant Enrollment**: Patient enrollment and randomization
- **Visit Scheduling**: Trial visit scheduling and compliance tracking
- **Adverse Event Reporting**: Safety monitoring and regulatory reporting
- **Milestone Tracking**: Trial timeline and deliverable management
- **Safety Monitoring**: Real-time safety signal detection and analysis
- **Regulatory Compliance**: FDA/EMA reporting and documentation
- **Protocol Management**: Study protocol versioning and amendments

### Security & Compliance

- **Role-based Access Control**: Granular permissions for different user types
- **HIPAA Compliance**: Healthcare data privacy and security
- **Audit Trails**: Complete audit logging for all system activities
- **Data Encryption**: Secure data storage and transmission

## Project Structure

```
basic-healthcare-system/
├── database/
│   ├── schema/          # Database schema definitions
│   │   ├── 01_create_tables.sql           # Core healthcare tables
│   │   ├── 03_views.sql                   # Database views
│   │   └── 04_clinical_trials_tables.sql  # Clinical trials extension
│   ├── data/           # Sample data and lookup tables
│   │   ├── 02_sample_data.sql             # Core sample data
│   │   └── 03_clinical_trials_sample_data.sql  # Clinical trials data
│   ├── packages/       # PL/SQL packages and procedures
│   │   ├── pkg_patient_mgmt.sql           # Patient management functions
│   │   ├── pkg_appointment_mgmt.sql       # Appointment functions
│   │   └── pkg_clinical_trials_mgmt.sql   # Clinical trials functions
│   └── triggers/       # Database triggers
│       ├── triggers.sql                   # Core system triggers
│       └── clinical_trials_triggers.sql   # Clinical trials triggers
├── apex/
│   ├── applications/   # APEX application exports
│   │   ├── application_structure.md       # Core APEX design
│   │   └── clinical_trials_structure.md   # Clinical trials APEX design
│   ├── pages/         # Individual page exports
│   ├── shared/        # Shared components
│   │   ├── reports.sql                    # Core reports
│   │   └── clinical_trials_reports.sql    # Clinical trials reports
│   └── static/        # Static files (CSS, JS, images)
├── docs/
│   ├── design/        # System design documents
│   ├── installation/  # Installation guides
│   └── user-guide/    # User documentation
└── scripts/
    ├── install/       # Installation scripts
    │   └── install.sql                    # Complete installation script
    └── deploy/        # Deployment scripts
```

## Oracle Cloud Setup

1. **Create Autonomous Database**

   - Log into Oracle Cloud Infrastructure (OCI)
   - Navigate to Autonomous Database
   - Create new ATP (Autonomous Transaction Processing) or ADW instance
   - APEX is pre-installed on all Autonomous Databases

2. **Access APEX**

   - From your Autonomous Database details page
   - Click "Tools" tab
   - Click "Open APEX"
   - Create workspace or use existing

3. **Deploy Application**
   - Import the APEX application file
   - Run the database scripts
   - Configure authentication and authorization

## Getting Started

1. Set up your Oracle Cloud Autonomous Database
2. Run the database schema scripts in order
3. Import the APEX application
4. Configure user roles and security
5. Load sample data (optional)

## Database Requirements

- Oracle Database 19c or higher
- Oracle APEX 21.1 or higher
- Minimum 1GB storage for development

## Security Features

- Role-based access control (RBAC)
- Data encryption at rest and in transit
- Audit logging
- HIPAA compliance considerations
- Session management and timeout

## Support

For questions or issues, please refer to the documentation in the `docs/` directory.
