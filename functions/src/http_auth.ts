import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';
import Stripe from 'stripe';

/**
 * Shared auth / CORS / Stripe helpers for HTTP Cloud Functions.
 * P0 security: never trust client-supplied identity or Stripe mode.
 */

type HttpRequest = functions.https.Request;
type HttpResponse = functions.Response;

export function setCorsHeaders(
  res: HttpResponse,
  methods: string = 'POST, OPTIONS'
): void {
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', methods);
  res.set(
    'Access-Control-Allow-Headers',
    'Content-Type, Authorization, X-OpenSlot-Client, X-Requested-With'
  );
  res.set('Access-Control-Max-Age', '3600');
}

export function handleOptions(req: HttpRequest, res: HttpResponse): boolean {
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
export async function requireAuth(
  req: HttpRequest,
  res: HttpResponse
): Promise<admin.auth.DecodedIdToken | null> {
  const header = req.get('Authorization') || '';
  const match = header.match(/^Bearer\s+(.+)$/i);
  if (!match) {
    res.status(401).json({ error: 'Unauthenticated', details: 'Missing Bearer token' });
    return null;
  }

  try {
    return await admin.auth().verifyIdToken(match[1].trim());
  } catch (error) {
    console.error('ID token verification failed', error);
    res.status(401).json({ error: 'Unauthenticated', details: 'Invalid or expired token' });
    return null;
  }
}

export async function isAdminUid(uid: string): Promise<boolean> {
  try {
    const adminDoc = await admin.firestore().collection('admins').doc(uid).get();
    return adminDoc.exists && adminDoc.data()?.isAdmin === true;
  } catch (error) {
    console.error('Admin check failed for uid', error);
    return false;
  }
}

/**
 * Resolve Stripe instance from server config only.
 * Defaults to test unless stripe.mode / STRIPE_MODE is explicitly "live".
 * Client-supplied debug flags are ignored.
 */
export function resolveStripeInstance(
  stripeTest: Stripe,
  stripeLive: Stripe
): { stripe: Stripe; isTest: boolean } {
  const mode = (
    functions.config().stripe?.mode ||
    process.env.STRIPE_MODE ||
    'test'
  )
    .toString()
    .toLowerCase();
  const isTest = mode !== 'live';
  return { stripe: isTest ? stripeTest : stripeLive, isTest };
}

export function customerIdField(isTest: boolean): string {
  return isTest ? 'test-customerID' : 'customerID';
}

/** Compare event passwords without logging either value. */
export function passwordsMatch(stored: string, received: string): boolean {
  try {
    const decodedReceived = decodeURIComponent(received);
    const encodedStored = encodeURIComponent(stored);
    const encodedReceived = encodeURIComponent(decodedReceived);
    return encodedStored === encodedReceived || stored === decodedReceived || stored === received;
  } catch (error) {
    console.error('Password compare decode failed', error);
    return stored === received;
  }
}
