#!/bin/bash

# Script to connect the custom domain to the Firebase sites

# First make sure we're using the correct project
firebase use open-mic-5cc8e

# Build the web app
echo "Building Flutter web app..."
flutter build web --release

# Deploy to all hosting targets
echo "Deploying to all hosting targets..."
firebase deploy --only hosting

# Verify sites are accessible
echo "Verifying sites are accessible..."
echo "Default site:"
curl -s -I https://open-mic-5cc8e.web.app | grep "HTTP"
echo "OpenSlot.me site:"
curl -s -I https://openslot-me.web.app | grep "HTTP"
echo "OpenSlot domain site:"
curl -s -I https://openslot-me-domain.web.app | grep "HTTP"
echo "OpenSlot web app site:"
curl -s -I https://openslot-web-app.web.app | grep "HTTP"

# Check domain resolution
echo "Checking domain resolution..."
dig openslot.me +short

echo "Done! If you're seeing 'You're offline' message, try clearing your browser cache or use a different browser."
echo "You can also try accessing the test page at: https://openslot.me/test.html" 