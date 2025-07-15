import 'package:cloud_firestore/cloud_firestore.dart';

enum PayoutStatus {
  pending, // Pending payout request
  processing, // Payout is being processed
  completed, // Payout successfully completed
  failed, // Payout failed
}

class PayoutFees {
  final double platformFee;
  final double payoutFee;
  
  PayoutFees({
    required this.platformFee,
    required this.payoutFee,
  });
  
  factory PayoutFees.fromMap(Map<String, dynamic> map) {
    return PayoutFees(
      platformFee: (map['platformFee'] as num?)?.toDouble() ?? 0.0,
      payoutFee: (map['payoutFee'] as num?)?.toDouble() ?? 0.0,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'platformFee': platformFee,
      'payoutFee': payoutFee,
    };
  }
  
  double get totalFees => platformFee + payoutFee;
  
  String get formattedBreakdown => '''
Platform Fee: \$${platformFee.toStringAsFixed(2)}
Payout Fee: \$${payoutFee.toStringAsFixed(2)}
Total Fees: \$${totalFees.toStringAsFixed(2)}
''';
}

class PayoutTransaction {
  String id;
  String hostId;
  String eventId;
  String eventName;
  double amount;
  DateTime requestDate;
  DateTime? processedDate;
  PayoutStatus status;
  String? paymentMethod; // "bank_account", "paypal", "venmo", etc.
  String? paymentAccount; // Last 4 digits or masked account info
  String? failureReason;
  String? transactionReference;
  PayoutFees? fees; // Enhanced fee tracking
  
  PayoutTransaction({
    required this.id,
    required this.hostId,
    required this.eventId,
    required this.eventName,
    required this.amount,
    required this.requestDate,
    this.processedDate,
    this.status = PayoutStatus.pending,
    this.paymentMethod,
    this.paymentAccount,
    this.failureReason,
    this.transactionReference,
    this.fees,
  });
  
  factory PayoutTransaction.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    return PayoutTransaction(
      id: doc.id,
      hostId: data['hostId'] as String? ?? '',
      eventId: data['eventId'] as String? ?? '',
      eventName: data['eventName'] as String? ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      requestDate: (data['requestDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      processedDate: (data['processedDate'] as Timestamp?)?.toDate(),
      status: _parseStatus(data['status'] as String?),
      paymentMethod: data['paymentMethod'] as String?,
      paymentAccount: data['paymentAccount'] as String?,
      failureReason: data['failureReason'] as String?,
      transactionReference: data['transactionReference'] as String?,
      fees: data['fees'] != null 
          ? PayoutFees.fromMap(data['fees'] as Map<String, dynamic>)
          : null,
    );
  }
  
  static PayoutStatus _parseStatus(String? status) {
    switch (status) {
      case 'processing':
        return PayoutStatus.processing;
      case 'completed':
        return PayoutStatus.completed;
      case 'failed':
        return PayoutStatus.failed;
      case 'pending':
        return PayoutStatus.pending;
      default:
        return PayoutStatus.pending;
    }
  }
  
  static String statusToString(PayoutStatus status) {
    switch (status) {
      case PayoutStatus.processing:
        return 'processing';
      case PayoutStatus.completed:
        return 'completed';
      case PayoutStatus.failed:
        return 'failed';
      case PayoutStatus.pending:
        return 'pending';
    }
  }
  
  Map<String, dynamic> toDocument() {
    return {
      'hostId': hostId,
      'eventId': eventId,
      'eventName': eventName,
      'amount': amount,
      'requestDate': Timestamp.fromDate(requestDate),
      'processedDate': processedDate != null ? Timestamp.fromDate(processedDate!) : null,
      'status': statusToString(status),
      'paymentMethod': paymentMethod,
      'paymentAccount': paymentAccount,
      'failureReason': failureReason,
      'transactionReference': transactionReference,
      'fees': fees?.toMap(),
    };
  }
  
  String get formattedAmount {
    return '\$${amount.toStringAsFixed(2)}';
  }
  
  String get statusDisplayText {
    switch (status) {
      case PayoutStatus.processing:
        return 'Processing';
      case PayoutStatus.completed:
        return 'Completed';
      case PayoutStatus.failed:
        return 'Failed';
      case PayoutStatus.pending:
        return 'Pending';
    }
  }
  
  String get formattedRequestDate {
    return '${requestDate.month}/${requestDate.day}/${requestDate.year}';
  }
  
  String get formattedProcessedDate {
    if (processedDate == null) return 'N/A';
    return '${processedDate!.month}/${processedDate!.day}/${processedDate!.year}';
  }
  
  // Enhanced display properties
  String get detailedFormattedDate {
    final months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[requestDate.month]} ${requestDate.day}, ${requestDate.year}';
  }
  
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(requestDate);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} minutes ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
    } else {
      final months = (difference.inDays / 30).floor();
      return months == 1 ? '1 month ago' : '$months months ago';
    }
  }
  
  bool get canBeCancelled {
    return status == PayoutStatus.pending;
  }
  
  String get formattedPaymentMethod {
    if (paymentMethod == null) return 'Unknown';
    
    switch (paymentMethod) {
      case 'bankAccount':
        return 'Bank Account';
      case 'paypal':
        return 'PayPal';
      case 'venmo':
        return 'Venmo';
      case 'cashApp':
        return 'Cash App';
      default:
        return paymentMethod!;
    }
  }
  
  String get displaySummary {
    final method = paymentAccount != null 
        ? '$formattedPaymentMethod ($paymentAccount)'
        : formattedPaymentMethod;
    return '$formattedAmount to $method';
  }
} 