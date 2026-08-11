import 'package:flutter/cupertino.dart';
import 'package:slotted/common/colors.dart' as app_colors;
import 'package:slotted/utils/event_password_verifier.dart';

/// Private-event password dialog that verifies via Cloud Function.
/// Does not accept or compare a local "correctPassword".
class PasswordVerificationDialog extends StatefulWidget {
  final String eventName;
  final String eventId;

  const PasswordVerificationDialog({
    super.key,
    required this.eventName,
    required this.eventId,
  });

  @override
  State<PasswordVerificationDialog> createState() =>
      _PasswordVerificationDialogState();
}

class _PasswordVerificationDialogState
    extends State<PasswordVerificationDialog> {
  final TextEditingController _passwordController = TextEditingController();
  String? _errorMessage;
  bool _isObscured = true;
  bool _isVerifying = false;

  Future<void> _verify() async {
    if (_isVerifying) return;
    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    final ok = await EventPasswordVerifier.verify(
      widget.eventId,
      _passwordController.text,
    );

    if (!mounted) return;

    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _isVerifying = false;
        _errorMessage = 'Incorrect password. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: Text(
        'Private Event: ${widget.eventName}',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: app_colors.AppColors.backgroundDark.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: app_colors.AppColors.primary.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: CupertinoTextField(
                    controller: _passwordController,
                    placeholder: 'Enter event password',
                    obscureText: _isObscured,
                    enabled: !_isVerifying,
                    style: const TextStyle(
                      color: CupertinoColors.label,
                    ),
                    decoration: null,
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: _isVerifying
                      ? null
                      : () {
                          setState(() {
                            _isObscured = !_isObscured;
                          });
                        },
                  child: Icon(
                    _isObscured ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
                    color: app_colors.AppColors.primary,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: const TextStyle(
                color: CupertinoColors.destructiveRed,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: _isVerifying ? null : () => Navigator.of(context).pop(false),
          isDestructiveAction: true,
          child: const Text('Cancel'),
        ),
        CupertinoDialogAction(
          onPressed: _isVerifying ? null : _verify,
          child: Text(_isVerifying ? 'Checking…' : 'Join Event'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }
}
