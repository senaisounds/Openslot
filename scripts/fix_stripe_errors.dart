import 'dart:io';

void main() async {
  // Path to the Stripe API file
  const stripeApiPath = 'lib/api/stripe.dart';
  
  try {
    final file = File(stripeApiPath);
    if (!await file.exists()) {
      // Error: Stripe API file not found at $stripeApiPath
      return;
    }
    
    String content = await file.readAsString();
    
    // Fix pattern matching errors
    final patternMatchRegex = RegExp(r"case '([^']+)':");
    final matches = patternMatchRegex.allMatches(content);
    
    if (matches.isNotEmpty) {
      // Found ${matches.length} string pattern matches in switch statements
      
      // Check if we need to add the StripeErrorCode enum
      if (!content.contains('enum StripeErrorCode')) {
        // Add the enum definition after the SlottedStripeError class
        final insertPosition = content.indexOf('class SlottedStripeError');
        if (insertPosition != -1) {
          final endOfClass = content.indexOf('}', insertPosition);
          if (endOfClass != -1) {
            // Collect all error codes from the switch statements
            final errorCodes = <String>{};
            for (final match in matches) {
              final errorCode = match.group(1);
              if (errorCode != null) {
                errorCodes.add(errorCode);
              }
            }
            
            // Create the enum definition
            final enumDefinition = '''

enum StripeErrorCode {
  ${errorCodes.map((code) => code).join(',\n  ')}
}
''';
            
            content = content.substring(0, endOfClass + 1) + 
                     enumDefinition + 
                     content.substring(endOfClass + 1);
            
            // Added StripeErrorCode enum with ${errorCodes.length} values
          }
        }
      }
      
      // Replace string literals with enum values in switch statements
      content = content.replaceAllMapped(
        RegExp(r"case '([^']+)':"), 
        (match) {
          return "case StripeErrorCode.${match.group(1)}:";
        }
      );
      
      // Update the error code comparisons
      content = content.replaceAllMapped(
        RegExp(r"e\.error\.code == '([^']+)'"), 
        (match) {
          return "e.error.code == StripeErrorCode.${match.group(1)}.toString()";
        }
      );
      
      await file.writeAsString(content);
      // Fixed $fixedErrors Stripe error code pattern matching issues
    } else {
      // No string pattern matches found in switch statements
    }
    
  } catch (e) {
    // Error processing Stripe API file: $e
  }
} 