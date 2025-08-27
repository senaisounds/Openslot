// Simple script to add admin using existing Firebase function setup
const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Use existing Firebase setup from functions
admin.initializeApp();

async function addAdmin() {
  try {
    console.log('Adding Senai as admin...');
    
    // For now, let's create a simple admin document
    // We'll use a known pattern for the document ID
    const adminData = {
      email: 'senai@openslot.me',
      isAdmin: true,
      createdAt: admin.firestore.Timestamp.now(),
      permissions: {
        moderation: true,
        userManagement: true,
        eventManagement: true,
        systemConfig: true
      },
      note: 'Auto-created admin account'
    };
    
    // Use a predictable document ID
    const docId = 'admin_senai';
    
    await admin.firestore()
      .collection('admins')
      .doc(docId)
      .set(adminData);
    
    console.log('✓ Successfully created admin document for senai@openslot.me');
    console.log('Document ID:', docId);
    console.log('Admin data:', adminData);
    
    // Also try to find the user by email and set up properly
    try {
      const userRecord = await admin.auth().getUserByEmail('senai@openslot.me');
      console.log('✓ Found user account:', userRecord.uid);
      
      // Create proper admin document with user ID
      const properAdminData = {
        ...adminData,
        uid: userRecord.uid
      };
      
      await admin.firestore()
        .collection('admins')
        .doc(userRecord.uid)
        .set(properAdminData);
      
      console.log('✓ Created proper admin document with user ID:', userRecord.uid);
      
    } catch (userError) {
      console.log('Note: User account not found, but admin email is set up in the app code');
      console.log('Error:', userError.message);
    }
    
    process.exit(0);
    
  } catch (error) {
    console.error('Error creating admin:', error);
    process.exit(1);
  }
}

addAdmin();

