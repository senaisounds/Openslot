#!/bin/bash

# Run Basic Tests Only Script
# This script runs only the basic tests that don't require Firebase initialization

echo "Running basic tests only..."

# Find all test files containing 'Basic' in their test group names
TESTS=$(find test -name "*.dart" -type f -exec grep -l "group('Basic" {} \;)

# Run the tests
flutter test $TESTS --name="Test scaffold" --no-pub

echo "Basic tests completed!" 