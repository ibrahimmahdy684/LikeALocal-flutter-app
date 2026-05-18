const admin = require("firebase-admin");
const serviceAccount = require("./serviceAccountKey.json");
const seedData = require("./seed-data.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function deleteCollection(collectionPath) {
  const snap = await db.collection(collectionPath).get();
  if (snap.empty) return;

  // Delete subcollections first for known nested collections
  const nested = {
    guideChats: ["messages"],
    places: ["reviews", "ratings", "comments"],
    cityChats: ["messages"],
  };

  for (const doc of snap.docs) {
    const subs = nested[collectionPath] || [];
    for (const sub of subs) {
      const subSnap = await doc.ref.collection(sub).get();
      const subBatch = db.batch();
      subSnap.docs.forEach((d) => subBatch.delete(d.ref));
      if (!subSnap.empty) await subBatch.commit();
    }
  }

  // Delete docs in batches of 500
  const batchSize = 500;
  for (let i = 0; i < snap.docs.length; i += batchSize) {
    const batch = db.batch();
    snap.docs.slice(i, i + batchSize).forEach((doc) => batch.delete(doc.ref));
    await batch.commit();
  }
  console.log(`Deleted ${collectionPath} (${snap.docs.length} docs)`);
}

async function clearAll() {
  console.log("\n--- CLEARING ALL DATA ---\n");
  const collections = [
    "places",
    "cities",
    "users",
    "notifications",
    "guideChats",
    "cityChats",
    "reminders",
    "meta",
  ];
  for (const col of collections) {
    await deleteCollection(col);
  }
  console.log("\nAll data cleared.\n");
}

async function deleteAuthUsers() {
  try {
    const listResult = await admin.auth().listUsers(1000);
    for (const user of listResult.users) {
      await admin.auth().deleteUser(user.uid);
      console.log(`Deleted auth user: ${user.email}`);
    }
  } catch (e) {
    console.log("Could not clear auth users:", e.message);
  }
}

async function seedAuthUsers() {
  for (const user of seedData.authUsers) {
    try {
      await admin.auth().createUser({
        uid: user.id,
        email: user.email,
        password: user.password,
        displayName: user.displayName,
      });
      console.log(`Created auth user: ${user.email}`);
    } catch (e) {
      console.log(`Skipped ${user.email}: ${e.message}`);
    }
  }
}

async function seedCollection(name, items) {
  const batchSize = 500;
  for (let i = 0; i < items.length; i += batchSize) {
    const batch = db.batch();
    items.slice(i, i + batchSize).forEach((item) => {
      const ref = db.collection(name).doc(item.id);
      batch.set(ref, item);
    });
    await batch.commit();
  }
  console.log(`Seeded ${name} (${items.length} docs)`);
}

async function run() {
  await clearAll();
  await deleteAuthUsers();

  console.log("\n--- SEEDING FRESH DATA ---\n");

  await seedAuthUsers();
  await db.collection("meta").doc("seed").set(seedData.meta.seed);
  await seedCollection("users", seedData.users);
  await seedCollection("cities", seedData.cities);
  await seedCollection("places", seedData.places);
  await seedCollection("notifications", seedData.notifications);

  console.log("\nDONE! Seeded successfully.\n");
  process.exit(0);
}

run();
