import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoyo_aio/core/design_system/components/app_icon_button.dart';
import 'package:hoyo_aio/core/design_system/components/app_snackbar.dart';
import 'package:hoyo_aio/core/design_system/components/game_switcher_chip.dart';
import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:hoyo_aio/core/error/app_exception.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/core/hoyolab/hoyolab_config.dart';
import 'package:hoyo_aio/core/l10n/game_labels.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/core/time/clock.dart';
import 'package:hoyo_aio/features/codes/data/codes_repository_impl.dart';
import 'package:hoyo_aio/features/codes/domain/redeem_code.dart';
import 'package:hoyo_aio/features/codes/presentation/widgets/code_card.dart';
import 'package:hoyo_aio/features/dashboard/presentation/states/dashboard_error.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

class CodesScreen extends ConsumerStatefulWidget {
  const CodesScreen({super.key});

  @override
  ConsumerState<CodesScreen> createState() => _CodesScreenState();
}

class _CodesScreenState extends ConsumerState<CodesScreen> {
  Game? _filter;
  var _showExpired = false;
  var _refreshing = false;

  @override
  void initState() {
    super.initState();
    unawaited(_refresh());
  }

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    try {
      await ref.read(codesRepositoryProvider).refresh();
    } on AppException catch (error) {
      if (mounted) {
        showAppSnackbar(
          context,
          message: dashboardErrorMessage(error, context.l10n),
          icon: LucideIcons.wifiOff,
        );
      }
    } finally {
      if (mounted) setState(() => _refreshing = false);
      unawaited(ref.read(codesRepositoryProvider).markAllRead());
    }
  }

  Future<void> _copy(RedeemCode code) async {
    await Clipboard.setData(ClipboardData(text: code.code));
    if (!mounted) return;
    showAppSnackbar(
      context,
      message: context.l10n.codesCopied(code.code),
      icon: LucideIcons.copy,
    );
  }

  Future<void> _redeem(RedeemCode code) async {
    await Clipboard.setData(ClipboardData(text: code.code));
    await ref.read(codesRepositoryProvider).markRedeemed(code.game, code.code);
    await launchUrl(
      redeemUri(code.game, code.code),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    ref.watch(clockTickProvider);
    final now = ref.watch(clockProvider)();
    final codes = [
      for (final code
          in ref.watch(redeemCodesProvider).value ?? const <RedeemCode>[])
        if (_filter == null || code.game == _filter) code,
    ];
    final active = [
      for (final code in codes)
        if (!code.isExpiredAt(now)) code,
    ];
    final expired = [
      for (final code in codes)
        if (code.isExpiredAt(now)) code,
    ];
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.gutter,
              AppSpacing.s8,
              AppSpacing.gutter,
              AppSpacing.s24,
            ),
            children: [
              Row(
                spacing: AppSpacing.s12,
                children: [
                  AppIconButton(
                    icon: LucideIcons.chevronLeft,
                    semanticLabel: l10n.commonBack,
                    onPressed: context.pop,
                  ),
                  Expanded(
                    child: Text(
                      l10n.codesTitle,
                      style: AppTextStyles.screenTitle.copyWith(
                        color: colors.text,
                      ),
                    ),
                  ),
                  AppIconButton(
                    icon: LucideIcons.refreshCw,
                    semanticLabel: l10n.dashboardRefresh,
                    onPressed: _refreshing ? null : () => unawaited(_refresh()),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  spacing: 6,
                  children: [
                    _AllChip(
                      label: l10n.widgetsAll,
                      selected: _filter == null,
                      onTap: () => setState(() => _filter = null),
                    ),
                    for (final game in HoyolabConfig.communityGameIds.keys)
                      GameSwitcherChip(
                        game: game,
                        label: l10n.gameShortName(game),
                        selected: _filter == game,
                        onTap: () => setState(() => _filter = game),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s4,
                  AppSpacing.s16,
                  AppSpacing.s4,
                  AppSpacing.s8,
                ),
                child: Text(
                  l10n.codesActiveCount(active.length).toUpperCase(),
                  style: AppTextStyles.overline.copyWith(color: colors.text2),
                ),
              ),
              if (active.isEmpty)
                Text(
                  l10n.codesEmpty,
                  style: AppTextStyles.bodyM.copyWith(color: colors.text2),
                ),
              for (final code in active) ...[
                CodeCard(
                  code: code,
                  now: now,
                  onCopy: () => unawaited(_copy(code)),
                  onRedeem: () => unawaited(_redeem(code)),
                ),
                const SizedBox(height: AppSpacing.cardGap),
              ],
              if (expired.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.s8),
                TextButton.icon(
                  onPressed: () => setState(() => _showExpired = !_showExpired),
                  icon: Icon(
                    _showExpired
                        ? LucideIcons.chevronUp
                        : LucideIcons.chevronDown,
                  ),
                  label: Text(l10n.codesExpiredCount(expired.length)),
                ),
                if (_showExpired)
                  for (final code in expired) ...[
                    CodeCard(
                      code: code,
                      now: now,
                      onCopy: null,
                      onRedeem: null,
                    ),
                    const SizedBox(height: AppSpacing.cardGap),
                  ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AllChip extends StatelessWidget {
  const _AllChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  static const double _height = 36;

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: _height,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? colors.text : colors.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: selected ? colors.text : colors.border),
          ),
          child: Text(
            label,
            style: AppTextStyles.chip.copyWith(
              color: selected ? colors.bg : colors.text2,
            ),
          ),
        ),
      ),
    );
  }
}
