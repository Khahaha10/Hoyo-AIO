import 'package:material_ui/material_ui.dart';

abstract final class AppDurations {
  static const ringFill = Duration(milliseconds: 700);
  static const countUp = Duration(milliseconds: 500);
  static const heroTransition = Duration(milliseconds: 350);
  static const gameSwitch = Duration(milliseconds: 250);
  static const toggle = Duration(milliseconds: 220);
  static const checkDraw = Duration(milliseconds: 300);
  static const shimmer = Duration(milliseconds: 1200);
  static const reducedMotion = Duration(milliseconds: 150);
  static const snackbar = Duration(seconds: 4);
  static const snackbarWithAction = Duration(seconds: 6);
  static const press = Duration(milliseconds: 100);
}

abstract final class AppCurves {
  static const emphasizedDecelerate = Cubic(0.05, 0.7, 0.1, 1);
  static const countUp = Curves.easeOut;
  static const shimmer = Curves.linear;
  static const toggle = Curves.easeOutBack;
}
