import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:slotted/common/payout_transaction.dart';
import 'package:slotted/common/payment_method.dart';
import 'package:slotted/common/event_class.dart';
import 'package:slotted/services/payout_service.dart';
import 'package:slotted/providers/theme_provider.dart';
import 'package:slotted/utils/logger.dart';
import 'package:slotted/pages/payment_method_page.dart';
import '../common/colors.dart';

class HostPayoutPage extends StatefulWidget {
  final User? user;
  
  const HostPayoutPage({
    super.key,
    required this.user,
  });

  @override
  HostPayoutPageState createState() => HostPayoutPageState();
}

class HostPayoutPageState extends State<HostPayoutPage> with TickerProviderStateMixin {
  final PayoutService _payoutService = PayoutService();
  
  List<Event> _hostEvents = [];
  List<PayoutTransaction> _payoutHistory = [];
  List<PaymentMethod> _paymentMethods = [];
  PayoutAnalytics? _analytics;
  PayoutCalculation? _currentCalculation;
  
  bool _isLoading = true;
  String? _selectedEventId;
  PaymentMethod? _selectedPaymentMethod;
  double _requestAmount = 0.0;
  
  final TextEditingController _amountController = TextEditingController();
  final PageController _pageController = PageController();
  int _currentPageIndex = 0;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  @override
  void dispose() {
    _amountController.dispose();
    _pageController.dispose();
    super.dispose();
  }
  
