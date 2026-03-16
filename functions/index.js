const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

/**
 * Send a test push notification to all app users subscribed to "news" topic.
 * Call from web/admin or: curl -X POST <url>
 * Requires Firebase Auth or add a secret for production.
 */
exports.sendTestNotification = functions.https.onRequest(async (req, res) => {
  try {
    const message = {
      notification: {
        title: 'Breaking',
        body: 'You have new articles to read.',
      },
      data: {
        title: 'Breaking',
        body: 'You have new articles to read.',
      },
      topic: 'news',
    };
    await admin.messaging().send(message);
    res.status(200).json({ ok: true, message: 'Test notification sent to topic "news".' });
  } catch (e) {
    res.status(500).json({ error: String(e.message) });
  }
});
