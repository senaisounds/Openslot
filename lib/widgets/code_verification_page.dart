// ignore_for_file: use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:slotted/common/colors.dart';

class CodeVerificationPage extends StatefulWidget {
  final String verificationId;

  const CodeVerificationPage(
      {super.key, required this.verificationId});

  @override
  CodeVerificationPageState createState() => CodeVerificationPageState();
}

class CodeVerificationPageState extends State<CodeVerificationPage> {
  final TextEditingController _codeController = TextEditingController();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: CupertinoColors.systemBackground,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Enter Verification Code'),
        leading: _loading ? const SizedBox() : null,
        backgroundColor: CupertinoColors.secondarySystemBackground,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 8.0),
            CupertinoTextField(
              keyboardType: TextInputType.number,
              style: const TextStyle(
                color: CupertinoColors.label,
                fontWeight: FontWeight.w600,
              ),
              padding: const EdgeInsets.all(12),
              controller: _codeController,
              placeholder: 'Verification Code',
              autofocus: true,
              decoration: BoxDecoration(
                color: CupertinoColors.secondarySystemBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: slottedOrange,
                  width: 1,
                ),
              ),
            ),
            const SizedBox(height: 24.0),
            CupertinoButton(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              borderRadius: BorderRadius.circular(12),
              color: slottedOrange,
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
                  ? const CupertinoActivityIndicator()
                  : const Text(
                      'Verify',
                      style: TextStyle(
                        color: CupertinoColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Error'),
          content: Text(exception.message ?? e.toString()),
          actions: [
            CupertinoButton(
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
