const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();

/**
 * Sends a push notification when a new document is created in the
 * 'notifications' collection. Looks up the recipient's FCM token
 * from their user document.
 */
exports.sendPushOnNotification = onDocumentCreated(
  "notifications/{notificationId}",
  async (event) => {
    const notification = event.data.data();
    if (!notification) return;

    const userId = notification.userId;
    if (!userId) return;

    // Get the recipient's FCM token
    const userDoc = await getFirestore()
      .collection("users")
      .doc(userId)
      .get();

    if (!userDoc.exists) return;
    const fcmToken = userDoc.data().fcmToken;
    if (!fcmToken) return;

    // Build the push message
    const title = notification.title || "LikeALocal";
    const body = notification.message || "You have a new notification";
    const type = notification.type || "general";

    const message = {
      token: fcmToken,
      notification: {
        title: title,
        body: body,
      },
      data: {
        type: type,
        notificationId: event.params.notificationId,
      },
      android: {
        priority: "high",
        notification: {
          channelId: "likealocal_default",
          priority: "high",
        },
      },
      apns: {
        payload: {
          aps: {
            badge: 1,
            sound: "default",
          },
        },
      },
    };

    try {
      await getMessaging().send(message);
      console.log(`Push sent to ${userId} for notification ${event.params.notificationId}`);
    } catch (error) {
      // Token may be invalid (user uninstalled app)
      if (
        error.code === "messaging/invalid-registration-token" ||
        error.code === "messaging/registration-token-not-registered"
      ) {
        // Remove stale token
        await getFirestore().collection("users").doc(userId).update({
          fcmToken: null,
        });
        console.log(`Removed stale FCM token for ${userId}`);
      } else {
        console.error("Push send error:", error);
      }
    }
  }
);

/**
 * Sends a push notification when a new chat message is sent.
 * Triggered on guideChats/{chatId}/messages/{messageId} creation.
 */
exports.sendPushOnChatMessage = onDocumentCreated(
  "guideChats/{chatId}/messages/{messageId}",
  async (event) => {
    const message = event.data.data();
    if (!message) return;

    const chatId = event.params.chatId;
    const senderId = message.senderId;
    const senderName = message.senderName || "Someone";
    const text = message.text || "";

    // Determine the recipient from the chat ID (format: id1_id2)
    const ids = chatId.split("_");
    const recipientId = ids.find((id) => id !== senderId);
    if (!recipientId) return;

    // Get recipient's FCM token
    const userDoc = await getFirestore()
      .collection("users")
      .doc(recipientId)
      .get();

    if (!userDoc.exists) return;
    const fcmToken = userDoc.data().fcmToken;
    if (!fcmToken) return;

    const preview = text.length > 100 ? text.substring(0, 100) + "..." : text;

    const pushMessage = {
      token: fcmToken,
      notification: {
        title: `${senderName} sent you a message`,
        body: preview,
      },
      data: {
        type: "message",
        chatId: chatId,
        senderId: senderId,
      },
      android: {
        priority: "high",
        notification: {
          channelId: "likealocal_default",
          priority: "high",
        },
      },
      apns: {
        payload: {
          aps: {
            badge: 1,
            sound: "default",
          },
        },
      },
    };

    try {
      await getMessaging().send(pushMessage);
      console.log(`Chat push sent to ${recipientId} from ${senderName}`);
    } catch (error) {
      if (
        error.code === "messaging/invalid-registration-token" ||
        error.code === "messaging/registration-token-not-registered"
      ) {
        await getFirestore().collection("users").doc(recipientId).update({
          fcmToken: null,
        });
      } else {
        console.error("Chat push error:", error);
      }
    }
  }
);
