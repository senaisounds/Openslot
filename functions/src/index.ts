import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import Stripe from 'stripe';

// Initialize Firebase Admin if not already initialized
if (!admin.apps.length) {
  admin.initializeApp();
}

// Stripe keys from environment variables
const stripeTestKey = functions.config().stripe?.test_key || process.env.STRIPE_TEST_KEY;
const stripeLiveKey = functions.config().stripe?.live_key || process.env.STRIPE_LIVE_KEY;

if (!stripeTestKey || !stripeLiveKey) {
  throw new Error('Stripe keys not configured. Please set stripe.test_key and stripe.live_key in Firebase config.');
}

const stripeTest = new Stripe(stripeTestKey);
const stripeLive = new Stripe(stripeLiveKey);

export const verifyEventPassword = functions.https.onRequest(async (req, res) => {
  try {
    console.log('Received password verification request:', { eventID: req.body.eventID });
    
    // Validate request method
    if (req.method !== 'POST') {
      console.error('Invalid method:', req.method);
      res.status(405).send({ error: 'Method not allowed' });
      return;
    }

    // Validate required parameters
    const { eventID, password } = req.body;
    if (!eventID || !password) {
      console.error('Missing parameters:', { eventID: !!eventID, password: !!password });
      res.status(400).send({ error: 'Missing required parameters' });
      return;
    }

    // Get event document
    const eventDoc = await admin.firestore().collection('events').doc(eventID).get();
    if (!eventDoc.exists) {
      console.error('Event not found:', eventID);
      res.status(404).send({ error: 'Event not found' });
      return;
    }

    const eventData = eventDoc.data();
    if (!eventData) {
      console.error('Event data is missing:', eventID);
      res.status(500).send({ error: 'Event data is missing' });
      return;
    }

    console.log('Event data retrieved:', { 
      eventID, 
      isPrivate: eventData.isPrivate,
      hasPassword: !!eventData.password
      // Passwords intentionally not logged for security
    });

    // Check if event is private
    if (!eventData.isPrivate) {
      console.error('Event is not private:', eventID);
      res.status(400).send({ error: 'Event is not private' });
      return;
    }

    // Verify password
    if (!eventData.password) {
      console.error('Event has no password set:', eventID);
      res.status(500).send({ error: 'Event has no password set' });
      return;
    }

    // Compare passwords (both should be URL-encoded)
    const decodedReceivedPassword = decodeURIComponent(password);
    const encodedStoredPassword = encodeURIComponent(eventData.password);
    const encodedReceivedPassword = encodeURIComponent(decodedReceivedPassword);
    
    if (encodedStoredPassword !== encodedReceivedPassword) {
      console.error('Invalid password provided for event:', {
        eventID,
        storedPassword: eventData.password,
        receivedPassword: decodedReceivedPassword,
        encodedStoredPassword,
        encodedReceivedPassword
      });
      res.status(401).send({ error: 'Invalid password' });
      return;
    }

    // Password is correct
    console.log('Password verification successful:', eventID);
    res.status(200).send({ success: true });
  } catch (error) {
    console.error('Error verifying event password:', error);
    res.status(500).send({ error: 'Internal server error' });
  }
});

