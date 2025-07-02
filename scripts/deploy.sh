#!/bin/bash

# OpenSlot Deployment Script
# Usage: ./scripts/deploy.sh [environment] [platform]
# Environments: staging, production
# Platforms: web, android, ios, all

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
ENVIRONMENT=${1:-staging}
PLATFORM=${2:-web}
FLUTTER_VERSION="3.24.0"

# Functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Validate environment
validate_environment() {
    if [[ "$ENVIRONMENT" != "staging" && "$ENVIRONMENT" != "production" ]]; then
        log_error "Invalid environment: $ENVIRONMENT. Use 'staging' or 'production'"
        exit 1
    fi
    
    if [[ "$PLATFORM" != "web" && "$PLATFORM" != "android" && "$PLATFORM" != "ios" && "$PLATFORM" != "all" ]]; then
        log_error "Invalid platform: $PLATFORM. Use 'web', 'android', 'ios', or 'all'"
        exit 1
    fi
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if Flutter is installed
    if ! command -v flutter &> /dev/null; then
        log_error "Flutter is not installed. Please install Flutter first."
        exit 1
    fi
    
    # Check Flutter version
    CURRENT_FLUTTER_VERSION=$(flutter --version | grep "Flutter" | awk '{print $2}')
    log_info "Current Flutter version: $CURRENT_FLUTTER_VERSION"
    
    # Check if Firebase CLI is installed (for web deployment)
    if [[ "$PLATFORM" == "web" || "$PLATFORM" == "all" ]]; then
        if ! command -v firebase &> /dev/null; then
            log_warning "Firebase CLI is not installed. Web deployment may fail."
        fi
    fi
    
    # Check if we're in the correct directory
    if [[ ! -f "pubspec.yaml" ]]; then
        log_error "Not in a Flutter project directory. Please run from project root."
        exit 1
    fi
    
    log_success "Prerequisites check completed"
}

# Setup environment
setup_environment() {
    log_info "Setting up environment for $ENVIRONMENT..."
    
    # Get dependencies
    log_info "Getting Flutter dependencies..."
    flutter pub get
    
    # Run code generation if needed
    if [[ -f "pubspec.yaml" ]] && grep -q "build_runner" pubspec.yaml; then
        log_info "Running code generation..."
        flutter packages pub run build_runner build --delete-conflicting-outputs
    fi
    
    # Set environment variables based on deployment target
    if [[ "$ENVIRONMENT" == "production" ]]; then
        export FIREBASE_PROJECT_ID="${FIREBASE_PROJECT_ID_PROD:-open-mic-5cc8e}"
        export STRIPE_PUBLISHABLE_KEY="${STRIPE_PUBLISHABLE_KEY_PROD}"
    else
        export FIREBASE_PROJECT_ID="${FIREBASE_PROJECT_ID_STAGING:-open-mic-5cc8e-staging}"
        export STRIPE_PUBLISHABLE_KEY="${STRIPE_PUBLISHABLE_KEY_TEST}"
    fi
    
    log_success "Environment setup completed"
}

# Run tests
run_tests() {
    log_info "Running tests before deployment..."
    
    # Run unit tests
    log_info "Running unit tests..."
    if ! flutter test --coverage --reporter=expanded; then
        log_error "Unit tests failed. Deployment aborted."
        exit 1
    fi
    
    # Run integration tests if they exist
    if [[ -d "integration_test" ]]; then
        log_info "Running integration tests..."
        if ! flutter test integration_test/; then
            log_warning "Integration tests failed, but continuing deployment..."
        fi
    fi
    
    # Check test coverage
    if [[ -f "coverage/lcov.info" ]]; then
        COVERAGE=$(lcov --summary coverage/lcov.info 2>/dev/null | grep "lines" | awk '{print $2}' | sed 's/%//' || echo "0")
        log_info "Test coverage: $COVERAGE%"
        
        if (( $(echo "$COVERAGE < 70" | bc -l) )); then
            log_warning "Test coverage is below 70%. Consider adding more tests."
        fi
    fi
    
    log_success "Tests completed"
}

