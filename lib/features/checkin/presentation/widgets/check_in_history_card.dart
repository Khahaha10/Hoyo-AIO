import 'package:hoyo_aio/core/database/database_enums.dart';
import 'package:hoyo_aio/core/design_system/components/settings_row.dart';
import 'package:hoyo_aio/core/design_system/icons/app_icon.dart';
import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:hoyo_aio/core/l10n/game_labels.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/features/checkin/domain/check_in_record.dart';
import 'package:hoyo_aio/features/dashboard/presentation/dashboard_format.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

class CheckInHistoryCard extends StatelessWidget {
  const CheckInHistoryCard({required this.runs, super.key});

  final List<CheckInRun> runs;

  @override
  Widget build(BuildContext context) {
    if (runs.isEmpty) {
      return Text(
        context.l10n.checkInHistoryEmpty,
        style: AppTextStyles.bodyM.copyWith(color: context.colors.text2),
      );
    }
    return SettingsCard(children: [for (final run in runs) _RunRow(run: run)]);
  }
}

class _RunRow extends StatelessWidget {
  const _RunRow({required this.run});

  static const double _iconTile = 36;

  final CheckInRun run;

  String _subtitle(AppLocalizations l10n) {
    final parts = [
      for (final record in run.records)
        if (record case CheckInRecord(isSuccess: true, reward: final reward?))
          reward,
    ];
    final failure = run.firstFailure;
    if (failure != null) {
      parts.add(
        l10n.checkInHistoryFailure(
          l10n.gameShortName(failure.game),
          switch (failure.result) {
            CheckInResult.captcha => l10n.checkInResultCaptcha,
            CheckInResult.cookieExpired => l10n.checkInResultCookieExpired,
            CheckInResult.noRole => l10n.checkInResultNoRole,
            CheckInResult.claimed ||
            CheckInResult.alreadyClaimed ||
            CheckInResult.failed => l10n.checkInResultFailed,
          },
        ),
      );
    }
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final ok = run.firstFailure == null;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s16,
        vertical: AppSpacing.s12,
      ),
      child: Row(
        spacing: AppSpacing.s12,
        children: [
          Container(
            width: _iconTile,
            height: _iconTile,
            decoration: BoxDecoration(
              color: ok ? colors.successBg : colors.dangerBg,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: AppIcon(
                ok ? LucideIcons.check : LucideIcons.x,
                size: AppIconSize.inline,
                color: ok ? colors.success : colors.danger,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.checkInHistoryTitle(
                    DateFormat.MMMd(l10n.localeName).format(run.runAt),
                    l10n.clockTime(run.runAt),
                  ),
                  style: AppTextStyles.tabular(AppTextStyles.rowTitle)
                      .copyWith(color: colors.text),
                ),
                Text(
                  _subtitle(l10n),
                  style: AppTextStyles.rowSubtitle.copyWith(
                    color: colors.text2,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${run.successCount}/${run.records.length}',
            style: AppTextStyles.tabular(AppTextStyles.rowTitle)
                .copyWith(color: colors.text),
          ),
        ],
      ),
    );
  }
}
