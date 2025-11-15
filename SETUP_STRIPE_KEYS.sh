#!/bin/bash

# Script to help setup Stripe keys in secure storage
# Run this after getting your keys from Stripe Dashboard

echo "================================================"
echo "  OpenSlot - Stripe Key Setup Helper"
echo "================================================"
echo ""
echo "This will help you store Stripe keys securely."
echo ""
echo "Get your keys from: https://dashboard.stripe.com/apikeys"
echo ""
echo "TEST MODE Keys:"
echo "  - Should start with: pk_test_..."
echo ""
echo "LIVE MODE Keys:"
echo "  - Should start with: pk_live_..."
echo ""
echo "================================================"
echo ""

read -p "Enter your TEST Publishable Key (pk_test_...): " TEST_KEY
read -p "Enter your LIVE Publishable Key (pk_live_...): " LIVE_KEY

echo ""
echo "Keys entered:"
echo "  Test: ${TEST_KEY:0:15}..."
echo "  Live: ${LIVE_KEY:0:15}..."
echo ""

read -p "Are these correct? (y/n): " CONFIRM

if [ "$CONFIRM" != "y" ]; then
    echo "Cancelled."
    exit 1
fi

echo ""
echo "Creating Dart script to store keys..."

cat > setup_stripe_keys_temp.dart << EOF
import 'package:slotted/api/stripe_config.dart';

void main() async {
  print('Storing Stripe keys securely...');
  
  await StripeConfig.storeKeys(
    testKey: '$TEST_KEY',
    liveKey: '$LIVE_KEY',
  );
  
  print('✅ Stripe keys stored successfully!');
  print('');
  print('Keys are now stored in secure storage.');
  print('Your app will use them automatically.');
}
EOF

echo ""
echo "================================================"
echo "Keys setup script created!"
echo "================================================"
echo ""
echo "To store the keys, run:"
echo "  dart run setup_stripe_keys_temp.dart"
echo ""
echo "After running, delete the temp file:"
echo "  rm setup_stripe_keys_temp.dart"
echo ""


