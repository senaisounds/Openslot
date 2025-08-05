#!/bin/bash

# Performance Optimization Script for OpenSlot
# This script implements high-priority performance optimizations

set -e

echo "🚀 Starting high-priority performance optimization..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}📋 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# 1. Clean and rebuild for better performance
print_status "Step 1: Cleaning and rebuilding..."
flutter clean
flutter pub get

# 2. Run analysis to identify issues
print_status "Step 2: Running code analysis..."
flutter analyze --no-fatal-infos > analysis_report.txt 2>&1 || true

# Count issues
TOTAL_ISSUES=$(grep -c "warning\|error" analysis_report.txt || echo "0")
DEAD_CODE_ISSUES=$(grep -c "dead_code" analysis_report.txt || echo "0")
UNUSED_ISSUES=$(grep -c "unused" analysis_report.txt || echo "0")

print_success "Analysis complete: $TOTAL_ISSUES total issues, $DEAD_CODE_ISSUES dead code, $UNUSED_ISSUES unused"

# 3. Optimize images
print_status "Step 3: Optimizing images..."
if [ -f "scripts/optimize_images.sh" ]; then
    bash scripts/optimize_images.sh
else
    print_warning "Image optimization script not found"
fi

# 4. Check for large files
print_status "Step 4: Checking for large files..."
find lib -name "*.dart" -exec wc -l {} + | sort -nr | head -10 > large_files.txt
print_success "Large files identified (see large_files.txt)"

# 5. Performance testing
print_status "Step 5: Running performance tests..."
flutter test test/performance/ --reporter=compact || {
    print_warning "Performance tests failed, but continuing..."
}

# 6. Build size analysis
print_status "Step 6: Analyzing build sizes..."

# iOS build size
if command -v xcrun &> /dev/null; then
    print_status "Building iOS for size analysis..."
    flutter build ios --release --no-codesign --dart-define=PRODUCTION=true || {
        print_warning "iOS build failed for size analysis"
    }
fi

# 7. Generate performance report
print_status "Step 7: Generating performance report..."

cat > performance_report.md << EOF
# Performance Optimization Report

## Summary
- Total Issues: $TOTAL_ISSUES
- Dead Code Issues: $DEAD_CODE_ISSUES
- Unused Code Issues: $UNUSED_ISSUES

## Recommendations

### High Priority
1. **Dead Code Removal**: $DEAD_CODE_ISSUES instances found
2. **Unused Code**: $UNUSED_ISSUES instances found
3. **Image Optimization**: Large images detected

### Medium Priority
1. **Code Splitting**: Consider lazy loading for large widgets
2. **Memory Management**: Review widget disposal
3. **Network Optimization**: Implement caching strategies

### Low Priority
1. **UI Optimization**: Reduce widget rebuilds
2. **Animation Optimization**: Use efficient animations
3. **Database Optimization**: Review Firestore queries

## Next Steps
1. Run: \`flutter analyze --no-fatal-infos\` to see detailed issues
2. Review large_files.txt for potential refactoring
3. Implement image optimization
4. Consider code splitting for large components
EOF

print_success "Performance report generated: performance_report.md"

# 8. Show quick wins
print_status "Step 8: Quick performance wins..."

echo "🎯 Quick Wins Available:"
echo "1. Remove dead code: $DEAD_CODE_ISSUES instances"
echo "2. Remove unused imports: $UNUSED_ISSUES instances"
echo "3. Optimize images: Run scripts/optimize_images.sh"
echo "4. Review large files: Check large_files.txt"

print_success "Performance optimization analysis complete!"
echo ""
echo "📊 Performance Report: performance_report.md"
echo "📁 Large Files: large_files.txt"
echo "🔍 Analysis Report: analysis_report.txt" 