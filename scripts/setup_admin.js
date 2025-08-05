const admin = require('firebase-admin');

// Initialize Firebase Admin
if (!admin.apps.length) {
  admin.initializeApp({
    projectId: 'open-mic-5cc8e'
  });
}

const db = admin.firestore();

async function setupAdmin() {
  try {
    // Your user ID from the export
    const userId = '0reLhlRongbxIVMSmy7bsr3pay83';
    
    // Create admin document
    await db.collection('admins').doc(userId).set({
      isAdmin: true,
      createdAt: new Date().toISOString(),
      createdBy: 'setup_script'
    });
    
    console.log('✅ Admin access set up successfully!');
    console.log(`User ID: ${userId}`);
    console.log('You can now access the admin panel in the app.');
    
  } catch (error) {
    console.error('❌ Error setting up admin:', error);
  }
}

setupAdmin(); 