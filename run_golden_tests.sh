#!/bin/bash
# Golden Test Runner Script
# This script helps run and manage golden tests for the Pitch Flutter app

set -e

echo "🎯 Pitch Golden Test Runner"
echo "=========================="

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter not found. Please install Flutter first:"
    echo "   https://docs.flutter.dev/get-started/install"
    exit 1
fi

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Not in a Flutter project directory"
    exit 1
fi

echo "✅ Flutter found: $(flutter --version | head -n1)"

# Enable web support
echo "🔧 Enabling web support..."
flutter config --enable-web

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Check for golden test files
GOLDEN_DIR="test/golden"
if [ ! -d "$GOLDEN_DIR" ]; then
    echo "❌ Golden test directory not found: $GOLDEN_DIR"
    exit 1
fi

echo "📁 Found golden test files:"
find "$GOLDEN_DIR" -name "*.dart" -type f | sed 's/^/   /'

# Function to run tests
run_tests() {
    local update_flag=""
    if [ "$1" = "--update" ]; then
        update_flag="--update-goldens"
        echo "🔄 Running tests with golden file updates..."
    else
        echo "🧪 Running golden tests..."
    fi
    
    flutter test $update_flag test/golden/ --reporter compact
}

# Parse command line arguments
case "${1:-}" in
    "--update"|"-u")
        echo "⚠️  This will update all golden files!"
        read -p "Continue? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            run_tests --update
        else
            echo "❌ Cancelled"
            exit 1
        fi
        ;;
    "--help"|"-h")
        echo "Usage: $0 [OPTIONS]"
        echo ""
        echo "OPTIONS:"
        echo "  --update, -u    Update golden files"
        echo "  --help, -h      Show this help"
        echo ""
        echo "Examples:"
        echo "  $0              Run golden tests"
        echo "  $0 --update     Update golden files"
        ;;
    "")
        run_tests
        ;;
    *)
        echo "❌ Unknown option: $1"
        echo "Use --help for usage information"
        exit 1
        ;;
esac

echo "✅ Golden tests completed!"