import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:slotted/common/payment_method.dart';
import 'package:slotted/services/payout_service.dart';
import 'package:slotted/providers/theme_provider.dart';
import 'package:slotted/utils/logger.dart';
import '../common/colors.dart';

class PaymentDetailsPage extends StatefulWidget {
  final User user;
  final PaymentMethodType selectedType;
  
  const PaymentDetailsPage({
    super.key,
    required this.user,
    required this.selectedType,
  });

  @override
  PaymentDetailsPageState createState() => PaymentDetailsPageState();
}

class PaymentDetailsPageState extends State<PaymentDetailsPage> {
  final PayoutService _payoutService = PayoutService();
  final TextEditingController _accountNumberController = TextEditingController();
  final TextEditingController _accountNameController = TextEditingController();
  bool _isDefault = false;
  bool _isLoading = false;
  
  @override
  void dispose() {
    _accountNumberController.dispose();
    _accountNameController.dispose();
    super.dispose();
  }
  
  String _getPaymentMethodTitle() {
    switch (widget.selectedType) {
      case PaymentMethodType.bankAccount:
        return 'Bank Account';
      case PaymentMethodType.paypal:
        return 'PayPal';
      case PaymentMethodType.venmo:
        return 'Venmo';
      case PaymentMethodType.cashApp:
        return 'Cash App';
      default:
        return 'Payment Method';
    }
  }
  
  String _getAccountLabel() {
    switch (widget.selectedType) {
      case PaymentMethodType.bankAccount:
        return 'Account Number';
      case PaymentMethodType.paypal:
        return 'PayPal Email';
      case PaymentMethodType.venmo:
        return 'Venmo Username';
      case PaymentMethodType.cashApp:
        return 'Cash App Username';
      default:
        return 'Account Information';
    }
  }
  
  String _getAccountPlaceholder() {
    switch (widget.selectedType) {
      case PaymentMethodType.bankAccount:
        return 'Enter account number';
      case PaymentMethodType.paypal:
        return 'Enter verified PayPal email';
      case PaymentMethodType.venmo:
        return 'Enter verified Venmo username';
      case PaymentMethodType.cashApp:
        return 'Enter verified Cash App username';
      default:
        return 'Enter account information';
    }
  }
  
  String _getVerificationNote() {
    switch (widget.selectedType) {
      case PaymentMethodType.bankAccount:
        return 'Note: Bank account requires routing number and verification. This will be added in the next update.';
      case PaymentMethodType.paypal:
        return 'Note: PayPal email must be verified and linked to a business account for payouts.';
      case PaymentMethodType.venmo:
        return 'Note: Venmo requires business account setup and verification for payouts.';
      case PaymentMethodType.cashApp:
        return 'Note: Cash App requires business account setup and verification for payouts.';
      default:
        return '';
    }
  }
  
  Future<void> _addPaymentMethod() async {
    // Manual validation
    if (_accountNumberController.text.isEmpty) {
      _showErrorDialog('Please enter account information');
      return;
    }
    
    if (widget.selectedType == PaymentMethodType.bankAccount && _accountNameController.text.isEmpty) {
      _showErrorDialog('Please enter account holder name');
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final newMethod = PaymentMethod(
        id: '',
        userId: widget.user.uid,
        type: widget.selectedType,
        accountNumber: _accountNumberController.text,
        accountName: _accountNameController.text,
        isDefault: _isDefault,
      );
      
      await _payoutService.addPaymentMethod(newMethod);
      
      if (mounted) {
        Navigator.pop(context);
        _showSuccessDialog('Payment method added successfully');
      }
    } catch (e) {
      Logger.d('Error adding payment method: $e', tag: 'PaymentDetailsPage');
      setState(() {
        _isLoading = false;
      });
      
      _showErrorDialog('Failed to add payment method: ${e.toString()}');
    }
  }
  
  void _showSuccessDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.checkmark_circle,
              color: Colors.green,
              size: 24,
            ),
            SizedBox(width: 8),
            Text('Success'),
          ],
        ),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
  
  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.exclamationmark_triangle,
              color: Colors.red,
              size: 24,
            ),
            SizedBox(width: 8),
            Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(_getPaymentMethodTitle()),
        backgroundColor: isDark ? AppColors.backgroundDark : CupertinoColors.white,
        border: null,
        leading: CupertinoNavigationBarBackButton(
          onPressed: () => Navigator.pop(context),
        ),
        trailing: _isLoading
            ? const CupertinoActivityIndicator()
            : CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _addPaymentMethod,
                child: const Text('Add'),
              ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Account Number/Email/Username field
              Text(
                _getAccountLabel(),
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              CupertinoTextField(
                controller: _accountNumberController,
                placeholder: _getAccountPlaceholder(),
                placeholderStyle: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black38,
                  fontSize: 16,
                ),
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 18,
                ),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF23232A) : const Color(0xFFF0F0F5),
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              const SizedBox(height: 24),
              
              // Verification note
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                                                color: isDark ? Colors.orange.withValues(alpha: 0.3) : Colors.orange.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      CupertinoIcons.info_circle,
                      color: Colors.orange,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _getVerificationNote(),
                        style: TextStyle(
                          color: isDark ? Colors.orange : Colors.orange.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Account Name field (only for bank accounts)
              if (widget.selectedType == PaymentMethodType.bankAccount) ...[
                Text(
                  'Account Holder Name',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                CupertinoTextField(
                  controller: _accountNameController,
                  placeholder: 'Enter account holder name',
                  placeholderStyle: TextStyle(
                    color: isDark ? Colors.white54 : Colors.black38,
                    fontSize: 16,
                  ),
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 18,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF23232A) : const Color(0xFFF0F0F5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                const SizedBox(height: 24),
              ],
              
              // Set as default toggle
              Row(
                children: [
                  CupertinoSwitch(
                    value: _isDefault,
                    onChanged: (value) {
                      setState(() {
                        _isDefault = value;
                      });
                    },
                    activeTrackColor: kPrimaryColor,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Set as default payment method',
                      style: TextStyle(fontSize: 17),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              // Add button
              SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  color: kPrimaryColor,
                  borderRadius: BorderRadius.circular(10),
                  onPressed: _isLoading ? null : _addPaymentMethod,
                  child: _isLoading
                      ? const CupertinoActivityIndicator(color: Colors.white)
                      : const Text(
                          'Add Payment Method',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 