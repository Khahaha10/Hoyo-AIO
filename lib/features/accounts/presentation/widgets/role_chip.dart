import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_radius.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:hoyo_aio/core/l10n/game_labels.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/features/accounts/domain/saved_role.dart';
import 'package:material_ui/material_ui.dart';

class RoleChip extends StatelessWidget {
  const RoleChip({required this.role, super.key});

  static const double _height = 28;
  static const double _padding = 10;
  static const double _dot = 8;
  static const double _gap = 6;

  final SavedRole role;

  @override
  Widget build(BuildContext context) {
    final accent = context.gameAccent(role.game);
    final l10n = context.l10n;
    return Container(
      height: _height,
      padding: const EdgeInsets.symmetric(horizontal: _padding),
      decoration: BoxDecoration(
        color: accent.soft,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: _gap,
        children: [
          Container(
            width: _dot,
            height: _dot,
            decoration: BoxDecoration(
              color: accent.acc,
              shape: BoxShape.circle,
            ),
          ),
          Text(
            '${l10n.gameShortName(role.game)} '
            '${l10n.gameLevel(role.game, role.level)}',
            style: AppTextStyles.tabular(
              AppTextStyles.caption,
            ).copyWith(color: context.colors.text, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
