import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:slotted/api/stripe_config.dart';
import 'package:slotted/common/colors.dart';
import 'package:slotted/utils/logger.dart';

class StripeSettingsPage extends StatefulWidget {
  const StripeSettingsPage({super.key});

  @override
  State<StripeSettingsPage> createState() => _StripeSettingsPageState();
}

class _StripeSettingsPageState extends State<StripeSettingsPage> {
  final _testKeyController = TextEditingController();
  final _liveKeyController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _showKeys = false;
  bool _testKeySaved = false;
  bool _liveKeySaved = false;

  @override
  void initState() {
    super.initState();
    _loadExistingKeys();
  }

  @override
  void dispose() {
    _testKeyController.dispose();
    _liveKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingKeys() async {
    try {
      // Try to load existing keys
      final testKey = await StripeConfig.getPublishableKey(true);
      final liveKey = await StripeConfig.getPublishableKey(false);
      
      if (mounted) {
        setState(() {
          // Only show if they're real keys (not placeholders)
          if (testKey.isNotEmpty && !testKey.contains('REPLACE')) {
            _testKeyController.text = testKey;
            _testKeySaved = true;
          }
          if (liveKey.isNotEmpty && !liveKey.contains('REPLACE')) {
            _liveKeyController.text = liveKey;
            _liveKeySaved = true;
          }
        });
      }
    } catch (e) {
      Logger.d('No existing keys found: $e', tag: 'StripeSettings');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stripe Configuration'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: AppColors.primary),
                          SizedBox(width: 8),
                          Text(
                            'Stripe API Keys',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Configure your Stripe publishable keys for payment processing. These keys are stored securely on your device.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Test Key Input
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.developer_mode, color: Colors.orange[600]),
                          const SizedBox(width: 8),
                          const Text(
                            'Test Key (Development)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          if (_testKeySaved)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle, color: Colors.green[700], size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Saved',
                                    style: TextStyle(
                                      color: Colors.green[700],
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _testKeyController,
                              obscureText: !_showKeys,
                              decoration: InputDecoration(
                                labelText: 'Test Publishable Key',
                                hintText: 'Tap paste button or type key',
                                border: const OutlineInputBorder(),
                                suffixIcon: IconButton(
                                  icon: Icon(_showKeys ? Icons.visibility_off : Icons.visibility),
                                  onPressed: () {
                                    setState(() {
                                      _showKeys = !_showKeys;
                                    });
                                  },
                                ),
                              ),
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  if (!value.startsWith('pk_test_')) {
                                    return 'Test key must start with pk_test_';
                                  }
                                  if (value.length < 20) {
                                    return 'Key appears to be too short';
                                  }
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final data = await Clipboard.getData(Clipboard.kTextPlain);
                              if (data?.text != null) {
                                setState(() {
                                  _testKeyController.text = data!.text!;
                                });
                              }
                            },
                            icon: const Icon(Icons.content_paste),
                            label: const Text('Paste'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Live Key Input
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.security, color: Colors.green[600]),
                          const SizedBox(width: 8),
                          const Text(
                            'Live Key (Production)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          if (_liveKeySaved)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle, color: Colors.green[700], size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Saved',
                                    style: TextStyle(
                                      color: Colors.green[700],
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.orange[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber, color: Colors.orange[600], size: 16),
                            const SizedBox(width: 6),
                            const Expanded(
                              child: Text(
                                'Only enter live key when ready for production!',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _liveKeyController,
                              obscureText: !_showKeys,
                              decoration: InputDecoration(
                                labelText: 'Live Publishable Key (Optional)',
                                hintText: 'Tap paste button or type key',
                                border: const OutlineInputBorder(),
                                suffixIcon: IconButton(
                                  icon: Icon(_showKeys ? Icons.visibility_off : Icons.visibility),
                                  onPressed: () {
                                    setState(() {
                                      _showKeys = !_showKeys;
                                    });
                                  },
                                ),
                              ),
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  if (!value.startsWith('pk_live_')) {
                                    return 'Live key must start with pk_live_';
                                  }
                                  if (value.length < 20) {
                                    return 'Key appears to be too short';
                                  }
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final data = await Clipboard.getData(Clipboard.kTextPlain);
                              if (data?.text != null) {
                                setState(() {
                                  _liveKeyController.text = data!.text!;
                                });
                              }
                            },
                            icon: const Icon(Icons.content_paste),
                            label: const Text('Paste'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Save Button
              ElevatedButton(
                onPressed: _isLoading ? null : _saveKeys,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Saving...'),
                        ],
                      )
                    : const Text(
                        'Save Configuration',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
              const SizedBox(height: 16),
              
              // Clear Cache Button
              TextButton(
                onPressed: _clearCache,
                child: const Text(
                  'Clear Cached Keys',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveKeys() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final testKey = _testKeyController.text.trim();
      final liveKey = _liveKeyController.text.trim();

      await StripeConfig.storeKeys(
        testKey: testKey.isNotEmpty ? testKey : null,
        liveKey: liveKey.isNotEmpty ? liveKey : null,
      );

      if (mounted) {
        // Update saved status
        setState(() {
          _testKeySaved = testKey.isNotEmpty;
          _liveKeySaved = liveKey.isNotEmpty;
        });
        
        // Show success dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
            title: const Text('Success!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Stripe keys saved successfully!'),
                const SizedBox(height: 16),
                if (testKey.isNotEmpty)
                  Row(
                    children: [
                      Icon(Icons.check, color: Colors.green[700], size: 20),
                      const SizedBox(width: 8),
                      const Text('Test key saved'),
                    ],
                  ),
                if (liveKey.isNotEmpty)
                  Row(
                    children: [
                      Icon(Icons.check, color: Colors.green[700], size: 20),
                      const SizedBox(width: 8),
                      const Text('Live key saved'),
                    ],
                  ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Keys are stored securely on your device',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        
        // Don't clear the form - keep keys visible (but obscured)
      }
    } catch (e) {
      Logger.e('Error saving Stripe keys: $e', tag: 'StripeSettings');
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text('Error saving keys: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _clearCache() {
    StripeConfig.clearCache();
    setState(() {
      _testKeyController.clear();
      _liveKeyController.clear();
      _testKeySaved = false;
      _liveKeySaved = false;
    });
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cache Cleared'),
        content: const Text('Stripe key cache has been cleared. You\'ll need to enter your keys again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

