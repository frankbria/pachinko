#!/bin/bash

# ========================================
# Test Coverage Report Generator
# ========================================
#
# This script generates a comprehensive test coverage report for the project.
# It runs all tests, generates coverage data, and creates an HTML report.
#
# REQUIREMENTS:
# -------------
# - lcov must be installed: sudo apt-get install lcov
#
# OUTPUT:
# -------
# - coverage/lcov.info: Raw coverage data
# - coverage/html/: HTML report (open index.html in browser)
#
# USAGE:
# ------
# ./scripts/generate_coverage.sh           # Generate report only
# ./scripts/generate_coverage.sh --open    # Generate and open in browser
#
# ========================================

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}📊 Generating test coverage report...${NC}"
echo ""

# Set Flutter path if not already in PATH
export PATH="/home/frankbria/projects/pachinko/tools/flutter/bin:$PATH"

# Check if lcov is installed
if ! command -v lcov &> /dev/null; then
    echo -e "${YELLOW}⚠️  lcov is not installed${NC}"
    echo "   Install it with: sudo apt-get install lcov"
    echo ""
    echo "   Generating lcov.info only..."
    flutter test --coverage
    echo -e "${GREEN}✅ Coverage data generated: coverage/lcov.info${NC}"
    exit 0
fi

# Run tests with coverage
echo "🧪 Running tests with coverage analysis..."
flutter test --coverage

# Check if coverage data was generated
if [ ! -f "coverage/lcov.info" ]; then
    echo -e "${YELLOW}⚠️  No coverage data generated${NC}"
    echo "   Make sure you have tests in the test/ directory"
    exit 1
fi

# Generate HTML report
echo ""
echo "📄 Generating HTML report..."
genhtml coverage/lcov.info -o coverage/html --quiet

# Calculate coverage percentage
COVERAGE=$(lcov --summary coverage/lcov.info 2>&1 | grep "lines......" | awk '{print $2}')

echo ""
echo -e "${GREEN}✅ Coverage report generated successfully!${NC}"
echo ""
echo "📊 Coverage: $COVERAGE"
echo ""
echo "📁 Report location:"
echo "   - Raw data: coverage/lcov.info"
echo "   - HTML report: coverage/html/index.html"
echo ""

# Open in browser if requested
if [ "$1" == "--open" ]; then
    echo "🌐 Opening report in browser..."
    xdg-open coverage/html/index.html 2>/dev/null || \
    open coverage/html/index.html 2>/dev/null || \
    echo "   Could not auto-open browser. Please open coverage/html/index.html manually"
else
    echo "💡 Tip: Run with --open flag to automatically open report in browser"
fi

echo ""

# Check coverage threshold (85% required per CLAUDE.md)
COVERAGE_NUM=$(echo $COVERAGE | sed 's/%//')
THRESHOLD=85

if (( $(echo "$COVERAGE_NUM < $THRESHOLD" | bc -l) )); then
    echo -e "${YELLOW}⚠️  Coverage ($COVERAGE) is below required threshold ($THRESHOLD%)${NC}"
    echo "   Please add more tests to meet the quality standards"
    exit 1
else
    echo -e "${GREEN}✅ Coverage meets required threshold ($THRESHOLD%)${NC}"
fi

echo ""
