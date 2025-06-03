# Oracle APEX Healthcare System - Application Structure

This document outlines the APEX application structure for the Healthcare Management System.

## Application Overview

**Application Name**: Healthcare Management System  
**Application ID**: [To be assigned by APEX]  
**Version**: 1.0  
**Schema**: HEALTHCARE (or your schema name)

## Page Structure

### 1. Dashboard (Page 1)

**Purpose**: Main landing page with key metrics and quick access  
**Type**: Dashboard/Cards  
**Source**: `v_dashboard_stats`

**Regions**:

- Header: Welcome message and current date
- Today's Statistics: Cards showing today's appointments, new patients
- Quick Actions: Buttons for common tasks
- Recent Appointments: Interactive report
- Alerts: Upcoming appointments requiring attention

**Navigation**:

- Patients → Page 10
- Appointments → Page 20
- Providers → Page 30
- Reports → Page 40

### 2. Patient Management (Pages 10-19)

#### Page 10: Patient List

**Type**: Interactive Report  
**Source**: `v_patient_summary`  
**Features**: Search, filter, export, pagination

**Columns**:

- Patient ID (hidden)
- Full Name (link to patient detail)
- Age
- Gender
- Phone
- Email
- Last Visit
- Next Appointment
- Active Status

**Actions**:

- Create Patient → Page 11
- Edit Patient → Page 11
- View Details → Page 12

#### Page 11: Patient Form

**Type**: Form  
**Source**: `patients` table  
**Mode**: Create/Edit

**Items**:

- First Name (required)
- Last Name (required)
- Date of Birth (required)
- Gender (select list)
- Phone
- Email
- Address fields
- Emergency contact
- Insurance information
- Medical conditions
- Allergies

#### Page 12: Patient Details

**Type**: Master-Detail  
**Master Source**: `patients`  
**Detail Sources**:

- Appointments (`v_appointment_details`)
- Medical Records (`v_medical_records`)
- Prescriptions (`v_active_prescriptions`)

### 3. Appointment Management (Pages 20-29)

#### Page 20: Appointment Calendar

**Type**: Calendar  
**Source**: `v_appointment_details`  
**Display**: Month/Week/Day views

**Features**:

- Drag and drop to reschedule
- Color coding by status
- Provider filtering
- Create appointment on click

#### Page 21: Appointment List

**Type**: Interactive Report  
**Source**: `v_appointment_details`

**Filters**:

- Date range
- Provider
- Status
- Patient

#### Page 22: Appointment Form

**Type**: Form  
**Source**: `appointments` table

**Items**:

- Patient (popup LOV)
- Provider (select list)
- Date (date picker)
- Time (select list with available slots)
- Type (select list)
- Duration
- Reason for visit
- Notes

**Validations**:

- Time slot availability
- Provider availability
- Patient not double-booked

#### Page 23: Schedule Management

**Type**: Interactive Grid  
**Source**: `v_provider_schedule`  
**Purpose**: Provider schedule overview and management

### 4. Provider Management (Pages 30-39)

#### Page 30: Provider List

**Type**: Interactive Report  
**Source**: `providers` table

#### Page 31: Provider Form

**Type**: Form  
**Source**: `providers` table

#### Page 32: Provider Schedule

**Type**: Calendar  
**Source**: Provider-specific appointments

### 5. Medical Records (Pages 40-49)

#### Page 40: Medical Records List

**Type**: Interactive Report  
**Source**: `v_medical_records`

#### Page 41: Medical Record Form

**Type**: Form  
**Source**: `medical_records` table

**Sections**:

- Patient Information (read-only)
- Visit Details
- Chief Complaint
- History of Present Illness
- Physical Examination
- Vital Signs
- Diagnosis
- Treatment Plan
- Follow-up Instructions

#### Page 42: Prescription Management

**Type**: Interactive Report  
**Source**: `v_active_prescriptions`

### 6. Reports (Pages 50-59)

#### Page 50: Reports Menu

**Type**: List  
**Purpose**: Navigation to various reports

