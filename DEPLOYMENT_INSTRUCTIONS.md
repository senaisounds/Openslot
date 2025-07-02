# Deployment Instructions for OpenSlot Web App

Follow these steps to deploy the OpenSlot web app properly and fix the "You're offline" issue:

## 1. Build the Flutter Web App

Make sure you have the correct Flutter environment set up:

```bash
# Ensure you're on the right Flutter channel (stable recommended)
flutter channel stable
flutter upgrade

# Clean the project to ensure a fresh build
flutter clean

# Get dependencies
flutter pub get

# Build the web app in release mode with renderer set to auto
flutter build web --release
```

## 2. Test Locally (Optional but Recommended)

Before deployment, test the web app locally to verify it works correctly:

```bash
# Serve the web build locally
cd build/web
python3 -m http.server 8000
```

Then open your browser to `http://localhost:8000` and verify the app loads correctly without showing the "You're offline" message.

## 3. Deploy to Firebase Hosting

```bash
# Make sure you're logged in to Firebase
firebase login

# Set the default project
firebase use open-mic-5cc8e

# Deploy to all hosting targets
firebase deploy --only hosting:main,hosting:openslot-me,hosting:openslot-me-domain,hosting:openslot-web-app
```

## 4. Verify the Deployment

Visit the following URLs to verify the app is working correctly:
- https://openslot.me
- https://open-mic-5cc8e.web.app
- (Any other domains configured in Firebase)

## Troubleshooting

If you still see the "You're offline" message:

1. **Clear Browser Cache**: Try clearing your browser cache or opening in an incognito/private window
2. **Check for Service Worker Issues**:
   ```bash
   # Add this to force update service workers
   firebase deploy --only hosting:main,hosting:openslot-me,hosting:openslot-me-domain,hosting:openslot-web-app -m "force service worker update"
   ```
3. **Check Browser Console**: Open developer tools and look for any errors in the console
4. **Try Different Browsers**: Test in Chrome, Firefox, Safari, and Edge to see if the issue is browser-specific
5. **Check Network Tab**: In developer tools, check the network tab to see if any requests are failing

## Notes

The key changes made to fix the "You're offline" issue are:

1. Completely rewritten `index.html` with:
   - A simpler, more robust Flutter initialization approach
   - Strong override of the browser's offline detection
   - Reliable fallback content if Flutter fails to load
   - Better error handling and logging

2. Updated Firebase configuration to target all hosting sites correctly

3. Added proper loading indicators and user feedback during initialization

If you make any changes to the web files, remember to rebuild the Flutter web app before deploying. 