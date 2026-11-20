import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:material_ui/material_ui.dart';

@immutable
class GameAccent {
  const GameAccent({
    required this.acc,
    required this.accInk,
    required this.soft,
  });

  final Color acc;
  final Color accInk;
  final Color soft;

  GameAccent lerp(GameAccent other, double t) => GameAccent(
    acc: Color.lerp(acc, other.acc, t) ?? other.acc,
    accInk: Color.lerp(accInk, other.accInk, t) ?? other.accInk,
    soft: Color.lerp(soft, other.soft, t) ?? other.soft,
  );
}

@immutable
class GameColors extends ThemeExtension<GameColors> {
  const GameColors({
    required this.genshin,
    required this.starRail,
    required this.zzz,
    required this.hi3,
  });

  static const light = GameColors(
    genshin: GameAccent(
      acc: Color(0xFF4A90E2),
      accInk: Color(0xFF1F62B0),
      soft: Color.fromRGBO(74, 144, 226, .14),
    ),
    starRail: GameAccent(
      acc: Color(0xFF8B7CF6),
      accInk: Color(0xFF5A46D4),
      soft: Color.fromRGBO(139, 124, 246, .15),
    ),
    zzz: GameAccent(
      acc: Color(0xFFF5C518),
      accInk: Color(0xFF735C00),
      soft: Color.fromRGBO(245, 197, 24, .18),
    ),
    hi3: GameAccent(
      acc: Color(0xFFE94B6A),
      accInk: Color(0xFFB32448),
      soft: Color.fromRGBO(233, 75, 106, .13),
    ),
  );

  static const dark = GameColors(
    genshin: GameAccent(
      acc: Color(0xFF4A90E2),
      accInk: Color(0xFF8DBDF3),
      soft: Color.fromRGBO(74, 144, 226, .14),
    ),
    starRail: GameAccent(
      acc: Color(0xFF8B7CF6),
      accInk: Color(0xFFBBB0FB),
      soft: Color.fromRGBO(139, 124, 246, .15),
    ),
    zzz: GameAccent(
      acc: Color(0xFFF5C518),
      accInk: Color(0xFFF5C518),
      soft: Color.fromRGBO(245, 197, 24, .18),
    ),
    hi3: GameAccent(
      acc: Color(0xFFE94B6A),
      accInk: Color(0xFFF58CA1),
      soft: Color.fromRGBO(233, 75, 106, .13),
    ),
  );

  final GameAccent genshin;
  final GameAccent starRail;
  final GameAccent zzz;
  final GameAccent hi3;

  GameAccent of(Game game) => switch (game) {
    Game.genshin => genshin,
    Game.starRail => starRail,
    Game.zzz => zzz,
    Game.hi3 => hi3,
  };

  @override
  GameColors copyWith({
    GameAccent? genshin,
    GameAccent? starRail,
    GameAccent? zzz,
    GameAccent? hi3,
  }) => GameColors(
    genshin: genshin ?? this.genshin,
    starRail: starRail ?? this.starRail,
    zzz: zzz ?? this.zzz,
    hi3: hi3 ?? this.hi3,
  );

  @override
  GameColors lerp(GameColors? other, double t) {
    if (other == null) return this;
    return GameColors(
      genshin: genshin.lerp(other.genshin, t),
      starRail: starRail.lerp(other.starRail, t),
      zzz: zzz.lerp(other.zzz, t),
      hi3: hi3.lerp(other.hi3, t),
    );
  }
}
