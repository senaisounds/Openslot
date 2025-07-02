import 'package:flutter/widgets.dart';

/// Helper class to ensure proper widget hierarchies in the app
class WidgetStructureHelper {
  /// Safely wraps a child with a RepaintBoundary
  /// This ensures we don't add a RepaintBoundary around a Positioned widget
  static Widget safeRepaintBoundary(Widget child) {
    // Don't wrap Positioned widgets with RepaintBoundary
    if (child is Positioned) {
      return child;
    }
    return RepaintBoundary(child: child);
  }
  
  /// Ensures a Positioned widget is properly placed in a Stack
  /// Use this when working with Positioned widgets to avoid nesting errors
  static Widget positionedInStack(
    Widget Function(BuildContext) positionedBuilder, 
    {List<Widget> otherChildren = const []}
  ) {
    return Builder(
      builder: (context) {
        return Stack(
          children: [
            ...otherChildren,
            positionedBuilder(context),
          ],
        );
      }
    );
  }
} 