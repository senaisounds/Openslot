#!/bin/bash

# optimize_all.sh - Comprehensive optimization script for the Slotted app
# Usage: ./scripts/optimize_all.sh

echo "Starting Slotted app optimization..."

# First clean up the Flutter build to ensure a clean state
echo "Cleaning Flutter build cache..."
flutter clean
flutter pub get

# 1. Run unused code detection
echo -e "\n========== DETECTING UNUSED CODE ==========\n"
dart scripts/remove_unused_code.dart

# 2. Remove unused imports
echo -e "\n========== REMOVING UNUSED IMPORTS ==========\n"
dart scripts/remove_unused_imports.dart

# 3. Fix withOpacity usage
echo -e "\n========== FIXING WITHOPACITY USAGE ==========\n"
dart scripts/fix_withopacity_usage.dart

# The replace_prints script must run after the withOpacity fixes
# to ensure we don't modify logger imports incorrectly
echo -e "\n========== REPLACING PRINT STATEMENTS ==========\n"
dart scripts/replace_prints.dart

# 5. Detect BuildContext async gap issues
echo -e "\n========== DETECTING ASYNC CONTEXT ISSUES ==========\n"
dart scripts/fix_async_context.dart

# Run the analyzer to verify improvements
echo -e "\n========== VERIFYING WITH FLUTTER ANALYZE ==========\n"
flutter analyze --no-fatal-infos --no-fatal-warnings

# Build for release to check final output
echo -e "\n========== BUILDING RELEASE VERSION ==========\n"
flutter build apk --release

echo -e "\n========== OPTIMIZATION COMPLETE ==========\n"
echo "All optimization scripts have been executed."
echo "Next steps:"
echo "  1. Review context_async_fixes.md to fix BuildContext issues"
echo "  2. Check unused_code_report.md for potential code to remove"
echo "  3. Test the optimized app on devices"
echo "  4. See PERFORMANCE_GUIDE.md for ongoing best practices"
echo ""
echo "Happy coding!" 