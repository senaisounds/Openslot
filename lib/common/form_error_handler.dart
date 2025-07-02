import 'package:flutter/material.dart';

/// A utility class for validating and displaying form errors
class FormErrorHandler {
  /// Display a formatted error message below a form field
  static Widget buildErrorText(String? errorText) {
    if (errorText == null || errorText.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Padding(
      padding: const EdgeInsets.only(top: 4.0, left: 12.0),
      child: Text(
        errorText,
        style: const TextStyle(
          color: Colors.red,
          fontSize: 12.0,
        ),
      ),
    );
  }
  
  /// Validate an email address
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }
  
  /// Validate a password
  static String? validatePassword(String? value, {int minLength = 6}) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < minLength) {
      return 'Password must be at least $minLength characters long';
    }
    
    return null;
  }
  
  /// Validate a phone number
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    
    final digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.length < 10) {
      return 'Please enter a valid phone number';
    }
    
    return null;
  }
  
  /// Validate required field
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    
    return null;
  }
  
  /// Validate a numeric field
  static String? validateNumeric(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    
    if (double.tryParse(value) == null) {
      return '$fieldName must be a number';
    }
    
    return null;
  }
  
  /// Show form error alert
  static void showFormErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Form Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  
  /// Show validation errors for multiple fields
  static bool showMultiValidationErrors(
    BuildContext context, 
    Map<String, String?> validationErrors,
  ) {
    final errors = validationErrors.entries
        .where((entry) => entry.value != null)
        .map((entry) => '• ${entry.key}: ${entry.value}')
        .toList();
    
    if (errors.isEmpty) {
      return true;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Please Fix the Following Errors'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final error in errors)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text(error),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    
    return false;
  }
} 