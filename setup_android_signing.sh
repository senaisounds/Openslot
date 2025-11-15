#!/bin/bash
# Android Release Signing Setup for OpenSlot
# This script will guide you through creating a release keystore

set -e

echo "🔐 Android Release Signing Setup"
echo "=================================="
echo ""
echo "This will create a keystore for signing your Android release builds."
echo ""

# Check if keytool is available
if ! command -v keytool &> /dev/null; then
    echo "❌ keytool not found!"
    echo "keytool is part of Java JDK. Please install Java JDK first:"
    echo "  brew install openjdk"
    exit 1
fi

echo "✅ keytool found"
echo ""

# Set keystore location
KEYSTORE_PATH="$HOME/.android/openslot-release.keystore"
KEY_PROPERTIES_PATH="android/key.properties"

# Check if keystore already exists
if [ -f "$KEYSTORE_PATH" ]; then
    echo "⚠️  Keystore already exists at: $KEYSTORE_PATH"
    read -p "Do you want to create a new one? This will overwrite the existing keystore. (y/n): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Using existing keystore."
    else
        rm "$KEYSTORE_PATH"
        echo "Removed old keystore. Creating new one..."
    fi
fi

# Create .android directory if it doesn't exist
mkdir -p "$HOME/.android"

# If keystore doesn't exist, create it
if [ ! -f "$KEYSTORE_PATH" ]; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Creating Release Keystore"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "You'll be asked to enter:"
    echo "  1. Keystore password (remember this!)"
    echo "  2. Key password (can be same as keystore password)"
    echo "  3. Your name"
    echo "  4. Organization (can use 'OpenSlot')"
    echo "  5. City, State, Country"
    echo ""
    echo "⚠️  IMPORTANT: Write down your passwords! You'll need them for every release."
    echo ""
    read -p "Press Enter to continue..."
    echo ""

    # Generate keystore
    keytool -genkey -v -keystore "$KEYSTORE_PATH" \
        -alias openslot \
        -keyalg RSA \
        -keysize 2048 \
        -validity 10000 \
        -storetype PKCS12

    if [ $? -eq 0 ]; then
        echo ""
        echo "✅ Keystore created successfully!"
        echo "📍 Location: $KEYSTORE_PATH"
    else
        echo "❌ Failed to create keystore"
        exit 1
    fi
else
    echo "✅ Using existing keystore: $KEYSTORE_PATH"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Creating key.properties File"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Prompt for passwords
echo "Now we need to create the key.properties file."
echo "This file will store your keystore passwords (it's in .gitignore)."
echo ""
read -sp "Enter your keystore password: " STORE_PASSWORD
echo ""
read -sp "Enter your key password: " KEY_PASSWORD
echo ""

# Create key.properties file
cat > "$KEY_PROPERTIES_PATH" << EOF
storePassword=$STORE_PASSWORD
keyPassword=$KEY_PASSWORD
keyAlias=openslot
storeFile=$KEYSTORE_PATH
EOF

echo ""
echo "✅ Created key.properties file"
echo ""

# Add to .gitignore if not already there
if ! grep -q "key.properties" .gitignore 2>/dev/null; then
    echo "android/key.properties" >> .gitignore
    echo "✅ Added key.properties to .gitignore"
fi

if ! grep -q ".keystore" .gitignore 2>/dev/null; then
    echo "*.keystore" >> .gitignore
    echo "✅ Added *.keystore to .gitignore"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Setup Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📁 Files created:"
echo "  • Keystore: $KEYSTORE_PATH"
echo "  • Properties: $KEY_PROPERTIES_PATH"
echo ""
echo "🔒 Security:"
echo "  • Keystore is stored in your home directory"
echo "  • key.properties added to .gitignore"
echo "  • Never commit these files to Git!"
echo ""
echo "💾 BACKUP REMINDER:"
echo "  • Save your keystore file in a secure location"
echo "  • Save your passwords in a password manager"
echo "  • You'll need these for EVERY app update!"
echo ""
echo "📋 Next Step:"
echo "  Run: ./update_android_build_config.sh"
echo "  This will update your build.gradle to use the keystore"
echo ""

