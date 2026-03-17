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
    return admin.initializeApp({ credential: admin.credential.cert(keyPath) });
  }
  const cwd = process.cwd();
  const candidates = [
    path.join(cwd, ROOT_GOOGLE_SERVICES),
    path.join(cwd, '..', ROOT_GOOGLE_SERVICES),
    path.join(cwd, MOBILE_SERVICE_JSON),
    path.join(cwd, '..', MOBILE_SERVICE_JSON),
  ];
  for (const filePath of candidates) {
    try {
      if (fs.existsSync(filePath)) {
        const parsed = JSON.parse(fs.readFileSync(filePath, 'utf8')) as unknown;
        if (!isServiceAccountKey(parsed)) {
          const p = parsed as Record<string, unknown>;
          if (p.project_info != null || p.client != null) {
            throw new Error(
              'google-services.json is the Android client config. For sending notifications, use a service account key: Firebase Console → Project settings → Service accounts → Generate new private key. Save that JSON as mobile_app/service.json or set FIREBASE_SERVICE_ACCOUNT_JSON.'
            );
          }
          continue;
        }
        return admin.initializeApp({ credential: admin.credential.cert(parsed) });
      }
    } catch (e) {
      if (e instanceof Error && e.message.includes('google-services.json is the Android')) throw e;
      // skip invalid or unreadable file
    }
  }
  throw new Error(
    'Set FIREBASE_SERVICE_ACCOUNT_JSON or GOOGLE_APPLICATION_CREDENTIALS in .env.local, or add a Firebase service account JSON (not google-services.json) at mobile_app/service.json (Project settings → Service accounts → Generate new key).'
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

/**
 * POST /api/send-notification – send push to all registered devices.
 * Uses FIREBASE_SERVICE_ACCOUNT_JSON (no Cloud Functions / Blaze needed).
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
    const message = e instanceof Error ? e.message : String(e);
    return NextResponse.json({ ok: false, error: message }, { status: 500 });
  }
}
