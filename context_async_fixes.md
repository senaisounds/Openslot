
# BuildContext Async Gap Fixes

## Problem Description

Using a BuildContext after an async gap is unsafe because the widget might have been unmounted. 
This can lead to bugs, memory leaks, and app crashes.

## Recommended Fix Pattern

```dart
// Before fixing:
void someMethod(BuildContext context) async {
  await someAsyncOperation();
  Navigator.of(context).pop(); // UNSAFE! Widget might be unmounted
}

// After fixing:
void someMethod(BuildContext context) async {
  // Use our utility to document the context use
  PerformanceOptimizer.checkContextBeforeAsyncGap(context, "someMethod");
  await someAsyncOperation();
  // Check if still mounted before using context
  if (mounted) {
    Navigator.of(context).pop(); // Now safe
  }
}
```

## Issues Found

### lib/api/calendar_service.dart

Line 134:
```dart
131:        
132:        // If we should ask before adding and context is provided
133:        if (_askBeforeAdding && currentContext != null) {
134:          final confirmed = await _showAddToCalendarConfirmation(currentContext, event); // <-- UNSAFE CONTEXT USAGE
135:          if (!confirmed) {
136:            return false;
137:          }
```

Fix suggestion: Add `if (mounted)` check before using the context after the async operation.

Line 275:
```dart
272:      }
273:      
274:      return await showDialog<String>(
275:        context: context, // <-- UNSAFE CONTEXT USAGE
276:        builder: (BuildContext context) {
277:          return AlertDialog(
278:            title: const Text('Select Calendar'),
```

Fix suggestion: Add `if (mounted)` check before using the context after the async operation.

### lib/pages/events_map_page.dart

Line 1801:
```dart
1798:                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
1799:                      onPressed: () async {
1800:                        await LocationService.setSimulatedLocation(location);
1801:                        Navigator.pop(context); // <-- UNSAFE CONTEXT USAGE
1802:                        await _getCurrentLocation();
1803:                      },
1804:                      child: Row(
```

Fix suggestion: Add `if (mounted)` check before using the context after the async operation.

### lib/pages/my_home_page.dart

Line 4039:
```dart
4036:        builder: (BuildContext context) {
4037:          // Auto-dismiss after 2 seconds
4038:          Future.delayed(const Duration(seconds: 2), () {
4039:            if (Navigator.of(context).canPop()) { // <-- UNSAFE CONTEXT USAGE
4040:              Navigator.of(context).pop();
4041:            }
4042:          });
```

Fix suggestion: Add `if (mounted)` check before using Navigator.

Line 4040:
```dart
4037:          // Auto-dismiss after 2 seconds
4038:          Future.delayed(const Duration(seconds: 2), () {
4039:            if (Navigator.of(context).canPop()) {
4040:              Navigator.of(context).pop(); // <-- UNSAFE CONTEXT USAGE
4041:            }
4042:          });
4043:          
```

Fix suggestion: Add `if (mounted)` check before using Navigator.

### lib/pages/payment_method_page.dart

Line 104:
```dart
101:        // Refresh list
102:        await _loadPaymentMethods();
103:        
104:        Navigator.pop(context); // Close the add payment method dialog // <-- UNSAFE CONTEXT USAGE
105:        
106:        _showSuccessDialog('Payment method added successfully');
107:      } catch (e) {
```

Fix suggestion: Add `if (mounted)` check before using the context after the async operation.

### lib/utils/error_handling_demo.dart

Line 107:
```dart
104:                          await NetworkHandler.get(url: 'https://nonexistent-domain-123456789.com');
105:                        } catch (e) {
106:                          ErrorHandler.showErrorDialog(
107:                            context: context, // <-- UNSAFE CONTEXT USAGE
108:                            title: 'Network Error',
109:                            message: 'Caught network error: ${e.toString()}',
110:                          );
```

Fix suggestion: Add `if (mounted)` check before using the context after the async operation.

