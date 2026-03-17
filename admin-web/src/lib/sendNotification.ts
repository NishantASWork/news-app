import appConfig from '../../firebase-app-config.json';

const region = process.env.NEXT_PUBLIC_FIREBASE_FUNCTIONS_REGION ?? 'us-central1';
const projectId = process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID ?? appConfig.projectId;

export const sendTestNotificationUrl =
  process.env.NEXT_PUBLIC_SEND_NOTIFICATION_URL ??
  `https://${region}-${projectId}.cloudfunctions.net/sendTestNotification`;

export type SendNotificationResult = {
  ok: boolean;
  error?: string;
  message?: string;
};

export async function sendPushNotification(): Promise<SendNotificationResult> {
  try {
    const res = await fetch(sendTestNotificationUrl, { method: 'POST' });
    const contentType = res.headers.get('content-type') ?? '';
    let data: { ok?: boolean; error?: string; message?: string } = {};
    if (contentType.includes('application/json')) {
      data = (await res.json()) as { ok?: boolean; error?: string; message?: string };
    }
    if (!res.ok) {
      if (res.status === 404) {
        return {
          ok: false,
          error: 'Function not found. Deploy with: firebase deploy --only functions',
        };
      }
      return {
        ok: false,
        error: data.error ?? data.message ?? `HTTP ${res.status}`,
      };
    }
    return { ok: data.ok ?? true, message: data.message };
  } catch (e) {
    const msg = e instanceof Error ? e.message : 'Request failed';
    if (msg.includes('CORS') || msg.includes('Failed to fetch')) {
      return {
        ok: false,
        error: 'Request blocked (CORS or network). Deploy the updated function: firebase deploy --only functions',
      };
    }
    return { ok: false, error: msg };
  }
}
