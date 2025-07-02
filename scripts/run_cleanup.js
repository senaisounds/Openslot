/**
 * Simple script to clean up invalid user data in OpenSlot database
 * This will remove all the users like "GG", "HE", "HEEE" etc. that appear with question marks
 */

const admin = require('firebase-admin');

// Initialize Firebase Admin
const serviceAccount = require('./firebase-admin-key.json'); // You'll need to add your service account key
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

/**
 * Clean up all invalid user references
 */
async function cleanupInvalidUsers() {
  console.log('🚀 Starting cleanup of invalid users...');
  
  try {
    const eventsSnapshot = await db.collection('events').get();
    let updatedCount = 0;
    
    const invalidUsers = [
      'hi', 'he', 'gg', 'heee', 'rr', 'rrr', 'me', 'you', 'nice',
      'kyle', 'james', 'gerry\'s', 'gerrys', 'dame', 'bbc'
    ];
    
    for (const doc of eventsSnapshot.docs) {
      const eventData = doc.data();
      const updates = {};
      let hasChanges = false;
      
      // Clean performer field
      if (eventData.performer && invalidUsers.includes(eventData.performer.toLowerCase())) {
        updates.performer = null;
        hasChanges = true;
        console.log(`Removing invalid performer: ${eventData.performer}`);
      }
      
      // Clean upNext field  
      if (eventData.upNext && invalidUsers.includes(eventData.upNext.toLowerCase())) {
        updates.upNext = null;
        hasChanges = true;
        console.log(`Removing invalid upNext: ${eventData.upNext}`);
      }
      
      // Clean attendees array
      if (eventData.attendees && Array.isArray(eventData.attendees)) {
        const validAttendees = eventData.attendees.filter(
          userId => !invalidUsers.includes(userId.toLowerCase())
        );
        if (validAttendees.length !== eventData.attendees.length) {
          updates.attendees = validAttendees;
          hasChanges = true;
          console.log(`Cleaned attendees: ${eventData.attendees.length} → ${validAttendees.length}`);
        }
      }
      
      // Clean waitlist array
      if (eventData.waitlist && Array.isArray(eventData.waitlist)) {
        const validWaitlist = eventData.waitlist.filter(
          userId => !invalidUsers.includes(userId.toLowerCase())
        );
        if (validWaitlist.length !== eventData.waitlist.length) {
          updates.waitlist = validWaitlist;
          hasChanges = true;
          console.log(`Cleaned waitlist: ${eventData.waitlist.length} → ${validWaitlist.length}`);
        }
      }
      
      // Apply updates
      if (hasChanges) {
        await doc.ref.update(updates);
        updatedCount++;
        console.log(`✅ Updated event: ${doc.id}`);
      }
    }
    
    console.log(`\n🎉 Cleanup complete! Updated ${updatedCount} events`);
    console.log('🚀 Your live page will now show only valid users!');
    
  } catch (error) {
    console.error('❌ Cleanup failed:', error);
  }
  
  process.exit(0);
}

// Run the cleanup
cleanupInvalidUsers(); 