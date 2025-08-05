import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:slotted/common/payment_method.dart';
import 'package:slotted/services/payout_service.dart';
import 'package:slotted/providers/theme_provider.dart';
import 'package:slotted/utils/logger.dart';
import '../common/colors.dart';
import 'payment_details_page.dart'; // Added import for PaymentDetailsPage

class PaymentMethodPage extends StatefulWidget {
  final User? user;
  
  const PaymentMethodPage({
    super.key,
    required this.user,
  });

  @override
  PaymentMethodPageState createState() => PaymentMethodPageState();
}

class PaymentMethodPageState extends State<PaymentMethodPage> {
  final PayoutService _payoutService = PayoutService();
  
  List<PaymentMethod> _paymentMethods = [];
  bool _isLoading = true;
  

  
  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
  }
  
  @override
  void dispose() {
    super.dispose();
  }
  
  Future<void> _loadPaymentMethods() async {
    if (widget.user == null) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final methods = await _payoutService.getPaymentMethods(widget.user!.uid);
      
      setState(() {
        _paymentMethods = methods;
        _isLoading = false;
      });
    } catch (e) {
      Logger.d('Error loading payment methods: $e', tag: 'PaymentMethodPage');
      setState(() {
        _isLoading = false;
      });
      
      _showErrorDialog('Failed to load payment methods: ${e.toString()}');
    }
  }
  

  
  Future<void> _setDefaultPaymentMethod(String methodId) async {
    if (widget.user == null) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _payoutService.setDefaultPaymentMethod(methodId, widget.user!.uid);
      
      // Refresh list
      await _loadPaymentMethods();
      
      _showSuccessDialog('Default payment method updated');
    } catch (e) {
      Logger.d('Error setting default payment method: $e', tag: 'PaymentMethodPage');
      setState(() {
        _isLoading = false;
      });
      
      _showErrorDialog('Failed to update default payment method: ${e.toString()}');
    }
  }
  
  Future<void> _deletePaymentMethod(String methodId) async {
    if (widget.user == null) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _payoutService.deletePaymentMethod(methodId, widget.user!.uid);
      
      // Refresh list
      await _loadPaymentMethods();
      
      _showSuccessDialog('Payment method deleted');
    } catch (e) {
      Logger.d('Error deleting payment method: $e', tag: 'PaymentMethodPage');
      setState(() {
        _isLoading = false;
      });
      
      _showErrorDialog('Failed to delete payment method: ${e.toString()}');
    }
  }
  
  void _showSuccessDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Success'),
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
        title: const Text('Error'),
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
  
  void _showAddPaymentMethodSheet() {
    // Show payment method selection first
    showCupertinoModalPopup(
      context: context,
      builder: (context) => SafeArea(
        child: Container(
          color: context.watch<ThemeProvider>().isDarkMode
              ? const Color(0xFF18181A)
              : CupertinoColors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Text('Cancel', style: TextStyle(fontSize: 18)),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  const Text(
                    'Select Payment Method',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 60), // Balance the header
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Choose your payment method type:',
                style: TextStyle(
                  color: context.watch<ThemeProvider>().isDarkMode
                      ? Colors.white
                      : Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              _buildSimplePaymentTypeSelector(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSimplePaymentTypeSelector(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final types = [
      PaymentMethodType.bankAccount,
      PaymentMethodType.paypal,
      PaymentMethodType.venmo,
      PaymentMethodType.cashApp,
    ];
    final icons = {
      PaymentMethodType.bankAccount: CupertinoIcons.building_2_fill,
      PaymentMethodType.paypal: CupertinoIcons.money_dollar_circle_fill,
      PaymentMethodType.venmo: CupertinoIcons.person_crop_circle_fill,
      PaymentMethodType.cashApp: CupertinoIcons.money_dollar,
    };
    final labels = {
      PaymentMethodType.bankAccount: 'Bank Account',
      PaymentMethodType.paypal: 'PayPal',
      PaymentMethodType.venmo: 'Venmo',
      PaymentMethodType.cashApp: 'Cash App',
    };

    return Column(
      children: types.map((type) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: CupertinoButton(
            padding: const EdgeInsets.all(16),
            color: isDark ? const Color(0xFF23232A) : const Color(0xFFF0F0F5),
            borderRadius: BorderRadius.circular(12),
            onPressed: () {
              Navigator.pop(context); // Close the modal
              _navigateToPaymentDetails(type); // Navigate to details page
            },
            child: Row(
              children: [
                Icon(
                  icons[type],
                  color: kPrimaryColor,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    labels[type]!,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                Icon(
                  CupertinoIcons.chevron_right,
                  color: isDark ? Colors.white54 : Colors.black54,
                  size: 20,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  void _navigateToPaymentDetails(PaymentMethodType selectedType) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => PaymentDetailsPage(
          user: widget.user!,
          selectedType: selectedType,
        ),
      ),
    ).then((_) => _loadPaymentMethods());
  }
  

  

  

  
  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDarkMode = themeProvider.isDarkMode;
    
    return CupertinoPageScaffold(
      backgroundColor: isDarkMode ? AppColors.backgroundDark : CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Payment Methods'),
        backgroundColor: isDarkMode ? AppColors.backgroundDark : CupertinoColors.white,
        border: null,
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _showAddPaymentMethodSheet,
          child: const Icon(CupertinoIcons.add),
        ),
      ),
      child: _isLoading
          ? const Center(child: CupertinoActivityIndicator())
          : SafeArea(
              child: _paymentMethods.isEmpty
                  ? _buildEmptyState(isDarkMode)
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _paymentMethods.length,
                      itemBuilder: (context, index) {
                        final method = _paymentMethods[index];
                        return _buildPaymentMethodCard(method, isDarkMode);
                      },
                    ),
            ),
    );
  }
  
  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            CupertinoIcons.creditcard,
            size: 60,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'No Payment Methods',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add a payment method to receive payouts',
            style: TextStyle(
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 24),
          CupertinoButton(
            color: kPrimaryColor,
            onPressed: _showAddPaymentMethodSheet,
            child: const Text('Add Payment Method'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPaymentMethodCard(PaymentMethod method, bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Type icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Icon(
                      _getMethodIcon(method.type),
                      color: kPrimaryColor,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            method.typeDisplayName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          if (method.isDefault) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: kPrimaryColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Default',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        method.maskedAccount,
                        style: TextStyle(
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                      ),
                      if (method.type == PaymentMethodType.bankAccount && method.accountName.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          method.accountName,
                          style: TextStyle(
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Actions
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isDarkMode ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                if (!method.isDefault)
                  Expanded(
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Text('Set as Default'),
                      onPressed: () => _setDefaultPaymentMethod(method.id),
                    ),
                  ),
                Expanded(
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Text(
                      'Delete',
                      style: TextStyle(
                        color: Colors.red.shade700,
                      ),
                    ),
                    onPressed: () {
                      showCupertinoDialog(
                        context: context,
                        builder: (context) => CupertinoAlertDialog(
                          title: const Text('Delete Payment Method'),
                          content: const Text('Are you sure you want to delete this payment method?'),
                          actions: [
                            CupertinoDialogAction(
                              child: const Text('Cancel'),
                              onPressed: () => Navigator.pop(context),
                            ),
                            CupertinoDialogAction(
                              isDestructiveAction: true,
                              child: const Text('Delete'),
                              onPressed: () {
                                Navigator.pop(context);
                                _deletePaymentMethod(method.id);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  IconData _getMethodIcon(PaymentMethodType type) {
    switch (type) {
      case PaymentMethodType.bankAccount:
        return CupertinoIcons.building_2_fill;
      case PaymentMethodType.paypal:
        return CupertinoIcons.money_dollar_circle_fill;
      case PaymentMethodType.venmo:
        return CupertinoIcons.person_crop_circle_fill;
      case PaymentMethodType.cashApp:
        return CupertinoIcons.money_dollar;
      default:
        return CupertinoIcons.creditcard_fill;
    }
  }
} 