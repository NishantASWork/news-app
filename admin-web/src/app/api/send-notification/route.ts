import { NextResponse } from 'next/server';
import * as admin from 'firebase-admin';
import * as fs from 'fs';
import * as path from 'path';

const BATCH = 500;

const MOBILE_SERVICE_JSON = 'mobile_app/service.json';
const ROOT_GOOGLE_SERVICES = 'google-services.json';

function isServiceAccountKey(obj: unknown): obj is admin.ServiceAccount {
  if (obj == null || typeof obj !== 'object') return false;
  const o = obj as Record<string, unknown>;
  return typeof (o.private_key ?? o.privateKey) === 'string';
}

function googleServicesJsonPaths(): string[] {
  const cwd = process.cwd();
  const fromEnv = process.env.GOOGLE_SERVICES_JSON?.trim();
  const list = [
    ...(fromEnv ? [fromEnv] : []),
    path.join(cwd, ROOT_GOOGLE_SERVICES),
    path.join(cwd, '..', ROOT_GOOGLE_SERVICES),
    path.join(cwd, '..', '..', ROOT_GOOGLE_SERVICES),
    path.join(cwd, '..', 'mobile_app', ROOT_GOOGLE_SERVICES),
  ];
  return Array.from(new Set(list.filter(Boolean)));
}

function projectIdFromGoogleServices(parsed: unknown): string | null {
  const p = parsed as Record<string, unknown>;
  const info = p.project_info as Record<string, unknown> | undefined;
  const id = info?.project_id;
  return typeof id === 'string' && id.length > 0 ? id : null;
}

/**
 * Resolves a path (relative or absolute). Relative paths are resolved from cwd.
 */
function resolveCredentialPath(rawPath: string): string {
  const trimmed = rawPath.trim();
  if (path.isAbsolute(trimmed)) return trimmed;
  return path.resolve(process.cwd(), trimmed);
}

/**
 * Prefers service account JSON. If only Android google-services.json exists, uses its
 * project_id + Application Default Credentials (e.g. gcloud auth application-default login).
 * FCM still requires server credentials — ADC must be a user/service account with Firebase access.
 */
function getAdminApp(): admin.app.App {
  if (admin.apps.length > 0) {
    return admin.app() as admin.app.App;
  }
  const json = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  const keyPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;
  if (json) {
    try {
      const key = JSON.parse(json) as admin.ServiceAccount;
      return admin.initializeApp({ credential: admin.credential.cert(key) });
    } catch {
      throw new Error('FIREBASE_SERVICE_ACCOUNT_JSON is invalid JSON.');
    }
  }
  if (keyPath) {
    const resolvedPath = resolveCredentialPath(keyPath);
    if (!fs.existsSync(resolvedPath)) {
      throw new Error(
        `GOOGLE_APPLICATION_CREDENTIALS file not found: ${resolvedPath}. Use an absolute path or a path relative to the project (e.g. ../mobile_app/service.json or service.json in admin-web).`
      );
    }
    try {
      const parsed = JSON.parse(fs.readFileSync(resolvedPath, 'utf8')) as unknown;
      if (isServiceAccountKey(parsed)) {
        return admin.initializeApp({ credential: admin.credential.cert(parsed) });
      }
    } catch (e) {
      throw new Error(
        `GOOGLE_APPLICATION_CREDENTIALS file at ${resolvedPath} is not valid service account JSON: ${e instanceof Error ? e.message : String(e)}`
      );
    }
  }
  const cwd = process.cwd();
  const serviceAccountPaths = [
    path.join(cwd, 'service.json'),
    path.join(cwd, MOBILE_SERVICE_JSON),
    path.join(cwd, '..', MOBILE_SERVICE_JSON),
  ];
  for (const filePath of serviceAccountPaths) {
    try {
      if (!fs.existsSync(filePath)) continue;
      const parsed = JSON.parse(fs.readFileSync(filePath, 'utf8')) as unknown;
      if (isServiceAccountKey(parsed)) {
        return admin.initializeApp({ credential: admin.credential.cert(parsed) });
      }
    } catch {
      // skip
    }
  }
  try {
    const files = fs.readdirSync(cwd);
    const adminsdk = files.find((f) => f.includes('-firebase-adminsdk-') && f.endsWith('.json'));
    if (adminsdk) {
      const filePath = path.join(cwd, adminsdk);
      const parsed = JSON.parse(fs.readFileSync(filePath, 'utf8')) as unknown;
      if (isServiceAccountKey(parsed)) {
        return admin.initializeApp({ credential: admin.credential.cert(parsed) });
      }
    }
  } catch {
    // skip
  }
  for (const filePath of googleServicesJsonPaths()) {
    try {
      if (!fs.existsSync(filePath)) continue;
      const parsed = JSON.parse(fs.readFileSync(filePath, 'utf8')) as unknown;
      if (isServiceAccountKey(parsed)) {
        return admin.initializeApp({ credential: admin.credential.cert(parsed) });
      }
    } catch {
      // skip
    }
  }
  for (const filePath of googleServicesJsonPaths()) {
    try {
      if (!fs.existsSync(filePath)) continue;
      const parsed = JSON.parse(fs.readFileSync(filePath, 'utf8')) as unknown;
      const projectId = projectIdFromGoogleServices(parsed);
      if (projectId) {
        return admin.initializeApp({
          credential: admin.credential.applicationDefault(),
          projectId,
        });
      }
    } catch {
      // skip
    }
  }
  throw new Error(
    'Could not initialize Firebase Admin. Either: (1) Add mobile_app/service.json (service account from Firebase Console → Project settings → Service accounts → Generate new private key), or set FIREBASE_SERVICE_ACCOUNT_JSON / GOOGLE_APPLICATION_CREDENTIALS. Or (2) Keep google-services.json at repo root (or set GOOGLE_SERVICES_JSON) and run: gcloud auth application-default login — your Google account needs access to this Firebase project.'
  );
}

