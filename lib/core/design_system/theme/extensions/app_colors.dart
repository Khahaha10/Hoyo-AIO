import 'package:material_ui/material_ui.dart';

@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.surface3,
    required this.text,
    required this.text2,
    required this.text3,
    required this.border,
    required this.border2,
    required this.success,
    required this.successBg,
    required this.danger,
    required this.dangerBg,
    required this.warning,
    required this.warningBg,
    required this.inverse,
    required this.onInverse,
    required this.shimmer,
    required this.scrim,
  });

  static const light = AppColors(
    bg: Color(0xFFF6F7F9),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFF1F3F6),
    surface3: Color(0xFFE6E9EE),
    text: Color(0xFF14161B),
    text2: Color(0xFF4A5060),
    text3: Color(0xFF5F6676),
    border: Color.fromRGBO(15, 17, 21, .08),
    border2: Color.fromRGBO(15, 17, 21, .16),
    success: Color(0xFF0E7A50),
    successBg: Color(0xFFE2F4EB),
    danger: Color(0xFFC42B2B),
    dangerBg: Color(0xFFFCEBEB),
    warning: Color(0xFF8F5600),
    warningBg: Color(0xFFFFF1DB),
    inverse: Color(0xFF14161B),
    onInverse: Color(0xFFF2F3F5),
    shimmer: Color.fromRGBO(255, 255, 255, .7),
    scrim: Color.fromRGBO(15, 17, 21, .45),
  );

  static const dark = AppColors(
    bg: Color(0xFF0F1115),
    surface: Color(0xFF171A21),
    surface2: Color(0xFF1D2129),
    surface3: Color(0xFF262B35),
    text: Color(0xFFF2F3F5),
    text2: Color(0xFFB6BCC8),
    text3: Color(0xFF9198A6),
    border: Color.fromRGBO(255, 255, 255, .08),
    border2: Color.fromRGBO(255, 255, 255, .16),
    success: Color(0xFF46D494),
    successBg: Color.fromRGBO(70, 212, 148, .12),
    danger: Color(0xFFFF8A8A),
    dangerBg: Color.fromRGBO(255, 138, 138, .12),
    warning: Color(0xFFFFC266),
    warningBg: Color.fromRGBO(255, 194, 102, .12),
    inverse: Color(0xFFF2F3F5),
    onInverse: Color(0xFF14161B),
    shimmer: Color.fromRGBO(255, 255, 255, .06),
    scrim: Color.fromRGBO(0, 0, 0, .62),
  );

  final Color bg;
  final Color surface;
  final Color surface2;
  final Color surface3;
  final Color text;
  final Color text2;
  final Color text3;
  final Color border;
  final Color border2;
  final Color success;
  final Color successBg;
  final Color danger;
  final Color dangerBg;
  final Color warning;
  final Color warningBg;
  final Color inverse;
  final Color onInverse;
  final Color shimmer;
  final Color scrim;

  @override
  AppColors copyWith({
    Color? bg,
    Color? surface,
    Color? surface2,
    Color? surface3,
    Color? text,
    Color? text2,
    Color? text3,
    Color? border,
    Color? border2,
    Color? success,
    Color? successBg,
    Color? danger,
    Color? dangerBg,
    Color? warning,
    Color? warningBg,
    Color? inverse,
    Color? onInverse,
    Color? shimmer,
    Color? scrim,
  }) => AppColors(
    bg: bg ?? this.bg,
    surface: surface ?? this.surface,
    surface2: surface2 ?? this.surface2,
    surface3: surface3 ?? this.surface3,
    text: text ?? this.text,
    text2: text2 ?? this.text2,
    text3: text3 ?? this.text3,
    border: border ?? this.border,
    border2: border2 ?? this.border2,
    success: success ?? this.success,
    successBg: successBg ?? this.successBg,
    danger: danger ?? this.danger,
    dangerBg: dangerBg ?? this.dangerBg,
    warning: warning ?? this.warning,
    warningBg: warningBg ?? this.warningBg,
    inverse: inverse ?? this.inverse,
    onInverse: onInverse ?? this.onInverse,
    shimmer: shimmer ?? this.shimmer,
    scrim: scrim ?? this.scrim,
  );

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t) ?? b;
    return AppColors(
      bg: mix(bg, other.bg),
      surface: mix(surface, other.surface),
      surface2: mix(surface2, other.surface2),
      surface3: mix(surface3, other.surface3),
      text: mix(text, other.text),
      text2: mix(text2, other.text2),
      text3: mix(text3, other.text3),
      border: mix(border, other.border),
      border2: mix(border2, other.border2),
      success: mix(success, other.success),
      successBg: mix(successBg, other.successBg),
      danger: mix(danger, other.danger),
      dangerBg: mix(dangerBg, other.dangerBg),
      warning: mix(warning, other.warning),
      warningBg: mix(warningBg, other.warningBg),
      inverse: mix(inverse, other.inverse),
      onInverse: mix(onInverse, other.onInverse),
      shimmer: mix(shimmer, other.shimmer),
      scrim: mix(scrim, other.scrim),
    );
  }
}
