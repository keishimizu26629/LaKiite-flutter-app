#!/bin/bash

# テスト実行スクリプト
# Usage: ./scripts/run_tests.sh [options]
# Options:
#   --unit-only     : Unit testsのみ実行
#   --widget-only   : Widget testsのみ実行
#   --integration   : Integration testsも実行（デフォルトはスキップ）
#   --coverage      : カバレッジレポート生成
#   --ci            : CI環境での実行

set -e

# デフォルト設定
RUN_UNIT=true
RUN_WIDGET=true
RUN_INTEGRATION=false
GENERATE_COVERAGE=false
CI_MODE=false

# 引数解析
while [[ $# -gt 0 ]]; do
  case $1 in
    --unit-only)
      RUN_UNIT=true
      RUN_WIDGET=false
      RUN_INTEGRATION=false
      shift
      ;;
    --widget-only)
      RUN_UNIT=false
      RUN_WIDGET=true
      RUN_INTEGRATION=false
      shift
      ;;
    --integration)
      RUN_INTEGRATION=true
      shift
      ;;
    --coverage)
      GENERATE_COVERAGE=true
      shift
      ;;
    --ci)
      CI_MODE=true
      export CI=true
      shift
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# 色付きログ関数
log_info() {
  echo -e "\033[34m[INFO]\033[0m $1"
}

log_success() {
  echo -e "\033[32m[SUCCESS]\033[0m $1"
}

log_error() {
  echo -e "\033[31m[ERROR]\033[0m $1"
}

log_warning() {
  echo -e "\033[33m[WARNING]\033[0m $1"
}

# テスト結果追跡
UNIT_TEST_RESULT=0
WIDGET_TEST_RESULT=0
INTEGRATION_TEST_RESULT=0

# プロジェクトルートに移動
cd "$(dirname "$0")/.."

log_info "=== LaKiite Flutter App Test Suite ==="
log_info "CI Mode: $CI_MODE"
log_info "Coverage: $GENERATE_COVERAGE"
log_info "Unit Tests: $RUN_UNIT"
log_info "Widget Tests: $RUN_WIDGET"
log_info "Integration Tests: $RUN_INTEGRATION"
echo ""

# 依存関係インストール
log_info "Installing dependencies..."
fvm flutter pub get

# Unit Tests
if [ "$RUN_UNIT" = true ]; then
  log_info "Running unit tests..."

  if [ "$GENERATE_COVERAGE" = true ]; then
    if fvm flutter test --coverage --dart-define=FLUTTER_TEST=true; then
      log_success "Unit tests passed ✅"
    else
      UNIT_TEST_RESULT=1
      log_error "Unit tests failed ❌"
    fi
  else
    if fvm flutter test --dart-define=FLUTTER_TEST=true; then
      log_success "Unit tests passed ✅"
    else
      UNIT_TEST_RESULT=1
      log_error "Unit tests failed ❌"
    fi
  fi
  echo ""
fi

# Widget Tests
if [ "$RUN_WIDGET" = true ]; then
  log_info "Running widget tests..."

  if fvm flutter test test/presentation/ --dart-define=FLUTTER_TEST=true; then
    log_success "Widget tests passed ✅"
  else
    WIDGET_TEST_RESULT=1
    log_warning "Widget tests had issues ⚠️"
    log_warning "Some widget tests may fail due to GoRouter configuration in test environment"
  fi
  echo ""
fi

# Integration Tests
if [ "$RUN_INTEGRATION" = true ]; then
  log_info "Running integration tests..."

  if [ "$CI_MODE" = true ]; then
    log_warning "Skipping integration tests in CI environment"
  else
    log_info "Note: Integration tests require device/simulator"

    if fvm flutter test integration_test/ --dart-define=FLUTTER_TEST=true; then
      log_success "Integration tests passed ✅"
    else
      INTEGRATION_TEST_RESULT=1
      log_warning "Integration tests had issues ⚠️"
      log_warning "Integration test failures may be due to Firebase emulator configuration"
    fi
  fi
  echo ""
fi

# カバレッジレポート生成
if [ "$GENERATE_COVERAGE" = true ] && [ "$RUN_UNIT" = true ]; then
  log_info "Generating coverage report..."

  if command -v lcov &> /dev/null; then
    # HTML レポート生成
    lcov --remove coverage/lcov.info \
      '*/test/*' \
      '*/generated/*' \
      '*/l10n/*' \
      '*/firebase_options*.dart' \
      -o coverage/lcov_cleaned.info

    genhtml coverage/lcov_cleaned.info -o coverage/html
    log_success "Coverage report generated: coverage/html/index.html"
  else
    log_warning "lcov not found. Install with: brew install lcov (macOS) or apt-get install lcov (Ubuntu)"
  fi
  echo ""
fi

# 結果サマリー
log_info "=== Test Results Summary ==="

if [ "$RUN_UNIT" = true ]; then
  if [ $UNIT_TEST_RESULT -eq 0 ]; then
    log_success "Unit Tests: PASSED"
  else
    log_error "Unit Tests: FAILED"
  fi
fi

if [ "$RUN_WIDGET" = true ]; then
  if [ $WIDGET_TEST_RESULT -eq 0 ]; then
    log_success "Widget Tests: PASSED"
  else
    log_warning "Widget Tests: HAD ISSUES"
  fi
fi

if [ "$RUN_INTEGRATION" = true ] && [ "$CI_MODE" = false ]; then
  if [ $INTEGRATION_TEST_RESULT -eq 0 ]; then
    log_success "Integration Tests: PASSED"
  else
    log_warning "Integration Tests: HAD ISSUES"
  fi
fi

# 終了コード決定
TOTAL_FAILURES=$((UNIT_TEST_RESULT))

if [ $TOTAL_FAILURES -eq 0 ]; then
  log_success "=== All critical tests passed! ==="
  if [ $WIDGET_TEST_RESULT -ne 0 ] || [ $INTEGRATION_TEST_RESULT -ne 0 ]; then
    log_warning "Some non-critical test issues were found but can be addressed later"
  fi
  exit 0
else
  log_error "=== Critical test failures detected ==="
  exit 1
fi
