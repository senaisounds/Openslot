"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.setCorsHeaders = setCorsHeaders;
exports.handleOptions = handleOptions;
exports.requireAuth = requireAuth;
exports.isAdminUid = isAdminUid;
exports.resolveStripeInstance = resolveStripeInstance;
exports.customerIdField = customerIdField;
exports.passwordsMatch = passwordsMatch;
const admin = require("firebase-admin");
const functions = require("firebase-functions");
function setCorsHeaders(res, methods = 'POST, OPTIONS') {
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', methods);
    res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-OpenSlot-Client, X-Requested-With');
    res.set('Access-Control-Max-Age', '3600');
}
function handleOptions(req, res) {
    if (req.method === 'OPTIONS') {
        res.status(204).send('');
        return true;
    }
    return false;
}
/**
 * Verify Firebase ID token from Authorization: Bearer <token>.
 * Sends 401 and returns null on failure.
 */
async function requireAuth(req, res) {
    const header = req.get('Authorization') || '';
    const match = header.match(/^Bearer\s+(.+)$/i);
    if (!match) {
        res.status(401).json({ error: 'Unauthenticated', details: 'Missing Bearer token' });
        return null;
    }
    try {
        return await admin.auth().verifyIdToken(match[1].trim());
    }
    catch (error) {
        console.error('ID token verification failed', error);
        res.status(401).json({ error: 'Unauthenticated', details: 'Invalid or expired token' });
        return null;
    }
}
async function isAdminUid(uid) {
    var _a;
    try {
        const adminDoc = await admin.firestore().collection('admins').doc(uid).get();
        return adminDoc.exists && ((_a = adminDoc.data()) === null || _a === void 0 ? void 0 : _a.isAdmin) === true;
    }
    catch (error) {
        console.error('Admin check failed for uid', error);
        return false;
    }
}
/**
 * Resolve Stripe instance from server config only.
 * Defaults to test unless stripe.mode / STRIPE_MODE is explicitly "live".
 * Client-supplied debug flags are ignored.
 */
function resolveStripeInstance(stripeTest, stripeLive) {
    var _a;
    const mode = (((_a = functions.config().stripe) === null || _a === void 0 ? void 0 : _a.mode) ||
        process.env.STRIPE_MODE ||
        'test')
        .toString()
        .toLowerCase();
    const isTest = mode !== 'live';
    return { stripe: isTest ? stripeTest : stripeLive, isTest };
}
function customerIdField(isTest) {
    return isTest ? 'test-customerID' : 'customerID';
}
/** Compare event passwords without logging either value. */
function passwordsMatch(stored, received) {
    try {
        const decodedReceived = decodeURIComponent(received);
        const encodedStored = encodeURIComponent(stored);
        const encodedReceived = encodeURIComponent(decodedReceived);
        return encodedStored === encodedReceived || stored === decodedReceived || stored === received;
    }
    catch (error) {
        console.error('Password compare decode failed', error);
        return stored === received;
    }
}
//# sourceMappingURL=http_auth.js.map