const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.sendNotificationOnCreate = functions.firestore
  .document("users/{userId}/notifications/{notificationId}")
  .onCreate(async (snap, context) => {
    try {
      const data = snap.data();
      const userId = context.params.userId;

      console.log("New notification:", data);

      // ดึง token
      const userDoc = await admin.firestore()
        .doc(`users/${userId}`)
        .get();

      const fcmToken = userDoc.data()?.fcmToken;

      if (!fcmToken) {
        console.log("No FCM token found");
        return null;
      }

      // ส่ง notification
      const message = {
        token: fcmToken,
        notification: {
          title: data.title || "New Notification",
          body: data.message || "",
        },
      };

      await admin.messaging().send(message);

      console.log("Notification sent!");
      return null;

    } catch (error) {
      console.error("Error:", error);
      return null;
    }
  });