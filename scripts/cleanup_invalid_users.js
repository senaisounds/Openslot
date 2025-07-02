/**
 * Firebase Cloud Functions script to clean up invalid user references in events
 * Run this in Firebase Console or deploy as a Cloud Function
 */

const admin = require('firebase-admin');

// Initialize Firebase Admin (if not already initialized)
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

/**
 * Identify invalid user IDs based on patterns
 */
function isInvalidUserId(userId) {
  if (!userId || typeof userId !== 'string') return true;
  
  // List of obviously invalid/test user IDs from your logs
  const suspiciousIds = [
    'hi', 'he', 'gg', 'test', 'demo', 'null', 'undefined',
    'dame', 'bbc', 'kyle', 'james', 'heee', 'eric',
    'gerry\'s', 'gerrys', 'admin', 'root', 'user'
  ];
  
  if (suspiciousIds.includes(userId.toLowerCase())) return true;
  if (userId.length === 1) return true;
  if (userId.length < 4 && userId.toLowerCase() === userId && !userId.includes('_')) return true;
  
  return false;
}

/**
 * Check if user actually exists in users collection
 */
async function userExists(userId) {
  try {
    const userDoc = await db.collection('users').doc(userId).get();
    return userDoc.exists;
  } catch (error) {
    console.error(`Error checking user ${userId}:`, error);
    return false;
  }
}

/**
 * Clean invalid users from a single event
 */
async function cleanEvent(eventId, eventData) {
  let hasChanges = false;
  const updates = {};
  
  console.log(`\n🔍 Checking event: ${eventId}`);
  
  // Check host
  if (eventData.host && isInvalidUserId(eventData.host)) {
    console.log(`  ❌ Invalid host: ${eventData.host}`);
    updates.host = '';
    hasChanges = true;
  } else if (eventData.host && !(await userExists(eventData.host))) {
    console.log(`  ❌ Non-existent host: ${eventData.host}`);
    updates.host = '';
    hasChanges = true;
  }
  
  // Check performer
  if (eventData.performer && isInvalidUserId(eventData.performer)) {
    console.log(`  ❌ Invalid performer: ${eventData.performer}`);
    updates.performer = null;
    hasChanges = true;
  } else if (eventData.performer && !(await userExists(eventData.performer))) {
    console.log(`  ❌ Non-existent performer: ${eventData.performer}`);
    updates.performer = null;
    hasChanges = true;
  }
  
  // Check upNext
  if (eventData.upNext && isInvalidUserId(eventData.upNext)) {
    console.log(`  ❌ Invalid upNext: ${eventData.upNext}`);
    updates.upNext = null;
    hasChanges = true;
  } else if (eventData.upNext && !(await userExists(eventData.upNext))) {
    console.log(`  ❌ Non-existent upNext: ${eventData.upNext}`);
    updates.upNext = null;
    hasChanges = true;
  }
  
  // Check attendees
  if (eventData.attendees && Array.isArray(eventData.attendees)) {
    const validAttendees = [];
    let removedCount = 0;
    
    for (const userId of eventData.attendees) {
      if (isInvalidUserId(userId)) {
        console.log(`  ❌ Invalid attendee: ${userId}`);
        removedCount++;
      } else if (!(await userExists(userId))) {
        console.log(`  ❌ Non-existent attendee: ${userId}`);
        removedCount++;
      } else {
        validAttendees.push(userId);
      }
    }
    
    if (removedCount > 0) {
      console.log(`  🧹 Removed ${removedCount} invalid attendees (${eventData.attendees.length} → ${validAttendees.length})`);
      updates.attendees = validAttendees;
      hasChanges = true;
    }
  }
  
  // Check waitlist
  if (eventData.waitlist && Array.isArray(eventData.waitlist)) {
    const validWaitlist = [];
    let removedCount = 0;
    
    for (const userId of eventData.waitlist) {
      if (isInvalidUserId(userId)) {
        console.log(`  ❌ Invalid waitlist user: ${userId}`);
        removedCount++;
      } else if (!(await userExists(userId))) {
        console.log(`  ❌ Non-existent waitlist user: ${userId}`);
        removedCount++;
      } else {
        validWaitlist.push(userId);
      }
    }
    
    if (removedCount > 0) {
      console.log(`  🧹 Removed ${removedCount} invalid waitlist users (${eventData.waitlist.length} → ${validWaitlist.length})`);
      updates.waitlist = validWaitlist;
      hasChanges = true;
    }
  }
  
  // Apply updates if there are changes
  if (hasChanges) {
    try {
      await db.collection('events').doc(eventId).update(updates);
      console.log(`  ✅ Updated event ${eventId}`);
      return { updated: true, changes: Object.keys(updates).length };
    } catch (error) {
      console.error(`  ❌ Failed to update event ${eventId}:`, error);
      return { updated: false, error: error.message };
    }
  }
  
  console.log(`  ✅ Event ${eventId} is clean`);
  return { updated: false, changes: 0 };
}

