import 'package:flutter/cupertino.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String placeholder;
  final TextInputType keyboardType;
  final Widget? prefix;
  final Widget? suffix;
  final bool obscureText;
  final String? errorText;
  final FocusNode? focusNode;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.placeholder,
    this.keyboardType = TextInputType.text,
    this.prefix,
    this.suffix,
    this.obscureText = false,
    this.errorText,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: CupertinoColors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: errorText != null 
                  ? CupertinoColors.destructiveRed 
                  : CupertinoColors.systemGrey4,
              width: 1,
            ),
          ),
          child: CupertinoTextField(
            controller: controller,
            placeholder: placeholder,
            prefix: Padding(
              padding: const EdgeInsets.only(left: 10),
              child: prefix,
            ),
            suffix: suffix != null 
                ? Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: suffix,
                  ) 
                : null,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            keyboardType: keyboardType,
            obscureText: obscureText,
            focusNode: focusNode,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            decoration: null,
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 12),
            child: Text(
              errorText!,
              style: const TextStyle(
                color: CupertinoColors.destructiveRed,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
} 