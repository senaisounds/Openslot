#!/bin/bash
# Update Android build.gradle to use release signing

set -e

echo "🔧 Updating Android Build Configuration"
echo "========================================"
echo ""

BUILD_GRADLE="android/app/build.gradle"

# Check if key.properties exists
if [ ! -f "android/key.properties" ]; then
    echo "❌ key.properties not found!"
    echo "Please run ./setup_android_signing.sh first"
    exit 1
fi

echo "✅ Found key.properties"
echo ""

# Create backup
cp "$BUILD_GRADLE" "$BUILD_GRADLE.backup"
echo "✅ Created backup: $BUILD_GRADLE.backup"
echo ""

# Create the new build.gradle content
cat > "$BUILD_GRADLE" << 'EOF'
plugins {
    id "com.android.application"
    id "kotlin-android"
    id "dev.flutter.flutter-gradle-plugin"
}

def localProperties = new Properties()
def localPropertiesFile = rootProject.file('local.properties')
if (localPropertiesFile.exists()) {
    localPropertiesFile.withReader('UTF-8') { reader ->
        localProperties.load(reader)
    }
}

def flutterVersionCode = localProperties.getProperty('flutter.versionCode')
if (flutterVersionCode == null) {
    flutterVersionCode = '1'
}

def flutterVersionName = localProperties.getProperty('flutter.versionName')
if (flutterVersionName == null) {
    flutterVersionName = '1.0'
}

// Load keystore properties
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    namespace "com.openslot.app"
    compileSdk 34
    ndkVersion flutter.ndkVersion

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = '1.8'
    }

    sourceSets {
        main.java.srcDirs += 'src/main/kotlin'
    }

    defaultConfig {
        applicationId "com.openslot.app"
        minSdkVersion 23
        targetSdkVersion flutter.targetSdkVersion
        versionCode flutterVersionCode.toInteger()
        versionName flutterVersionName
    }

    // Signing configurations
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }

    buildTypes {
        release {
            // Use release signing config
            signingConfig signingConfigs.release
            
            // Enable code shrinking and obfuscation
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
        debug {
            // Debug builds use debug signing
            signingConfig signingConfigs.debug
        }
    }
}

flutter {
    source '../..'
}

dependencies {}
EOF

echo "✅ Updated build.gradle with release signing configuration"
echo ""

# Create proguard rules if they don't exist
PROGUARD_FILE="android/app/proguard-rules.pro"
if [ ! -f "$PROGUARD_FILE" ]; then
    cat > "$PROGUARD_FILE" << 'EOF'
# OpenSlot ProGuard Rules

# Keep Stripe SDK
-keep class com.stripe.android.** { *; }

# Keep Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Preserve line numbers for debugging
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
EOF
    echo "✅ Created proguard-rules.pro"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Configuration Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📝 Changes made:"
echo "  • Updated build.gradle with release signing"
echo "  • Added code minification and obfuscation"
echo "  • Created ProGuard rules for Flutter/Firebase/Stripe"
echo "  • Backup saved to: $BUILD_GRADLE.backup"
echo ""
echo "🧪 Test the configuration:"
echo "  flutter build appbundle --release"
echo ""
echo "📦 This will create a release AAB at:"
echo "  build/app/outputs/bundle/release/app-release.aab"
echo ""
echo "🚀 Ready for Google Play Store!"
echo ""

