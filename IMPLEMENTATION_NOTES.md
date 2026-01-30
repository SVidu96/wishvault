# WishVault - Google Sign-In with Firebase Implementation

## Overview
This implementation adds Google Sign-In authentication with Firebase, saves user data to Firestore, and displays a personalized welcome message on the home page.

## What Was Implemented

### 1. **Dependencies Added**
- `firebase_auth: ^5.3.3` - For Firebase Authentication
- `cloud_firestore: ^5.5.0` - For Firestore database

### 2. **New Files Created**

#### `lib/models/user_model.dart`
- User data model with fields: uid, email, displayName, photoUrl, createdAt, lastLoginAt
- Methods for converting to/from Firestore Map
- CopyWith method for updating user data

#### `lib/services/auth_service.dart`
- Handles Google Sign-In with Firebase Authentication
- Creates or updates user documents in Firestore
- Manages user sessions and sign-out
- Key methods:
  - `signInWithGoogle()` - Signs in user and returns UserModel
  - `getUserData(uid)` - Retrieves user data from Firestore
  - `signOut()` - Signs out from both Firebase and Google

#### `lib/home_page.dart`
- New home page that displays:
  - User's profile picture (or initial if no photo)
  - Welcome message with user's name
  - User's email
  - Sign-out button in app bar

### 3. **Modified Files**

#### `lib/login_screen.dart`
- Updated to use `AuthService` instead of direct Google Sign-In
- Passes user data to home page after successful login

#### `lib/main.dart`
- Replaced simple routes with `onGenerateRoute` for passing user data
- Removed old counter demo page
- Added proper routing with UserModel arguments

#### `pubspec.yaml`
- Added Firebase Auth and Firestore dependencies

## How It Works

### Authentication Flow:
1. **User clicks "Sign in with Google"** on LoginScreen
2. **Google Sign-In dialog appears** (handled by google_sign_in package)
3. **User selects Google account** and grants permissions
4. **AuthService receives Google credentials** and signs in to Firebase
5. **User document is created/updated in Firestore** at `/users/{uid}`
6. **UserModel is returned** with user data
7. **User is navigated to HomePage** with their data
8. **HomePage displays welcome message** with user's name from Google

### Firestore Structure:
```
users (collection)
  └── {userId} (document)
      ├── uid: string
      ├── email: string
      ├── displayName: string
      ├── photoUrl: string (nullable)
      ├── createdAt: ISO8601 timestamp
      └── lastLoginAt: ISO8601 timestamp
```

## Firebase Console Setup Required

### 1. Enable Authentication
- Go to Firebase Console → Authentication → Sign-in method
- Enable "Google" as a sign-in provider

### 2. Enable Firestore
- Go to Firebase Console → Firestore Database
- Click "Create database"
- Choose "Start in test mode" (for development)
- Select a location

### 3. Add SHA Certificates
- Run `gradlew signingReport` (after fixing Java version issue)
- Copy SHA-1 and SHA-256 from debug variant
- Add to Firebase Console → Project Settings → Your Android App

### 4. Security Rules (for development)
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## Features Implemented

✅ Google Sign-In integration with Firebase Auth
✅ User data saved to Firestore on first login
✅ User data updated on subsequent logins (lastLoginAt)
✅ Welcome message with user's display name
✅ User profile picture display
✅ User email display
✅ Sign-out functionality
✅ Proper navigation with user data passing
✅ Error handling for sign-in failures

## Next Steps

To test the implementation:
1. Fix the Java version issue (use Java 17 or 21)
2. Run `gradlew signingReport` to get SHA certificates
3. Add SHA-1 and SHA-256 to Firebase Console
4. Enable Google Sign-In in Firebase Console
5. Enable Firestore in Firebase Console
6. Run the app: `flutter run`

## Testing Checklist

- [ ] User can sign in with Google
- [ ] User data is saved to Firestore
- [ ] Welcome message shows correct user name
- [ ] Profile picture displays (if available)
- [ ] Sign-out works correctly
- [ ] Returning users see updated lastLoginAt
- [ ] Error messages display for failed sign-ins
