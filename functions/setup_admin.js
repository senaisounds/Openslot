const admin = require('firebase-admin');
const readline = require('readline');

// Initialize Firebase Admin SDK with project configuration
if (!admin.apps.length) {
  admin.initializeApp({
    projectId: 'open-mic-5cc8e', // Your Firebase project ID
  });
}

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

async function setupAdmin() {
  try {
    console.log('=== OpenSlot Admin Setup ===\n');
    
    // Predefined admin email for Senai
    const adminEmail = 'senai@openslot.me';
    
    console.log(`Setting up admin access for: ${adminEmail}`);
    
    // Find user by email
    let userRecord;
    try {
      userRecord = await admin.auth().getUserByEmail(adminEmail);
      console.log(`✓ Found user: ${userRecord.uid}`);
    } catch (error) {
      if (error.code === 'auth/user-not-found') {
        console.log(`✗ User with email ${adminEmail} not found.`);
        console.log('Please make sure the user has created an account first.');
        process.exit(1);
      } else {
        throw error;
      }
    }
    
    // Add user to admins collection
    const adminDoc = {
      email: adminEmail,
      uid: userRecord.uid,
      isAdmin: true,
      createdAt: admin.firestore.Timestamp.now(),
      permissions: {
        moderation: true,
        userManagement: true,
        eventManagement: true,
        systemConfig: true
      }
    };
    
    await admin.firestore()
      .collection('admins')
      .doc(userRecord.uid)
      .set(adminDoc);
    
    console.log(`✓ Successfully added ${adminEmail} as admin`);
    console.log(`  User ID: ${userRecord.uid}`);
    console.log(`  Permissions: Full admin access`);
    
    // Also set custom claims for user
    await admin.auth().setCustomUserClaims(userRecord.uid, { admin: true });
    console.log(`✓ Set custom claims for enhanced security`);
    
    console.log('\n=== Setup Complete ===');
    console.log('The user will need to sign out and sign back in for changes to take effect.');
    
  } catch (error) {
    console.error('Error setting up admin:', error);
  } finally {
    rl.close();
    process.exit(0);
  }
}

// Show admin list function
async function showAdmins() {
  try {
    console.log('=== Current Admins ===\n');
    
    const adminsSnapshot = await admin.firestore().collection('admins').get();
    
    if (adminsSnapshot.empty) {
      console.log('No admins found.');
      return;
    }
    
    adminsSnapshot.forEach(doc => {
      const data = doc.data();
      console.log(`• ${data.email} (${doc.id})`);
      console.log(`  Created: ${data.createdAt?.toDate?.() || 'Unknown'}`);
      console.log(`  Status: ${data.isAdmin ? 'Active' : 'Inactive'}`);
      console.log('');
    });
    
  } catch (error) {
    console.error('Error fetching admins:', error);
  }
}

// Main menu
function showMenu() {
  console.log('\n=== Admin Management ===');
  console.log('1. Setup Senai as admin');
  console.log('2. Show current admins');
  console.log('3. Exit');
  console.log('');
  
  rl.question('Choose option (1-3): ', (answer) => {
    switch (answer.trim()) {
      case '1':
        setupAdmin();
        break;
      case '2':
        showAdmins().then(() => showMenu());
        break;
      case '3':
        console.log('Goodbye!');
        rl.close();
        process.exit(0);
        break;
      default:
        console.log('Invalid option. Please choose 1-3.');
        showMenu();
        break;
    }
  });
}

// Start the program
showMenu();