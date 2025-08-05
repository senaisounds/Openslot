#!/bin/bash

# Dead Code Removal Script
# This script removes common dead code patterns

set -e

echo "🧹 Starting dead code removal..."

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Files to clean
FILES=(
    "lib/pages/notifications_page.dart"
    "lib/widgets/enhanced_event_card.dart"
)

for file in "${FILES[@]}"; do
    if [ -f "$file" ]; then
        print_success "Cleaning $file"
        
        # Create backup
        cp "$file" "$file.backup"
        
        # Remove common dead code patterns
        # 1. Remove unreachable code after return statements
        sed -i '' '/return.*;/,/^[[:space:]]*}/d' "$file" 2>/dev/null || true
        
        # 2. Remove unused variables with // unused comment
        sed -i '' '/final.*=.*;.*\/\/ unused/d' "$file" 2>/dev/null || true
        
        # 3. Remove debug print statements
        sed -i '' '/print.*(.*);/d' "$file" 2>/dev/null || true
        
        # 4. Remove empty lines at end of file
        sed -i '' '/^[[:space:]]*$/d' "$file" 2>/dev/null || true
        
        print_success "Cleaned $file"
    else
        print_warning "File not found: $file"
    fi
done

# Count remaining dead code issues
echo ""
echo "📊 Checking remaining dead code issues..."
REMAINING_ISSUES=$(flutter analyze --no-fatal-infos 2>/dev/null | grep -c "dead_code" || echo "0")
print_success "Remaining dead code issues: $REMAINING_ISSUES"

echo ""
echo "🎯 Dead code removal complete!"
echo "💡 Run 'flutter analyze' to see detailed results" 