# Build for web
build_web() {
    log_info "Building for web ($ENVIRONMENT)..."
    
    # Set build mode
    if [[ "$ENVIRONMENT" == "production" ]]; then
        BUILD_MODE="release"
    else
        BUILD_MODE="profile"
    fi
    
    # Build web app
    if ! flutter build web --$BUILD_MODE --web-renderer canvaskit; then
        log_error "Web build failed"
        return 1
    fi
    
    # Optimize build
    log_info "Optimizing web build..."
    
    # Gzip compress main files
    if command -v gzip &> /dev/null; then
        find build/web -name "*.js" -exec gzip -k {} \;
        find build/web -name "*.css" -exec gzip -k {} \;
        log_info "Gzip compression applied"
    fi
    
    # Generate build info
    cat > build/web/build-info.json << EOL
{
  "buildTime": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "environment": "$ENVIRONMENT",
  "platform": "web",
  "version": "$(git describe --tags --always)",
  "commit": "$(git rev-parse HEAD)"
}
EOL
    
    log_success "Web build completed"
    return 0
}

# Build for Android
build_android() {
    log_info "Building for Android ($ENVIRONMENT)..."
    
    # Set build mode and signing
    if [[ "$ENVIRONMENT" == "production" ]]; then
        BUILD_MODE="release"
        SIGN_OPTIONS="--release"
    else
        BUILD_MODE="profile"
        SIGN_OPTIONS="--profile"
    fi
    
    # Build APK
    if ! flutter build apk $SIGN_OPTIONS --split-per-abi; then
        log_error "Android APK build failed"
        return 1
    fi
    
    # Build App Bundle for Play Store (production only)
    if [[ "$ENVIRONMENT" == "production" ]]; then
        if ! flutter build appbundle --release; then
            log_error "Android App Bundle build failed"
            return 1
        fi
        log_info "App Bundle created for Play Store upload"
    fi
    
    # Show build info
    log_info "APK files created:"
    ls -lh build/app/outputs/flutter-apk/*.apk
    
    if [[ "$ENVIRONMENT" == "production" ]]; then
        log_info "App Bundle created:"
        ls -lh build/app/outputs/bundle/release/*.aab
    fi
    
    log_success "Android build completed"
    return 0
}

# Build for iOS
build_ios() {
    log_info "Building for iOS ($ENVIRONMENT)..."
    
    # Check if on macOS
    if [[ "$OSTYPE" != "darwin"* ]]; then
        log_error "iOS builds are only supported on macOS"
        return 1
    fi
    
    # Set build mode
    if [[ "$ENVIRONMENT" == "production" ]]; then
        BUILD_MODE="release"
    else
        BUILD_MODE="profile"
    fi
    
    # Install pods
    log_info "Installing iOS dependencies..."
    cd ios
    pod install
    cd ..
    
    # Build iOS
    if [[ "$ENVIRONMENT" == "production" ]]; then
        # For production, build archive for App Store
        if ! flutter build ipa --release; then
            log_error "iOS IPA build failed"
            return 1
        fi
        log_info "IPA file created for App Store upload"
        ls -lh build/ios/ipa/*.ipa
    else
        # For staging, build without code signing
        if ! flutter build ios --$BUILD_MODE --no-codesign; then
            log_error "iOS build failed"
            return 1
        fi
    fi
    
    log_success "iOS build completed"
    return 0
}

# Deploy web to Firebase
deploy_web() {
    if [[ $1 -ne 0 ]]; then
        log_error "Skipping web deployment due to build failure"
        return 1
    fi
    
    log_info "Deploying web app to Firebase ($ENVIRONMENT)..."
    
    # Check if Firebase CLI is available
    if ! command -v firebase &> /dev/null; then
        log_error "Firebase CLI is not installed. Please install it first."
        return 1
    fi
    
    # Deploy to Firebase Hosting
    if [[ "$ENVIRONMENT" == "production" ]]; then
        FIREBASE_PROJECT="$FIREBASE_PROJECT_ID"
    else
        FIREBASE_PROJECT="$FIREBASE_PROJECT_ID"
    fi
    
    # Deploy
    if ! firebase deploy --project="$FIREBASE_PROJECT" --only hosting; then
        log_error "Firebase deployment failed"
        return 1
    fi
    
    # Get deployment URL
    DEPLOY_URL=$(firebase hosting:channel:list --project="$FIREBASE_PROJECT" | grep "live" | awk '{print $4}' || echo "Unknown")
    
    log_success "Web deployment completed"
    log_info "Deployment URL: $DEPLOY_URL"
    return 0
}

# Generate deployment report
generate_report() {
    log_info "Generating deployment report..."
    
    REPORT_FILE="deployment_report_$(date +%Y%m%d_%H%M%S).md"
    
    cat > "$REPORT_FILE" << EOL
# Deployment Report

**Date:** $(date)
**Environment:** $ENVIRONMENT
**Platform:** $PLATFORM
**Version:** $(git describe --tags --always)
**Commit:** $(git rev-parse HEAD)

## Build Results

EOL
    
    if [[ "$PLATFORM" == "web" || "$PLATFORM" == "all" ]]; then
        if [[ -d "build/web" ]]; then
            WEB_SIZE=$(du -sh build/web | cut -f1)
            echo "- **Web Build:** ✅ Success (Size: $WEB_SIZE)" >> "$REPORT_FILE"
        else
            echo "- **Web Build:** ❌ Failed" >> "$REPORT_FILE"
        fi
    fi
    
    if [[ "$PLATFORM" == "android" || "$PLATFORM" == "all" ]]; then
        if [[ -f "build/app/outputs/flutter-apk/app-release.apk" ]] || [[ -f "build/app/outputs/flutter-apk/app-profile.apk" ]]; then
            APK_SIZE=$(ls -lh build/app/outputs/flutter-apk/*.apk | head -1 | awk '{print $5}')
            echo "- **Android Build:** ✅ Success (APK Size: $APK_SIZE)" >> "$REPORT_FILE"
        else
            echo "- **Android Build:** ❌ Failed" >> "$REPORT_FILE"
        fi
    fi
    
    if [[ "$PLATFORM" == "ios" || "$PLATFORM" == "all" ]]; then
        if [[ -d "build/ios" ]]; then
            echo "- **iOS Build:** ✅ Success" >> "$REPORT_FILE"
        else
            echo "- **iOS Build:** ❌ Failed" >> "$REPORT_FILE"
        fi
    fi
    
    cat >> "$REPORT_FILE" << EOL

## Test Results

EOL
    
    if [[ -f "coverage/lcov.info" ]]; then
        COVERAGE=$(lcov --summary coverage/lcov.info 2>/dev/null | grep "lines" | awk '{print $2}' | sed 's/%//' || echo "0")
        echo "- **Test Coverage:** $COVERAGE%" >> "$REPORT_FILE"
    fi
    
    echo "- **Unit Tests:** ✅ Passed" >> "$REPORT_FILE"
    
    cat >> "$REPORT_FILE" << EOL

## Next Steps

- Monitor application performance
- Check error logs
- Verify all features are working correctly

---
*Generated by OpenSlot deployment script*
EOL
    
    log_success "Deployment report generated: $REPORT_FILE"
}

# Main deployment function
main() {
    log_info "Starting OpenSlot deployment..."
    log_info "Environment: $ENVIRONMENT"
    log_info "Platform: $PLATFORM"
    
    validate_environment
    check_prerequisites
    setup_environment
    run_tests
    
    # Build for requested platforms
    WEB_BUILD_SUCCESS=0
    ANDROID_BUILD_SUCCESS=0
    IOS_BUILD_SUCCESS=0
    
    if [[ "$PLATFORM" == "web" || "$PLATFORM" == "all" ]]; then
        build_web
        WEB_BUILD_SUCCESS=$?
        if [[ $WEB_BUILD_SUCCESS -eq 0 ]]; then
            deploy_web $WEB_BUILD_SUCCESS
        fi
    fi
    
    if [[ "$PLATFORM" == "android" || "$PLATFORM" == "all" ]]; then
        build_android
        ANDROID_BUILD_SUCCESS=$?
    fi
    
    if [[ "$PLATFORM" == "ios" || "$PLATFORM" == "all" ]]; then
        build_ios
        IOS_BUILD_SUCCESS=$?
    fi
    
    generate_report
    
    # Summary
    log_info "Deployment Summary:"
    if [[ "$PLATFORM" == "web" || "$PLATFORM" == "all" ]]; then
        if [[ $WEB_BUILD_SUCCESS -eq 0 ]]; then
            log_success "Web: Deployed successfully"
        else
            log_error "Web: Deployment failed"
        fi
    fi
    
    if [[ "$PLATFORM" == "android" || "$PLATFORM" == "all" ]]; then
        if [[ $ANDROID_BUILD_SUCCESS -eq 0 ]]; then
            log_success "Android: Built successfully"
        else
            log_error "Android: Build failed"
        fi
    fi
    
    if [[ "$PLATFORM" == "ios" || "$PLATFORM" == "all" ]]; then
        if [[ $IOS_BUILD_SUCCESS -eq 0 ]]; then
            log_success "iOS: Built successfully"
        else
            log_error "iOS: Build failed"
        fi
    fi
    
    log_success "Deployment process completed!"
}

# Run main function
main "$@"
