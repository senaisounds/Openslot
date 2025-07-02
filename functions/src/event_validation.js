const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
if (admin.apps.length === 0) {
  admin.initializeApp();
}

const db = admin.firestore();

/**
 * Validates event data for security issues
 * @param {Object} eventData - The event data to validate
 * @returns {Object} Object with validation result and errors
 */
function validateEventData(eventData) {
  const errors = {};
  
  // Name validation
  if (!eventData.name) {
    errors.name = 'Event name is required';
  } else if (eventData.name.length < 3) {
    errors.name = 'Event name must be at least 3 characters long';
  } else if (eventData.name.length > 100) {
    errors.name = 'Event name must not exceed 100 characters';
  }
  
  // Description validation
  if (!eventData.description) {
    errors.description = 'Event description is required';
  } else if (eventData.description.length < 10) {
    errors.description = 'Description must be at least 10 characters long';
  } else if (eventData.description.length > 2000) {
    errors.description = 'Description must not exceed 2000 characters';
  }
  
  // Check for potential XSS in description
  if (eventData.description && /<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/i.test(eventData.description)) {
    errors.description = 'Description contains disallowed content';
  }
  
  // Address validation
  if (!eventData.address) {
    errors.address = 'Event address is required';
  }
  
  // Category validation
  if (!eventData.category) {
    errors.category = 'Event category is required';
  }
  
  // Date validation
  if (!eventData.date) {
    errors.date = 'Event date is required';
  } else {
    const date = eventData.date.toDate ? eventData.date.toDate() : new Date(eventData.date);
    
    // Lower and upper limits for event dates
    const lowerLimit = new Date('2020-01-01');
    const upperLimit = new Date();
    upperLimit.setFullYear(upperLimit.getFullYear() + 1); // One year from now
    
    if (date < lowerLimit) {
      errors.date = 'Event date cannot be before 2020';
    } else if (date > upperLimit) {
      errors.date = 'Event date cannot be more than one year in the future';
    }
  }
  
  // Rules validation
  if (eventData.rules && eventData.rules.length > 1000) {
    errors.rules = 'Rules must not exceed 1000 characters';
  }
  
  // Check for XSS in rules
  if (eventData.rules && /<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/i.test(eventData.rules)) {
    errors.rules = 'Rules contain disallowed content';
  }
  
  // Capacity validation
  if (eventData.capacity !== undefined) {
    if (isNaN(eventData.capacity) || !Number.isInteger(Number(eventData.capacity))) {
      errors.capacity = 'Capacity must be a valid integer';
    } else if (Number(eventData.capacity) < 1) {
      errors.capacity = 'Capacity must be at least 1';
    } else if (Number(eventData.capacity) > 10000) {
      errors.capacity = 'Capacity cannot exceed 10,000';
    }
  }
  
  // Verify host exists
  if (!eventData.host) {
    errors.host = 'Event host is required';
  }
  
  return {
    isValid: Object.keys(errors).length === 0,
    errors
  };
}

/**
 * Check if a user has permission to modify an event
 * @param {string} eventId - The event ID
 * @param {string} userId - The user ID requesting the modification
 * @returns {Promise<boolean>} True if the user has permission
 */
async function hasEventPermission(eventId, userId) {
  if (!eventId || !userId) {
    return false;
  }
  
  try {
    const eventDoc = await db.collection('events').doc(eventId).get();
    
    if (!eventDoc.exists) {
      return false;
    }
    
    const eventData = eventDoc.data();
    
    // Check if user is the event host
    if (eventData.host === userId) {
      return true;
    }
    
    // Check if user is an admin
    const adminDoc = await db.collection('admins').doc(userId).get();
    return adminDoc.exists && adminDoc.data().isAdmin === true;
  } catch (error) {
    console.error('Error checking event permission:', error);
    return false;
  }
}

/**
 * Cloud Function to validate and sanitize event data before saving
 */
