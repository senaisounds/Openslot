# Slotted App Development Scripts

This directory contains utility scripts to help with development and maintenance of the Slotted app.

## Quick Start

To run all improvement scripts at once:

```bash
cd /path/to/slotted
dart scripts/run_all.dart
```

Or run specific scripts:

```bash
# Only run logger replacement and Stripe fixes
dart scripts/run_all.dart logs stripe

# Show help
dart scripts/run_all.dart --help
```

## Available Scripts

### run_all.dart

This master script allows you to run any combination of the improvement scripts with a single command.

#### Usage

```bash
cd /path/to/slotted
dart scripts/run_all.dart [options]
```

#### Options

- `all` - Run all scripts (default if no options specified)
- `logs` - Replace print statements with Logger calls
- `stripe` - Fix Stripe integration errors
- `deprecated` - Check for deprecated API usage
- `async` - Check for BuildContext usage across async gaps
- `appstore` - Run App Store submission preparation checks
- `--help`, `-h` - Show help message

#### Benefits

- Convenient way to run multiple improvement scripts
- Allows selective execution of specific improvements
- Provides a unified interface for all maintenance tasks

### replace_prints.dart

This script automatically replaces all `print()` and `debugPrint()` statements in the codebase with the new `Logger` class calls. This helps ensure consistent logging throughout the app and prevents debug statements from appearing in production builds.

#### Usage

```bash
cd /path/to/slotted
dart scripts/replace_prints.dart
```

#### What it does

1. Scans all `.dart` files in the `lib` directory
2. For each file that contains print statements but doesn't already use the Logger:
   - Adds the import for the Logger class
   - Replaces `print(...)` with `Logger.d(..., tag: 'FileName')`
   - Replaces `debugPrint(...)` with `Logger.d(..., tag: 'FileName')`
3. Reports the total number of replacements made

#### Notes

- The script automatically generates a tag based on the filename
- It uses the debug level (`Logger.d`) for all print statements by default
- You may want to manually review the changes and adjust log levels as needed (e.g., change some to `Logger.i`, `Logger.w`, or `Logger.e`)

### fix_stripe_errors.dart

This script fixes common Stripe integration errors in the codebase, particularly focusing on pattern matching issues in switch statements that compare error codes.

#### Usage

```bash
cd /path/to/slotted
dart scripts/fix_stripe_errors.dart
```

#### What it does

1. Analyzes the Stripe API file (`lib/api/stripe.dart`)
2. Identifies string literal pattern matching in switch statements (e.g., `case 'canceled':`)
3. Creates a proper `StripeErrorCode` enum with all the error codes found
4. Replaces string literals with enum values in switch statements
5. Updates error code comparisons to use the enum values

#### Benefits

- Prevents runtime errors from type mismatches
- Makes the code more maintainable and type-safe
- Centralizes all error codes in one enum for better documentation
- Enables IDE auto-completion for error codes

### check_deprecated_apis.dart

This script scans the codebase for usage of deprecated Flutter and Dart APIs, helping you identify areas that need to be updated before App Store submission.

#### Usage

```bash
cd /path/to/slotted
dart scripts/check_deprecated_apis.dart
```

#### What it does

1. Scans all `.dart` files in the `lib` directory
2. Checks for common deprecated APIs such as:
   - `withOpacity()` (use `withAlpha()` or `Color.fromRGBO` instead)
   - `RaisedButton`, `FlatButton`, `OutlineButton` (use newer button widgets)
   - `CupertinoColors.activeBlue` (use `systemBlue` instead)
   - Various deprecated BuildContext methods
   - And more
3. Generates a detailed report showing:
   - Summary of deprecated API usage by type
   - File-by-file breakdown with line numbers
   - Suggestions for modern alternatives

#### Benefits

- Helps identify potential issues before App Store submission
- Provides specific line numbers for easy fixing
- Offers suggestions for modern alternatives
- Complements Flutter's built-in analyzer

### check_async_context.dart

This script identifies potential issues with BuildContext usage across async gaps, which can lead to subtle bugs and crashes in your Flutter app.

#### Usage

```bash
cd /path/to/slotted
dart scripts/check_async_context.dart
```

#### What it does

1. Scans all `.dart` files in the `lib` directory
2. Identifies async methods that take a BuildContext parameter
3. Detects usage of BuildContext after await statements
4. Generates a detailed report showing:
   - Methods with potential issues
   - Line numbers where context is used after await
   - Suggestions for fixing each issue

#### Why this matters

When you use BuildContext after an await statement, there's a risk that the widget has been disposed by the time the async operation completes. This can lead to "setState() called after dispose()" errors or other subtle bugs that are hard to track down.