  Future<void> _loadData() async {
    if (widget.user == null) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Load host events
      final eventsSnapshot = await FirebaseFirestore.instance
          .collection('events')
          .where('host', isEqualTo: widget.user!.uid)
          .where('ended', isEqualTo: true)
          .get();
      
      final events = eventsSnapshot.docs
          .map((doc) => Event.fromDocument(doc))
          .toList();
      
      // Load all data in parallel
      final futures = await Future.wait([
        _payoutService.getPayoutHistory(widget.user!.uid),
        _payoutService.getPaymentMethods(widget.user!.uid),
        _payoutService.getDefaultPaymentMethod(widget.user!.uid),
        _payoutService.getPayoutAnalytics(widget.user!.uid),
      ]);
      
      final payoutHistory = futures[0] as List<PayoutTransaction>;
      final paymentMethods = futures[1] as List<PaymentMethod>;
      final defaultMethod = futures[2] as PaymentMethod?;
      final analytics = futures[3] as PayoutAnalytics;
      
      setState(() {
        _hostEvents = events;
        _payoutHistory = payoutHistory;
        _paymentMethods = paymentMethods;
        _selectedPaymentMethod = defaultMethod;
        _analytics = analytics;
        
        if (events.isNotEmpty) {
          _selectedEventId = events.first.id;
          _updateCalculation();
        }
        
        _isLoading = false;
      });
    } catch (e) {
      Logger.d('Error loading data: $e', tag: 'HostPayoutPage');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _updateCalculation() async {
    if (_selectedEventId == null) return;
    
    try {
      final calculation = await _payoutService.calculatePayoutDetails(_selectedEventId!);
      setState(() {
        _currentCalculation = calculation;
      });
    } catch (e) {
      Logger.d('Error calculating payout details: $e', tag: 'HostPayoutPage');
    }
  }
  
  Future<void> _requestPayout() async {
    if (widget.user == null) return;
    if (_selectedEventId == null) {
      _showErrorDialog('Please select an event');
      return;
    }
    
    if (_selectedPaymentMethod == null) {
      _showErrorDialog('Please add a payment method');
      return;
    }
    
    if (_requestAmount <= 0) {
      _showErrorDialog('Please enter a valid amount');
      return;
    }
    
    if (_currentCalculation != null && _requestAmount > _currentCalculation!.availableAmount) {
      _showErrorDialog('Amount exceeds available balance');
      return;
    }
    
    if (_requestAmount < PayoutService.minimumPayoutAmount) {
      _showErrorDialog('Minimum payout amount is \$${PayoutService.minimumPayoutAmount.toStringAsFixed(2)}');
      return;
    }
    
    try {
      HapticFeedback.mediumImpact();
      
      setState(() {
        _isLoading = true;
      });
      
      // Find event name
      final event = _hostEvents.firstWhere((e) => e.id == _selectedEventId);
      
      // Request payout
      await _payoutService.requestPayout(
        hostId: widget.user!.uid,
        eventId: _selectedEventId!,
        eventName: event.name,
        amount: _requestAmount,
        paymentMethodId: _selectedPaymentMethod!.id,
      );
      
      // Clear form
      _amountController.clear();
      setState(() {
        _requestAmount = 0.0;
      });
      
      // Refresh data
      await _loadData();
      
      HapticFeedback.lightImpact();
      _showSuccessDialog('Payout request submitted successfully! 🎉');
    } catch (e) {
      Logger.d('Error requesting payout: $e', tag: 'HostPayoutPage');
      setState(() {
        _isLoading = false;
      });
      
      HapticFeedback.heavyImpact();
      _showErrorDialog('Failed to request payout: ${e.toString()}');
    }
  }
  
  Future<void> _cancelPayout(String payoutId) async {
    try {
      HapticFeedback.lightImpact();
      
      setState(() {
        _isLoading = true;
      });
      
      await _payoutService.cancelPayout(payoutId);
      
      // Refresh data
      await _loadData();
      
      HapticFeedback.lightImpact();
      _showSuccessDialog('Payout request cancelled');
    } catch (e) {
      Logger.d('Error cancelling payout: $e', tag: 'HostPayoutPage');
      setState(() {
        _isLoading = false;
      });
      
      HapticFeedback.heavyImpact();
      _showErrorDialog('Failed to cancel payout: ${e.toString()}');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (widget.user == null) {
      return _buildUnauthenticatedView();
    }

    return CupertinoPageScaffold(
      backgroundColor: context.watch<ThemeProvider>().backgroundColor,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.backgroundDark.withValues(alpha: 0.8),
        border: null,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
            onPressed: () => Navigator.of(context).pop(),
          child: const Icon(
            CupertinoIcons.back,
            color: AppColors.backgroundLight,
      ),
        ),
        middle: const Text(
          'Payouts',
          style: TextStyle(
            color: AppColors.backgroundLight,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _addPaymentMethod,
          child: const Icon(
            CupertinoIcons.add,
            color: AppColors.primary,
            size: 24,
          ),
        ),
      ),
      child: _isLoading
          ? const Center(child: CupertinoActivityIndicator(radius: 20))
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    return Column(
                children: [
        // Enhanced Analytics Dashboard
        _buildAnalyticsDashboard(),
                  
        // Page View for different sections
        Expanded(
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPageIndex = index;
              });
            },
            children: [
              _buildRequestPayoutPage(),
              _buildPayoutHistoryPage(),
                ],
              ),
            ),
        
        // Bottom Navigation
        _buildBottomNavigation(),
      ],
    );
  }
  
  Widget _buildAnalyticsDashboard() {
    if (_analytics == null) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundDark.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Earnings Overview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: context.watch<ThemeProvider>().textColor,
            ),
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'This Year',
                  '\$${_analytics!.thisYearTotal.toStringAsFixed(2)}',
                  CupertinoIcons.calendar,
                  AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Pending',
                  '\$${_analytics!.pendingTotal.toStringAsFixed(2)}',
                  CupertinoIcons.clock,
                  AppColors.highlight,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'All Time',
                  '\$${_analytics!.allTimeTotal.toStringAsFixed(2)}',
                  CupertinoIcons.star_fill,
                  AppColors.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
          ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: context.watch<ThemeProvider>().textColor,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: context.watch<ThemeProvider>().textColor.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestPayoutPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event Selection
          _buildEventSelector(),
          
          const SizedBox(height: 16),
          
          // Payout Calculation Details
          if (_currentCalculation != null) _buildPayoutBreakdown(),
          
          const SizedBox(height: 16),
          
          // Payment Method Selection
          _buildPaymentMethodSelector(),
          
          const SizedBox(height: 16),
          
          // Amount Input
          _buildAmountInput(),
          
          const SizedBox(height: 24),
          
          // Request Button
          _buildRequestButton(),
        ],
      ),
    );
  }

  Widget _buildEventSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundDark.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Event',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: context.watch<ThemeProvider>().textColor,
            ),
          ),
          const SizedBox(height: 8),
          if (_hostEvents.isEmpty)
          Text(
              'No completed events available for payout',
            style: TextStyle(
              fontSize: 14,
                color: context.watch<ThemeProvider>().textColor.withValues(alpha: 0.7),
              ),
            )
          else
            DropdownButton<String>(
              value: _selectedEventId,
              isExpanded: true,
                style: TextStyle(
                color: context.watch<ThemeProvider>().textColor,
                fontSize: 14,
                ),
              dropdownColor: AppColors.backgroundDark,
              items: _hostEvents.map((event) {
                return DropdownMenuItem<String>(
                  value: event.id,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
            ),
                      Text(
                        '${event.attendees.length} attendees • \$${event.price.toStringAsFixed(2)} each',
                        style: TextStyle(
                          fontSize: 12,
                          color: context.watch<ThemeProvider>().textColor.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            onChanged: (value) {
              setState(() {
                  _selectedEventId = value;
                  _updateCalculation();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPayoutBreakdown() {
    final calc = _currentCalculation!;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundDark.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Payout Breakdown',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: context.watch<ThemeProvider>().textColor,
                  ),
                ),
              if (!calc.meetsMinimum)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Below Minimum',
                    style: TextStyle(
                  color: Colors.white,
                      fontSize: 10,
                  fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
          
          const SizedBox(height: 12),
          
          _buildBreakdownRow('Gross Revenue', calc.grossRevenue, isPositive: true),
          _buildBreakdownRow('Platform Fee (10%)', calc.platformFee, isNegative: true),
          _buildBreakdownRow('Previous Payouts', calc.previousPayouts, isNegative: true),
          _buildBreakdownRow('Payout Fee', calc.payoutFee, isNegative: true),
          
          const Divider(color: Colors.grey),
          
          _buildBreakdownRow(
            'Available Amount',
            calc.availableAmount,
            isTotal: true,
            color: calc.meetsMinimum ? AppColors.primary : Colors.orange,
        ),
          
          if (!calc.meetsMinimum)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Minimum payout amount is \$${PayoutService.minimumPayoutAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.orange,
                  fontStyle: FontStyle.italic,
              ),
            ),
            ),
          ],
        ),
    );
  }

  Widget _buildBreakdownRow(
    String label,
    double amount, {
    bool isPositive = false,
    bool isNegative = false,
    bool isTotal = false,
    Color? color,
  }) {
    final textColor = color ?? context.watch<ThemeProvider>().textColor;
    final prefix = isNegative ? '-' : '';
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 14 : 13,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: textColor.withValues(alpha: isTotal ? 1.0 : 0.8),
            ),
          ),
          Text(
            '$prefix\$${amount.toStringAsFixed(2)}',
                    style: TextStyle(
              fontSize: isTotal ? 14 : 13,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: textColor,
              ),
            ),
          ],
      ),
    );
  }
  
  Widget _buildPaymentMethodSelector() {
      return Container(
      padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
        color: AppColors.backgroundDark.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Payment Method',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: context.watch<ThemeProvider>().textColor,
            ),
              ),
            CupertinoButton(
              padding: EdgeInsets.zero,
                onPressed: _addPaymentMethod,
                child: const Text(
                  'Add New',
                style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                ),
              ),
            ),
          ],
        ),
          const SizedBox(height: 8),
          if (_paymentMethods.isEmpty)
            Text(
              'No payment methods added',
              style: TextStyle(
                fontSize: 14,
                color: context.watch<ThemeProvider>().textColor.withValues(alpha: 0.7),
              ),
            )
          else
            Column(
              children: _paymentMethods.map((method) {
                final isSelected = _selectedPaymentMethod?.id == method.id;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPaymentMethod = method;
                    });
                  },
      child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
                      color: isSelected 
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected 
                            ? AppColors.primary
                            : Colors.grey.withValues(alpha: 0.3),
                        width: 1,
                      ),
        ),
        child: Row(
          children: [
                        Icon(
                          _getPaymentMethodIcon(method.type),
                          color: isSelected ? AppColors.primary : Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
            Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                method.typeDisplayName,
                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: context.watch<ThemeProvider>().textColor,
                ),
              ),
                              Text(
                                method.maskedAccount,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: context.watch<ThemeProvider>().textColor.withValues(alpha: 0.7),
            ),
            ),
          ],
        ),
      ),
                        if (method.isDefault)
            Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                              color: AppColors.secondary,
                              borderRadius: BorderRadius.circular(4),
              ),
                            child: const Text(
                              'Default',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                  ),
                ],
              ),
            ),
                );
              }).toList(),
            ),
          ],
      ),
    );
  }
  
  Widget _buildAmountInput() {
    final maxAmount = _currentCalculation?.availableAmount ?? 0.0;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundDark.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payout Amount',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: context.watch<ThemeProvider>().textColor,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '\$',
                style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
                  color: context.watch<ThemeProvider>().textColor,
          ),
              ),
              Expanded(
                child: CupertinoTextField(
                  controller: _amountController,
                  placeholder: '0.00',
                  placeholderStyle: TextStyle(
                    color: context.watch<ThemeProvider>().textColor.withValues(alpha: 0.5),
                  ),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: context.watch<ThemeProvider>().textColor,
                  ),
                  decoration: const BoxDecoration(),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (value) {
                    setState(() {
                      _requestAmount = double.tryParse(value) ?? 0.0;
                    });
                  },
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: maxAmount > 0 ? () {
                  _amountController.text = maxAmount.toStringAsFixed(2);
                  setState(() {
                    _requestAmount = maxAmount;
                  });
                } : null,
                    child: Text(
                  'Max',
                      style: TextStyle(
                    color: maxAmount > 0 ? AppColors.primary : Colors.grey,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
            ],
          ),
          if (maxAmount > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Max available: \$${maxAmount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 12,
                  color: context.watch<ThemeProvider>().textColor.withValues(alpha: 0.6),
                ),
              ),
                ),
        ],
      ),
    );
  }
  
  Widget _buildRequestButton() {
    final canRequest = _selectedEventId != null &&
        _selectedPaymentMethod != null &&
        _requestAmount >= PayoutService.minimumPayoutAmount &&
        (_currentCalculation?.meetsMinimum ?? false) &&
        _requestAmount <= (_currentCalculation?.availableAmount ?? 0.0);
    
    return SizedBox(
      width: double.infinity,
      child: CupertinoButton(
        color: canRequest ? AppColors.primary : Colors.grey,
        borderRadius: BorderRadius.circular(12),
        onPressed: canRequest ? _requestPayout : null,
        child: const Text(
          'Request Payout',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildPayoutHistoryPage() {
    return _payoutHistory.isEmpty
        ? _buildEmptyHistoryState()
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _payoutHistory.length,
            itemBuilder: (context, index) {
              final payout = _payoutHistory[index];
              return _buildPayoutHistoryItem(payout);
            },
          );
  }

  Widget _buildPayoutHistoryItem(PayoutTransaction payout) {
    Color statusColor;
    IconData statusIcon;
    
    switch (payout.status) {
      case PayoutStatus.completed:
        statusColor = Colors.green;
        statusIcon = CupertinoIcons.checkmark_circle_fill;
        break;
      case PayoutStatus.processing:
        statusColor = Colors.orange;
        statusIcon = CupertinoIcons.clock_fill;
        break;
      case PayoutStatus.failed:
        statusColor = Colors.red;
        statusIcon = CupertinoIcons.xmark_circle_fill;
        break;
      case PayoutStatus.pending:
        statusColor = Colors.blue;
        statusIcon = CupertinoIcons.clock;
        break;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundDark.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
          ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  payout.eventName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.watch<ThemeProvider>().textColor,
                  ),
                ),
            ),
              Row(
                children: [
                  Icon(
              statusIcon,
              color: statusColor,
                    size: 16,
          ),
                  const SizedBox(width: 4),
                  Text(
                    payout.statusDisplayText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                payout.formattedAmount,
                  style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  ),
                ),
                Text(
                payout.timeAgo,
                  style: TextStyle(
                    fontSize: 12,
                  color: context.watch<ThemeProvider>().textColor.withValues(alpha: 0.6),
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 4),
          
                  Text(
            payout.displaySummary,
                    style: TextStyle(
              fontSize: 14,
              color: context.watch<ThemeProvider>().textColor.withValues(alpha: 0.7),
            ),
          ),
          
          if (payout.canBeCancelled) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: CupertinoButton(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    onPressed: () => _cancelPayout(payout.id),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    ),
                  ),
                ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.backgroundDark.withValues(alpha: 0.8),
        border: Border(
          top: BorderSide(
            color: Colors.grey.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildNavItem(
              'Request',
              CupertinoIcons.money_dollar_circle,
              0,
            ),
          ),
          Expanded(
            child: _buildNavItem(
              'History',
              CupertinoIcons.time,
              1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(String title, IconData icon, int index) {
    final isSelected = _currentPageIndex == index;
    
    return GestureDetector(
      onTap: () {
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : Colors.grey,
              size: 20,
            ),
            const SizedBox(height: 4),
                Text(
              title,
                  style: TextStyle(
                    fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppColors.primary : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildEmptyHistoryState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
            children: [
            Icon(
              CupertinoIcons.money_dollar_circle,
              size: 64,
              color: Colors.grey.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
              Text(
              'No Payout History',
                style: TextStyle(
                fontSize: 20,
                  fontWeight: FontWeight.bold,
                color: context.watch<ThemeProvider>().textColor,
                ),
              ),
            const SizedBox(height: 8),
            Text(
              'Your payout requests will appear here',
              textAlign: TextAlign.center,
                  style: TextStyle(
                fontSize: 16,
                color: context.watch<ThemeProvider>().textColor.withValues(alpha: 0.7),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnauthenticatedView() {
    return CupertinoPageScaffold(
      backgroundColor: context.watch<ThemeProvider>().backgroundColor,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.person_circle,
                size: 64,
                color: Colors.grey.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Please sign in to access payouts',
                    style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.watch<ThemeProvider>().textColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getPaymentMethodIcon(PaymentMethodType type) {
    switch (type) {
      case PaymentMethodType.bankAccount:
        return CupertinoIcons.building_2_fill;
      case PaymentMethodType.paypal:
        return CupertinoIcons.creditcard;
      case PaymentMethodType.venmo:
        return CupertinoIcons.phone;
      case PaymentMethodType.cashApp:
        return CupertinoIcons.money_dollar;
      default:
        return CupertinoIcons.creditcard;
    }
  }

  void _addPaymentMethod() {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => PaymentMethodPage(
          user: widget.user!,
        ),
      ),
    ).then((_) => _loadData());
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
} 