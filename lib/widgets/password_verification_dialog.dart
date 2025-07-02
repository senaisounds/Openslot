import 'package:flutter/cupertino.dart';
import 'package:slotted/common/colors.dart' as app_colors;
// Main Theme Colors
// Rich Purple - Stage Lights
// Soft Purple - Energy
// Electric Blue - Microphone Glow
// Warm Yellow - Spotlight
// Dark Stage
// Light Mode

class PasswordVerificationDialog extends StatefulWidget {
  final String eventName;
  final String correctPassword;

  const PasswordVerificationDialog({
    super.key,
    required this.eventName,
    required this.correctPassword,
  });

  @override
  State<PasswordVerificationDialog> createState() => _PasswordVerificationDialogState();
}

class _PasswordVerificationDialogState extends State<PasswordVerificationDialog> {
  final TextEditingController _passwordController = TextEditingController();
  String? _errorMessage;
  bool _isObscured = true;

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
                    style: const TextStyle(
                      color: CupertinoColors.label,
                    ),
                    decoration: null,
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
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
          onPressed: () => Navigator.of(context).pop(false),
          isDestructiveAction: true,
          child: const Text('Cancel'),
        ),
        CupertinoDialogAction(
          onPressed: () {
            if (_passwordController.text == widget.correctPassword) {
              Navigator.of(context).pop(true);
            } else {
              setState(() {
                _errorMessage = 'Incorrect password. Please try again.';
              });
            }
          },
          child: const Text('Join Event'),
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