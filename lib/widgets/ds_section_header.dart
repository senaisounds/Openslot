import 'package:flutter/cupertino.dart';
import 'package:slotted/common/design_system.dart';

/// Section header component following the design system
class DSSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final bool showBorder;

  const DSSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.trailing,
    this.onTap,
    this.padding,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding ?? LayoutHelpers.cardPadding,
      decoration: showBorder ? ComponentStyles.sectionHeader : null,
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: DesignSystem.primaryOrange,
              size: 20,
            ),
            LayoutHelpers.horizontalSpacingM,
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: DesignSystem.h3.copyWith(
                    color: DesignSystem.primaryOrange,
                  ),
                ),
                if (subtitle != null) ...[
                  LayoutHelpers.smallSpacing,
                  Text(
                    subtitle!,
                    style: DesignSystem.body2.copyWith(
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: content,
      );
    }

    return content;
  }
}

/// Simple section divider with text
class DSSectionDivider extends StatelessWidget {
  final String text;
  final EdgeInsetsGeometry? margin;

  const DSSectionDivider({
    super.key,
    required this.text,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(
        vertical: DesignSystem.spacingL,
        horizontal: DesignSystem.spacingM,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              color: DesignSystem.borderLight.withValues(alpha: 0.3),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: DesignSystem.spacingM),
            child: Text(
              text.toUpperCase(),
              style: DesignSystem.caption.copyWith(
                color: CupertinoColors.systemGrey,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              color: DesignSystem.borderLight.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }
} 
