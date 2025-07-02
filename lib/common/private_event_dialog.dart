import 'package:flutter/cupertino.dart';

class PrivateEventDialog extends StatefulWidget {
  final String eventName;
  final Function(String) onSubmit;
  final VoidCallback onCancel;

  const PrivateEventDialog({
    super.key,
    required this.eventName,
    required this.onSubmit,
    required this.onCancel,
  });

  @override
  State<PrivateEventDialog> createState() => _PrivateEventDialogState();
}

class _PrivateEventDialogState extends State<PrivateEventDialog> {
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: const Text('Private Event'),
      content: Column(
        children: [
          const SizedBox(height: 8),
          Text('Enter password to reserve "${widget.eventName}"'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: CupertinoColors.systemBackground.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: CupertinoTextField(
                    controller: _passwordController,
                    placeholder: 'Password',
                    obscureText: !_isPasswordVisible,
                    style: const TextStyle(color: CupertinoColors.white),
                    decoration: null,
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                  child: Icon(
                    _isPasswordVisible
                        ? CupertinoIcons.eye_slash_fill
                        : CupertinoIcons.eye_fill,
                    color: CupertinoColors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: widget.onCancel,
          isDestructiveAction: true,
          child: const Text('Cancel'),
        ),
        CupertinoDialogAction(
          onPressed: () {
            final password = _passwordController.text.trim();
            if (password.isNotEmpty) {
              widget.onSubmit(password);
            }
          },
          child: const Text('Submit'),
        ),
      ],
    );
  }
} 