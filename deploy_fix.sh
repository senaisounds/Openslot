#!/bin/bash

# OpenSlot Web App Fix and Deployment Script

echo "Starting OpenSlot web app fix deployment..."

# 1. Create build/web directory if it doesn't exist
echo "Preparing build directory..."
mkdir -p build/web

# 2. Copy our fixed files to the build/web directory
echo "Copying fixed files..."
cp public/index.html build/web/
cp public/static_backup.html build/web/
cp public/fix-plugins.js build/web/

# 3. Check if Flutter web build exists (main.dart.js)
if [ ! -f "build/web/main.dart.js" ]; then
  echo "Warning: main.dart.js not found in build/web directory."
  echo "This may be a fresh deployment without an existing Flutter build."
  echo "You should run 'flutter build web' before deploying."
  
  read -p "Continue deployment without Flutter build? (y/n) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Deployment cancelled."
    exit 1
  fi
fi

# 4. Copy other necessary web files if they exist in the web directory
echo "Copying additional web assets..."
cp -r web/icons build/web/ 2>/dev/null || echo "No icons directory found"
cp web/favicon.png build/web/ 2>/dev/null || echo "No favicon.png found"
cp web/manifest.json build/web/ 2>/dev/null || echo "No manifest.json found"

# 5. Deploy to Firebase hosting
echo "Deploying to Firebase hosting..."
firebase deploy --only hosting

# 6. Deployment complete
echo "Deployment completed."
echo "If you encounter any issues, you can manually copy the fixed files to the hosting server."
echo "Remember that static_backup.html provides a fallback when the Flutter app fails to load." 