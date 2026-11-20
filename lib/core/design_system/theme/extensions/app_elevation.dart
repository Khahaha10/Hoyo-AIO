import 'package:material_ui/material_ui.dart';

@immutable
class AppElevation extends ThemeExtension<AppElevation> {
  const AppElevation({required this.card, required this.dialog});

  static const light = AppElevation(
    card: [
      BoxShadow(
        color: Color.fromRGBO(16, 24, 40, .04),
        offset: Offset(0, 1),
        blurRadius: 2,
      ),
      BoxShadow(
        color: Color.fromRGBO(16, 24, 40, .08),
        offset: Offset(0, 6),
        blurRadius: 20,
        spreadRadius: -8,
      ),
    ],
    dialog: [
      BoxShadow(
        color: Color.fromRGBO(16, 24, 40, .28),
        offset: Offset(0, 24),
        blurRadius: 48,
        spreadRadius: -12,
      ),
    ],
  );

  static const dark = AppElevation(
    card: [],
    dialog: [
      BoxShadow(
        color: Color.fromRGBO(0, 0, 0, .35),
        offset: Offset(0, 24),
        blurRadius: 48,
        spreadRadius: -12,
      ),
    ],
  );

  static const glassBackgroundOpacity = 0.72;
  static const glassBlurSigma = 20.0;

  final List<BoxShadow> card;
  final List<BoxShadow> dialog;

  @override
  AppElevation copyWith({List<BoxShadow>? card, List<BoxShadow>? dialog}) =>
      AppElevation(card: card ?? this.card, dialog: dialog ?? this.dialog);

  @override
  AppElevation lerp(AppElevation? other, double t) {
    if (other == null) return this;
    return t < 0.5 ? this : other;
  }
}
