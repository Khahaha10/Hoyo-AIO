@Tags(['golden'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';

import '../features/dashboard/_support/dashboard_golden.dart';

void main() {
  dashboardGoldens('dashboard_star_rail', game: Game.starRail);
}
