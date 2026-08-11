"use strict";
var _a, _b;
Object.defineProperty(exports, "__esModule", { value: true });
exports.createStripeCustomer = exports.reportStripeUsage = exports.getReviewedReports = exports.getPendingReports = exports.checkPendingReports = exports.reviewReport = exports.getUserReports = exports.reportContent = exports.getBlockedUsers = exports.isUserBlocked = exports.blockUser = exports.deleteEvent = exports.createPaymentIntent = exports.getEphemeralKey = exports.forceAddUserToEvent = exports.reserveAction = exports.verifyEventPassword = void 0;
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const stripe_1 = require("stripe");
const http_auth_1 = require("./http_auth");
// Initialize Firebase Admin if not already initialized
if (!admin.apps.length) {
    admin.initializeApp();
}
// Stripe keys from environment variables
const stripeTestKey = ((_a = functions.config().stripe) === null || _a === void 0 ? void 0 : _a.test_key) || process.env.STRIPE_TEST_KEY;
const stripeLiveKey = ((_b = functions.config().stripe) === null || _b === void 0 ? void 0 : _b.live_key) || process.env.STRIPE_LIVE_KEY;
if (!stripeTestKey || !stripeLiveKey) {
    throw new Error('Stripe keys not configured. Please set stripe.test_key and stripe.live_key in Firebase config.');
}
const stripeTest = new stripe_1.default(stripeTestKey);
const stripeLive = new stripe_1.default(stripeLiveKey);
exports.verifyEventPassword = functions.https.onRequest(async (req, res) => {
    (0, http_auth_1.setCorsHeaders)(res);
    if ((0, http_auth_1.handleOptions)(req, res))
        return;
    try {
        if (req.method !== 'POST') {
            res.status(405).json({ error: 'Method not allowed' });
            return;
        }
        const decoded = await (0, http_auth_1.requireAuth)(req, res);
        if (!decoded)
            return;
        const { eventID, password } = req.body;
        if (!eventID || !password) {
            res.status(400).json({ error: 'Missing required parameters' });
            return;
        }
        const eventDoc = await admin.firestore().collection('events').doc(eventID).get();
        if (!eventDoc.exists) {
            res.status(404).json({ error: 'Event not found' });
            return;
        }
        const eventData = eventDoc.data();
        if (!eventData) {
            res.status(500).json({ error: 'Event data is missing' });
            return;
        }
        if (!eventData.isPrivate) {
            res.status(400).json({ error: 'Event is not private' });
            return;
        }
        if (!eventData.password) {
            res.status(500).json({ error: 'Event has no password set' });
            return;
        }
        if (!(0, http_auth_1.passwordsMatch)(eventData.password, password)) {
            // Never log password values
            console.warn('Invalid password provided for event:', { eventID, uid: decoded.uid });
            res.status(401).json({ error: 'Invalid password' });
            return;
        }
        console.log('Password verification successful:', { eventID, uid: decoded.uid });
        res.status(200).json({ success: true, valid: true });
    }
    catch (error) {
        console.error('Error verifying event password:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});
exports.reserveAction = functions.https.onRequest(async (req, res) => {
    (0, http_auth_1.setCorsHeaders)(res, 'GET, POST, OPTIONS');
    if ((0, http_auth_1.handleOptions)(req, res))
        return;
    try {
        const startTime = Date.now();
        if (req.method !== 'POST') {
            res.status(405).json({ error: 'Method not allowed', details: 'Only POST requests are accepted' });
            return;
        }
        const decoded = await (0, http_auth_1.requireAuth)(req, res);
        if (!decoded)
            return;
        // Identity comes from the verified token only — never trust body.userID
        const userID = decoded.uid;
        const eventID = req.body.eventID || req.body.eventId;
        const password = req.body.password;
        if (!eventID) {
            res.status(400).json({
                error: 'Missing required parameters',
                details: 'Missing: eventID',
            });
            return;
        }
        console.log('Reservation request received:', {
            eventID,
            uid: userID,
            hasPassword: !!password,
            timestamp: new Date().toISOString(),
        });
        let eventDoc = null;
        let retryCount = 0;
        const maxRetries = 3;
        while (retryCount < maxRetries) {
            try {
                eventDoc = await admin.firestore().collection('events').doc(eventID).get();
                break;
            }
            catch (dbError) {
                console.error(`Database fetch error (attempt ${retryCount + 1}/${maxRetries}):`, dbError);
                retryCount++;
                if (retryCount >= maxRetries) {
                    throw new Error(`Failed to fetch event after ${maxRetries} attempts: ${dbError instanceof Error ? dbError.message : String(dbError)}`);
                }
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
        const attendees = eventData.attendees || [];
        const waitlist = eventData.waitlist || [];
        const reservationTimestamps = eventData.reservationTimestamps || {};
        const alreadyJoined = attendees.includes(userID) || waitlist.includes(userID);
        // Private events: require password on join (ignore client passwordVerified boolean)
        if (eventData.isPrivate && !alreadyJoined) {
            if (!password || !eventData.password || !(0, http_auth_1.passwordsMatch)(eventData.password, password)) {
                res.status(403).json({ error: 'Password verification required for private event' });
                return;
            }
        }
        // Handle removing user from event (unreserve)
        if (alreadyJoined) {
            const updatedAttendees = attendees.filter((id) => id !== userID);
            const updatedWaitlist = waitlist.filter((id) => id !== userID);
            const updatedReservationTimestamps = Object.assign({}, reservationTimestamps);
            delete updatedReservationTimestamps[userID];
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
                }
                catch (updateError) {
                    console.error(`Event update error (attempt ${retryCount + 1}/${maxRetries}):`, updateError);
                    retryCount++;
                    if (retryCount >= maxRetries) {
                        throw new Error(`Failed to update event after ${maxRetries} attempts: ${updateError instanceof Error ? updateError.message : String(updateError)}`);
                    }
                    await new Promise(resolve => setTimeout(resolve, 100 * Math.pow(2, retryCount)));
                }
            }
            console.log('User unreserved successfully:', {
                eventID,
                userID,
                previousStatus: attendees.includes(userID) ? 'attendee' : 'waitlisted'
            });
            if (attendees.includes(userID) && updatedWaitlist.length > 0) {
                const firstWaitlistedUser = updatedWaitlist[0];
                const remainingWaitlist = updatedWaitlist.slice(1);
                const newAttendees = [...updatedAttendees, firstWaitlistedUser];
                const newReservationTimestamps = Object.assign(Object.assign({}, updatedReservationTimestamps), { [firstWaitlistedUser]: admin.firestore.Timestamp.now() });
                await eventDoc.ref.update({
                    attendees: newAttendees,
                    waitlist: remainingWaitlist,
                    reservationTimestamps: newReservationTimestamps
                });
                try {
                    const userDoc = await admin.firestore().collection('users').doc(firstWaitlistedUser).get();
                    if (userDoc.exists) {
                        const userData = userDoc.data();
                        const pushToken = (userData === null || userData === void 0 ? void 0 : userData.fcmToken) || (userData === null || userData === void 0 ? void 0 : userData.pushToken);
                        if (pushToken) {
                            await admin.messaging().send({
                                token: pushToken,
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
                }
                catch (notificationError) {
                    console.error('Error sending notification:', notificationError);
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
        const openSlots = eventData.slots - attendees.length;
        if (openSlots > 0) {
            const newAttendees = [...attendees, userID];
            const newReservationTimestamps = Object.assign(Object.assign({}, reservationTimestamps), { [userID]: admin.firestore.Timestamp.now() });
            let updateSuccess = false;
            retryCount = 0;
            while (retryCount < maxRetries && !updateSuccess) {
                try {
                    await eventDoc.ref.update({
                        attendees: newAttendees,
                        reservationTimestamps: newReservationTimestamps
                    });
                    updateSuccess = true;
                }
                catch (updateError) {
                    console.error(`Event update error (attempt ${retryCount + 1}/${maxRetries}):`, updateError);
                    retryCount++;
                    if (retryCount >= maxRetries) {
                        throw new Error(`Failed to update event after ${maxRetries} attempts: ${updateError instanceof Error ? updateError.message : String(updateError)}`);
                    }
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
        }
        else {
            const newWaitlist = [...waitlist, userID];
            let updateSuccess = false;
            retryCount = 0;
            while (retryCount < maxRetries && !updateSuccess) {
                try {
                    await eventDoc.ref.update({
                        waitlist: newWaitlist
                    });
                    updateSuccess = true;
                }
                catch (updateError) {
                    console.error(`Event update error (attempt ${retryCount + 1}/${maxRetries}):`, updateError);
                    retryCount++;
                    if (retryCount >= maxRetries) {
                        throw new Error(`Failed to update event after ${maxRetries} attempts: ${updateError instanceof Error ? updateError.message : String(updateError)}`);
                    }
                    await new Promise(resolve => setTimeout(resolve, 100 * Math.pow(2, retryCount)));
                }
            }
            const waitlistPosition = newWaitlist.indexOf(userID) + 1;
            const processingTime = Date.now() - startTime;
            console.log(`Waitlist request completed in ${processingTime}ms`);
            res.status(200).json({
                status: 'waitlisted',
                position: waitlistPosition,
                message: `You are #${waitlistPosition} on the waitlist`
            });
        }
    }
    catch (error) {
        console.error('Error in reserveAction:', error);
        res.status(500).json({
            error: 'Internal server error',
            message: error instanceof Error ? error.message : 'Unknown error',
            timestamp: new Date().toISOString()
        });
    }
});
// Force add a user to an event's attendees list (bypass waitlist)
exports.forceAddUserToEvent = functions.https.onCall(async (data, context) => {
    var _a;
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
        const isHost = (eventData === null || eventData === void 0 ? void 0 : eventData.host) === callerID;
        // Check if caller is an admin
        const adminDoc = await admin.firestore().collection('admins').doc(callerID).get();
        const isAdmin = adminDoc.exists && ((_a = adminDoc.data()) === null || _a === void 0 ? void 0 : _a.isAdmin) === true;
        if (!isHost && !isAdmin) {
            throw new functions.https.HttpsError('permission-denied', 'Only event hosts and admins can force add users');
        }
        // Get the current event data
        const attendees = [...((eventData === null || eventData === void 0 ? void 0 : eventData.attendees) || [])];
        const waitlist = [...((eventData === null || eventData === void 0 ? void 0 : eventData.waitlist) || [])];
        let reservationTimestamps = Object.assign({}, ((eventData === null || eventData === void 0 ? void 0 : eventData.reservationTimestamps) || {}));
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
                const pushToken = userData === null || userData === void 0 ? void 0 : userData.pushToken;
                if (pushToken) {
                    await admin.messaging().send({
                        token: pushToken,
                        notification: {
                            title: "You've Been Added to an Event",
                            body: `You've been added to ${eventData === null || eventData === void 0 ? void 0 : eventData.name} by the organizer!`
                        },
                        data: {
                            type: 'event_added',
                            eventID: eventID
                        }
                    });
                }
            }
        }
        catch (error) {
            console.error('Error sending notification:', error);
            // Continue even if notification fails
        }
        return { success: true };
    }
    catch (error) {
        console.error('Error in forceAddUserToEvent:', error);
        throw error;
    }
});
// Function to get Stripe ephemeral key
exports.getEphemeralKey = functions.https.onRequest(async (req, res) => {
    var _a;
    (0, http_auth_1.setCorsHeaders)(res, 'GET, POST, OPTIONS');
    if ((0, http_auth_1.handleOptions)(req, res))
        return;
    try {
        if (req.method !== 'POST') {
            res.status(405).json({ error: 'Method not allowed' });
            return;
        }
        const decoded = await (0, http_auth_1.requireAuth)(req, res);
        if (!decoded)
            return;
        const { stripe, isTest } = (0, http_auth_1.resolveStripeInstance)(stripeTest, stripeLive);
        const field = (0, http_auth_1.customerIdField)(isTest);
        // Resolve customer from the authenticated user's Firestore doc — ignore client cusID
        const userDoc = await admin.firestore().collection('users').doc(decoded.uid).get();
        const cusID = (_a = userDoc.data()) === null || _a === void 0 ? void 0 : _a[field];
        if (!cusID || typeof cusID !== 'string' || !cusID.startsWith('cus_')) {
            res.status(400).json({ error: 'No Stripe customer found for authenticated user' });
            return;
        }
        const ephemeralKey = await stripe.ephemeralKeys.create({ customer: cusID }, { apiVersion: '2023-10-16' });
        res.status(200).json({ secret: ephemeralKey.secret });
    }
    catch (error) {
        console.error('Error creating ephemeral key:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});
exports.createPaymentIntent = functions.https.onRequest(async (req, res) => {
    var _a;
    (0, http_auth_1.setCorsHeaders)(res, 'GET, POST, OPTIONS');
    if ((0, http_auth_1.handleOptions)(req, res))
        return;
    try {
        if (req.method !== 'POST') {
            res.status(405).json({ error: 'Method not allowed' });
            return;
        }
        const decoded = await (0, http_auth_1.requireAuth)(req, res);
        if (!decoded)
            return;
        const { amount, currency, eventID } = req.body;
        if (!amount || !currency) {
            res.status(400).json({ error: 'Missing required parameters: amount, currency' });
            return;
        }
        const parsedAmount = parseInt(amount, 10);
        if (!Number.isFinite(parsedAmount) || parsedAmount <= 0 || parsedAmount > 500000) {
            res.status(400).json({ error: 'Invalid amount' });
            return;
        }
        const { stripe, isTest } = (0, http_auth_1.resolveStripeInstance)(stripeTest, stripeLive);
        const field = (0, http_auth_1.customerIdField)(isTest);
        // Bind customer to authenticated user only
        const userDoc = await admin.firestore().collection('users').doc(decoded.uid).get();
        const ownedCustomerId = (_a = userDoc.data()) === null || _a === void 0 ? void 0 : _a[field];
        const paymentIntentParams = {
            amount: parsedAmount,
            currency,
            automatic_payment_methods: {
                enabled: true,
                allow_redirects: 'never',
            },
            metadata: {
                app_name: 'OpenSlot',
                firebaseUID: decoded.uid,
                eventID: typeof eventID === 'string' ? eventID : '',
                environment: isTest ? 'test' : 'live',
            },
        };
        if (typeof ownedCustomerId === 'string' &&
            ownedCustomerId.startsWith('cus_')) {
            paymentIntentParams.customer = ownedCustomerId;
        }
        const paymentIntent = await stripe.paymentIntents.create(paymentIntentParams);
        res.status(200).json({ clientSecret: paymentIntent.client_secret });
    }
    catch (error) {
        console.error('Error creating PaymentIntent:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});
// Function to delete an event
exports.deleteEvent = functions.https.onRequest(async (req, res) => {
    (0, http_auth_1.setCorsHeaders)(res, 'GET, POST, OPTIONS');
    if ((0, http_auth_1.handleOptions)(req, res))
        return;
    try {
        if (req.method !== 'POST') {
            res.status(405).json({ error: 'Method not allowed' });
            return;
        }
        const decoded = await (0, http_auth_1.requireAuth)(req, res);
        if (!decoded)
            return;
        const eventID = req.body.eventID || req.body.eventId;
        if (!eventID) {
            res.status(400).json({ error: 'Event ID is required' });
            return;
        }
        console.log('Deleting event:', { eventID, uid: decoded.uid });
        const eventDoc = await admin.firestore().collection('events').doc(eventID).get();
        if (!eventDoc.exists) {
            res.status(404).json({ error: 'Event not found' });
            return;
        }
        const eventData = eventDoc.data();
        if (!eventData) {
            res.status(500).json({ error: 'Event data is missing' });
            return;
        }
        const isHost = eventData.host === decoded.uid;
        const adminUser = await (0, http_auth_1.isAdminUid)(decoded.uid);
        if (!isHost && !adminUser) {
            res.status(403).json({ error: 'Only the event host or an admin can delete this event' });
            return;
        }
        console.log('Event found, proceeding with deletion:', {
            eventID,
            eventName: eventData.name,
            hostID: eventData.host,
            deletedBy: decoded.uid,
        });
        await admin.firestore().collection('events').doc(eventID).delete();
        if (eventData.attendees && eventData.attendees.length > 0) {
            const batch = admin.firestore().batch();
            for (const attendeeId of eventData.attendees) {
                const userRef = admin.firestore().collection('users').doc(attendeeId);
                batch.update(userRef, {
                    savedEvents: admin.firestore.FieldValue.arrayRemove(eventID)
                });
            }
            await batch.commit();
            console.log('Removed event from attendees savedEvents lists');
        }
        if (eventData.host) {
            try {
                const hostRef = admin.firestore().collection('users').doc(eventData.host);
                await hostRef.update({
                    openMics: admin.firestore.FieldValue.arrayRemove(eventID)
                });
                console.log('Removed event from host openMics list');
            }
            catch (error) {
                console.warn('Could not remove event from host openMics:', error);
            }
        }
        console.log('Event deletion completed successfully:', eventID);
        res.status(200).json({
            success: true,
            message: 'Event deleted successfully',
            eventID: eventID
        });
    }
    catch (error) {
        console.error('Error deleting event:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});
// Block/Unblock user functionality
exports.blockUser = functions.https.onCall(async (data, context) => {
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
                    const pushToken = targetUserData === null || targetUserData === void 0 ? void 0 : targetUserData.pushToken;
                    if (pushToken) {
                        await admin.messaging().send({
                            token: pushToken,
                            notification: {
                                title: 'Account Blocked',
                                body: 'Your account has been blocked by another user'
                            },
                            data: {
                                type: 'account_blocked'
                            }
                        });
                    }
                }
                catch (error) {
                    console.error('Error sending block notification:', error);
                    // Continue even if notification fails
                }
            }
        }
        else {
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
                : blockedUsers.filter((id) => id !== targetUserId)
        };
    }
    catch (error) {
        console.error('Error in blockUser function:', error);
        throw new functions.https.HttpsError('internal', 'Failed to process block action');
    }
});
// Check if user is blocked
exports.isUserBlocked = functions.https.onCall(async (data, context) => {
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
        const blockedUsers = (currentUserData === null || currentUserData === void 0 ? void 0 : currentUserData.blockedUsers) || [];
        return { isBlocked: blockedUsers.includes(targetUserId) };
    }
    catch (error) {
        console.error('Error in isUserBlocked function:', error);
        throw new functions.https.HttpsError('internal', 'Failed to check block status');
    }
});
// Get user's blocked users list
exports.getBlockedUsers = functions.https.onCall(async (data, context) => {
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
        const blockedUsers = (currentUserData === null || currentUserData === void 0 ? void 0 : currentUserData.blockedUsers) || [];
        // Get details of blocked users
        const blockedUsersDetails = [];
        for (const blockedUserId of blockedUsers) {
            try {
                const blockedUserDoc = await db.collection('users').doc(blockedUserId).get();
                if (blockedUserDoc.exists) {
                    const blockedUserData = blockedUserDoc.data();
                    blockedUsersDetails.push({
                        id: blockedUserId,
                        username: (blockedUserData === null || blockedUserData === void 0 ? void 0 : blockedUserData.username) || 'Unknown User',
                        photoUrl: blockedUserData === null || blockedUserData === void 0 ? void 0 : blockedUserData.photoUrl
                    });
                }
            }
            catch (error) {
                console.error(`Error getting blocked user ${blockedUserId}:`, error);
            }
        }
        return { blockedUsers: blockedUsersDetails };
    }
    catch (error) {
        console.error('Error in getBlockedUsers function:', error);
        throw new functions.https.HttpsError('internal', 'Failed to get blocked users');
    }
});
// Content reporting and moderation system
exports.reportContent = functions.https.onCall(async (data, context) => {
    try {
        // Check authentication
        if (!context.auth) {
            throw new functions.https.HttpsError('unauthenticated', 'User must be logged in to report content');
        }
        const { contentType, contentId, reportType, description } = data;
        if (!contentType || !contentId || !reportType) {
            throw new functions.https.HttpsError('invalid-argument', 'Missing required parameters');
        }
        // Always use authenticated caller — never trust client reporterId
        const reporter = context.auth.uid;
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
    }
    catch (error) {
        console.error('Error reporting content:', error);
        throw new functions.https.HttpsError('internal', 'Failed to report content');
    }
});
// Get user's reports
exports.getUserReports = functions.https.onCall(async (data, context) => {
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
        const reports = reportsSnapshot.docs.map(doc => (Object.assign({ id: doc.id }, doc.data())));
        return { reports };
    }
    catch (error) {
        console.error('Error getting user reports:', error);
        throw new functions.https.HttpsError('internal', 'Failed to get reports');
    }
});
// Admin function to review reports (24-hour requirement)
exports.reviewReport = functions.https.onCall(async (data, context) => {
    try {
        // Check authentication
        if (!context.auth) {
            throw new functions.https.HttpsError('unauthenticated', 'User must be logged in');
        }
        const { reportId, action, notes } = data;
        if (!reportId || !action) {
            throw new functions.https.HttpsError('invalid-argument', 'Missing required parameters');
        }
        if (!(await (0, http_auth_1.isAdminUid)(context.auth.uid))) {
            throw new functions.https.HttpsError('permission-denied', 'Only admins can review reports');
        }
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
        }
        else if (action === 'warning') {
            await _sendWarningToUser(reportData.contentType, reportData.contentId);
        }
        console.log('Report reviewed successfully:', {
            reportId,
            action,
            reviewer: context.auth.uid,
        });
        return { success: true };
    }
    catch (error) {
        console.error('Error reviewing report:', error);
        throw new functions.https.HttpsError('internal', 'Failed to review report');
    }
});
// Automated 24-hour review reminder (scheduled function)
exports.checkPendingReports = functions.pubsub.schedule('every 1 hours').onRun(async (context) => {
    var _a;
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
            if ((_a = adminDoc.data()) === null || _a === void 0 ? void 0 : _a.isAdmin) {
                // Send notification to admin about pending reports
                // This could be implemented with Firebase Cloud Messaging
                console.log(`Notifying admin ${adminDoc.id} about ${pendingReportsSnapshot.size} pending reports`);
            }
        }
        return null;
    }
    catch (error) {
        console.error('Error checking pending reports:', error);
        return null;
    }
});
// Get pending reports for admin panel
exports.getPendingReports = functions.https.onCall(async (data, context) => {
    try {
        // Check authentication
        if (!context.auth) {
            throw new functions.https.HttpsError('unauthenticated', 'User must be logged in');
        }
        if (!(await (0, http_auth_1.isAdminUid)(context.auth.uid))) {
            throw new functions.https.HttpsError('permission-denied', 'Only admins can view pending reports');
        }
        const pendingReportsSnapshot = await admin.firestore()
            .collection('reports')
            .where('status', '==', 'pending')
            .orderBy('timestamp', 'desc')
            .get();
        const reports = pendingReportsSnapshot.docs.map(doc => (Object.assign({ id: doc.id }, doc.data())));
        return { reports };
    }
    catch (error) {
        console.error('Error getting pending reports:', error);
        throw new functions.https.HttpsError('internal', 'Failed to get pending reports');
    }
});
// Get reviewed reports for admin panel
exports.getReviewedReports = functions.https.onCall(async (data, context) => {
    try {
        // Check authentication
        if (!context.auth) {
            throw new functions.https.HttpsError('unauthenticated', 'User must be logged in');
        }
        if (!(await (0, http_auth_1.isAdminUid)(context.auth.uid))) {
            throw new functions.https.HttpsError('permission-denied', 'Only admins can view reviewed reports');
        }
        const reviewedReportsSnapshot = await admin.firestore()
            .collection('reports')
            .where('status', '==', 'reviewed')
            .orderBy('reviewedAt', 'desc')
            .get();
        const reports = reviewedReportsSnapshot.docs.map(doc => (Object.assign({ id: doc.id }, doc.data())));
        return { reports };
    }
    catch (error) {
        console.error('Error getting reviewed reports:', error);
        throw new functions.https.HttpsError('internal', 'Failed to get reviewed reports');
    }
});
// Helper function to remove content
async function _removeContent(contentType, contentId) {
    try {
        if (contentType === 'event') {
            await admin.firestore().collection('events').doc(contentId).delete();
            console.log('Event removed:', contentId);
        }
        else if (contentType === 'user') {
            // For user content, you might want to suspend the account instead of deleting
            await admin.firestore().collection('users').doc(contentId).update({
                suspended: true,
                suspendedAt: new Date().toISOString(),
            });
            console.log('User suspended:', contentId);
        }
    }
    catch (error) {
        console.error('Error removing content:', error);
    }
}
// Helper function to send warning to user
async function _sendWarningToUser(contentType, contentId) {
    try {
        // This could send a notification or email to the user
        console.log('Warning sent to user for content:', { contentType, contentId });
    }
    catch (error) {
        console.error('Error sending warning:', error);
    }
}
// Report usage to Stripe Billing Meter
// This is CRITICAL for usage-based billing ($0.99 per booking)
exports.reportStripeUsage = functions.https.onRequest(async (req, res) => {
    var _a;
    (0, http_auth_1.setCorsHeaders)(res);
    if ((0, http_auth_1.handleOptions)(req, res))
        return;
    try {
        if (req.method !== 'POST') {
            res.status(405).json({ error: 'Method not allowed' });
            return;
        }
        const decoded = await (0, http_auth_1.requireAuth)(req, res);
        if (!decoded)
            return;
        const { eventName, quantity, timestamp, metadata } = req.body;
        if (!eventName) {
            res.status(400).json({ error: 'Missing required parameters: eventName' });
            return;
        }
        // Only allow known meter event names
        if (eventName !== 'booking_completed') {
            res.status(400).json({ error: 'Unsupported event name' });
            return;
        }
        const { stripe, isTest } = (0, http_auth_1.resolveStripeInstance)(stripeTest, stripeLive);
        const field = (0, http_auth_1.customerIdField)(isTest);
        // Customer must belong to the authenticated user
        const userDoc = await admin.firestore().collection('users').doc(decoded.uid).get();
        const customerId = (_a = userDoc.data()) === null || _a === void 0 ? void 0 : _a[field];
        if (!customerId || typeof customerId !== 'string' || !customerId.startsWith('cus_')) {
            res.status(400).json({ error: 'No Stripe customer found for authenticated user' });
            return;
        }
        console.log('Reporting usage to Stripe:', {
            uid: decoded.uid,
            customerId,
            eventName,
            quantity: quantity || 1,
            isTest,
        });
        const usageRecord = await stripe.billing.meterEvents.create({
            event_name: eventName,
            payload: {
                stripe_customer_id: customerId,
                value: String(quantity || 1),
            },
            timestamp: timestamp ? Math.floor(new Date(timestamp).getTime() / 1000) : Math.floor(Date.now() / 1000),
        });
        try {
            await admin.firestore().collection('stripe_usage').add({
                customerId,
                firebaseUID: decoded.uid,
                eventName,
                quantity: quantity || 1,
                timestamp: timestamp || new Date().toISOString(),
                metadata: metadata || {},
                stripeEventId: usageRecord.identifier,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                isTest,
            });
        }
        catch (firestoreError) {
            console.error('Warning: Failed to store usage in Firestore:', firestoreError);
        }
        console.log('Usage reported successfully:', usageRecord.identifier);
        res.status(200).json({
            success: true,
            id: usageRecord.identifier,
            message: 'Usage reported successfully',
        });
    }
    catch (error) {
        console.error('Error reporting usage to Stripe:', error);
        res.status(500).json({
            error: 'Failed to report usage',
        });
    }
});
// Create Stripe Customer
exports.createStripeCustomer = functions.https.onRequest(async (req, res) => {
    var _a;
    (0, http_auth_1.setCorsHeaders)(res);
    if ((0, http_auth_1.handleOptions)(req, res))
        return;
    try {
        if (req.method !== 'POST') {
            res.status(405).json({ error: 'Method not allowed' });
            return;
        }
        const decoded = await (0, http_auth_1.requireAuth)(req, res);
        if (!decoded)
            return;
        // Only allow creating/updating customer for the authenticated user
        const userId = decoded.uid;
        const { email, name } = req.body;
        const { stripe, isTest } = (0, http_auth_1.resolveStripeInstance)(stripeTest, stripeLive);
        const field = (0, http_auth_1.customerIdField)(isTest);
        console.log(`Creating Stripe customer for user ${userId} (isTest: ${isTest})`);
        const userDoc = await admin.firestore().collection('users').doc(userId).get();
        if (!userDoc.exists) {
            res.status(404).json({ error: 'User profile not found' });
            return;
        }
        const userData = userDoc.data();
        const existingCustomerId = userData === null || userData === void 0 ? void 0 : userData[field];
        if (existingCustomerId && typeof existingCustomerId === 'string' && existingCustomerId.startsWith('cus_')) {
            try {
                const existingCustomer = await stripe.customers.retrieve(existingCustomerId);
                if (!existingCustomer.deleted) {
                    console.log(`Customer already exists: ${existingCustomerId}`);
                    res.status(200).json({
                        customerId: existingCustomerId,
                        message: 'Customer already exists',
                        isNew: false
                    });
                    return;
                }
            }
            catch (error) {
                console.log('Existing customer ID is invalid, creating new one', error);
            }
        }
        const customerParams = {
            metadata: {
                firebaseUID: userId,
                app: 'OpenSlot',
                environment: isTest ? 'test' : 'live',
            },
        };
        if (email && typeof email === 'string' && email.trim() !== '') {
            customerParams.email = email.trim();
        }
        if (name && typeof name === 'string' && name.trim() !== '') {
            customerParams.name = name.trim();
        }
        let customer;
        try {
            customer = await stripe.customers.create(customerParams);
            console.log(`Created new Stripe customer: ${customer.id}`);
        }
        catch (createError) {
            if (createError.type === 'StripeInvalidRequestError' && ((_a = createError.message) === null || _a === void 0 ? void 0 : _a.includes('email'))) {
                console.log('Email validation failed, creating customer without email');
                delete customerParams.email;
                customer = await stripe.customers.create(customerParams);
                console.log(`Created new Stripe customer without email: ${customer.id}`);
            }
            else {
                throw createError;
            }
        }
        await admin.firestore().collection('users').doc(userId).update({
            [field]: customer.id,
            [`${field}_created`]: admin.firestore.FieldValue.serverTimestamp(),
        });
        console.log(`Updated Firestore user ${userId} with customer ID: ${customer.id}`);
        res.status(200).json({
            customerId: customer.id,
            message: 'Customer created successfully',
            isNew: true
        });
    }
    catch (error) {
        console.error('Error creating Stripe customer:', error);
        res.status(500).json({
            error: 'Failed to create customer',
        });
    }
});
//# sourceMappingURL=index.js.map