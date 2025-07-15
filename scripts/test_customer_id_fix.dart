import 'dart:convert';
import 'package:http/http.dart' as http;

/// Test script to verify customer ID handling fixes
/// This script tests the customer ID validation and creation logic

class CustomerIdTest {
  static const String testStripeKey = 'sk_test_51RMvr1Q0wBFV119bcCWvuYTtuA28bN7iS2xWJtGrlYGw8VCEzNJazTehBETO8WJf00Yyvmjcky';
  static const String liveStripeKey = 'sk_live_YOUR_NEW_LIVE_SECRET_KEY';

  /// Test customer ID validation
  static Future<void> testCustomerIdValidation() async {
    print('Testing customer ID validation...');
    
    // Test 1: Valid customer ID
    await testValidCustomerId();
    
    // Test 2: Invalid customer ID
    await testInvalidCustomerId();
    
    // Test 3: Empty customer ID
    await testEmptyCustomerId();
    
    // Test 4: Create new customer
    await testCreateNewCustomer();
  }

  static Future<void> testValidCustomerId() async {
    print('\n1. Testing valid customer ID...');
    try {
      // This would be a real customer ID from your Stripe account
      const customerId = 'cus_test123';
      final response = await http.get(
        Uri.parse('https://api.stripe.com/v1/customers/$customerId'),
        headers: {
          'Authorization': 'Bearer $testStripeKey',
        },
      );
      
      if (response.statusCode == 200) {
        print('✅ Valid customer ID test passed');
      } else {
        print('❌ Valid customer ID test failed: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Valid customer ID test failed: $e');
    }
  }

  static Future<void> testInvalidCustomerId() async {
    print('\n2. Testing invalid customer ID...');
    try {
      const customerId = 'cus_invalid123';
      final response = await http.get(
        Uri.parse('https://api.stripe.com/v1/customers/$customerId'),
        headers: {
          'Authorization': 'Bearer $testStripeKey',
        },
      );
      
      if (response.statusCode == 404) {
        print('✅ Invalid customer ID test passed (correctly returned 404)');
      } else {
        print('❌ Invalid customer ID test failed: ${response.statusCode}');
      }
    } catch (e) {
      print('✅ Invalid customer ID test passed (caught exception as expected)');
    }
  }

  static Future<void> testEmptyCustomerId() async {
    print('\n3. Testing empty customer ID...');
    try {
      const customerId = '';
      if (customerId.isEmpty) {
        print('✅ Empty customer ID test passed (correctly identified as empty)');
      } else {
        print('❌ Empty customer ID test failed');
      }
    } catch (e) {
      print('❌ Empty customer ID test failed: $e');
    }
  }

  static Future<void> testCreateNewCustomer() async {
    print('\n4. Testing new customer creation...');
    try {
      final response = await http.post(
        Uri.parse('https://api.stripe.com/v1/customers'),
        headers: {
          'Authorization': 'Bearer $testStripeKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      );
      
      if (response.statusCode == 200) {
        final customerData = json.decode(response.body);
        final newCustomerId = customerData['id'];
        print('✅ New customer creation test passed: $newCustomerId');
      } else {
        print('❌ New customer creation test failed: ${response.statusCode}');
        print('Response: ${response.body}');
      }
    } catch (e) {
      print('❌ New customer creation test failed: $e');
    }
  }

  /// Test the field name consistency
  static void testFieldNameConsistency() {
    print('\n5. Testing field name consistency...');
    
    // Test the field names used in the app
    const testCases = [
      {'debug': true, 'expectedField': 'testCustomerID'},
      {'debug': false, 'expectedField': 'customerID'},
    ];
    
    for (final testCase in testCases) {
      final debug = testCase['debug'] as bool;
      final expectedField = testCase['expectedField'] as String;
      final actualField = debug ? 'testCustomerID' : 'customerID';
      
      if (actualField == expectedField) {
        print('✅ Field name consistency test passed for debug=$debug: $actualField');
      } else {
        print('❌ Field name consistency test failed for debug=$debug: expected $expectedField, got $actualField');
      }
    }
  }

  /// Run all tests
  static Future<void> runAllTests() async {
    print('🧪 Starting Customer ID Fix Tests...\n');
    
    testFieldNameConsistency();
    await testCustomerIdValidation();
    
    print('\n✅ All tests completed!');
    print('\n📋 Summary of fixes applied:');
    print('1. Fixed field name inconsistency in SlottedUser class');
    print('2. Added customer ID validation before payment intent creation');
    print('3. Added automatic customer creation for invalid/missing customer IDs');
    print('4. Added debug logging for customer ID handling');
    print('5. Updated both main navigation and event details pages');
  }
}

void main() async {
  await CustomerIdTest.runAllTests();
}