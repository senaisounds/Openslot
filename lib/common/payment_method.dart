import 'package:cloud_firestore/cloud_firestore.dart';

enum PaymentMethodType {
  bankAccount,
  paypal,
  venmo,
  cashApp,
  other,
}

class PaymentMethod {
  String id;
  String userId;
  PaymentMethodType type;
  String accountNumber; // Masked except last 4 digits
  String accountName; // Name on account
  bool isDefault;
  Map<String, dynamic>? additionalData; // For method-specific data
  
  PaymentMethod({
    required this.id,
    required this.userId,
    required this.type,
    required this.accountNumber,
    required this.accountName,
    this.isDefault = false,
    this.additionalData,
  });
  
  factory PaymentMethod.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    return PaymentMethod(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      type: _parseType(data['type'] as String?),
      accountNumber: data['accountNumber'] as String? ?? '',
      accountName: data['accountName'] as String? ?? '',
      isDefault: data['isDefault'] as bool? ?? false,
      additionalData: data['additionalData'] as Map<String, dynamic>?,
    );
  }
  
  static PaymentMethodType _parseType(String? type) {
    switch (type) {
      case 'bankAccount':
        return PaymentMethodType.bankAccount;
      case 'paypal':
        return PaymentMethodType.paypal;
      case 'venmo':
        return PaymentMethodType.venmo;
      case 'cashApp':
        return PaymentMethodType.cashApp;
      case 'other':
      default:
        return PaymentMethodType.other;
    }
  }
  
  static String typeToString(PaymentMethodType type) {
    switch (type) {
      case PaymentMethodType.bankAccount:
        return 'bankAccount';
      case PaymentMethodType.paypal:
        return 'paypal';
      case PaymentMethodType.venmo:
        return 'venmo';
      case PaymentMethodType.cashApp:
        return 'cashApp';
      case PaymentMethodType.other:
      default:
        return 'other';
    }
  }
  
  Map<String, dynamic> toDocument() {
    return {
      'userId': userId,
      'type': typeToString(type),
      'accountNumber': accountNumber,
      'accountName': accountName,
      'isDefault': isDefault,
      'additionalData': additionalData,
    };
  }
  
  String get typeDisplayName {
    switch (type) {
      case PaymentMethodType.bankAccount:
        return 'Bank Account';
      case PaymentMethodType.paypal:
        return 'PayPal';
      case PaymentMethodType.venmo:
        return 'Venmo';
      case PaymentMethodType.cashApp:
        return 'Cash App';
      case PaymentMethodType.other:
      default:
        return 'Other';
    }
  }
  
  String get maskedAccount {
    if (accountNumber.length <= 4) {
      return accountNumber;
    }
    
    final lastFour = accountNumber.substring(accountNumber.length - 4);
    return '••••$lastFour';
  }
  
  String get displayInfo {
    final lastFour = maskedAccount;
    if (type == PaymentMethodType.bankAccount) {
      return '$typeDisplayName | $accountName | $lastFour';
    } else {
      return '$typeDisplayName | $lastFour';
    }
  }
} 