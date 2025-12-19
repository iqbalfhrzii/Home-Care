# Product Overview

## Project Purpose
Home Care Mobile is a Flutter-based healthcare application designed to support doctors, nurses, and medical staff in providing home care services directly to patients. The system enables medical professionals to manage visit schedules, patient data, medical records, electronic prescriptions, billing, and reports in one integrated mobile platform.

## Value Proposition
- **Centralized Healthcare Management**: Single platform for all home care operations
- **Real-time Patient Care**: Immediate access to patient data and medical records during home visits
- **Streamlined Workflows**: Automated report generation, prescription management, and billing processes
- **AI-Powered Insights**: Real-time analysis of vital signs with early warning capabilities
- **Mobile-First Design**: Optimized for healthcare professionals working in the field

## Key Features

### 🏠 Home Dashboard
- Today's visit summary and quick statistics
- Quick access to patients and notifications
- Shortcuts to main menus (Schedule, Report, Profile)
- Real-time updates on visit status

### 📅 Schedule Management
- View daily, weekly, and monthly visit schedules
- Patient information: name, address, visit time, and status
- Filter by status (Pending, Ongoing, Completed)
- Notifications and reminders for upcoming visits
- Registration (Registrasi) management for patient visits

### 📑 Report & Documentation
- Record visit results: vital signs, SOAP notes, medical actions, photos
- Auto-generate reports in hospital standard format
- Verification flow for supervising doctors
- Report history for each patient
- Status tracking: Draft → Pending → Approved

### 💊 e-Prescription & Services
- Create electronic prescriptions directly in the app
- Integrated with pharmacy unit
- Track prescription status (Pending, Processing, Completed)
- Request additional services (referrals, lab tests)
- Medical action (Tindakan) catalog and management

### 🧾 Billing & Administration
- Auto-generate billing draft based on medical actions and prescriptions
- Submit billing for admin approval
- Billing status tracking (Draft, Pending, Approved, Rejected)
- Integration with hospital financial systems

### 🤖 AI Analysis (Planned)
- Process patient vital sign data in real time
- Provide early warning for potential health risks
- Suggest preventive care recommendations

## Target Users

### Primary Users
- **Nurses**: Field healthcare workers conducting home visits
- **Doctors**: Medical professionals supervising care and approving reports
- **Medical Staff**: Administrative personnel managing schedules and billing

### Use Cases
1. **Home Visit Management**: Schedule, conduct, and document patient home visits
2. **Medical Documentation**: Record vital signs, SOAP notes, and medical actions during visits
3. **Prescription Management**: Create and track electronic prescriptions for patients
4. **Billing Processing**: Generate and submit billing for medical services rendered
5. **Patient Monitoring**: Track patient history and ongoing treatment plans
6. **Report Approval**: Supervising doctors review and approve visit reports

## Technical Scope
- **Platform**: Cross-platform mobile application (iOS & Android)
- **Architecture**: Feature-based Clean Architecture with BLoC pattern
- **Backend Integration**: RESTful API communication with hospital backend systems
- **Offline Support**: Secure local storage for working without connectivity
- **Localization**: Indonesian (id_ID) and English (en_US) support
