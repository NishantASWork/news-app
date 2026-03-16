# News App

A simple mobile news application with an admin panel and Firebase backend.

## Structure

- **mobile_app/** – Flutter mobile app (iOS/Android) for reading news, auth, and bookmarks
- **admin_panel/** – Flutter web admin for managing articles and categories
- **firebase.json**, **firestore.rules**, **storage.rules** – Firebase config and security rules

## Prerequisites

- [Flutter](https://docs.flutter.dev/get-started/install) (latest stable)
- [Firebase CLI](https://firebase.google.com/docs/cli) and [FlutterFire CLI](https://firebase.flutter.dev/docs/cli/)

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Login to Firebase
firebase login
```

## Firebase Setup

1. Create a project at [Firebase Console](https://console.firebase.google.com).
2. Enable **Authentication** → Email/Password and Google sign-in.
3. Create **Firestore Database** and **Storage**.
4. Register two apps: one **Android** (and optionally **iOS**) for the mobile app, one **Web** for the admin panel.

## Configure Apps

```bash
# Mobile app
cd mobile_app && flutterfire configure

# Admin panel
cd admin_panel && flutterfire configure
```

Select your Firebase project and the platforms (Android, iOS, Web) for each app. This generates `lib/firebase_options.dart` in each project.

## Run Mobile App

```bash
cd mobile_app
flutter pub get
flutter run
# Or: flutter run -d chrome (for web)
```

## Run Admin Panel

```bash
cd admin_panel
flutter pub get
flutter run -d chrome
# Or: flutter run -d web-server
```

## Deploy Rules

```bash
firebase deploy --only firestore:rules,storage
```

## Firestore index (optional)

If you use **filter by category** in the mobile app, Firestore may require a composite index. When you first filter by category, if you see an error in the console with a link to create the index, open that link and create the index (collection `articles`, fields `categoryId` ascending, `publishedAt` descending).

## Caching (Redis-style)

The mobile app uses an in-memory cache with TTL for the article list and article detail. On launch we show cached data (if any) immediately, then refresh from Firestore and replace the cache. This mirrors a **cache-aside** pattern: read from cache first, on miss or expiry read from Firestore and populate the cache. In a production system, Redis would sit in front of the database the same way—first check cache, then hit the primary store and update the cache.
