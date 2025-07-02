const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
if (admin.apps.length === 0) {
  admin.initializeApp();
}

const db = admin.firestore();

/**
 * Validates if a username is already taken
 * @param {string} username - The username to check
 * @param {string} userId - The user ID to exclude from the check
 * @returns {Promise<boolean>} True if the username is available, false if taken
 */
async function isUsernameAvailable(username, userId) {
  const snapshot = await db.collection('users')
    .where('username', '==', username)
    .get();
  
  // If no documents found, username is available
  if (snapshot.empty) {
    return true;
  }
  
  // If there's only one document and it's the current user, username is available
  if (snapshot.size === 1 && snapshot.docs[0].id === userId) {
    return true;
  }
  
  // Username is taken by another user
  return false;
}

/**
 * Validates user data for security issues
 * @param {Object} userData - The user data to validate
 * @returns {Object} Object with validation result and errors
 */
function validateUserData(userData) {
  const errors = {};
  
  // Username validation
  if (!userData.username) {
    errors.username = 'Username is required';
  } else if (userData.username.length < 3) {
    errors.username = 'Username must be at least 3 characters long';
  } else if (userData.username.length > 30) {
    errors.username = 'Username must not exceed 30 characters';
  } else if (!/^[a-zA-Z0-9_]+$/.test(userData.username)) {
    errors.username = 'Username can only contain letters, numbers, and underscores';
  }
  
  // Bio validation
  if (userData.bio && userData.bio.length > 500) {
    errors.bio = 'Bio must not exceed 500 characters';
  }
  
  // Check for potential XSS in bio
  if (userData.bio && /<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/i.test(userData.bio)) {
    errors.bio = 'Bio contains disallowed content';
  }
  
  // Social media validation
  if (userData.instagram && userData.instagram.includes(' ')) {
    errors.instagram = 'Instagram username should not contain spaces';
  }
  
  if (userData.twitter && userData.twitter.includes(' ')) {
    errors.twitter = 'Twitter username should not contain spaces';
  }
  
  return {
    isValid: Object.keys(errors).length === 0,
    errors
  };
}

/**
 * Cloud Function to validate and sanitize user data before saving
 */
exports.validateUserBeforeSave = functions.firestore
  .document('users/{userId}')
  .beforeUpdate(async (change, context) => {
    const newData = change.after.data();
    const oldData = change.before.data();
    const userId = context.params.userId;
    
    // Skip validation for admin updates
    if (newData._admin_update === true) {
      // Remove the admin flag before saving
      delete newData._admin_update;
      return change.after;
    }
    
    // Validate user data
    const validationResult = validateUserData(newData);
    
    if (!validationResult.isValid) {
      console.log(`User data validation failed: ${JSON.stringify(validationResult.errors)}`);
      throw new functions.https.HttpsError(
        'invalid-argument', 
        'The provided user data is invalid', 
        validationResult.errors
      );
    }
    
    // Check if username has changed and validate availability
    if (newData.username !== oldData.username) {
      const usernameAvailable = await isUsernameAvailable(newData.username, userId);
      
      if (!usernameAvailable) {
        throw new functions.https.HttpsError(
          'already-exists',
          'The username is already taken',
          { username: 'This username is already taken' }
        );
      }
    }
    
    // Sanitize user data
    newData.username = sanitizeText(newData.username);
    newData.bio = sanitizeText(newData.bio || '');
    newData.email = newData.email || oldData.email; // Preserve email if not provided
    
    // Remove any admin fields that might have been added
    delete newData.isAdmin;
    delete newData.admin;
    delete newData.role;
    
    // Return the sanitized data
    return { data: newData };
  });

/**
 * Cloud Function to validate new user creation
 */
exports.validateNewUser = functions.firestore
  .document('users/{userId}')
  .onCreate(async (snapshot, context) => {
    const userData = snapshot.data();
    const userId = context.params.userId;
    
    // Validate user data
    const validationResult = validateUserData(userData);
    
    if (!validationResult.isValid) {
      // Delete the invalid user
      await snapshot.ref.delete();
      
      console.log(`New user data validation failed: ${JSON.stringify(validationResult.errors)}`);
      throw new functions.https.HttpsError(
        'invalid-argument', 
        'The provided user data is invalid', 
        validationResult.errors
      );
    }
    
    // Check username availability
    const usernameAvailable = await isUsernameAvailable(userData.username, userId);
    
    if (!usernameAvailable) {
      // Delete the user with duplicate username
      await snapshot.ref.delete();
      
      throw new functions.https.HttpsError(
        'already-exists',
        'The username is already taken',
        { username: 'This username is already taken' }
      );
    }
    
    // User data is valid, no action needed
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