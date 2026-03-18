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
- **Push notifications:** The app saves each device’s FCM token to Firestore when the user is logged in. The admin clicks **“Send to all devices”** to send a notification to every registered device. See **Push notifications – free setup** below.

## Run the admin panel (admin-web)

```bash
cd admin-web
npm install
npm run dev
```

Create `.env.local` with your Firebase config (e.g. `NEXT_PUBLIC_*` from your Firebase project) and optionally `NEXT_PUBLIC_IMGBB_API_KEY` for image uploads. The admin panel supports login (email + Google), articles, categories, image upload via ImgBB, and a "Push notification" button to send a test notification to the mobile app. Use the sidebar theme button to switch light / dark / system.

## Push notifications – 100% free (no Blaze, no Cloud Functions)

Notifications are sent from the **admin-web** API route using your Firebase service account. No Cloud Functions and no Blaze plan.

### What’s free

- **FCM, Firestore, Auth** – Firebase free tier.
- **Sending** – Admin panel’s Next.js API route (`/api/send-notification`) uses Firebase Admin SDK; no Cloud Functions or billing plan needed.

### One-time setup

1. **Firebase Console**  
   - **Build** → **Cloud Messaging** (no extra config).  
   - **Project settings** → **Service accounts** → **Generate new private key** → download the JSON file.

2. **`google-services.json` at repo root**  
   Put your Firebase Android config at **`google-services.json`** in the repo root (same folder as `admin-web/`, `mobile_app/`).  
   - **Android**: The mobile app build copies it into `mobile_app/android/app/` automatically.  
   - **Admin send-notification**: The API reads **`project_id`** from that file. You still need **server** credentials to call FCM/Firestore Admin:
     - **Recommended:** Service account JSON → **`mobile_app/service.json`** or `FIREBASE_SERVICE_ACCOUNT_JSON` / `GOOGLE_APPLICATION_CREDENTIALS` in `admin-web/.env.local`.  
     - **Local dev:** With only `google-services.json`, run **`gcloud auth application-default login`** (Google account must have access to that Firebase project). Optional: set **`GOOGLE_SERVICES_JSON`** in `.env.local` to an absolute path if the file isn’t at repo root.

3. **Firestore rules** (so the app can write FCM tokens):
   ```bash
   firebase deploy --only firestore:rules
   ```

4. **Android**  
   After `flutterfire configure`, run the app and sign in once so the device token is saved. Then “Send to all devices” in the admin will reach it.

5. **iOS**  
   Requires an Apple Developer account ($99/year) and APNs in Firebase. Skip if you only need Android.

### Flow

- User opens the **mobile app** and **signs in** → app saves FCM token to `users/{uid}/fcmTokens`.
- Admin opens **admin-web**, clicks **“Send to all devices”** → request goes to **same app** at `/api/send-notification`, which reads tokens from Firestore and sends via FCM.

### Will notifications work now? Checklist

| Step | What to do |
|------|------------|
| 1 | **Repo root** has `google-services.json` (Android config). You have this. |
| 2 | **Service account key for sending:** Firebase Console → Project settings → **Service accounts** → **Generate new private key** → save the downloaded JSON as **`mobile_app/service.json`**. Without this, the admin “Send to all devices” button will show an error (your `google-services.json` is client config, not a service account). |
| 3 | **Firestore rules:** run `firebase deploy --only firestore:rules` so the app can write FCM tokens. |
| 4 | **Mobile app:** run the app on a device/emulator, **sign in** (email or Google) once so the token is saved to Firestore. |
| 5 | **Admin:** run `cd admin-web && npm run dev`, open the app, click **“Send to all devices”**. |

If send fails with *default credentials* / *permission denied*, add **`mobile_app/service.json`** (service account key). If it says *“No device tokens registered”*, open the mobile app and sign in, then try again.

## Deploy Firestore rules

```bash
firebase deploy --only firestore:rules
```

## Firestore index (optional)

If you use **filter by category** in the mobile app, Firestore may require a composite index. When you first filter by category, if you see an error in the console with a link to create the index, open that link and create the index (collection `articles`, fields `categoryId` ascending, `publishedAt` descending).

## Caching (Redis-style)

The mobile app uses an in-memory cache with TTL for the article list and article detail. On launch we show cached data (if any) immediately, then refresh from Firestore and replace the cache. This mirrors a **cache-aside** pattern: read from cache first, on miss or expiry read from Firestore and populate the cache. In a production system, Redis would sit in front of the database the same way—first check cache, then hit the primary store and update the cache.
