# Firebase Cloud Storage Setup Guide

This guide will help you set up Firebase for your Integrated Health App to enable cloud data storage and multi-device synchronization.

## Features Implemented

- **Firebase Authentication**: Secure user authentication with email/password
- **Cloud Firestore**: Real-time NoSQL database for patient data
- **Multi-device Sync**: Access patient data from any device after login
- **Automatic Sync**: Patient data automatically syncs to cloud after create/update/delete
- **Offline Support**: Works offline, syncs when connection is restored

## Prerequisites

- Google account
- Node.js installed (for Firebase CLI)
- Flutter development environment

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Enter project name (e.g., "integrated-health-app")
4. Disable Google Analytics (optional for health apps)
5. Click "Create project"

## Step 2: Enable Firebase Authentication

1. In Firebase Console, go to **Authentication** > **Sign-in method**
2. Click on **Email/Password**
3. Toggle **Enable** on
4. Click **Save**

## Step 3: Create Cloud Firestore Database

1. In Firebase Console, go to **Firestore Database**
2. Click **Create database**
3. Select **Start in production mode** (we'll add security rules later)
4. Choose a location closest to your users
5. Click **Enable**

## Step 4: Set Up Firestore Security Rules

1. Go to **Firestore Database** > **Rules** tab
2. Replace the default rules with the following:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // User can only read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;

      // User's patients collection
      match /patients/{patientId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }

      // User's visits collection
      match /visits/{visitId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }

      // User's prescriptions collection
      match /prescriptions/{prescriptionId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }

      // User's lab tests collection
      match /lab_tests/{labTestId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

3. Click **Publish**

## Step 5: Install Firebase CLI

```bash
# Install Firebase CLI globally
npm install -g firebase-tools

# Login to Firebase
firebase login

# Install FlutterFire CLI
dart pub global activate flutterfire_cli
```

## Step 6: Configure Firebase for Flutter

1. Navigate to your project directory:
```bash
cd /path/to/integrated_health_app
```

2. Run FlutterFire configuration:
```bash
flutterfire configure
```

3. Select your Firebase project from the list
4. Select platforms you want to support (iOS, Android, Web, macOS)
5. This will generate `firebase_options.dart` with your project credentials

## Step 7: Install Dependencies

```bash
flutter pub get
```

This will install all Firebase dependencies:
- `firebase_core`: Core Firebase SDK
- `firebase_auth`: Authentication
- `cloud_firestore`: Firestore database
- `firebase_storage`: File storage (for future use)

## Step 8: Register Your First User

1. Run the app:
```bash
flutter run
```

2. On the login screen, toggle **Cloud Storage** switch ON
3. Click "Don't have an account? Register"
4. Create a new account with:
   - Name: Your name
   - Email: your-email@example.com
   - Password: secure-password
   - Role: Doctor/Nurse/Patient

## Step 9: Verify Setup

1. Login with your newly created account
2. Add a patient in the app
3. Go to Firebase Console > Firestore Database
4. You should see:
   - `users/{your-user-id}` document
   - `users/{your-user-id}/patients` collection with patient data

## Step 10: Test Multi-Device Sync

1. Login on Device 1 with cloud storage enabled
2. Add a patient
3. Logout and login on Device 2 (or web)
4. The patient should appear automatically after login

## Data Structure in Firestore

```
users (collection)
└── {userId} (document)
    ├── name: string
    ├── email: string
    ├── role: string
    ├── specialty: string
    └── createdAt: timestamp

    └── patients (subcollection)
        └── {patientId} (document)
            ├── id: string
            ├── name: string
            ├── age: number
            ├── phone: string
            ├── conditions: array
            ├── vitals: object
            ├── notes: string
            └── syncedAt: timestamp

    └── visits (subcollection)
        └── {visitId} (document)
            └── ... visit data

    └── prescriptions (subcollection)
        └── {prescriptionId} (document)
            └── ... prescription data

    └── lab_tests (subcollection)
        └── {labTestId} (document)
            └── ... lab test data
```

## Usage in the App

### Cloud Authentication (Default)

- Toggle **Cloud Storage** switch ON in login screen
- Login with Firebase account
- All patient data syncs to cloud automatically
- Data accessible from any device

### Local Authentication (Fallback)

- Toggle **Cloud Storage** switch OFF in login screen
- Login with local SQLite account
- Data stored only on local device
- No cloud sync

## Sync Behavior

1. **Create Patient**: Saves to local SQLite + syncs to Firestore
2. **Update Patient**: Updates local SQLite + syncs to Firestore
3. **Delete Patient**: Deletes from local SQLite + deletes from Firestore
4. **Login**: Automatically pulls latest data from Firestore
5. **Offline**: App works offline, syncs when connection restored

## Troubleshooting

### Error: Firebase not initialized

- Make sure you ran `flutterfire configure`
- Check that `firebase_options.dart` exists
- Verify `Firebase.initializeApp()` is called in `main.dart`

### Error: User not found

- Make sure you registered the user with Cloud Storage enabled
- Check Firebase Console > Authentication to see registered users

### Error: Permission denied

- Verify Firestore security rules are configured correctly
- Make sure user is authenticated before accessing data

### Data not syncing

- Check internet connection
- Check Firebase Console > Firestore for data
- Check app logs for sync errors
- Verify user is logged in with cloud auth enabled

## Security Best Practices

1. **Never commit Firebase credentials to Git**
   - `firebase_options.dart` is already in `.gitignore`
   - Keep API keys secure

2. **Use strong passwords**
   - Enforce minimum 8 characters
   - Use password validation

3. **Implement rate limiting**
   - Firebase has built-in rate limiting
   - Monitor usage in Firebase Console

4. **Regular backups**
   - Enable Firestore daily backups in Firebase Console
   - Export data regularly

5. **HIPAA Compliance** (for production)
   - Sign Google Cloud's BAA (Business Associate Agreement)
   - Enable audit logging
   - Use Firebase Healthcare API if needed

## Cost Considerations

Firebase has a generous free tier:
- **Authentication**: 50,000 monthly active users (free)
- **Firestore**:
  - 50,000 reads/day (free)
  - 20,000 writes/day (free)
  - 1 GB storage (free)
- **Storage**: 5 GB storage (free)

For production with many users, consider:
- Firebase Blaze plan (pay as you go)
- Monitor usage in Firebase Console
- Set budget alerts

## Next Steps

1. Implement forgot password functionality
2. Add email verification
3. Implement user profile management
4. Add Firebase Storage for images/PDFs
5. Implement real-time sync listeners
6. Add offline indicator in UI

## Support

For Firebase issues:
- Firebase Documentation: https://firebase.google.com/docs
- FlutterFire Documentation: https://firebase.flutter.dev

For app-specific issues:
- Check app logs
- Review code in `lib/services/firebase_auth_service.dart`
- Review code in `lib/services/cloud_sync_service.dart`
