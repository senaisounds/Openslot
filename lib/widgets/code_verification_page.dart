// ignore_for_file: use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CodeVerificationPage extends StatefulWidget {
  final String verificationId;

  const CodeVerificationPage({super.key, required this.verificationId});

  @override
  CodeVerificationPageState createState() => CodeVerificationPageState();
}

class CodeVerificationPageState extends State<CodeVerificationPage> {
  final TextEditingController _codeController = TextEditingController();
  bool _loading = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter Verification Code'),
        leading: _loading ? const SizedBox() : null,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(labelText: 'Verification Code'),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _loading
                  ? null
                  : () async {
                      setState(() {
                        _loading = true;
                      });
                      final code = _codeController.text.trim();
                      await _verifyCode(code, context);
                    },
              child: _loading
                  ? const CircularProgressIndicator()
                  : const Text('Verify'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _verifyCode(String code, BuildContext context) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: code,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      // Navigate to your desired page after successful login
      Navigator.of(context).pop();
    } catch (e) {
      FirebaseAuthException exception = e as FirebaseAuthException;
      // Handle error, show dialog, etc.
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text(exception.message ?? e.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }
}
