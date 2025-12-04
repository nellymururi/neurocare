# 🧠 NeuroCare – ADHD Activity Monitoring App
**NeuroCare** is a modern and intuitive mobile application built with **Flutter**.
It helps caregivers monitor ADHD patients by providing real-time activity insights, alerts, and predictions powered by machine learning.

The app integrates with Google Fit to fetch real-time movement, steps, and heart-rate data. This data is sent to an ML model to detect abnormal activity levels and notify caregivers instantly.

## 📱 Features

### 🧬 ML-Powered Predictions

Sends activity data to an LSTM model to predict abnormal activity spikes.

### 🔔 Caregiver Alerts

Notifies users when activity crosses predefined thresholds or when unusual behavior is detected.

### 🔐 Secure Authentication

Email/Password login, Google Sign-In, and password reset via Firebase Authentication.

### 🎨 Clean UI & Smooth Navigation

A modern, simple interface with a splash screen, bottom navigation, and a caregiver-friendly layout.

### 👤 User Profile & CRUD

View, edit, update, or delete user details. Admins can also manage user credentials.

## 🧠 Tech Stack

- Framework: Flutter (Dart)
- Backend ML Model: Python (FastAPI/Flask with LSTM model)
- Authentication: Firebase Authentication
- Database: Firestore
- APIs: Google Fit API (real-time activity data)
- Architecture: MVVM / Provider (or your preferred state management)
- Notifications: Firebase Cloud Messaging

## 🚀 Getting Started

Follow these steps to get a local copy up and running:

Prerequisites
- Flutter SDK installed
- Android Studio or VS Code
- Git installed
- A configured Firebase project
- Google Fit API enabled
- Physical Android device or emulator


## Installation
1. Clone the repository
```sh
git clone https://github.com/yourusername/neurocare.git
```

2. Navigate into the project folder:
```sh
cd neurocare
```

3. Install Dependencies
Run:
```sh
flutter pub get
```

4. Add Firebase Configuration
Place the config files in the correct directories:
```sh
android/app/google-services.json
ios/Runner/GoogleService-Info.plist
```

5. Set Up Google Fit Permissions
Make sure the Google Fit scopes are added in your Flutter project, usually in:
android/app/src/main/AndroidManifest.xml

6. Run the App
 ```sh
flutter run
```

7. Connect a real device or emulator, then click Run ▶️ in your IDE.

   
## 🧩 Folder Structure
 ```sh
NeuroCare/
│
├── lib/
│   ├── screens/               # Screens: splash, login, signup, home, alert, profile
│   ├── services/              # AuthService, GoogleFitService, backend integration
│   ├── models/                # Activity model, prediction model
│   ├── widgets/               # Reusable UI components
│   ├── navigation/            # Bottom navigation setup
│   └── utils/                 # Theme, constants, helpers
│
├── android/                   # Android-specific configuration
├── ios/                       # iOS configuration
└── pubspec.yaml               # Dependencies and assets
```

## 💡 Future Enhancements

- Add support for wearable devices (Fitbit, Samsung Health).
- Implement push notifications using Firebase Cloud Messaging.
- Add caregiver chat or messaging.
- Offline mode for activity caching.
- More advanced ML predictions (stress, sleep patterns).

## 📜 License

This project is licensed under the [MIT License](LICENSE).
