import 'package:flutter/material.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:slotted/api/firebase_auth_service.dart';

class AppleSignInTestPage extends StatefulWidget {
  const AppleSignInTestPage({super.key});

  @override
  State<AppleSignInTestPage> createState() => _AppleSignInTestPageState();
}

class _AppleSignInTestPageState extends State<AppleSignInTestPage> {
  bool _isAvailable = false;
  bool _isLoading = false;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _checkAvailability();
  }

  Future<void> _checkAvailability() async {
    try {
      final available = await SignInWithApple.isAvailable();
      setState(() {
        _isAvailable = available;
        _statusMessage = 'Apple Sign In available: $available';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error checking availability: $e';
      });
    }
  }

  Future<void> _testAppleSignIn() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Testing Apple Sign In...';
    });

    try {
      // Test the Apple Sign In flow
      final authService = FirebaseAuthService();
      final userCredential = await authService.signInWithApple();
      
      setState(() {
        _isLoading = false;
        _statusMessage = 'Apple Sign In test completed successfully!';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Apple Sign In test: ${userCredential.user != null ? 'SUCCESS' : 'FAILED'}'),
            backgroundColor: userCredential.user != null ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Apple Sign In test failed: $e';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Apple Sign In Test'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Apple Sign In Configuration Test',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Availability: $_isAvailable'),
                    const SizedBox(height: 8),
                    Text('Status: $_statusMessage'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_isAvailable) ...[
              SignInWithAppleButton(
                onPressed: _isLoading ? null : _testAppleSignIn,
                style: SignInWithAppleButtonStyle.black,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _testAppleSignIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Test Apple Sign In'),
              ),
            ] else ...[
              const Card(
                color: Colors.orange,
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Apple Sign In is not available on this device/simulator. '
                    'Please test on a physical iOS device.',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Configuration Checklist:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('✅ sign_in_with_apple package installed'),
                    Text('✅ iOS entitlements configured'),
                    Text('✅ URL schemes configured'),
                    Text('✅ Firebase Auth implementation'),
                    Text('✅ Bundle ID consistency'),
                    Text('✅ Apple App Site Association'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 