export const reserveAction = functions.https.onRequest(async (req, res) => {
  // Enhanced CORS headers for better browser compatibility
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-OpenSlot-Client, X-Requested-With');
  res.set('Access-Control-Max-Age', '3600');
  
  // Handle preflight requests (OPTIONS)
  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }

  try {
    // Start timing the request for performance monitoring
    const startTime = Date.now();
    
    // Validate request method
    if (req.method !== 'POST') {
      res.status(405).json({ error: 'Method not allowed', details: 'Only POST requests are accepted' });
      return;
    }

    // Log request details for debugging
    const requestDetails = {
      body: req.body,
      headers: req.headers,
      method: req.method,
      path: req.path,
      url: req.url,
      ip: req.ip,
      timestamp: new Date().toISOString()
    };
    console.log('Reservation request received:', requestDetails);

    // Validate required parameters
    const { eventID, userID, passwordVerified } = req.body;
    if (!eventID || !userID) {
      res.status(400).json({ 
        error: 'Missing required parameters',
        details: `Missing: ${!eventID ? 'eventID' : ''} ${!userID ? 'userID' : ''}`.trim()
      });
      return;
    }

    // Get event document with retries
    let eventDoc = null;
    let retryCount = 0;
    const maxRetries = 3;
    
    while (retryCount < maxRetries) {
      try {
        eventDoc = await admin.firestore().collection('events').doc(eventID).get();
        break; // If successful, exit the retry loop
      } catch (dbError) {
        console.error(`Database fetch error (attempt ${retryCount + 1}/${maxRetries}):`, dbError);
        retryCount++;
        if (retryCount >= maxRetries) {
          throw new Error(`Failed to fetch event after ${maxRetries} attempts: ${dbError instanceof Error ? dbError.message : String(dbError)}`);
        }
        // Wait before retrying with exponential backoff
        await new Promise(resolve => setTimeout(resolve, 100 * Math.pow(2, retryCount)));
      }
    }
    
    if (!eventDoc || !eventDoc.exists) {
      res.status(404).json({ error: 'Event not found', eventID });
      return;
    }

    const eventData = eventDoc.data();
    if (!eventData) {
      res.status(500).json({ error: 'Event data is missing', eventID });
      return;
    }

    // Initialize arrays if they don't exist
    const attendees = eventData.attendees || [];
    const waitlist = eventData.waitlist || [];
    let reservationTimestamps = eventData.reservationTimestamps || {};

    // Check if event is private and user is not already registered
    if (eventData.isPrivate && 
        !attendees.includes(userID) && 
        !waitlist.includes(userID) &&
        passwordVerified !== 'true') {
      // For private events, require password verification before proceeding
      res.status(403).json({ error: 'Password verification required for private event' });
      return;
    }

    // Handle removing user from event (unreserve)
    if (attendees.includes(userID) || waitlist.includes(userID)) {
      const updatedAttendees = attendees.filter((id: string) => id !== userID);
      const updatedWaitlist = waitlist.filter((id: string) => id !== userID);
      
      // Remove from reservation timestamps
      const updatedReservationTimestamps = { ...reservationTimestamps };
      delete updatedReservationTimestamps[userID];
      
      // Update event document with retries
      let updateSuccess = false;
      retryCount = 0;
      
      while (retryCount < maxRetries && !updateSuccess) {
        try {
          await eventDoc.ref.update({
            attendees: updatedAttendees,
            waitlist: updatedWaitlist,
            reservationTimestamps: updatedReservationTimestamps
          });
          updateSuccess = true;
        } catch (updateError) {
          console.error(`Event update error (attempt ${retryCount + 1}/${maxRetries}):`, updateError);
          retryCount++;
          if (retryCount >= maxRetries) {
            throw new Error(`Failed to update event after ${maxRetries} attempts: ${updateError instanceof Error ? updateError.message : String(updateError)}`);
          }
          // Wait before retrying with exponential backoff
          await new Promise(resolve => setTimeout(resolve, 100 * Math.pow(2, retryCount)));
        }
      }
      
      // Log successful unreserve action
      console.log('User unreserved successfully:', {
        eventID,
        userID,
        previousStatus: attendees.includes(userID) ? 'attendee' : 'waitlisted'
      });
      
      // If user was in the main attendees list and there are people on the waitlist,
      // move the first waitlisted person to the attendees list
      if (attendees.includes(userID) && updatedWaitlist.length > 0) {
        const firstWaitlistedUser = updatedWaitlist[0];
        const remainingWaitlist = updatedWaitlist.slice(1);
        
        // Add to attendees and update timestamp
        const newAttendees = [...updatedAttendees, firstWaitlistedUser];
        const newReservationTimestamps = { 
          ...updatedReservationTimestamps,
          [firstWaitlistedUser]: admin.firestore.Timestamp.now()
        };
        
        // Update document with promoted user
        await eventDoc.ref.update({
          attendees: newAttendees,
          waitlist: remainingWaitlist,
          reservationTimestamps: newReservationTimestamps
        });
        
        // Send notification to the promoted user
        try {
          const userDoc = await admin.firestore().collection('users').doc(firstWaitlistedUser).get();
          if (userDoc.exists) {
            const userData = userDoc.data();
            if (userData && userData.fcmToken) {
              await admin.messaging().send({
                token: userData.fcmToken,
                notification: {
                  title: 'Spot Available!',
                  body: `You've been moved from the waitlist to the attendee list for ${eventData.name}`
                },
                data: {
                  type: 'waitlist_promoted',
                  eventId: eventID
                }
              });
            }
          }
        } catch (notificationError) {
          console.error('Error sending notification:', notificationError);
          // Continue even if notification fails
        }
      }
      
      const processingTime = Date.now() - startTime;
      console.log(`Unreserve request completed in ${processingTime}ms`);
      
      res.status(200).json({
        status: 'success',
        message: 'Successfully unreserved',
        action: 'unreserve'
      });
      return;
    }
    
    // Handle new reservation
    const openSlots = eventData.slots - attendees.length;
    
    // If there are open slots, add user to attendees
    if (openSlots > 0) {
      const newAttendees = [...attendees, userID];
      const newReservationTimestamps = { 
        ...reservationTimestamps,
        [userID]: admin.firestore.Timestamp.now()
      };
      
      // Update event document with retries
      let updateSuccess = false;
      retryCount = 0;
      
      while (retryCount < maxRetries && !updateSuccess) {
        try {
          await eventDoc.ref.update({
            attendees: newAttendees,
            reservationTimestamps: newReservationTimestamps
          });
          updateSuccess = true;
        } catch (updateError) {
          console.error(`Event update error (attempt ${retryCount + 1}/${maxRetries}):`, updateError);
          retryCount++;
          if (retryCount >= maxRetries) {
            throw new Error(`Failed to update event after ${maxRetries} attempts: ${updateError instanceof Error ? updateError.message : String(updateError)}`);
          }
          // Wait before retrying with exponential backoff
          await new Promise(resolve => setTimeout(resolve, 100 * Math.pow(2, retryCount)));
        }
      }
      
      const processingTime = Date.now() - startTime;
      console.log(`Reserve request completed in ${processingTime}ms`);
      
      res.status(200).json({
        status: 'success',
        message: 'Successfully reserved',
        action: 'reserve'
      });
    } else {
      // Event is full, add user to waitlist
      const newWaitlist = [...waitlist, userID];
      
      // Update event document with retries
      let updateSuccess = false;
      retryCount = 0;
      
      while (retryCount < maxRetries && !updateSuccess) {
        try {
          await eventDoc.ref.update({
            waitlist: newWaitlist
          });
          updateSuccess = true;
        } catch (updateError) {
          console.error(`Event update error (attempt ${retryCount + 1}/${maxRetries}):`, updateError);
          retryCount++;
          if (retryCount >= maxRetries) {
            throw new Error(`Failed to update event after ${maxRetries} attempts: ${updateError instanceof Error ? updateError.message : String(updateError)}`);
          }
          // Wait before retrying with exponential backoff
          await new Promise(resolve => setTimeout(resolve, 100 * Math.pow(2, retryCount)));
        }
      }
      
      // Return the waitlist position
      const waitlistPosition = newWaitlist.indexOf(userID) + 1;
      
      const processingTime = Date.now() - startTime;
      console.log(`Waitlist request completed in ${processingTime}ms`);
      
      res.status(200).json({
        status: 'waitlisted',
        position: waitlistPosition,
        message: `You are #${waitlistPosition} on the waitlist`
      });
    }
  } catch (error) {
    console.error('Error in reserveAction:', error);
    
    // Return a structured error response
    res.status(500).json({
      error: 'Internal server error',
      message: error instanceof Error ? error.message : 'Unknown error',
      timestamp: new Date().toISOString()
    });
  }
});