exports.validateEventBeforeSave = functions.firestore
  .document('events/{eventId}')
  .beforeUpdate(async (change, context) => {
    const newData = change.after.data();
    const oldData = change.before.data();
    const eventId = context.params.eventId;
    
    // Verify that the user has permission to modify this event
    // This requires an auth token to be passed, which is available in callable functions
    const auth = context.auth;
    if (auth && auth.uid) {
      const hasPermission = await hasEventPermission(eventId, auth.uid);
      
      if (!hasPermission) {
        throw new functions.https.HttpsError(
          'permission-denied',
          'You do not have permission to modify this event'
        );
      }
    }
    
    // Skip validation for admin updates
    if (newData._admin_update === true) {
      // Remove the admin flag before saving
      delete newData._admin_update;
      return change.after;
    }
    
    // Validate event data
    const validationResult = validateEventData(newData);
    
    if (!validationResult.isValid) {
      console.log(`Event data validation failed: ${JSON.stringify(validationResult.errors)}`);
      throw new functions.https.HttpsError(
        'invalid-argument', 
        'The provided event data is invalid', 
        validationResult.errors
      );
    }
    
    // Sanitize event data
    newData.name = sanitizeText(newData.name);
    newData.description = sanitizeText(newData.description);
    newData.address = sanitizeText(newData.address);
    newData.category = sanitizeText(newData.category);
    newData.rules = sanitizeText(newData.rules || '');
    
    // Preserve immutable fields
    newData.host = oldData.host; // Host cannot be changed
    newData.created = oldData.created; // Creation date cannot be changed
    
    // Return the sanitized data
    return { data: newData };
  });

/**
 * Cloud Function to validate new event creation
 */
exports.validateNewEvent = functions.firestore
  .document('events/{eventId}')
  .onCreate(async (snapshot, context) => {
    const eventData = snapshot.data();
    
    // Validate event data
    const validationResult = validateEventData(eventData);
    
    if (!validationResult.isValid) {
      // Delete the invalid event
      await snapshot.ref.delete();
      
      console.log(`New event validation failed: ${JSON.stringify(validationResult.errors)}`);
      throw new functions.https.HttpsError(
        'invalid-argument', 
        'The provided event data is invalid', 
        validationResult.errors
      );
    }
    
    // Event data is valid, no action needed
    return null;
  });

/**
 * Cloud Function to enforce user limit when joining events
 */
exports.enforceEventReservationLimits = functions.firestore
  .document('events/{eventId}')
  .onUpdate(async (change, context) => {
    const newData = change.after.data();
    const oldData = change.before.data();
    
    // Check if attendees array has changed
    if (JSON.stringify(newData.attendees) === JSON.stringify(oldData.attendees)) {
      return null; // No changes to attendees
    }
    
    // Verify capacity limits
    if (newData.capacity && newData.attendees && newData.attendees.length > newData.capacity) {
      // Move excess attendees to waitlist
      const excessCount = newData.attendees.length - newData.capacity;
      const excessAttendees = newData.attendees.slice(-excessCount);
      
      // Remove excess attendees from the attendees list
      newData.attendees = newData.attendees.slice(0, newData.capacity);
      
      // Add excess attendees to waitlist if they're not already there
      if (!newData.waitlist) {
        newData.waitlist = [];
      }
      
      for (const attendee of excessAttendees) {
        if (!newData.waitlist.includes(attendee)) {
          newData.waitlist.push(attendee);
        }
      }
      
      // Update the document with corrected attendees and waitlist
      await change.after.ref.update({
        attendees: newData.attendees,
        waitlist: newData.waitlist
      });
    }
    
    return null;
  });

/**
 * Sanitize text to prevent XSS attacks
 * @param {string} text - Text to sanitize
 * @returns {string} Sanitized text
 */
function sanitizeText(text) {
  if (!text) return '';
  
  // Remove HTML tags
  const sanitized = text.replace(/<[^>]*>?/gm, '');
  
  // Trim whitespace
  return sanitized.trim();
} 