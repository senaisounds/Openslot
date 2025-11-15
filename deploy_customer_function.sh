#!/bin/bash

# Stripe Customer Function Deployment Script
# This script will guide you through deploying the customer creation function

set -e  # Exit on error

echo "🚀 Stripe Customer Function Deployment"
echo "======================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    echo -e "${RED}❌ Error: Not in the project root directory${NC}"
    echo "Please run this script from: /Users/senaimotley/openslot"
    exit 1
fi

echo -e "${BLUE}📍 Current directory: $(pwd)${NC}"
echo ""

# Step 1: Check Firebase CLI
echo -e "${BLUE}Step 1: Checking Firebase CLI...${NC}"
if ! command -v firebase &> /dev/null; then
    echo -e "${RED}❌ Firebase CLI not found${NC}"
    echo "Install it with: npm install -g firebase-tools"
    exit 1
fi
echo -e "${GREEN}✅ Firebase CLI installed${NC}"
echo ""

# Step 2: Check if functions are built
echo -e "${BLUE}Step 2: Building Firebase Functions...${NC}"
cd functions
if [ ! -f "lib/index.js" ]; then
    echo "Building TypeScript functions..."
    npm run build
fi
echo -e "${GREEN}✅ Functions built${NC}"
echo ""

# Step 3: Authentication check
echo -e "${BLUE}Step 3: Checking Firebase authentication...${NC}"
if ! firebase projects:list &> /dev/null; then
    echo -e "${YELLOW}⚠️  Not authenticated with Firebase${NC}"
    echo ""
    echo "Opening browser for authentication..."
    echo "Please log in with your Google account when prompted."
    echo ""
    read -p "Press Enter to continue..."
    
    # Try to authenticate
    firebase login --reauth || {
        echo -e "${RED}❌ Authentication failed${NC}"
        echo "Please run manually: firebase login --reauth"
        exit 1
    }
fi
echo -e "${GREEN}✅ Authenticated${NC}"
echo ""

# Step 4: Verify project
echo -e "${BLUE}Step 4: Verifying project...${NC}"
PROJECT_ID=$(firebase use | grep -o "open-mic-[a-z0-9]*" | head -1)
if [ -z "$PROJECT_ID" ]; then
    echo -e "${YELLOW}⚠️  No project selected${NC}"
    echo "Setting project to: open-mic-5cc8e"
    firebase use open-mic-5cc8e
    PROJECT_ID="open-mic-5cc8e"
fi
echo -e "${GREEN}✅ Using project: $PROJECT_ID${NC}"
echo ""

# Step 5: Deploy function
echo -e "${BLUE}Step 5: Deploying createStripeCustomer function...${NC}"
echo "This may take 1-2 minutes..."
echo ""

firebase deploy --only functions:createStripeCustomer || {
    echo -e "${RED}❌ Deployment failed${NC}"
    echo ""
    echo "Common issues:"
    echo "1. Check your internet connection"
    echo "2. Verify Firebase project permissions"
    echo "3. Check Stripe keys are configured:"
    echo "   firebase functions:config:get"
    exit 1
}

echo ""
echo -e "${GREEN}✅ Function deployed successfully!${NC}"
echo ""

# Step 6: Get function URL
echo -e "${BLUE}Step 6: Getting function URL...${NC}"
FUNCTION_URL="https://us-central1-${PROJECT_ID}.cloudfunctions.net/createStripeCustomer"
echo -e "${GREEN}Function URL: $FUNCTION_URL${NC}"
echo ""

# Step 7: Test function
echo -e "${BLUE}Step 7: Testing function...${NC}"
echo "Testing with sample data..."
echo ""

TEST_RESPONSE=$(curl -s -X POST "$FUNCTION_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "test_deploy_'$(date +%s)'",
    "email": "test@example.com",
    "name": "Test User",
    "debug": true
  }')

if echo "$TEST_RESPONSE" | grep -q "customerId"; then
    echo -e "${GREEN}✅ Function test successful!${NC}"
    echo "Response: $TEST_RESPONSE"
else
    echo -e "${YELLOW}⚠️  Function deployed but test returned unexpected response${NC}"
    echo "Response: $TEST_RESPONSE"
    echo ""
    echo "This might be okay - check function logs:"
    echo "  firebase functions:log --only createStripeCustomer"
fi
echo ""

# Success summary
echo "======================================"
echo -e "${GREEN}🎉 Deployment Complete!${NC}"
echo "======================================"
echo ""
echo "Next steps:"
echo "1. Hot restart your Flutter app"
echo "2. Make a test payment"
echo "3. Watch for 'Got customer ID' in logs"
echo "4. Verify customer in Stripe Dashboard:"
echo "   https://dashboard.stripe.com/test/customers"
echo ""
echo "Function logs:"
echo "  firebase functions:log --only createStripeCustomer"
echo ""
echo "Documentation:"
echo "  cat STRIPE_CUSTOMER_SETUP_COMPLETE.md"
echo ""
echo -e "${GREEN}✨ Happy coding!${NC}"