// Force add a user to an event's attendees list (bypass waitlist)
export const forceAddUserToEvent = functions.https.onCall(async (data, context) => {
  try {
    // Check authentication
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be logged in to force add users to events');
    }

    const { eventID, userID } = data;
    
    if (!eventID || !userID) {
      throw new functions.https.HttpsError('invalid-argument', 'Event ID and User ID are required');
    }

    // Check if the caller is an admin or event host
    const eventDoc = await admin.firestore().collection('events').doc(eventID).get();
    if (!eventDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Event not found');
    }

    const eventData = eventDoc.data();
    const callerID = context.auth.uid;
    
    // Only allow event hosts and admins to force add users
    const isHost = eventData?.host === callerID;
    
    // Check if caller is an admin
    const adminDoc = await admin.firestore().collection('admins').doc(callerID).get();
    const isAdmin = adminDoc.exists && adminDoc.data()?.isAdmin === true;
    
    if (!isHost && !isAdmin) {
      throw new functions.https.HttpsError('permission-denied', 'Only event hosts and admins can force add users');
    }

    // Get the current event data
    const attendees = [...(eventData?.attendees || [])];
    const waitlist = [...(eventData?.waitlist || [])];
    let reservationTimestamps = { ...(eventData?.reservationTimestamps || {}) };

    // Check if user is already in attendees
    if (attendees.includes(userID)) {
      throw new functions.https.HttpsError('already-exists', 'User is already in the attendees list');
    }

    // Add user to attendees
    attendees.push(userID);
    
    // Remove from waitlist if present
    const waitlistIndex = waitlist.indexOf(userID);
    if (waitlistIndex >= 0) {
      waitlist.splice(waitlistIndex, 1);
    }
    
    // Add timestamp for the reservation
    reservationTimestamps[userID] = admin.firestore.Timestamp.now();

    // Update the event document
    await admin.firestore().collection('events').doc(eventID).update({
      attendees: attendees,
      waitlist: waitlist,
      reservationTimestamps: reservationTimestamps,
      '_admin_update': true // Skip validation checks
    });

    // Send notification to the user
    try {
      const userDoc = await admin.firestore().collection('users').doc(userID).get();
      if (userDoc.exists) {
        const userData = userDoc.data();
        const pushToken = userData?.pushToken;
        
        if (pushToken) {
          await admin.messaging().send({
            token: pushToken,
            notification: {
              title: "You've Been Added to an Event",
              body: `You've been added to ${eventData?.name} by the organizer!`
            },
            data: {
              type: 'event_added',
              eventID: eventID
            }
          });
        }
      }
    } catch (error) {
      console.error('Error sending notification:', error);
      // Continue even if notification fails
    }

    return { success: true };
  } catch (error) {
    console.error('Error in forceAddUserToEvent:', error);
    throw error;
  }
});

