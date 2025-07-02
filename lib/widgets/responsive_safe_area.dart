import 'package:flutter/cupertino.dart';
import 'package:slotted/common/responsive_system.dart';

/// Responsive SafeArea wrapper that handles different device types
/// Ensures proper safe area handling across all screen sizes and orientations
class ResponsiveSafeArea extends StatelessWidget {
  final Widget child;
  final bool top;
  final bool bottom;
  final bool left;
  final bool right;
  final EdgeInsets? minimumPadding;
  final bool maintainBottomViewPadding;
  final Color? backgroundColor;
  
  const ResponsiveSafeArea({
    super.key,
    required this.child,
    this.top = true,
    this.bottom = true,
    this.left = true,
    this.right = true,
    this.minimumPadding,
    this.maintainBottomViewPadding = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final deviceType = context.deviceType;
    final spacing = context.spacing;
    
    // Get device-specific safe area padding
    
    // Calculate minimum padding based on device type
    EdgeInsets defaultMinimumPadding;
    
    switch (deviceType) {
      case DeviceType.phoneSmall:
        defaultMinimumPadding = EdgeInsets.only(
          top: top ? 20 : 0,
          bottom: bottom ? 10 : 0,
          left: left ? spacing.s : 0,
          right: right ? spacing.s : 0,
        );
        break;
      case DeviceType.phone:
        defaultMinimumPadding = EdgeInsets.only(
          top: top ? 44 : 0,
          bottom: bottom ? 20 : 0,
          left: left ? spacing.m : 0,
          right: right ? spacing.m : 0,
        );
        break;
      case DeviceType.phoneLarge:
        defaultMinimumPadding = EdgeInsets.only(
          top: top ? 44 : 0,
          bottom: bottom ? 20 : 0,
          left: left ? spacing.m : 0,
          right: right ? spacing.m : 0,
        );
        break;
      case DeviceType.tablet:
      case DeviceType.tabletLarge:
        defaultMinimumPadding = EdgeInsets.only(
          top: top ? 20 : 0,
          bottom: bottom ? 20 : 0,
          left: left ? spacing.l : 0,
          right: right ? spacing.l : 0,
        );
        break;
      case DeviceType.desktop:
      case DeviceType.desktopLarge:
        defaultMinimumPadding = EdgeInsets.only(
          top: top ? spacing.m : 0,
          bottom: bottom ? spacing.m : 0,
          left: left ? spacing.xl : 0,
          right: right ? spacing.xl : 0,
        );
        break;
    }
    
    final effectiveMinimumPadding = minimumPadding ?? defaultMinimumPadding;
    
    Widget result = SafeArea(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      minimum: effectiveMinimumPadding,
      maintainBottomViewPadding: maintainBottomViewPadding,
      child: child,
    );
    
    // Add background color if specified
    if (backgroundColor != null) {
      result = Container(
        color: backgroundColor,
        child: result,
      );
    }
    
    return result;
  }
}

/// Responsive page wrapper that provides consistent layout and spacing
class ResponsivePageWrapper extends StatelessWidget {
  final Widget child;
  final bool hasBottomNavigation;
  final bool hasAppBar;
  final Color? backgroundColor;
  final EdgeInsets? customPadding;
  final bool constrainWidth;
  final bool addScrollPadding;
  
  const ResponsivePageWrapper({
    super.key,
    required this.child,
    this.hasBottomNavigation = false,
    this.hasAppBar = false,
    this.backgroundColor,
    this.customPadding,
    this.constrainWidth = true,
    this.addScrollPadding = true,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final layout = context.layout;
    final deviceType = context.deviceType;
    
    // Calculate padding adjustments
    EdgeInsets pagePadding = customPadding ?? EdgeInsets.symmetric(
      horizontal: spacing.horizontal,
      vertical: spacing.vertical,
    );
    
    // Adjust for bottom navigation
    if (hasBottomNavigation) {
      pagePadding = pagePadding.copyWith(
        bottom: pagePadding.bottom + (deviceType.index <= DeviceType.phone.index ? 80 : 90),
      );
    }
    
    // Adjust for app bar
    if (hasAppBar) {
      pagePadding = pagePadding.copyWith(
        top: pagePadding.top + (deviceType.index <= DeviceType.phone.index ? 60 : 80),
      );
    }
    
    Widget content = Padding(
      padding: pagePadding,
      child: child,
    );
    
    // Constrain width for larger screens if requested
    if (constrainWidth && layout.maxContentWidth < MediaQuery.of(context).size.width) {
      content = Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: layout.maxContentWidth,
          ),
          child: content,
        ),
      );
    }
    
