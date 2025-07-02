import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:slotted/common/payment_method.dart';
import 'package:slotted/services/payout_service.dart';
import 'package:slotted/providers/theme_provider.dart';
import 'package:slotted/utils/logger.dart';
import '../common/colors.dart';

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
  
  // Form controllers
  final _formKey = GlobalKey<FormState>();
  PaymentMethodType _selectedType = PaymentMethodType.bankAccount;
  final TextEditingController _accountNumberController = TextEditingController();
  final TextEditingController _accountNameController = TextEditingController();
  bool _isDefault = false;
  
  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
  }
  
  @override
  void dispose() {
    _accountNumberController.dispose();
    _accountNameController.dispose();
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
  
  Future<void> _addPaymentMethod() async {
    if (widget.user == null) return;
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final newMethod = PaymentMethod(
        id: '',
        userId: widget.user!.uid,
        type: _selectedType,
        accountNumber: _accountNumberController.text,
        accountName: _accountNameController.text,
        isDefault: _isDefault,
      );
      
      await _payoutService.addPaymentMethod(newMethod);
      
      // Reset form
      _accountNumberController.clear();
      _accountNameController.clear();
      setState(() {
        _selectedType = PaymentMethodType.bankAccount;
        _isDefault = false;
      });
      
      // Refresh list
      await _loadPaymentMethods();
      
      if (mounted) {
        Navigator.pop(context); // Close the add payment method dialog
      }
      
      _showSuccessDialog('Payment method added successfully');
    } catch (e) {
      Logger.d('Error adding payment method: $e', tag: 'PaymentMethodPage');
      setState(() {
        _isLoading = false;
      });
      
      _showErrorDialog('Failed to add payment method: ${e.toString()}');
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
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        color: context.watch<ThemeProvider>().isDarkMode
            ? const Color(0xFF1C1C1E)
            : CupertinoColors.white,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                const Text(
                  'Add Payment Method',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: _addPaymentMethod,
                  child: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Method type
                        Text(
                          'Payment Method Type',
                          style: TextStyle(
                            color: context.watch<ThemeProvider>().isDarkMode
                                ? Colors.white70
                                : Colors.black54,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: context.watch<ThemeProvider>().isDarkMode
                                ? const Color(0xFF2C2C2E)
                                : const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: CupertinoSegmentedControl<PaymentMethodType>(
                            padding: const EdgeInsets.all(4),
                            groupValue: _selectedType,
                            onValueChanged: (value) {
                              setState(() {
                                _selectedType = value;
                              });
                            },
                            children: {
                              PaymentMethodType.bankAccount: _buildSegmentWidget('Bank'),
                              PaymentMethodType.paypal: _buildSegmentWidget('PayPal'),
                              PaymentMethodType.venmo: _buildSegmentWidget('Venmo'),
                              PaymentMethodType.cashApp: _buildSegmentWidget('Cash App'),
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Account number
                        Text(
                          _accountLabel(_selectedType),
                          style: TextStyle(
                            color: context.watch<ThemeProvider>().isDarkMode
                                ? Colors.white70
                                : Colors.black54,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        CupertinoTextFormFieldRow(
                          controller: _accountNumberController,
                          placeholder: _accountPlaceholder(_selectedType),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter account information';
                            }
                            return null;
                          },
                          decoration: BoxDecoration(
                            color: context.watch<ThemeProvider>().isDarkMode
                                ? const Color(0xFF2C2C2E)
                                : const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        const SizedBox(height: 24),
                        
                        // Account name (only for bank accounts)
                        if (_selectedType == PaymentMethodType.bankAccount) ...[
                          const Text(
                            'Account Name',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Builder(
                            builder: (context) {
                              final isDark = context.watch<ThemeProvider>().isDarkMode;
                              return CupertinoTextFormFieldRow(
                                controller: _accountNameController,
                                placeholder: 'Name on account',
                                validator: (value) {
                                  if (_selectedType == PaymentMethodType.bankAccount &&
                                      (value == null || value.isEmpty)) {
                                    return 'Please enter account name';
                                  }
                                  return null;
                                },
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF2C2C2E)
                                      : const Color(0xFFF5F5F5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                        ],
                        
                        // Set as default
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
                            const SizedBox(width: 8),
                            const Text(
                              'Set as default payment method',
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSegmentWidget(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13),
      ),
    );
  }
  
  String _accountLabel(PaymentMethodType type) {
    switch (type) {
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
  
  String _accountPlaceholder(PaymentMethodType type) {
    switch (type) {
      case PaymentMethodType.bankAccount:
        return 'Enter account number';
      case PaymentMethodType.paypal:
        return 'Enter PayPal email';
      case PaymentMethodType.venmo:
        return 'Enter Venmo username';
      case PaymentMethodType.cashApp:
        return 'Enter Cash App username';
      default:
        return 'Enter account information';
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDarkMode = themeProvider.isDarkMode;
    
    return CupertinoPageScaffold(
      backgroundColor: isDarkMode ? kBackgroundDark : CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Payment Methods'),
        backgroundColor: isDarkMode ? kBackgroundDark : CupertinoColors.white,
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