// Function to get Stripe ephemeral key
export const getEphemeralKey = functions.https.onRequest(async (req, res) => {
  // Set CORS headers
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'GET, POST');
  res.set('Access-Control-Allow-Headers', 'Content-Type');
  
  // Handle preflight OPTIONS request
  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }
  
  try {
    // Only allow POST requests
    if (req.method !== 'POST') {
      res.status(405).send({ error: 'Method not allowed' });
      return;
    }

    // Get customer ID and debug mode from request
    const { cusID, debug } = req.body;
    
    if (!cusID) {
      res.status(400).send({ error: 'Customer ID is required' });
      return;
    }

    // Get the appropriate Stripe instance based on debug mode
    const stripe = debug === 'true' ? stripeTest : stripeLive;

    // Create ephemeral key
    const ephemeralKey = await stripe.ephemeralKeys.create(
      { customer: cusID },
      { apiVersion: '2023-10-16' } // Use the latest Stripe API version
    );

    // Return the ephemeral key
    res.status(200).send({ secret: ephemeralKey.secret });
  } catch (error) {
    console.error('Error creating ephemeral key:', error);
    res.status(500).send({ 
      error: error instanceof Error ? error.message : 'Internal server error' 
    });
  }
});

export const createPaymentIntent = functions.https.onRequest(async (req, res) => {
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  res.set('Access-Control-Max-Age', '3600');

  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }

  try {
    if (req.method !== 'POST') {
      res.status(405).json({ error: 'Method not allowed' });
      return;
    }

    const { amount, currency, customerId, debug } = req.body;
    if (!amount || !currency) {
      res.status(400).json({ error: 'Missing required parameters: amount, currency' });
      return;
    }

    // Use test or live Stripe key
    const stripe = debug ? stripeTest : stripeLive;

    // Only include customer if valid
    let paymentIntentParams: any = {
      amount: parseInt(amount, 10), // amount in cents
      currency,
      payment_method_types: ['card'],
    };
    if (
      typeof customerId === 'string' &&
      customerId.startsWith('cus_') &&
      customerId.length > 4 // basic check for valid Stripe customer ID
    ) {
      paymentIntentParams.customer = customerId;
    }

    // Create PaymentIntent
    const paymentIntent = await stripe.paymentIntents.create(paymentIntentParams);

    res.status(200).json({ clientSecret: paymentIntent.client_secret });
  } catch (error) {
    console.error('Error creating PaymentIntent:', error);
    res.status(500).json({ error: error instanceof Error ? error.message : String(error) });
  }
});

