const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

const firestore = admin.firestore();

/** CORS headers so the admin app (e.g. localhost:3000) can call this function. */
function setCors(res) {
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  res.set('Access-Control-Max-Age', '86400');
}

/** Collect all FCM tokens from users/{uid}/fcmTokens (each doc has .token). */
async function getAllFcmTokens() {
  const tokens = [];
  const usersSnap = await firestore.collection('users').get();
  for (const userDoc of usersSnap.docs) {
    const tokensSnap = await firestore
      .collection('users')
      .doc(userDoc.id)
      .collection('fcmTokens')
      .get();
    tokensSnap.docs.forEach((doc) => {
      const t = doc.data().token;
      if (t && typeof t === 'string') tokens.push(t);
    });
  }
  return tokens;
}

/** Send to batches of 500 (FCM multicast limit). */
async function sendToAllDevices(tokens, payload) {
  const BATCH = 500;
  let success = 0;
  let failure = 0;
  for (let i = 0; i < tokens.length; i += BATCH) {
    const batch = tokens.slice(i, i + BATCH);
    const msg = {
      ...payload,
      tokens: batch,
    };
    const response = await admin.messaging().sendEachForMulticast(msg);
    success += response.successCount;
    failure += response.failureCount;
  }
  return { success, failure };
}

/**
 * Send a test push notification to all devices that have registered FCM tokens
 * (users must be logged in on the app at least once so their token is saved).
 * Call from web/admin or: curl -X POST <url>
 */
exports.sendTestNotification = functions.https.onRequest(async (req, res) => {
  setCors(res);

  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }

  try {
    const tokens = await getAllFcmTokens();
    if (tokens.length === 0) {
      res.status(200).json({
        ok: true,
        message: 'No device tokens registered. Have users open the app while logged in.',
        sent: 0,
      });
      return;
    }

    const payload = {
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

    const { success, failure } = await sendToAllDevices(tokens, payload);
    res.status(200).json({
      ok: true,
      message: `Sent to ${success} device(s).`,
      sent: success,
      failed: failure,
      totalTokens: tokens.length,
    });
  } catch (e) {
    res.status(500).json({ error: String(e.message) });
  }
});