#### Page 51: Patient Statistics

**Type**: Chart/Report  
**Charts**:

- Patient demographics
- Age distribution
- Gender distribution
- Insurance providers

#### Page 52: Appointment Analytics

**Type**: Dashboard  
**Charts**:

- Appointments by status
- Provider utilization
- Peak hours analysis
- Cancellation rates

#### Page 53: Provider Performance

**Type**: Interactive Report  
**Metrics**:

- Appointments completed
- Patient satisfaction (if available)
- Availability rates

### 7. Administration (Pages 60-69)

#### Page 60: Admin Dashboard

**Type**: Dashboard  
**Access**: Admin role only

#### Page 61: User Management

**Type**: Interactive Report  
**Source**: Application users

#### Page 62: System Settings

**Type**: Form  
**Purpose**: Application configuration

## Shared Components

### Application Items

- AI_CURRENT_USER_ID
- AI_CURRENT_PATIENT_ID
- AI_SELECTED_DATE
- AI_SELECTED_PROVIDER

### Application Processes

- Initialize Session
- Set Security Context
- Cleanup

### Lists

- Navigation Menu
- Breadcrumb
- Quick Actions

### LOVs (List of Values)

- Patients (ID, Display: Full Name)
- Providers (ID, Display: Full Name + Title)
- Appointment Types
- Appointment Statuses
- Specialties
- States/Provinces
- Time Slots

### Dynamic Actions

- Patient Search
- Provider Availability Check
- Appointment Conflict Check
- Auto-save drafts

## Authentication & Authorization

### Authentication Scheme

- Database Account Authentication
- OR Custom authentication with application users

### Authorization Schemes

- Administrator: Full access
- Provider: Patient records, own appointments
- Staff: Scheduling, basic patient info
- Patient: Own records only (if patient portal)

### Page Authorization

```
Page 1-59: Must have valid session
Page 60-69: Must be Administrator
Medical Records: Must be Provider or Administrator
```

## CSS and JavaScript

### Custom CSS

```css
/* Application-specific styles */
.patient-card {
  border-left: 4px solid #0066cc;
}

.appointment-urgent {
  background-color: #fff3cd;
}

.status-completed {
  color: #28a745;
}

.status-cancelled {
  color: #dc3545;
}
```

### Custom JavaScript

```javascript
// Initialize application
function initHealthcareApp() {
  // Set up real-time updates
  // Initialize charts
  // Set up notifications
}

// Appointment time slot validation
function validateTimeSlot(providerId, date, time) {
  // AJAX call to check availability
}
```

## Deployment Configuration

### Application Properties

- **Application Name**: Healthcare Management System
- **Application Alias**: HEALTHCARE
- **Version**: 1.0.0
- **Build Status**: Run Application Only
- **Availability**: Available
- **Authentication**: Custom/Database
- **Authorization**: Reader Rights

### Performance Settings

- **Page View Logging**: Yes
- **Page Performance Analytics**: Yes
- **Deep Linking**: Yes
- **Browser Cache**: Default

### Security Settings

- **Session Timeout**: 8 hours
- **Maximum Session Length**: 12 hours
- **Rejoin Sessions**: Enabled
- **Session Sharing**: Disabled

## Integration Points

### Email Integration

- Appointment reminders
- Password reset
- Notifications

### External Systems

- Insurance verification APIs
- Laboratory systems
- Pharmacy systems
- Electronic Health Records (EHR)

### File Upload

- Patient documents
- Medical images
- Insurance cards

## Mobile Considerations

### Responsive Design

- Universal Theme responsive features
- Mobile-first approach
- Touch-friendly controls

### Mobile-Specific Pages

- Mobile appointment booking
- Patient check-in
- Provider schedule view

## Backup and Recovery

### Application Export

- Regular exports for version control
- Environment promotion
- Disaster recovery

### Data Backup

- Database-level backups
- Application metadata backup
- User preferences backup

---

This structure provides a comprehensive healthcare management system built on Oracle APEX with proper security, functionality, and user experience considerations.