    // Add scroll padding for keyboard and other overlays
    if (addScrollPadding) {
      content = MediaQuery(
        data: MediaQuery.of(context).copyWith(
          padding: MediaQuery.of(context).padding.copyWith(
            bottom: MediaQuery.of(context).padding.bottom + (hasBottomNavigation ? 80 : 0),
          ),
        ),
        child: content,
      );
    }
    
    return ResponsiveSafeArea(
      backgroundColor: backgroundColor,
      child: content,
    );
  }
}

/// Responsive card that adapts its size and spacing to the device
class ResponsiveCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? margin;
  final EdgeInsets? padding;
  final Color? color;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? boxShadow;
  final double? elevation;
  
  const ResponsiveCard({
    super.key,
    required this.child,
    this.margin,
    this.padding,
    this.color,
    this.borderRadius,
    this.boxShadow,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final layout = context.layout;
    final deviceType = context.deviceType;
    
    // Default margins and padding based on device type
    EdgeInsets defaultMargin = EdgeInsets.symmetric(
      horizontal: spacing.horizontal,
      vertical: spacing.s,
    );
    
    EdgeInsets defaultPadding = EdgeInsets.all(spacing.m);
    
    // Adjust for very small screens
    if (deviceType == DeviceType.phoneSmall) {
      defaultMargin = EdgeInsets.symmetric(
        horizontal: spacing.s,
        vertical: spacing.xs,
      );
      defaultPadding = EdgeInsets.all(spacing.s);
    }
    
    return Container(
      margin: margin ?? defaultMargin,
      padding: padding ?? defaultPadding,
      decoration: BoxDecoration(
        color: color ?? CupertinoColors.systemBackground,
        borderRadius: borderRadius ?? BorderRadius.circular(layout.borderRadius),
        boxShadow: boxShadow ?? (elevation != null ? [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: 0.1),
            blurRadius: elevation! * 2,
            offset: Offset(0, elevation!),
          ),
        ] : null),
      ),
      child: child,
    );
  }
}

/// Responsive text that automatically adjusts size based on device
class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final ResponsiveTextType type;
  final Color? color;
  
  const ResponsiveText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.type = ResponsiveTextType.body1,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final fonts = context.fonts;
    
    double fontSize;
    FontWeight fontWeight;
    
    switch (type) {
      case ResponsiveTextType.h1:
        fontSize = fonts.h1;
        fontWeight = FontWeight.w800;
        break;
      case ResponsiveTextType.h2:
        fontSize = fonts.h2;
        fontWeight = FontWeight.w700;
        break;
      case ResponsiveTextType.h3:
        fontSize = fonts.h3;
        fontWeight = FontWeight.w600;
        break;
      case ResponsiveTextType.h4:
        fontSize = fonts.h4;
        fontWeight = FontWeight.w600;
        break;
      case ResponsiveTextType.h5:
        fontSize = fonts.h5;
        fontWeight = FontWeight.w500;
        break;
      case ResponsiveTextType.h6:
        fontSize = fonts.h6;
        fontWeight = FontWeight.w500;
        break;
      case ResponsiveTextType.body1:
        fontSize = fonts.body1;
        fontWeight = FontWeight.w400;
        break;
      case ResponsiveTextType.body2:
        fontSize = fonts.body2;
        fontWeight = FontWeight.w400;
        break;
      case ResponsiveTextType.caption:
        fontSize = fonts.caption;
        fontWeight = FontWeight.w400;
        break;
      case ResponsiveTextType.overline:
        fontSize = fonts.overline;
        fontWeight = FontWeight.w500;
        break;
    }
    
    return Text(
      text,
      style: (style ?? const TextStyle()).copyWith(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      ),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

enum ResponsiveTextType {
  h1, h2, h3, h4, h5, h6,
  body1, body2,
  caption, overline,
} 