// Function to delete an event
export const deleteEvent = functions.https.onRequest(async (req, res) => {
  // Set CORS headers
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Requested-With');
  res.set('Access-Control-Max-Age', '3600');
  
  // Handle preflight OPTIONS request
  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }
  
  try {
    // Only allow POST requests
    if (req.method !== 'POST') {
      res.status(405).send({ error: 'Method not allowed' });
      return;
    }

    // Get eventID and debug mode from request
    const { eventID, debug } = req.body;
    
    if (!eventID) {
      res.status(400).send({ error: 'Event ID is required' });
      return;
    }

    console.log('Deleting event:', { eventID, debug });

    // Get event document
    const eventDoc = await admin.firestore().collection('events').doc(eventID).get();
    if (!eventDoc.exists) {
      res.status(404).send({ error: 'Event not found' });
      return;
    }

    const eventData = eventDoc.data();
    if (!eventData) {
      res.status(500).send({ error: 'Event data is missing' });
      return;
    }

    console.log('Event found, proceeding with deletion:', {
      eventID,
      eventName: eventData.name,
      hostID: eventData.host
    });

    // Delete the event document
    await admin.firestore().collection('events').doc(eventID).delete();

    // Remove event from all users' savedEvents arrays
    if (eventData.attendees && eventData.attendees.length > 0) {
      const batch = admin.firestore().batch();
      
      for (const userID of eventData.attendees) {
        const userRef = admin.firestore().collection('users').doc(userID);
        batch.update(userRef, {
          savedEvents: admin.firestore.FieldValue.arrayRemove(eventID)
        });
      }
      
      await batch.commit();
      console.log('Removed event from attendees savedEvents lists');
    }

    // Remove event from host's openMics array (if applicable)
    if (eventData.host) {
      try {
        const hostRef = admin.firestore().collection('users').doc(eventData.host);
        await hostRef.update({
          openMics: admin.firestore.FieldValue.arrayRemove(eventID)
        });
        console.log('Removed event from host openMics list');
      } catch (error) {
        console.warn('Could not remove event from host openMics:', error);
        // Continue even if this fails
      }
    }

    console.log('Event deletion completed successfully:', eventID);
    res.status(200).send({ 
      success: true, 
      message: 'Event deleted successfully',
      eventID: eventID 
    });
  } catch (error) {
    console.error('Error deleting event:', error);
    res.status(500).send({ 
      error: error instanceof Error ? error.message : 'Internal server error' 
    });
  }
}); 