async function getAllFcmTokens(firestore: admin.firestore.Firestore): Promise<string[]> {
  const tokens: string[] = [];
  const usersSnap = await firestore.collection('users').get();
  for (const userDoc of usersSnap.docs) {
    const tokensSnap = await firestore
      .collection('users')
      .doc(userDoc.id)
      .collection('fcmTokens')
      .get();
    tokensSnap.docs.forEach((d) => {
      const t = d.data().token;
      if (t && typeof t === 'string') tokens.push(t);
    });
  }
  return tokens;
}

async function sendToAllDevices(
  messaging: admin.messaging.Messaging,
  tokens: string[],
  payload: Omit<admin.messaging.MulticastMessage, 'tokens'>
): Promise<{ success: number; failure: number }> {
  let success = 0;
  let failure = 0;
  for (let i = 0; i < tokens.length; i += BATCH) {
    const batch = tokens.slice(i, i + BATCH);
    const response = await messaging.sendEachForMulticast({ ...payload, tokens: batch });
    success += response.successCount;
    failure += response.failureCount;
  }
  return { success, failure };
}

const PUSH_NOT_CONFIGURED =
  'Push notifications are not configured. Add GOOGLE_APPLICATION_CREDENTIALS (path to service account JSON) or FIREBASE_SERVICE_ACCOUNT_JSON to .env to enable. Firebase Console → Project settings → Service accounts → Generate new private key.';

/**
 * POST /api/send-notification – send push to all registered devices.
 * Works with only NEXT_PUBLIC_* env vars; returns ok: false with a message if server credentials are missing.
 */
export async function POST() {
  try {
    const app = getAdminApp();
    const firestore = app.firestore();
    const messaging = app.messaging();

    const tokens = await getAllFcmTokens(firestore);
    if (tokens.length === 0) {
      return NextResponse.json({
        ok: true,
        message: 'No device tokens registered. Have users open the app while logged in.',
        sent: 0,
      });
    }

    const payload: Omit<admin.messaging.MulticastMessage, 'tokens'> = {
      notification: {
        title: 'Breaking',
        body: 'You have new articles to read.',
      },
      data: {
        title: 'Breaking',
        body: 'You have new articles to read.',
      },
      android: { priority: 'high' },
      apns: { payload: { aps: { sound: 'default' } } },
    };

    const { success, failure } = await sendToAllDevices(messaging, tokens, payload);
    return NextResponse.json({
      ok: true,
      message: `Sent to ${success} device(s).`,
      sent: success,
      failed: failure,
      totalTokens: tokens.length,
    });
  } catch (e) {
    console.error(e);
    const message = e instanceof Error ? e.message : String(e);
    const isMissingCreds =
      message.includes('Could not initialize Firebase Admin') ||
      message.includes('service account') ||
      message.includes('GOOGLE_APPLICATION_CREDENTIALS') ||
      message.includes('FIREBASE_SERVICE_ACCOUNT') ||
      message.includes('ENOENT') ||
      message.includes('no such file or directory') ||
      message.includes('does not exist');
    if (isMissingCreds) {
      return NextResponse.json({ ok: false, error: PUSH_NOT_CONFIGURED }, { status: 200 });
    }
    return NextResponse.json({ ok: false, error: message }, { status: 500 });
  }
}
