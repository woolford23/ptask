import 'package:flutter_test/flutter_test.dart';
import 'package:ptask/services/scheduling_service.dart';

void main() {
  group('Sanity', () {
    test('scheduling service can be instantiated', () {
      final svc = SchedulingService();
      expect(svc, isNotNull);
    });

    // This test is intentionally simple and environment-agnostic. More
    // deterministic scheduling tests require DB fixtures and are left for
    // maintainer-driven test additions.
  });
}
