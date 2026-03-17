/**
 * Sends push notification to all devices via the local API route.
 * No Cloud Functions or Blaze plan needed – uses FIREBASE_SERVICE_ACCOUNT_JSON in admin-web.
 */
export type SendNotificationResult = {
  ok: boolean;
  error?: string;
  message?: string;
};

export async function sendPushNotification(): Promise<SendNotificationResult> {
  try {
    const res = await fetch('/api/send-notification', { method: 'POST' });
    const contentType = res.headers.get('content-type') ?? '';
    let data: { ok?: boolean; error?: string; message?: string } = {};
    if (contentType.includes('application/json')) {
      data = (await res.json()) as { ok?: boolean; error?: string; message?: string };
    }
    if (!res.ok) {
      return {
        ok: false,
        error: data.error ?? data.message ?? `HTTP ${res.status}`,
      };
    }
    return { ok: data.ok ?? true, message: data.message };
  } catch (e) {
    return {
      ok: false,
      error: e instanceof Error ? e.message : 'Request failed',
    };
  }
}
