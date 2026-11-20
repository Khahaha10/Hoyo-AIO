import 'package:hoyo_aio/core/design_system/theme/extensions/app_colors.dart';
import 'package:hoyo_aio/core/design_system/theme/extensions/app_elevation.dart';
import 'package:hoyo_aio/core/design_system/theme/extensions/game_colors.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:material_ui/material_ui.dart';

extension ThemeContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;

  AppElevation get elevation => Theme.of(this).extension<AppElevation>()!;

  GameAccent gameAccent(Game game) =>
      Theme.of(this).extension<GameColors>()!.of(game);

  TextTheme get textStyles => Theme.of(this).textTheme;
}