// Block/Unblock user functionality
export const blockUser = functions.https.onCall(async (data, context) => {
  try {
    // Check authentication
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be logged in to block users');
    }

    const { targetUserId, action } = data;
    const currentUserId = context.auth.uid;
    
    if (!targetUserId) {
      throw new functions.https.HttpsError('invalid-argument', 'Target user ID is required');
    }
    
    if (!action || !['block', 'unblock'].includes(action)) {
      throw new functions.https.HttpsError('invalid-argument', 'Action must be either "block" or "unblock"');
    }

    // Prevent self-blocking
    if (targetUserId === currentUserId) {
      throw new functions.https.HttpsError('invalid-argument', 'You cannot block yourself');
    }

    const db = admin.firestore();
    const currentUserRef = db.collection('users').doc(currentUserId);
    const targetUserRef = db.collection('users').doc(targetUserId);

    // Verify target user exists
    const targetUserDoc = await targetUserRef.get();
    if (!targetUserDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Target user not found');
    }

    // Get current user's blocked users list
    const currentUserDoc = await currentUserRef.get();
    const currentUserData = currentUserDoc.data() || {};
    const blockedUsers = currentUserData.blockedUsers || [];

    if (action === 'block') {
      // Add user to blocked list if not already blocked
      if (!blockedUsers.includes(targetUserId)) {
        await currentUserRef.update({
          blockedUsers: admin.firestore.FieldValue.arrayUnion([targetUserId])
        });
        
        console.log(`User ${currentUserId} blocked user ${targetUserId}`);
        
        // Send notification to target user (optional)
        try {
          const targetUserData = targetUserDoc.data();
          const pushToken = targetUserData?.pushToken;
          if (pushToken) {
            await admin.messaging().send({
              token: pushToken,
              notification: {
                title: 'Account Blocked',
                body: 'Your account has been blocked by another user'
              },
              data: {
                type: 'account_blocked',
                blockedBy: currentUserId
              }
            });
          }
        } catch (error) {
          console.error('Error sending block notification:', error);
          // Continue even if notification fails
        }
      }
    } else {
      // Remove user from blocked list
      if (blockedUsers.includes(targetUserId)) {
        await currentUserRef.update({
          blockedUsers: admin.firestore.FieldValue.arrayRemove([targetUserId])
        });
        
        console.log(`User ${currentUserId} unblocked user ${targetUserId}`);
      }
    }

    return { 
      success: true, 
      action: action,
      blockedUsers: action === 'block' 
        ? [...blockedUsers, targetUserId]
        : blockedUsers.filter((id: string) => id !== targetUserId)
    };

  } catch (error) {
    console.error('Error in blockUser function:', error);
    throw new functions.https.HttpsError('internal', 'Failed to process block action');
  }
});

// Check if user is blocked
export const isUserBlocked = functions.https.onCall(async (data, context) => {
  try {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be logged in');
    }

    const { targetUserId } = data;
    const currentUserId = context.auth.uid;
    
    if (!targetUserId) {
      throw new functions.https.HttpsError('invalid-argument', 'Target user ID is required');
    }

    const db = admin.firestore();
    const currentUserDoc = await db.collection('users').doc(currentUserId).get();
    
    if (!currentUserDoc.exists) {
      return { isBlocked: false };
    }

    const currentUserData = currentUserDoc.data();
    const blockedUsers = currentUserData?.blockedUsers || [];
    
    return { isBlocked: blockedUsers.includes(targetUserId) };

  } catch (error) {
    console.error('Error in isUserBlocked function:', error);
    throw new functions.https.HttpsError('internal', 'Failed to check block status');
  }
});