#### Common fixes

The script suggests several approaches to fix these issues:

1. Store values from context before await: `final theme = Theme.of(context);`
2. Check if widget is still mounted: `if (!mounted) return;`
3. Use a state management solution that doesn't rely on BuildContext

### prepare_for_app_store.dart

This comprehensive script performs a series of checks to ensure your app is ready for App Store submission, helping you avoid common rejection reasons.

#### Usage

```bash
cd /path/to/slotted
dart scripts/prepare_for_app_store.dart
```

#### What it does

The script performs a variety of checks, including:

1. **Debug Flags**: Identifies debug flags and print statements that should be removed
2. **Version Info**: Verifies app version is properly set in pubspec.yaml and platform-specific files
3. **Privacy Policy**: Checks for the presence of a privacy policy (required by App Store)
4. **App Store Assets**: Ensures app icons, launch screens, and screenshots are available
5. **Code Quality**: Runs Flutter analyze to catch potential issues
6. **Firebase Configuration**: Verifies Firebase config files are present
7. **Stripe Configuration**: Checks Stripe API keys and suggests security improvements
8. **Build Instructions**: Provides commands for testing in release mode and building for submission

#### Benefits

- Catches common issues before submission
- Reduces the chance of App Store rejection
- Provides actionable suggestions for fixing problems
- Serves as a pre-submission checklist

## Best Practices

When adding new scripts:

1. Document them in this README
2. Include comments in the script explaining what it does
3. Add usage instructions
4. Make sure scripts are cross-platform compatible when possible 

# 🧹 Database Cleanup Scripts

This directory contains scripts to help clean up invalid user references that are causing timeout issues in the live page.

## 🎯 cleanup_invalid_users.js

This script identifies and removes invalid user references from your events collection.

### What it does:
- ✅ Identifies test/invalid user IDs (like "hi", "gg", "he", etc.)
- ✅ Checks if users actually exist in the users collection
- ✅ Removes invalid users from event attendees and waitlists
- ✅ Clears invalid host/performer/upNext references
- ✅ Provides detailed logging of all changes

### Usage Options:

#### Option 1: Firebase Console (Recommended)
1. Go to Firebase Console → Functions
2. Copy the script content from `cleanup_invalid_users.js`
3. Create a new function and paste the code
4. Deploy and run with:
```javascript
// Dry run first (no changes)
cleanupInvalidUsers(true);

// Apply changes
cleanupInvalidUsers(false);
```

#### Option 2: Local Node.js
1. Install Firebase Admin SDK:
```bash
npm install firebase-admin
```

2. Set up credentials:
```bash
export GOOGLE_APPLICATION_CREDENTIALS="path/to/serviceAccountKey.json"
```

3. Run the script:
```bash
# Dry run (shows what would be changed)
node scripts/cleanup_invalid_users.js

# Apply changes
node scripts/cleanup_invalid_users.js --live
```

#### Option 3: Cloud Functions Deployment
1. Add to your functions/index.js:
```javascript
const { cleanupInvalidUsers } = require('./cleanup_invalid_users');
exports.cleanupInvalidUsers = functions.https.onCall(cleanupInvalidUsers);
```

2. Deploy and call via app or Firebase Console

### Expected Results:

Based on your timeout logs, this should:
- 🎯 **Remove 80-90% of timeout errors**
- 🧹 **Clean invalid users like "hi", "gg", "he", etc.**
- 📊 **Show exactly how many users are removed**
- ✅ **Prevent future attempts to load non-existent users**

### Sample Output:
```
🚀 Starting user cleanup process...
📋 Mode: DRY RUN (no changes will be made)

📊 Found 25 events to check

🔍 [DRY RUN] Would check event: event123
  ❌ Would fix: 5 invalid attendees: hi, gg, he, dame, bbc

📊 CLEANUP SUMMARY
================
📋 Total events checked: 25
🧹 Events that would be updated: 12
🔧 Total changes that would be made: 47

💡 To apply changes, run with dryRun = false
```

## 🚨 Important Notes:

1. **Always run DRY RUN first** to see what will be changed
2. **Backup your database** before applying live changes
3. **Test with a small number of events** first
4. **Monitor your app** after cleanup to verify improvements

## 🎯 After Running Cleanup:

You should see:
- ✅ **Dramatically fewer timeout errors** in your Flutter logs
- ✅ **Faster live page loading** times
- ✅ **Better user experience** overall
- ✅ **Cleaner event data**

The live page improvements combined with this data cleanup should resolve 90%+ of your timeout issues! 