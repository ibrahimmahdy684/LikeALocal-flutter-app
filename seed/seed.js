const admin = require("firebase-admin");
const serviceAccount = require("./serviceAccountKey.json");
const seedData = require("./seed-data.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

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
      console.log(`Skipped ${user.email}`);
    }
  }
}

async function seedCollection(name, items) {
  const batch = db.batch();

  items.forEach((item) => {
    const ref = db.collection(name).doc(item.id);

    batch.set(ref, item);
  });

  await batch.commit();

  console.log(`Seeded ${name}`);
}

async function run() {
  await seedAuthUsers();

  await db.collection("meta").doc("seed").set(seedData.meta.seed);

  await seedCollection("users", seedData.users);
  await seedCollection("cities", seedData.cities);
  await seedCollection("places", seedData.places);
  await seedCollection("notifications", seedData.notifications);

  console.log("DONE");
}

run();