# LikeALocal - Flutter App

A social travel app that helps tourists explore cities like locals, featuring hidden gems, local guides, AI chat, and gamification.

## Setup Instructions

### 1. Prerequisites
- Flutter SDK (3.0+)
- Android Studio or VS Code with Flutter extension
- Firebase account

### 2. Create Flutter Project & Copy Source
```bash
flutter create like_a_local
# Then copy the lib/ folder, pubspec.yaml, and analysis_options.yaml 
# from this repo into the created project
cd like_a_local
flutter pub get
```

### 3. Firebase Setup (Lecture 8 approach)

#### Using FlutterFire CLI (Recommended)
```bash
dart pub global activate flutterfire_cli
flutterfire configure
```
This auto-generates `lib/firebase_options.dart`.

#### Firebase Services to Enable:
1. **Authentication** -> Sign-in method -> Enable Email/Password
2. **Cloud Firestore** -> Create database
3. **Firebase Storage** -> Set up for image uploads

#### Firestore Security Rules:
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    match /places/{placeId} {
      allow read: if true;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null;
    }
  }
}
```

### 4. Run
```bash
flutter run
```

## Project Structure

```
lib/
  main.dart                    # App entry, Firebase init, Provider setup
  firebase_options.dart        # Firebase config (auto-generated)
  models/                      # Data models (User, Place, City, Message, Notification)
  providers/                   # State management (Provider pattern - Lecture 6)
  screens/                     # All 10 screens
  theme/                       # Colors and Material theme
```

## Course Concepts Used

- Stateful/Stateless Widgets (L2)
- Cards, ListViews, Bottom Sheet (L3)
- Responsive Design with MediaQuery (L4)
- Navigation with Navigator.push (L5)
- GridView for grids (L5)
- Provider pattern for state management (L6)
- Firebase Auth with email/password (L7)
- Firebase SDK + Cloud Firestore (L8)
- Image Picker (L9)
- SharedPreferences for persistence (L7)
- Swipe to delete (L6)

## Features

- 5-tab bottom navigation (Home, Explore, Map, Chat, Profile)
- Firebase Authentication with role selection (Tourist/Local)
- City discovery with search and hidden gem scores
- Interactive OpenStreetMap with draggable bottom sheet
- AI chat with keyword-based recommendations
- Profile with stats, saved/shared/badges tabs
- Place contribution form with admin approval flow
- Notifications with swipe-to-delete
- Gamification: points and badges system
