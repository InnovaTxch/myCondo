# CMSC-129-Project

## Description

{App Name} is a mobile application built with Flutter and Dart. It allows condo managers to {insert manager functions}. Residents can {insert resident functions}. The system uses Supabase as its backend for authentication, database, and storage.

## Logical View Diagram

<img width="289" height="230" alt="image" src="https://github.com/user-attachments/assets/620fe1f3-1167-4a09-bf60-6012f7b82ddf" />


## Software Architecture



## Project Structure
```
App-Title/
└── lib/
    ├── data/
    │   ├── models/      		    # Blueprints: Converts Firestore JSON to Dart Objects
    │   └── repositories/     	# Logic: Pure Firebase functions (Auth, CRUD, etc.)
    │
    ├── features/             	# Business Logic & UI grouped by feature
    │   ├── auth/             	# Login, Signup, Forgot Password
    │   │   ├── pages/        	# Full-screen widgets
    │   │   └── widgets/      	# Small, reusable auth-only components
    │   │
    │   ├── tenant/           	# Logic specific to the Tenant role
    │   │   ├── pages/        
    │   │   └── widgets/      
    │   │
    │   └── manager/          	# Logic specific to the Manager role
    │       ├── pages/        
    │       └── widgets/      
    │
    ├── app.dart              	# Global app settings (Theming, Route generation)
    └── main.dart             	# Root: App entry point & Firebase initialization
```
