#!/usr/bin/env node

/**
 * Cleanup Invalid Stripe Customer IDs
 * 
 * This script finds and removes invalid Stripe customer IDs from Firestore.
 * Run this before deploying the customer creation function to clean up existing data.
 * 
 * Usage:
 *   node scripts/cleanup_invalid_customers.js [--dry-run] [--all]
 * 
 * Options:
 *   --dry-run    Show what would be changed without actually changing it
 *   --all        Clean up all users (default: only users with invalid IDs)
 */

const admin = require('firebase-admin');
const Stripe = require('stripe');

// Initialize Firebase Admin
if (!admin.apps.length) {
  try {
    // Try to use default credentials
    admin.initializeApp();
    console.log('✅ Firebase Admin initialized with default credentials');
  } catch (error) {
    console.error('❌ Failed to initialize Firebase Admin');
    console.error('Make sure you have GOOGLE_APPLICATION_CREDENTIALS set or run:');
    console.error('  firebase login');
    console.error('  export GOOGLE_APPLICATION_CREDENTIALS="path/to/serviceAccountKey.json"');
    process.exit(1);
  }
}

const db = admin.firestore();

// Parse command line arguments
const args = process.argv.slice(2);
const dryRun = args.includes('--dry-run');
const cleanAll = args.includes('--all');

console.log('🧹 Stripe Customer ID Cleanup');
console.log('=============================');
console.log('');
console.log(`Mode: ${dryRun ? '🔍 DRY RUN (no changes)' : '✍️  WRITE (making changes)'}`);
console.log(`Scope: ${cleanAll ? '🌐 All users' : '🎯 Only invalid IDs'}`);
console.log('');

// Function to check if customer exists in Stripe
async function isValidCustomer(customerId, stripe) {
  if (!customerId || typeof customerId !== 'string') {
    return false;
  }
  
  if (!customerId.startsWith('cus_')) {
    return false;
  }
  
  try {
    const customer = await stripe.customers.retrieve(customerId);
    return !customer.deleted;
  } catch (error) {
    if (error.code === 'resource_missing') {
      return false;
    }
    console.warn(`⚠️  Error checking customer ${customerId}:`, error.message);
    return false;
  }
}

// Main cleanup function
async function cleanupCustomers() {
  try {
    // Get all users
    console.log('📥 Fetching users from Firestore...');
    const usersSnapshot = await db.collection('users').get();
    console.log(`Found ${usersSnapshot.size} users`);
    console.log('');
    
    // Initialize Stripe (using test key for validation)
    const stripeTestKey = process.env.STRIPE_TEST_KEY;
    const stripeLiveKey = process.env.STRIPE_LIVE_KEY;
    
    let stripeTest, stripeLive;
    
    if (stripeTestKey) {
      stripeTest = new Stripe(stripeTestKey);
      console.log('✅ Stripe test API initialized');
    } else {
      console.warn('⚠️  STRIPE_TEST_KEY not set, skipping test customer validation');
    }
    
    if (stripeLiveKey) {
      stripeLive = new Stripe(stripeLiveKey);
      console.log('✅ Stripe live API initialized');
    } else {
      console.warn('⚠️  STRIPE_LIVE_KEY not set, skipping live customer validation');
    }
    console.log('');
    
    let processedCount = 0;
    let invalidTestCount = 0;
    let invalidLiveCount = 0;
    let cleanedCount = 0;
    
    // Process each user
    for (const doc of usersSnapshot.docs) {
      const userData = doc.data();
      const userId = doc.id;
      processedCount++;
      
      let needsUpdate = false;
      const updates = {};
      
      // Check test customer ID
      if (userData['test-customerID']) {
        const testCustomerId = userData['test-customerID'];
        console.log(`[${processedCount}/${usersSnapshot.size}] Checking user ${userId}`);
        console.log(`  Test Customer ID: ${testCustomerId}`);
        
        if (stripeTest) {
          const isValid = await isValidCustomer(testCustomerId, stripeTest);
          if (!isValid) {
            console.log(`  ❌ Invalid test customer ID: ${testCustomerId}`);
            invalidTestCount++;
            needsUpdate = true;
            updates['test-customerID'] = admin.firestore.FieldValue.delete();
            if (userData['test-customerID_created']) {
              updates['test-customerID_created'] = admin.firestore.FieldValue.delete();
            }
          } else {
            console.log(`  ✅ Valid test customer ID`);
          }
        }
      }
      
      // Check live customer ID
      if (userData.customerID) {
        const liveCustomerId = userData.customerID;
        if (!userData['test-customerID']) {
          console.log(`[${processedCount}/${usersSnapshot.size}] Checking user ${userId}`);
        }
        console.log(`  Live Customer ID: ${liveCustomerId}`);
        
        if (stripeLive) {
          const isValid = await isValidCustomer(liveCustomerId, stripeLive);
          if (!isValid) {
            console.log(`  ❌ Invalid live customer ID: ${liveCustomerId}`);
            invalidLiveCount++;
            needsUpdate = true;
            updates.customerID = admin.firestore.FieldValue.delete();
            if (userData.customerID_created) {
              updates.customerID_created = admin.firestore.FieldValue.delete();
            }
          } else {
            console.log(`  ✅ Valid live customer ID`);
          }
        }
      }
      
      // Apply updates
      if (needsUpdate) {
        if (dryRun) {
          console.log(`  🔍 DRY RUN: Would delete invalid customer IDs`);
        } else {
          await doc.ref.update(updates);
          console.log(`  ✅ Cleaned up invalid customer IDs`);
          cleanedCount++;
        }
      }
      
      console.log('');
    }
    
    // Summary
    console.log('=============================');
    console.log('✨ Cleanup Complete!');
    console.log('=============================');
    console.log(`Users processed: ${processedCount}`);
    console.log(`Invalid test customer IDs found: ${invalidTestCount}`);
    console.log(`Invalid live customer IDs found: ${invalidLiveCount}`);
    
    if (dryRun) {
      console.log(`Would clean up: ${invalidTestCount + invalidLiveCount} invalid IDs`);
      console.log('');
      console.log('Run without --dry-run to apply changes:');
      console.log('  node scripts/cleanup_invalid_customers.js');
    } else {
      console.log(`Cleaned up: ${cleanedCount} users`);
    }
    console.log('');
    
  } catch (error) {
    console.error('❌ Error during cleanup:', error);
    process.exit(1);
  }
}

// Run the cleanup
cleanupCustomers()
  .then(() => {
    console.log('Done! 🎉');
    process.exit(0);
  })
  .catch((error) => {
    console.error('Fatal error:', error);
    process.exit(1);
  });