// Get user's blocked users list
export const getBlockedUsers = functions.https.onCall(async (data, context) => {
  try {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be logged in');
    }

    const currentUserId = context.auth.uid;
    const db = admin.firestore();
    const currentUserDoc = await db.collection('users').doc(currentUserId).get();
    
    if (!currentUserDoc.exists) {
      return { blockedUsers: [] };
    }

    const currentUserData = currentUserDoc.data();
    const blockedUsers = currentUserData?.blockedUsers || [];
    
    // Get details of blocked users
    const blockedUsersDetails = [];
    for (const blockedUserId of blockedUsers) {
      try {
        const blockedUserDoc = await db.collection('users').doc(blockedUserId).get();
        if (blockedUserDoc.exists) {
          const blockedUserData = blockedUserDoc.data();
          blockedUsersDetails.push({
            id: blockedUserId,
            username: blockedUserData?.username || 'Unknown User',
            photoUrl: blockedUserData?.photoUrl
          });
        }
      } catch (error) {
        console.error(`Error getting blocked user ${blockedUserId}:`, error);
      }
    }
    
    return { blockedUsers: blockedUsersDetails };

  } catch (error) {
    console.error('Error in getBlockedUsers function:', error);
    throw new functions.https.HttpsError('internal', 'Failed to get blocked users');
  }
}); 

// Content reporting and moderation system
export const reportContent = functions.https.onCall(async (data, context) => {
  try {
    // Check authentication
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be logged in to report content');
    }

    const { contentType, contentId, reportType, description, reporterId } = data;
    
    if (!contentType || !contentId || !reportType) {
      throw new functions.https.HttpsError('invalid-argument', 'Missing required parameters');
    }

    const reporter = reporterId || context.auth.uid;
    const timestamp = new Date().toISOString();

    // Create report document
    const reportData = {
      contentType,
      contentId,
      reportType,
      description: description || '',
      reporterId: reporter,
      timestamp,
      status: 'pending',
      reviewedBy: null,
      reviewedAt: null,
      action: null,
      notes: null,
    };

    const reportRef = await admin.firestore().collection('reports').add(reportData);

    console.log('Content reported successfully:', {
      reportId: reportRef.id,
      contentType,
      contentId,
      reportType,
      reporterId: reporter,
    });

    return { success: true, reportId: reportRef.id };
  } catch (error) {
    console.error('Error reporting content:', error);
    throw new functions.https.HttpsError('internal', 'Failed to report content');
  }
});

// Get user's reports
export const getUserReports = functions.https.onCall(async (data, context) => {
  try {
    // Check authentication
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be logged in');
    }

    const userId = context.auth.uid;
    
    const reportsSnapshot = await admin.firestore()
      .collection('reports')
      .where('reporterId', '==', userId)
      .orderBy('timestamp', 'desc')
      .get();

    const reports = reportsSnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
    }));

    return { reports };
  } catch (error) {
    console.error('Error getting user reports:', error);
    throw new functions.https.HttpsError('internal', 'Failed to get reports');
  }
});

// Admin function to review reports (24-hour requirement)
export const reviewReport = functions.https.onCall(async (data, context) => {
  try {
    // Check authentication
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be logged in');
    }

    const { reportId, action, notes } = data;
    
    if (!reportId || !action) {
      throw new functions.https.HttpsError('invalid-argument', 'Missing required parameters');
    }

    // Check if user is admin
    // TEMPORARY: Disable admin check for testing
    // const adminDoc = await admin.firestore().collection('admins').doc(context.auth.uid).get();
    // if (!adminDoc.exists || !adminDoc.data()?.isAdmin) {
    //   throw new functions.https.HttpsError('permission-denied', 'Only admins can review reports');
    // }

    const reportRef = admin.firestore().collection('reports').doc(reportId);
    const reportDoc = await reportRef.get();

    if (!reportDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Report not found');
    }

    const reportData = reportDoc.data();
    if (!reportData) {
      throw new functions.https.HttpsError('not-found', 'Report data not found');
    }
    
    const reviewData = {
      status: 'reviewed',
      reviewedBy: context.auth.uid,
      reviewedAt: new Date().toISOString(),
      action,
      notes: notes || '',
    };

    await reportRef.update(reviewData);

    // Take action based on review decision
    if (action === 'remove') {
      await _removeContent(reportData.contentType, reportData.contentId);
    } else if (action === 'warning') {
      await _sendWarningToUser(reportData.contentType, reportData.contentId);
    }

    console.log('Report reviewed successfully:', {
      reportId,
      action,
      reviewer: context.auth.uid,
    });

    return { success: true };
  } catch (error) {
    console.error('Error reviewing report:', error);
    throw new functions.https.HttpsError('internal', 'Failed to review report');
  }
});

