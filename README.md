
---

# CMSC 129 Project

### Group Members:
* *Kent Francis Genilo*
* *Angel May Janiola*
* *Jasmine Magadan*
* *Eleah Joy Melchor*
* *Mae Maricar Yap*

---

# Logical View Diagram

### Description

{App Name} is a mobile application built with Flutter and Dart. It allows condo managers to {insert manager functions}. Residents can {insert resident functions}. The system uses Supabase as its backend for authentication, database, and storage.

```
User
  ↕
Mobile App
  ↕
Supabase Backend
```

---

# Software Architecture

### Architecture Pattern

Feature-First Architecture with Layered Data Access

The system follows a Feature-First architecture where code is organized by business capability instead of technical type. Each feature contains its own UI and logic. Shared data logic is placed in a centralized data layer.

## Structure Layers

### Presentation Layer

* Pages
* Widgets
* Role-based UI (Tenant, Manager)

### Feature Layer

* Auth
* Resident
* Manager

### Data Layer

* Models
* Repositories
* Supabase integration

---

# Project Structure

```
App-Title/
└── lib/
    ├── data/
    │   ├── models/            # Blueprints: Converts Firestore JSON to Dart Objects
    │   └── repositories/      # Logic: Pure Firebase functions (Auth, CRUD, etc.)
    │
    ├── features/              # Business Logic & UI grouped by feature
    │   ├── auth/              # Login, Signup, Forgot Password
    │   │   ├── pages/         # Full-screen widgets
    │   │   └── widgets/       # Small, reusable auth-only components
    │   │
    │   ├── resident/          # Logic specific to the Tenant role
    │   │   ├── pages/
    │   │   └── widgets/
    │   │
    │   └── manager/           # Logic specific to the Manager role
    │       ├── pages/
    │       └── widgets/
    │
    ├── app.dart               # Global app settings (Theming, Route generation)
    └── main.dart              # Root: App entry point & Firebase initialization
```
