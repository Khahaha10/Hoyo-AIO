@Tags(['golden'])
library;

import 'package:flutter_test/flutter_test.dart';

import '../features/dashboard/_support/dashboard_golden.dart';

void main() {
  dashboardGoldens('dashboard_error', kind: DashboardGoldenCase.error);
}
