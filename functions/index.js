const functions = require("firebase-functions");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");

admin.initializeApp();

const db = admin.firestore();

const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: "YOUR_EMAIL@gmail.com",
    pass: "qtpdqswboovcvwcn"
  }
});

// SEND OTP
exports.sendOTP = functions.https.onCall(async (data, context) => {

  const email = data.email;

  if (!email) {
    throw new functions.https.HttpsError("invalid-argument", "Email required");
  }

  const otp = Math.floor(100000 + Math.random() * 900000).toString();

  await db.collection("otp").doc(email).set({
    otp: otp,
    createdAt: Date.now()
  });

  await transporter.sendMail({
    from: "Focus Planner",
    to: email,
    subject: "Your OTP Code",
    text: `Your OTP code is ${otp}`
  });

  return { success: true };
});


// VERIFY OTP
exports.verifyOTP = functions.https.onCall(async (data, context) => {

  const email = data.email;
  const otp = data.otp;

  const doc = await db.collection("otp").doc(email).get();

  if (!doc.exists) {
    throw new functions.https.HttpsError("not-found", "OTP not found");
  }

  if (doc.data().otp !== otp) {
    throw new functions.https.HttpsError("invalid-argument", "Invalid OTP");
  }

  return { success: true };
});


// CHANGE PASSWORD
exports.changePassword = functions.https.onCall(async (data, context) => {

  const email = data.email;
  const password = data.password;

  const user = await admin.auth().getUserByEmail(email);

  await admin.auth().updateUser(user.uid, {
    password: password
  });

  return { success: true };
});