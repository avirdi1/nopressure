# 💓 NoPressure

**NoPressure** is a health-tracking mobile app built with Flutter. It helps users log, monitor, and visualize their blood pressure trends with a clean UI and personalized data. Each user gets secure access via Firebase Authentication, and data is synced in real-time using Cloud Firestore.

---

## 📱 Features

- 🔐 **Secure Login**  
  Sign up and sign in with Firebase Authentication.

- 📝 **Daily Logs**  
  Add systolic and diastolic readings with built-in warnings for abnormal values.

- 📊 **7-Day Chart**  
  Track weekly trends with a bar chart using color-coded health zones.

- 📍 **Clinic Finder**  
  Uses the device’s location with the Google Places API to help find nearby clinics.

- 📷 **Camera Access**  
  The Scan page lets you snap photos of BP monitors (Google ML Vision integration coming soon).

- 👤 **User Profiles**  
  Save your height and weight, and see average vitals specific to your account.

- 🔄 **Dynamic UI**  
  Works responsively across devices and updates instantly with Firestore.

---

## 🔧 Tech Stack

- **Flutter** / **Dart**
- **Firebase Authentication**
- **Cloud Firestore**
- **Google Places API**
- **Google ML Vision** *(planned integration)*
- [`fl_chart`](https://pub.dev/packages/fl_chart) – For data visualization
- [`intl`](https://pub.dev/packages/intl) – For date formatting
- [`flutter_dotenv`](https://pub.dev/packages/flutter_dotenv) – Environment variable management

---

## 📂 APK Release

The release version of the app is available in this repo as:  
📦 `no_pressure_final.apk`

---

## 🔐 Environment Setup

This app uses a `.env` file to store API keys and other secrets (not committed to Git).  
Create a `.env` file in your project root with the following keys:

```env
FIREBASE_API_KEY=
FIREBASE_APP_ID=
FIREBASE_MESSAGING_SENDER_ID=
FIREBASE_PROJECT_ID=
FIREBASE_STORAGE_BUCKET=
GOOGLE_PLACES_KEY=