/**
 * Main cleanup function
 */
async function cleanupInvalidUsers(dryRun = true) {
  console.log('🚀 Starting user cleanup process...');
  console.log(`📋 Mode: ${dryRun ? 'DRY RUN (no changes will be made)' : 'LIVE (changes will be applied)'}`);
  
  let totalEvents = 0;
  let eventsUpdated = 0;
  let totalChanges = 0;
  
  try {
    // Get all events
    const eventsSnapshot = await db.collection('events').get();
    totalEvents = eventsSnapshot.size;
    
    console.log(`\n📊 Found ${totalEvents} events to check`);
    
    // Process each event
    for (const doc of eventsSnapshot.docs) {
      const eventId = doc.id;
      const eventData = doc.data();
      
      if (!dryRun) {
        const result = await cleanEvent(eventId, eventData);
        if (result.updated) {
          eventsUpdated++;
          totalChanges += result.changes;
        }
      } else {
        // Dry run - just log what would be changed
        console.log(`\n🔍 [DRY RUN] Would check event: ${eventId}`);
        
        const issues = [];
        if (eventData.host && (isInvalidUserId(eventData.host) || !(await userExists(eventData.host)))) {
          issues.push(`host: ${eventData.host}`);
        }
        if (eventData.performer && (isInvalidUserId(eventData.performer) || !(await userExists(eventData.performer)))) {
          issues.push(`performer: ${eventData.performer}`);
        }
        if (eventData.upNext && (isInvalidUserId(eventData.upNext) || !(await userExists(eventData.upNext)))) {
          issues.push(`upNext: ${eventData.upNext}`);
        }
        
        if (eventData.attendees) {
          const invalidAttendees = [];
          for (const userId of eventData.attendees) {
            if (isInvalidUserId(userId) || !(await userExists(userId))) {
              invalidAttendees.push(userId);
            }
          }
          if (invalidAttendees.length > 0) {
            issues.push(`${invalidAttendees.length} invalid attendees: ${invalidAttendees.join(', ')}`);
          }
        }
        
        if (eventData.waitlist) {
          const invalidWaitlist = [];
          for (const userId of eventData.waitlist) {
            if (isInvalidUserId(userId) || !(await userExists(userId))) {
              invalidWaitlist.push(userId);
            }
          }
          if (invalidWaitlist.length > 0) {
            issues.push(`${invalidWaitlist.length} invalid waitlist: ${invalidWaitlist.join(', ')}`);
          }
        }
        
        if (issues.length > 0) {
          console.log(`  ❌ Would fix: ${issues.join(', ')}`);
          eventsUpdated++;
        } else {
          console.log(`  ✅ Event is clean`);
        }
      }
    }
    
    console.log('\n📊 CLEANUP SUMMARY');
    console.log('================');
    console.log(`📋 Total events checked: ${totalEvents}`);
    console.log(`🧹 Events ${dryRun ? 'that would be' : ''} updated: ${eventsUpdated}`);
    console.log(`🔧 Total changes ${dryRun ? 'that would be' : ''} made: ${totalChanges}`);
    
    if (dryRun) {
      console.log('\n💡 To apply changes, run with dryRun = false');
    } else {
      console.log('\n✅ Cleanup completed successfully!');
    }
    
  } catch (error) {
    console.error('❌ Error during cleanup:', error);
  }
}

/**
 * Export the function for Cloud Functions deployment
 */
exports.cleanupInvalidUsers = cleanupInvalidUsers;

/**
 * Run directly if this script is executed
 * Usage: node cleanup_invalid_users.js [--live]
 */
if (require.main === module) {
  const dryRun = !process.argv.includes('--live');
  cleanupInvalidUsers(dryRun)
    .then(() => process.exit(0))
    .catch((error) => {
      console.error('Script failed:', error);
      process.exit(1);
    });
} 