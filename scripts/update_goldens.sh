#!/bin/bash

# ========================================
# Golden File Update Script
# ========================================
#
# This script regenerates visual regression golden files for widget tests.
#
# WHEN TO RUN THIS:
# -----------------
# 1. After intentional UI changes (colors, layouts, sizes, etc.)
# 2. When golden tests fail due to expected visual updates
# 3. When adding new golden tests for the first time
#
# WARNING:
# --------
# DO NOT run this to "fix" failing tests without reviewing the diffs first!
# Always verify that the visual changes are intentional before updating goldens.
#
# WORKFLOW:
# ---------
# 1. Make UI changes in your code
# 2. Run `flutter test` to see which goldens fail
# 3. Review the failure diffs in test/failures/
# 4. If changes are correct, run this script to update goldens
# 5. Commit the updated golden files with your changes
#
# ========================================

set -e  # Exit on error

echo "🎨 Updating golden files for visual regression tests..."
echo ""
echo "⚠️  This will overwrite existing golden files!"
echo "   Make sure you've reviewed the visual changes first."
echo ""

# Set Flutter path if not already in PATH
export PATH="/home/frankbria/projects/pachinko/tools/flutter/bin:$PATH"

# Run tests with golden file update flag
flutter test --update-goldens

echo ""
echo "✅ Golden files updated successfully!"
echo ""
echo "📋 Next steps:"
echo "   1. Review the updated files in test/goldens/"
echo "   2. Run 'flutter test' to verify all tests pass"
echo "   3. Commit the updated golden files with your changes"
echo ""
