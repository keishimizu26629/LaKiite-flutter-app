import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lakiite/app/di/providers.dart';
import 'package:lakiite/infrastructure/airbridge_growth_analytics.dart';

void main() {
  test('growthAnalyticsProvider は Flutter test で No-op を提供する', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(growthAnalyticsProvider), isA<NoopGrowthAnalytics>());
  });
}