// Automated 24-hour review reminder (scheduled function)
export const checkPendingReports = functions.pubsub.schedule('every 1 hours').onRun(async (context) => {
  try {
    const oneDayAgo = new Date(Date.now() - 24 * 60 * 60 * 1000);
    
    const pendingReportsSnapshot = await admin.firestore()
      .collection('reports')
      .where('status', '==', 'pending')
      .where('timestamp', '<', oneDayAgo.toISOString())
      .get();

    console.log(`Found ${pendingReportsSnapshot.size} reports pending for over 24 hours`);

    // Send notifications to admins about pending reports
    const adminSnapshot = await admin.firestore().collection('admins').get();
    
    for (const adminDoc of adminSnapshot.docs) {
      if (adminDoc.data()?.isAdmin) {
        // Send notification to admin about pending reports
        // This could be implemented with Firebase Cloud Messaging
        console.log(`Notifying admin ${adminDoc.id} about ${pendingReportsSnapshot.size} pending reports`);
      }
    }

    return null;
  } catch (error) {
    console.error('Error checking pending reports:', error);
    return null;
  }
});

// Get pending reports for admin panel
export const getPendingReports = functions.https.onCall(async (data, context) => {
  try {
    // Check authentication
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be logged in');
    }

    // Check if user is admin
    // TEMPORARY: Disable admin check for testing
    // const adminDoc = await admin.firestore().collection('admins').doc(context.auth.uid).get();
    // if (!adminDoc.exists || !adminDoc.data()?.isAdmin) {
    //   throw new functions.https.HttpsError('permission-denied', 'Only admins can view pending reports');
    // }

    const pendingReportsSnapshot = await admin.firestore()
      .collection('reports')
      .where('status', '==', 'pending')
      .orderBy('timestamp', 'desc')
      .get();

    const reports = pendingReportsSnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
    }));

    return { reports };
  } catch (error) {
    console.error('Error getting pending reports:', error);
    throw new functions.https.HttpsError('internal', 'Failed to get pending reports');
  }
});

// Get reviewed reports for admin panel
export const getReviewedReports = functions.https.onCall(async (data, context) => {
  try {
    // Check authentication
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be logged in');
    }

    // Check if user is admin
    // TEMPORARY: Disable admin check for testing
    // const adminDoc = await admin.firestore().collection('admins').doc(context.auth.uid).get();
    // if (!adminDoc.exists || !adminDoc.data()?.isAdmin) {
    //   throw new functions.https.HttpsError('permission-denied', 'Only admins can view reviewed reports');
    // }

    const reviewedReportsSnapshot = await admin.firestore()
      .collection('reports')
      .where('status', '==', 'reviewed')
      .orderBy('reviewedAt', 'desc')
      .get();

    const reports = reviewedReportsSnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
    }));

    return { reports };
  } catch (error) {
    console.error('Error getting reviewed reports:', error);
    throw new functions.https.HttpsError('internal', 'Failed to get reviewed reports');
  }
});

// Helper function to remove content
async function _removeContent(contentType: string, contentId: string) {
  try {
    if (contentType === 'event') {
      await admin.firestore().collection('events').doc(contentId).delete();
      console.log('Event removed:', contentId);
    } else if (contentType === 'user') {
      // For user content, you might want to suspend the account instead of deleting
      await admin.firestore().collection('users').doc(contentId).update({
        suspended: true,
        suspendedAt: new Date().toISOString(),
      });
      console.log('User suspended:', contentId);
    }
  } catch (error) {
    console.error('Error removing content:', error);
  }
}

// Helper function to send warning to user
async function _sendWarningToUser(contentType: string, contentId: string) {
  try {
    // This could send a notification or email to the user
    console.log('Warning sent to user for content:', { contentType, contentId });
  } catch (error) {
    console.error('Error sending warning:', error);
  }
} 