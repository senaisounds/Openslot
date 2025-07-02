import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// A custom text field with a transparent background
class TransparentTextField extends StatelessWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? placeholder;
  final TextStyle? placeholderStyle;
  final TextStyle? style;
  final TextAlign textAlign;
  final EdgeInsetsGeometry padding;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final TextInputType keyboardType;
  final int? maxLines;
  final Color? cursorColor;

  const TransparentTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.placeholder,
    this.placeholderStyle,
    this.style,
    this.textAlign = TextAlign.start,
    this.padding = const EdgeInsets.all(16),
    this.enabled = true,
    this.onChanged,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.cursorColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: CupertinoTextField.borderless(
        controller: controller,
        focusNode: focusNode,
        placeholder: placeholder,
        placeholderStyle: placeholderStyle,
        style: style,
        textAlign: textAlign,
        padding: padding,
        enabled: enabled,
        onChanged: onChanged,
        keyboardType: keyboardType,
        maxLines: maxLines,
        cursorColor: cursorColor,
        decoration: null,
      ),
    );
  }
} 