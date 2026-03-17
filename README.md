# News App

A simple mobile news application with a web admin panel and Firebase backend.

## Structure

- **mobile_app/** – Flutter app: reader (home, article detail, bookmarks), search, filter by category, infinite scroll, dark mode. Optionally includes in-app admin routes (RBAC) for articles/categories.
- **admin-web/** – Next.js admin panel (web dashboard): login (email + Google), add/edit/delete articles, upload image (ImgBB), add/delete categories, send test push notification, dark mode.
- **functions/** – Cloud Function to send a test push notification to the app (topic `news`).
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
3. Create **Firestore Database** (Storage is not used; article images use ImgBB).
4. Register two apps: one **Android** (and optionally **iOS**) for the mobile app, one **Web** for the admin panel.

## Configure Apps

```bash
cd mobile_app && flutterfire configure
```

Select your Firebase project and the platforms (Android, iOS, Web). This generates `lib/firebase_options.dart`. Enable **Cloud Messaging** in Firebase Console for push notifications.

## Image upload (New Article / Edit Article)

Article images are uploaded to **ImgBB** (free), and the image URL is stored in Firestore. Firebase Storage is not used.

1. Get a free API key at [api.imgbb.com](https://api.imgbb.com/).
2. Set the key via **environment variable** (recommended for mobile/desktop) or **dart-define**:
   ```bash
   # Option A: environment variable (inherited by flutter run)
   export IMGBB_API_KEY=your_imgbb_api_key
   flutter run -d android
   ```
   ```bash
   # Option B: dart-define (works on all platforms including web)
   flutter run -d android --dart-define=IMGBB_API_KEY=your_key
   ```

Without the key, saving an article with an image will show an error asking you to set `IMGBB_API_KEY`.

## Run the mobile app

```bash
cd mobile_app
flutter pub get
flutter run
# Or: flutter run -d chrome (set IMGBB_API_KEY in env or --dart-define for image upload)
```

- **Theme:** Default is system theme (light/dark follows device). Use the app bar icon to cycle system → light → dark.
- **Admin (RBAC, in-app):** To grant admin access in the Flutter app, set the user's `role` in Firestore: in `users/{userId}` add field `role: "admin"`. Only those users see "Admin panel" in the drawer and can open `/admin/articles` and `/admin/categories`.
- **Push notifications:** The app subscribes to FCM topic `news`. When the server (or Cloud Function) sends a message to that topic, the app shows it in-app (SnackBar) and can open an article if the payload includes `articleId` or `id`. Deploy the Cloud Function and use the **admin-web** "Push notification" button, or POST the function URL. The function URL is `https://<region>-<project>.cloudfunctions.net/sendTestNotification`.

## Run the admin panel (admin-web)

```bash
cd admin-web
npm install
npm run dev
```

Create `.env.local` with your Firebase config (e.g. `NEXT_PUBLIC_*` from your Firebase project) and optionally `NEXT_PUBLIC_IMGBB_API_KEY` for image uploads. The admin panel supports login (email + Google), articles, categories, image upload via ImgBB, and a "Push notification" button to send a test notification to the mobile app. Use the sidebar theme button to switch light / dark / system.

## Deploy Rules and Functions

```bash
firebase deploy --only firestore:rules
# Optional: deploy Cloud Function to send test notifications
firebase deploy --only functions
```

## Firestore index (optional)

If you use **filter by category** in the mobile app, Firestore may require a composite index. When you first filter by category, if you see an error in the console with a link to create the index, open that link and create the index (collection `articles`, fields `categoryId` ascending, `publishedAt` descending).

## Caching (Redis-style)

The mobile app uses an in-memory cache with TTL for the article list and article detail. On launch we show cached data (if any) immediately, then refresh from Firestore and replace the cache. This mirrors a **cache-aside** pattern: read from cache first, on miss or expiry read from Firestore and populate the cache. In a production system, Redis would sit in front of the database the same way—first check cache, then hit the primary store and update the cache.
