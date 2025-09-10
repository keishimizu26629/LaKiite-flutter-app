#!/bin/bash

# LaKiite Flutter App Test Script
# このスクリプトは、ローカルでの開発時に各種テストを実行するためのものです

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed or not in PATH"
    exit 1
fi

# Function to run static analysis
run_analysis() {
    print_status "Running static analysis..."

    print_status "Checking code formatting..."
    if ! dart format --output=none --set-exit-if-changed .; then
        print_error "Code formatting check failed. Run 'dart format .' to fix."
        return 1
    fi

    print_status "Running dart analyze..."
    if ! flutter analyze --fatal-infos; then
        print_error "Static analysis failed"
        return 1
    fi

    print_success "Static analysis completed successfully"
}

# Function to run unit tests
run_unit_tests() {
    print_status "Running unit tests..."

    if ! flutter test --coverage; then
        print_error "Unit tests failed"
        return 1
    fi

    print_success "Unit tests completed successfully"
}

# Function to run integration tests
run_integration_tests() {
    print_status "Running integration tests..."

    if ! flutter test integration_test; then
        print_error "Integration tests failed"
        return 1
    fi

    print_success "Integration tests completed successfully"
}

# Function to generate coverage report
generate_coverage() {
    print_status "Generating coverage report..."

    if command -v lcov &> /dev/null; then
        lcov --remove coverage/lcov.info 'lib/generated/*' 'lib/l10n/*' -o coverage/lcov.info
        genhtml coverage/lcov.info -o coverage/html
        print_success "Coverage report generated at coverage/html/index.html"
    else
        print_warning "lcov not found. Install lcov to generate HTML coverage report."
        print_status "Coverage data available at coverage/lcov.info"
    fi
}

# Function to run all tests
run_all_tests() {
    print_status "Running all tests..."

    # Install dependencies
    print_status "Installing dependencies..."
    flutter pub get

    # Run static analysis
    if ! run_analysis; then
        return 1
    fi

    # Run unit tests
    if ! run_unit_tests; then
        return 1
    fi

    # Generate coverage report
    generate_coverage

    print_success "All tests completed successfully!"
}

# Function to run quick tests (without integration tests)
run_quick_tests() {
    print_status "Running quick tests (unit tests + analysis)..."

    # Install dependencies
    flutter pub get

    # Run static analysis
    if ! run_analysis; then
        return 1
    fi

    # Run unit tests
    if ! run_unit_tests; then
        return 1
    fi

    print_success "Quick tests completed successfully!"
}

# Function to show help
show_help() {
    echo "LaKiite Flutter App Test Script"
    echo ""
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "Options:"
    echo "  all           Run all tests (analysis + unit tests + coverage)"
    echo "  quick         Run quick tests (analysis + unit tests)"
    echo "  analysis      Run static analysis only"
    echo "  unit          Run unit tests only"
    echo "  integration   Run integration tests only"
    echo "  coverage      Generate coverage report"
    echo "  help          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 all        # Run all tests"
    echo "  $0 quick      # Run quick tests"
    echo "  $0 unit       # Run unit tests only"
}

# Main script logic
case "${1:-all}" in
    "all")
        run_all_tests
        ;;
    "quick")
        run_quick_tests
        ;;
    "analysis")
        flutter pub get
        run_analysis
        ;;
    "unit")
        flutter pub get
        run_unit_tests
        ;;
    "integration")
        flutter pub get
        run_integration_tests
        ;;
    "coverage")
        generate_coverage
        ;;
    "help")
        show_help
        ;;
    *)
        print_error "Unknown option: $1"
        show_help
        exit 1
        ;;
esac
