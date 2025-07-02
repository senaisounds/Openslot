import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:slotted/common/payout_transaction.dart';
import 'package:slotted/common/payment_method.dart';
import 'package:slotted/common/event_class.dart';
import 'package:slotted/utils/logger.dart';
class PayoutService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Production-ready configuration
  static const double minimumPayoutAmount = 20.0; // $20 minimum
  static const double platformFeePercentage = 0.10; // 10% platform fee
  static const double payoutFee = 0.25; // $0.25 per payout
  
  // Get all payment methods for a user
  Future<List<PaymentMethod>> getPaymentMethods(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('paymentMethods')
          .where('userId', isEqualTo: userId)
          .get();
      
      return snapshot.docs
          .map((doc) => PaymentMethod.fromDocument(doc))
          .toList();
    } catch (e) {
      Logger.d('Error fetching payment methods: $e', tag: 'PayoutService');
      rethrow;
    }
  }
  
  // Get default payment method for a user
  Future<PaymentMethod?> getDefaultPaymentMethod(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('paymentMethods')
          .where('userId', isEqualTo: userId)
          .where('isDefault', isEqualTo: true)
          .limit(1)
          .get();
      
      if (snapshot.docs.isEmpty) {
        return null;
      }
      
      return PaymentMethod.fromDocument(snapshot.docs.first);
    } catch (e) {
      Logger.d('Error fetching default payment method: $e', tag: 'PayoutService');
      rethrow;
    }
  }
  
  // Enhanced bank account verification
  Future<bool> verifyBankAccount({
    required String userId,
    required String accountNumber,
    required String routingNumber,
    required String accountHolderName,
  }) async {
    try {
      // Basic validation
      if (accountNumber.length < 6 || routingNumber.length != 9) {
        throw Exception('Invalid account or routing number format');
      }
      
      // Create Stripe external account for verification
      final response = await _createStripeExternalAccount(
        accountNumber: accountNumber,
        routingNumber: routingNumber,
        accountHolderName: accountHolderName,
      );
      
      if (response['status'] == 'verified') {
        return true;
      } else {
        // Store pending verification
        await _firestore.collection('bankVerifications').add({
          'userId': userId,
          'accountNumber': _maskAccountNumber(accountNumber),
          'routingNumber': routingNumber,
          'accountHolderName': accountHolderName,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
          'stripeAccountId': response['id'],
        });
        return false;
      }
    } catch (e) {
      Logger.d('Error verifying bank account: $e', tag: 'PayoutService');
      rethrow;
    }
  }
  
  // Create Stripe external account
  Future<Map<String, dynamic>> _createStripeExternalAccount({
    required String accountNumber,
    required String routingNumber,
    required String accountHolderName,
  }) async {
    try {
      // This would integrate with Stripe API
      // For demo purposes, we'll simulate the response
      return {
        'id': 'ba_${DateTime.now().millisecondsSinceEpoch}',
        'status': 'verified', // or 'pending'
        'last4': accountNumber.substring(accountNumber.length - 4),
      };
    } catch (e) {
      Logger.d('Error creating Stripe external account: $e', tag: 'PayoutService');
      rethrow;
    }
  }
  
  String _maskAccountNumber(String accountNumber) {
    if (accountNumber.length <= 4) return accountNumber;
    final lastFour = accountNumber.substring(accountNumber.length - 4);
    return '••••$lastFour';
  }
  
  // Add new payment method with verification
  Future<PaymentMethod> addPaymentMethod(PaymentMethod paymentMethod) async {
    try {
      // Verify bank account if it's a bank account type
      if (paymentMethod.type == PaymentMethodType.bankAccount) {
        final additionalData = paymentMethod.additionalData;
        if (additionalData != null && additionalData.containsKey('routingNumber')) {
          final isVerified = await verifyBankAccount(
            userId: paymentMethod.userId,
            accountNumber: paymentMethod.accountNumber,
            routingNumber: additionalData['routingNumber'],
            accountHolderName: paymentMethod.accountName,
          );
          
          if (!isVerified) {
            throw Exception('Bank account verification required. Please complete verification process.');
          }
        }
      }
      
      // Check if this is the first payment method for user and set as default
      final existingMethods = await getPaymentMethods(paymentMethod.userId);
      if (existingMethods.isEmpty) {
        paymentMethod.isDefault = true;
      }
      
      // If this method is being set as default, clear other defaults
      if (paymentMethod.isDefault) {
        await _clearOtherDefaultPaymentMethods(paymentMethod.userId);
      }
      
      final ref = await _firestore
          .collection('paymentMethods')
          .add(paymentMethod.toDocument());
      
      return paymentMethod..id = ref.id;
    } catch (e) {
      Logger.d('Error adding payment method: $e', tag: 'PayoutService');
      rethrow;
    }
  }
  
  // Clear default status from other payment methods
  Future<void> _clearOtherDefaultPaymentMethods(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('paymentMethods')
          .where('userId', isEqualTo: userId)
          .where('isDefault', isEqualTo: true)
          .get();
      
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'isDefault': false});
      }
      
      await batch.commit();
    } catch (e) {
      Logger.d('Error clearing default payment methods: $e', tag: 'PayoutService');
      rethrow;
    }
  }
  
  // Set a payment method as default
  Future<void> setDefaultPaymentMethod(String methodId, String userId) async {
    try {
      await _clearOtherDefaultPaymentMethods(userId);
      
      await _firestore
          .collection('paymentMethods')
          .doc(methodId)
          .update({'isDefault': true});
    } catch (e) {
      Logger.d('Error setting default payment method: $e', tag: 'PayoutService');
      rethrow;
    }
  }
  
  // Delete a payment method
  Future<void> deletePaymentMethod(String methodId, String userId) async {
    try {
      final methodSnapshot = await _firestore
          .collection('paymentMethods')
          .doc(methodId)
          .get();
      
      if (methodSnapshot.exists) {
        final method = PaymentMethod.fromDocument(methodSnapshot);
        
        // If deleting the default method, set another one as default if available
        if (method.isDefault) {
          final otherMethods = await _firestore
              .collection('paymentMethods')
              .where('userId', isEqualTo: userId)
              .where(FieldPath.documentId, isNotEqualTo: methodId)
              .limit(1)
              .get();
          
          if (otherMethods.docs.isNotEmpty) {
            await _firestore
                .collection('paymentMethods')
                .doc(otherMethods.docs.first.id)
                .update({'isDefault': true});
          }
        }
        
        await _firestore
            .collection('paymentMethods')
            .doc(methodId)
            .delete();
      }
    } catch (e) {
      Logger.d('Error deleting payment method: $e', tag: 'PayoutService');
      rethrow;
    }
  }
  
  // Enhanced payout calculation with detailed breakdown
  Future<PayoutCalculation> calculatePayoutDetails(String eventId) async {
    try {
      final eventSnapshot = await _firestore
          .collection('events')
          .doc(eventId)
          .get();
      
      if (!eventSnapshot.exists) {
        throw Exception('Event not found');
      }
      
      final event = Event.fromDocument(eventSnapshot);
      
      // Calculate revenue
      final numberOfAttendees = event.attendees.length;
      final ticketPrice = event.price;
      final grossRevenue = numberOfAttendees * ticketPrice;
      
      // Calculate fees
      final platformFee = grossRevenue * platformFeePercentage;
      final netRevenue = grossRevenue - platformFee;
      
      // Get previous payouts for this event
      final previousPayoutsSnapshot = await _firestore
          .collection('payouts')
          .where('eventId', isEqualTo: eventId)
          .where('status', whereIn: ['pending', 'processing', 'completed'])
          .get();
      
      final previousPayoutsTotal = previousPayoutsSnapshot.docs
          .map((doc) => (doc.data()['amount'] as num).toDouble())
          .fold<double>(0, (total, amount) => total + amount);
      
      final availableAmount = netRevenue - previousPayoutsTotal;
      final finalAmount = (availableAmount - payoutFee).clamp(0.0, double.infinity);
      
      return PayoutCalculation(
        eventId: eventId,
        eventName: event.name,
        grossRevenue: grossRevenue,
        platformFee: platformFee,
        payoutFee: payoutFee,
        previousPayouts: previousPayoutsTotal,
        availableAmount: finalAmount,
        meetsMinimum: finalAmount >= minimumPayoutAmount,
        attendeeCount: numberOfAttendees,
        ticketPrice: ticketPrice,
      );
    } catch (e) {
      Logger.d('Error calculating payout details: $e', tag: 'PayoutService');
      rethrow;
    }
  }
  
  // Calculate available payout amount for an event (legacy method for compatibility)
  Future<double> calculateAvailablePayoutAmount(String eventId) async {
    final calculation = await calculatePayoutDetails(eventId);
    return calculation.availableAmount;
  }
  
  // Enhanced payout request with validation
  Future<PayoutTransaction> requestPayout({
    required String hostId,
    required String eventId,
    required String eventName,
    required double amount,
    required String paymentMethodId,
  }) async {
    try {
      // Get detailed calculation
      final calculation = await calculatePayoutDetails(eventId);
      
      // Validate amount
      if (amount > calculation.availableAmount) {
        throw Exception('Requested amount (\$${amount.toStringAsFixed(2)}) exceeds available amount (\$${calculation.availableAmount.toStringAsFixed(2)})');
      }
      
      if (amount < minimumPayoutAmount) {
        throw Exception('Minimum payout amount is \$${minimumPayoutAmount.toStringAsFixed(2)}');
      }
      
      // Get payment method details
      final methodSnapshot = await _firestore
          .collection('paymentMethods')
          .doc(paymentMethodId)
          .get();
      
      if (!methodSnapshot.exists) {
        throw Exception('Payment method not found');
      }
      
      final paymentMethod = PaymentMethod.fromDocument(methodSnapshot);
      
      // Create payout transaction
      final payout = PayoutTransaction(
        id: '',
        hostId: hostId,
        eventId: eventId,
        eventName: eventName,
        amount: amount,
        requestDate: DateTime.now(),
        status: PayoutStatus.pending,
        paymentMethod: PaymentMethod.typeToString(paymentMethod.type),
        paymentAccount: paymentMethod.maskedAccount,
        fees: PayoutFees(
          platformFee: calculation.platformFee,
          payoutFee: payoutFee,
        ),
      );
      
      final ref = await _firestore
          .collection('payouts')
          .add(payout.toDocument());
      
      return payout..id = ref.id;
    } catch (e) {
      Logger.d('Error requesting payout: $e', tag: 'PayoutService');
      rethrow;
    }
  }
  
  // Get payout history for a host
  Future<List<PayoutTransaction>> getPayoutHistory(String hostId) async {
    try {
      final snapshot = await _firestore
          .collection('payouts')
          .where('hostId', isEqualTo: hostId)
          .orderBy('requestDate', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => PayoutTransaction.fromDocument(doc))
          .toList();
    } catch (e) {
      Logger.d('Error fetching payout history: $e', tag: 'PayoutService');
      rethrow;
    }
  }
  
  // Get pending payouts for a host
  Future<List<PayoutTransaction>> getPendingPayouts(String hostId) async {
    try {
      final snapshot = await _firestore
          .collection('payouts')
          .where('hostId', isEqualTo: hostId)
          .where('status', isEqualTo: PayoutTransaction.statusToString(PayoutStatus.pending))
          .orderBy('requestDate', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => PayoutTransaction.fromDocument(doc))
          .toList();
    } catch (e) {
      Logger.d('Error fetching pending payouts: $e', tag: 'PayoutService');
      rethrow;
    }
  }
  
  // Get payout analytics
  Future<PayoutAnalytics> getPayoutAnalytics(String hostId) async {
    try {
      final currentYear = DateTime.now().year;
      
      // Get this year's payouts
      final thisYearSnapshot = await _firestore
          .collection('payouts')
          .where('hostId', isEqualTo: hostId)
          .where('status', isEqualTo: PayoutTransaction.statusToString(PayoutStatus.completed))
          .where('requestDate', isGreaterThanOrEqualTo: DateTime(currentYear, 1, 1))
          .get();
      
      final thisYearPayouts = thisYearSnapshot.docs
          .map((doc) => PayoutTransaction.fromDocument(doc))
          .toList();
      
      final thisYearTotal = thisYearPayouts
          .fold<double>(0, (total, payout) => total + payout.amount);
      
      // Get pending payouts
      final pendingPayouts = await getPendingPayouts(hostId);
      final pendingTotal = pendingPayouts
          .fold<double>(0, (total, payout) => total + payout.amount);
      
      // Get all-time total
      final allTimeSnapshot = await _firestore
          .collection('payouts')
          .where('hostId', isEqualTo: hostId)
          .where('status', isEqualTo: PayoutTransaction.statusToString(PayoutStatus.completed))
          .get();
      
      final allTimeTotal = allTimeSnapshot.docs
          .map((doc) => (doc.data()['amount'] as num).toDouble())
          .fold<double>(0, (total, amount) => total + amount);
      
      return PayoutAnalytics(
        thisYearTotal: thisYearTotal,
        pendingTotal: pendingTotal,
        allTimeTotal: allTimeTotal,
        payoutCount: thisYearPayouts.length,
        averagePayoutAmount: thisYearPayouts.isNotEmpty 
            ? thisYearTotal / thisYearPayouts.length 
            : 0.0,
      );
    } catch (e) {
      Logger.d('Error fetching payout analytics: $e', tag: 'PayoutService');
      rethrow;
    }
  }
  
  // Cancel a pending payout request
  Future<void> cancelPayout(String payoutId) async {
    try {
      final payoutSnapshot = await _firestore
          .collection('payouts')
          .doc(payoutId)
          .get();
      
      if (!payoutSnapshot.exists) {
        throw Exception('Payout not found');
      }
      
      final payout = PayoutTransaction.fromDocument(payoutSnapshot);
      
      if (payout.status != PayoutStatus.pending) {
        throw Exception('Only pending payouts can be cancelled');
      }
      
      await _firestore
          .collection('payouts')
          .doc(payoutId)
          .delete();
    } catch (e) {
      Logger.d('Error cancelling payout: $e', tag: 'PayoutService');
      rethrow;
    }
  }
}

