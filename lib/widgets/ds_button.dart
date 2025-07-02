import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:slotted/common/design_system.dart';

/// Primary button component following the design system
class DSPrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  final EdgeInsetsGeometry? padding;

  const DSPrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isFullWidth ? double.infinity : null,
      decoration: ComponentStyles.primaryButton,
      child: CupertinoButton(
        padding: padding ?? const EdgeInsets.symmetric(
          vertical: DesignSystem.spacingM,
          horizontal: DesignSystem.spacingL,
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const CupertinoActivityIndicator(
                color: Colors.white,
                radius: 12,
              )
            : Row(
                mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      color: Colors.white,
                      size: 20,
                    ),
                    LayoutHelpers.horizontalSpacingS,
                  ],
                  Text(
                    text,
                    style: DesignSystem.body1.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Secondary button component following the design system
class DSSecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  final EdgeInsetsGeometry? padding;

  const DSSecondaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isFullWidth ? double.infinity : null,
      decoration: ComponentStyles.secondaryButton,
      child: CupertinoButton(
        padding: padding ?? const EdgeInsets.symmetric(
          vertical: DesignSystem.spacingM,
          horizontal: DesignSystem.spacingL,
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const CupertinoActivityIndicator(
                color: DesignSystem.primaryOrange,
                radius: 12,
              )
            : Row(
                mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      color: DesignSystem.primaryOrange,
                      size: 20,
                    ),
                    LayoutHelpers.horizontalSpacingS,
                  ],
                  Text(
                    text,
                    style: DesignSystem.body1.copyWith(
                      color: DesignSystem.primaryOrange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Text button component following the design system
class DSTextButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? color;
  final EdgeInsetsGeometry? padding;

  const DSTextButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.color,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final buttonColor = color ?? DesignSystem.primaryOrange;
    
    return CupertinoButton(
      padding: padding ?? const EdgeInsets.symmetric(
        vertical: DesignSystem.spacingS,
        horizontal: DesignSystem.spacingM,
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: buttonColor,
              size: 18,
            ),
            LayoutHelpers.horizontalSpacingS,
          ],
          Text(
            text,
            style: DesignSystem.body1.copyWith(
              color: buttonColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Icon button component following the design system
class DSIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final double? size;
  final EdgeInsetsGeometry? padding;
  final bool showBackground;

  const DSIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.color,
    this.size,
    this.padding,
    this.showBackground = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? DesignSystem.primaryOrange;
    
    final iconWidget = Icon(
      icon,
      color: iconColor,
      size: size ?? 24,
    );

    if (showBackground) {
      return Container(
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(DesignSystem.radiusS),
        ),
        child: CupertinoButton(
          padding: padding ?? const EdgeInsets.all(DesignSystem.spacingS),
          onPressed: onPressed,
          child: iconWidget,
        ),
      );
    }

    return CupertinoButton(
      padding: padding ?? const EdgeInsets.all(DesignSystem.spacingS),
      onPressed: onPressed,
      child: iconWidget,
    );
  }
} 