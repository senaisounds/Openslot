import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:slotted/api/apple_pay.dart';
import 'package:slotted/api/stripe_config.dart';
import 'package:slotted/common/colors.dart';
import 'package:slotted/common/event_class.dart';
import 'package:slotted/utils/logger.dart';

class ModernPaymentWidget extends StatefulWidget {
  final Event event;
  final String clientSecret;
  final bool debug;
  final Function(PaymentProcessResult) onPaymentResult;
  final VoidCallback? onCancel;

  const ModernPaymentWidget({
    super.key,
    required this.event,
    required this.clientSecret,
    required this.debug,
    required this.onPaymentResult,
    this.onCancel,
  });

  @override
  State<ModernPaymentWidget> createState() => _ModernPaymentWidgetState();
}

class _ModernPaymentWidgetState extends State<ModernPaymentWidget> {
  bool _isProcessing = false;
  bool _platformPaySupported = false;

  @override
  void initState() {
    super.initState();
    _checkPlatformPaySupport();
  }

  Future<void> _checkPlatformPaySupport() async {
    try {
      final isSupported = await ModernPaymentService.isPlatformPaySupported();
      if (mounted) {
        setState(() {
          _platformPaySupported = isSupported;
        });
      }
    } catch (e) {
      Logger.e('Error checking platform pay support: $e', tag: 'ModernPaymentWidget');
    }
  }

  Future<void> _processPlatformPayment() async {
    if (_isProcessing) return;
    
    setState(() {
      _isProcessing = true;
    });

    try {
      final result = await ModernPaymentService.processPlatformPayment(
        event: widget.event,
        clientSecret: widget.clientSecret,
        merchantName: StripeConfig.getMerchantName(),
        debug: widget.debug,
      );

      widget.onPaymentResult(result);
    } catch (e) {
      Logger.e('Error in platform payment: $e', tag: 'ModernPaymentWidget');
      widget.onPaymentResult(
        PaymentFailure('Payment processing failed'),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _processCardPayment() async {
    if (_isProcessing) return;
    
    setState(() {
      _isProcessing = true;
    });

    try {
      final result = await ModernPaymentService.processCardPayment(
        event: widget.event,
        clientSecret: widget.clientSecret,
        merchantName: StripeConfig.getMerchantName(),
        debug: widget.debug,
      );

      widget.onPaymentResult(result);
    } catch (e) {
      Logger.e('Error in card payment: $e', tag: 'ModernPaymentWidget');
      widget.onPaymentResult(
        PaymentFailure('Payment processing failed'),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Payment Header
          Row(
            children: [
              const Icon(
                CupertinoIcons.creditcard,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Complete Payment',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Reserve your spot for ${widget.event.name}',
                      style: TextStyle(
                        color: AppColors.textPrimary.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Event Price Display
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Amount',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '\$${widget.event.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Payment Methods
          if (_platformPaySupported) ...[
            // Platform Pay Button (Apple Pay / Google Pay)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: CupertinoButton(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
                onPressed: _isProcessing ? null : _processPlatformPayment,
                child: _isProcessing
                    ? const CupertinoActivityIndicator(color: Colors.white)
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            StripeConfig.isApplePayAvailable() 
                                ? CupertinoIcons.device_phone_portrait
                                : Icons.contactless,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            ModernPaymentService.getPlatformPayLabel(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Divider
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 1,
                    color: AppColors.textPrimary.withValues(alpha: 0.3),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'or',
                    style: TextStyle(
                      color: AppColors.textPrimary.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 1,
                    color: AppColors.textPrimary.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
          ],
          
          // Card Payment Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: CupertinoButton(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(12),
              onPressed: _isProcessing ? null : _processCardPayment,
              child: _isProcessing
                  ? const CupertinoActivityIndicator(color: Colors.white)
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.creditcard,
                          color: Colors.white,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Pay with Card',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Cancel Button
          if (widget.onCancel != null)
            SizedBox(
              width: double.infinity,
              height: 44,
              child: CupertinoButton(
                onPressed: _isProcessing ? null : widget.onCancel,
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: AppColors.textPrimary.withValues(alpha: 0.7),
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          
          const SizedBox(height: 8),
          
          // Security Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.lock_shield,
                color: AppColors.textPrimary.withValues(alpha: 0.5),
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                'Secured by Stripe',
                style: TextStyle(
                  color: AppColors.textPrimary.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