// Enhanced data models
class PayoutCalculation {
  final String eventId;
  final String eventName;
  final double grossRevenue;
  final double platformFee;
  final double payoutFee;
  final double previousPayouts;
  final double availableAmount;
  final bool meetsMinimum;
  final int attendeeCount;
  final double ticketPrice;
  
  PayoutCalculation({
    required this.eventId,
    required this.eventName,
    required this.grossRevenue,
    required this.platformFee,
    required this.payoutFee,
    required this.previousPayouts,
    required this.availableAmount,
    required this.meetsMinimum,
    required this.attendeeCount,
    required this.ticketPrice,
  });
  
  double get netRevenue => grossRevenue - platformFee;
  String get formattedBreakdown => '''
Gross Revenue: \$${grossRevenue.toStringAsFixed(2)}
Platform Fee (${(PayoutService.platformFeePercentage * 100).toInt()}%): -\$${platformFee.toStringAsFixed(2)}
Previous Payouts: -\$${previousPayouts.toStringAsFixed(2)}
Payout Fee: -\$${payoutFee.toStringAsFixed(2)}
Available: \$${availableAmount.toStringAsFixed(2)}
''';
}

class PayoutAnalytics {
  final double thisYearTotal;
  final double pendingTotal;
  final double allTimeTotal;
  final int payoutCount;
  final double averagePayoutAmount;
  
  PayoutAnalytics({
    required this.thisYearTotal,
    required this.pendingTotal,
    required this.allTimeTotal,
    required this.payoutCount,
    required this.averagePayoutAmount,
  });
} 