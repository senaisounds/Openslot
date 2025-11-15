import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:slotted/config/environment_config.dart';
import 'package:slotted/utils/logger.dart';

/// Service for managing Stripe customer creation and management
class StripeCustomerService {
  /// Create or retrieve a Stripe customer for a user
  /// 
  /// This function will:
  /// 1. Check if user already has a valid customer ID
  /// 2. If not, create a new customer in Stripe
  /// 3. Store the customer ID in Firestore
  /// 4. Return the customer ID
  /// 
  /// Parameters:
  /// - [userId]: Firebase user ID
  /// - [email]: User's email (optional)
  /// - [name]: User's name (optional)
  /// - [debug]: Whether to use test or live Stripe key
  static Future<String?> createOrGetCustomer({
    required String userId,
    String? email,
    String? name,
    bool debug = true,
  }) async {
    try {
      if (userId.isEmpty) {
        Logger.e('User ID is required to create customer', tag: 'StripeCustomer');
        return null;
      }

      Logger.d('Creating/retrieving Stripe customer for user: $userId', tag: 'StripeCustomer');

      final url = '${EnvironmentConfig.apiBaseUrl}/createStripeCustomer';
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'email': email,
          'name': name,
          'debug': debug,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final customerId = data['customerId'] as String?;
        final isNew = data['isNew'] as bool? ?? false;

        if (customerId != null && customerId.isNotEmpty) {
          if (isNew) {
            Logger.i('Created new Stripe customer: $customerId', tag: 'StripeCustomer');
          } else {
            Logger.d('Retrieved existing Stripe customer: $customerId', tag: 'StripeCustomer');
          }
          return customerId;
        } else {
          Logger.e('No customer ID returned from server', tag: 'StripeCustomer');
          return null;
        }
      } else {
        final errorData = jsonDecode(response.body);
        Logger.e('Failed to create customer: ${errorData['error']}', tag: 'StripeCustomer');
        return null;
      }
    } catch (e) {
      Logger.e('Error creating/retrieving Stripe customer: $e', tag: 'StripeCustomer');
      return null;
    }
  }

  /// Clean up invalid customer ID from user profile
  /// 
  /// This will attempt to create a valid customer and replace the invalid one
  static Future<bool> cleanupInvalidCustomerId({
    required String userId,
    String? email,
    String? name,
    bool debug = true,
  }) async {
    try {
      Logger.i('Cleaning up invalid customer ID for user: $userId', tag: 'StripeCustomer');
      
      final customerId = await createOrGetCustomer(
        userId: userId,
        email: email,
        name: name,
        debug: debug,
      );

      if (customerId != null) {
        Logger.i('Successfully cleaned up customer ID: $customerId', tag: 'StripeCustomer');
        return true;
      } else {
        Logger.e('Failed to cleanup customer ID', tag: 'StripeCustomer');
        return false;
      }
    } catch (e) {
      Logger.e('Error cleaning up customer ID: $e', tag: 'StripeCustomer');
      return false;
    }
  }
}

