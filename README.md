# MediHive - Healthcare Management System

Welcome to **MediHive**, a comprehensive Healthcare Management System built with Flutter. MediHive provides doctors, clinic administrators, and healthcare professionals with an offline-first, seamless tool for managing patient data, Outpatient Department (OPD) queues, appointments, and prescriptions.
ready
## ✨ Features

- **Secure Authentication**: Google Sign-In and secure credential storage.
- **Interactive Dashboard**: High-level statistical overview and analytics charts powered by `fl_chart`.
- **OPD Registration**: Efficient workflow for registering new outpatients and managing current queues.
- **Patient Management**: Detailed view for managing patient demographics, medical history, and records.
- **Prescription Generation**: Generate professional medical prescriptions and export them to PDF using the `pdf` and `printing` packages.
- **Appointments & Calendar**: Visual calendar to manage doctor schedules, bookings, and patient follow-ups.
- **AI Chatbot**: Intelligent virtual assistant embedded for quick help and queries.
- **Offline-First & Local Storage**: Utilizes `Hive` to store patient data, OPD records, and appointments locally, ensuring the app works perfectly without internet access.
- **Data Export & Cloud Backup**: Export records to Excel, share data, and automatically perform background backups to Google Drive via `Workmanager` and `googleapis`.
- **Customizable Themes**: Full Light/Dark mode support.

---

## 🏗️ Architecture & Technology Stack

The app follows a structured, provider-based architecture to decouple business logic from the UI.

### Frontend & Core
- **Framework**: Flutter (Dart)
- **State Management**: `provider`
- **Navigation**: `go_router` (React-Router-like declarative routing)
- **Theming**: Custom ThemeData with `google_fonts` and `cupertino_icons`

### Data & Storage
- **Local Database**: `hive` and `hive_flutter` for fast NoSQL-like local storage.
- **Offline Sync**: Background sync and backups managed by `workmanager`.
- **File Output**: `pdf` (for prescriptions), `excel` (for data dumps), and `share_plus` (for sharing files).

### Authentication & APIs
- **Auth Services**: `google_sign_in`, `flutter_secure_storage`
- **Cloud Backup**: `googleapis`, `googleapis_auth`

---

## 📂 Project Structure

```text
lib/
├── auth/           # Authentication UI and logic
├── dashboard/      # Main statistics dashboard
├── models/         # Hive models (Patient, OPD Record, Appointment)
├── providers/      # State management classes
├── screens/        # Main UI routes (Patients, Calendar, OPD, etc.)
├── services/       # External integrations (SyncManager, API calls)
├── theme/          # App color schemes and typography
├── utils/          # Helper functions and constants
└── widgets/        # Reusable UI components
```

---

## 🚀 Running the Project Locally

### Prerequisites
- Install Flutter SDK (^3.8.0)
- Set up an Android/iOS emulator or connect a physical device
- Make sure you have Android Studio / Xcode configured properly

### Setup

1. **Install Dependencies**
   Navigate to the project root and run:
   ```bash
   flutter pub get
   ```

2. **Generate Hive Adapters (If modifying models)**
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

3. **Run the App**
   ```bash
   flutter run
   ```
   *(To run specifically on web/chrome, use `flutter run -d chrome`)*

---

## 🌐 Background Tasks & Backups

MediHive uses **Workmanager** to handle background tasks seamlessly. By default, it schedules a daily database backup at 2:00 AM using the `SyncManager` service. 

If running on Web, background backup tasks are bypassed since web platforms do not support native background isolations out of the box.
