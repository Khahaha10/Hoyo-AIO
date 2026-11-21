import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoyo_aio/core/design_system/components/app_badge.dart';
import 'package:hoyo_aio/core/design_system/components/app_button.dart';
import 'package:hoyo_aio/core/design_system/components/app_icon_button.dart';
import 'package:hoyo_aio/core/design_system/components/app_segmented_control.dart';
import 'package:hoyo_aio/core/design_system/components/app_slider.dart';
import 'package:hoyo_aio/core/design_system/components/app_snackbar.dart';
import 'package:hoyo_aio/core/design_system/components/app_swatch_picker.dart';
import 'package:hoyo_aio/core/design_system/components/settings_row.dart';
import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_radius.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:hoyo_aio/core/design_system/tokens/widget_tokens.dart';
import 'package:hoyo_aio/core/l10n/game_labels.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/core/time/clock.dart';
import 'package:hoyo_aio/features/accounts/domain/saved_role.dart';
import 'package:hoyo_aio/features/accounts/presentation/providers/selected_role_provider.dart';
import 'package:hoyo_aio/features/dashboard/presentation/widgets/role_switcher_sheet.dart';
import 'package:hoyo_aio/features/home_widgets/data/widget_config_repository_impl.dart';
import 'package:hoyo_aio/features/home_widgets/domain/home_widget_repositories.dart';
import 'package:hoyo_aio/features/home_widgets/domain/widget_snapshot.dart';
import 'package:hoyo_aio/features/home_widgets/presentation/providers/widget_sync_provider.dart';
import 'package:hoyo_aio/features/home_widgets/presentation/widget_size_labels.dart';
import 'package:hoyo_aio/features/home_widgets/presentation/widgets/widget_preview.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

class WidgetEditorScreen extends ConsumerStatefulWidget {
  const WidgetEditorScreen({
    required this.widgetId,
    required this.size,
    super.key,
  });

  final int widgetId;
  final HomeWidgetSize size;

  @override
  ConsumerState<WidgetEditorScreen> createState() => _WidgetEditorScreenState();
}

class _WidgetEditorScreenState extends ConsumerState<WidgetEditorScreen> {
  static const _maxItems = 3;
  static const double _previewHeight = 200;
  static const _minOpacity = 0.3;
  static const _opacitySteps = 14;
  static const _percent = 100;
  static const _accents = ['match', 'lime', 'genshin', 'starRail', 'neutral'];

  WidgetConfigSnapshot? _draft;
  var _saving = false;

  WidgetConfigSnapshot _initial(List<SavedRole> roles) =>
      ref
          .read(widgetConfigsProvider)
          .value
          ?.where((c) => c.widgetId == widget.widgetId)
          .firstOrNull ??
      WidgetConfigSnapshot(
        widgetId: widget.widgetId,
        size: widget.size.name,
        roleId: roles.firstOrNull?.id,
        theme: 'system',
        opacity: 1,
        accent: 'match',
        fontSize: 'medium',
        visibleItems: const [],
      );

  Future<void> _save(WidgetConfigSnapshot draft, List<SavedRole> roles) async {
    setState(() => _saving = true);
    final accountId = roles
        .where((r) => r.id == draft.roleId)
        .firstOrNull
        ?.accountId;
    await ref
        .read(widgetConfigRepositoryProvider)
        .save(draft, accountId: accountId);
    if (!mounted) return;
    showAppSnackbar(
      context,
      message: context.l10n.widgetEditorSaved,
      icon: LucideIcons.check,
    );
    context.pop();
  }

  void _update(WidgetConfigSnapshot next) => setState(() => _draft = next);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final roles = ref.watch(dashboardRolesProvider);
    final snapshot = ref.watch(widgetSyncProvider).value;
    final draft = _draft ??= _initial(roles);
    ref.watch(clockTickProvider);
    final now = ref.watch(clockProvider)();
    final role = roles.where((r) => r.id == draft.roleId).firstOrNull;
    final itemKeys = [
      for (final item
          in snapshot?.roles
                  .where((r) => r.roleId == draft.roleId)
                  .firstOrNull
                  ?.items ??
              const <WidgetItem>[])
        item.key,
    ];
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
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
                          l10n.widgetEditorTitle,
                          style: AppTextStyles.screenTitle.copyWith(
                            color: colors.text,
                          ),
                        ),
                      ),
                      AppBadge(label: l10n.widgetSizeTitle(widget.size)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s16),
                  _Wallpaper(
                    height: _previewHeight,
                    label: l10n.widgetEditorLivePreview,
                    child: snapshot == null
                        ? const SizedBox.shrink()
                        : FittedBox(
                            child: WidgetPreview(
                              snapshot: snapshot,
                              size: widget.size,
                              config: draft,
                              now: now,
                            ),
                          ),
                  ),
                  _Label(l10n.widgetEditorTheme),
                  AppSegmentedControl<String>(
                    options: [
                      SegmentOption(
                        value: 'light',
                        label: l10n.widgetThemeLight,
                      ),
                      SegmentOption(value: 'dark', label: l10n.widgetThemeDark),
                      SegmentOption(
                        value: 'clear',
                        label: l10n.widgetThemeClear,
                      ),
                      SegmentOption(
                        value: 'system',
                        label: l10n.widgetThemeSystem,
                      ),
                    ],
                    selected: draft.theme,
                    onChanged: (theme) => _update(draft.copyWith(theme: theme)),
                  ),
                  _Label(
                    l10n.widgetEditorOpacity,
                    trailing: l10n.notificationsThresholdPercent(
                      (draft.opacity * _percent).round(),
                    ),
                  ),
                  AppSlider(
                    value: draft.opacity,
                    min: _minOpacity,
                    divisions: _opacitySteps,
                    semanticLabel: l10n.widgetEditorOpacity,
                    onChanged: (value) =>
                        _update(draft.copyWith(opacity: value)),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: AppSpacing.s16,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Label(l10n.widgetEditorAccent),
                            AppSwatchPicker<String>(
                              options: [
                                for (final accent in _accents)
                                  SwatchOption(
                                    value: accent,
                                    label: l10n.widgetAccentName(accent),
                                    colors: _swatchColors(accent),
                                  ),
                              ],
                              selected: draft.accent,
                              onChanged: (accent) =>
                                  _update(draft.copyWith(accent: accent)),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Label(l10n.widgetEditorFontSize),
                            AppSegmentedControl<String>(
                              options: const [
                                SegmentOption(value: 'small', label: 'S'),
                                SegmentOption(value: 'medium', label: 'M'),
                                SegmentOption(value: 'large', label: 'L'),
                              ],
                              selected: draft.fontSize,
                              onChanged: (size) =>
                                  _update(draft.copyWith(fontSize: size)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (widget.size == HomeWidgetSize.medium &&
                      itemKeys.isNotEmpty) ...[
                    _Label(
                      l10n.widgetEditorVisibleItems(
                        _visible(draft, itemKeys).length,
                        _maxItems,
                      ),
                    ),
                    Wrap(
                      spacing: AppSpacing.s8,
                      runSpacing: AppSpacing.s8,
                      children: [
                        for (final key in itemKeys)
                          _ItemChip(
                            label: snapshot?.labels[key] ?? key,
                            selected: _visible(draft, itemKeys).contains(key),
                            onTap: () => _toggle(draft, itemKeys, key),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: AppSpacing.s16),
                  SettingsCard(
                    children: [
                      SettingsRow(
                        icon: LucideIcons.user,
                        title: role == null
                            ? l10n.widgetEditorNoRole
                            : '${role.nickname} · ${l10n.gameName(role.game)}',
                        subtitle: role?.uid,
                        onTap: roles.length < 2 || role == null
                            ? null
                            : () => showRoleSwitcherSheet(
                                context,
                                roles: roles,
                                current: role,
                                onSelect: (picked) => _update(
                                  draft.copyWith(
                                    roleId: picked.id,
                                    visibleItems: const [],
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                AppSpacing.s8,
                AppSpacing.gutter,
                AppSpacing.s16,
              ),
              child: AppButton(
                label: l10n.widgetEditorSave,
                isLoading: _saving,
                onPressed: () => unawaited(_save(draft, roles)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _visible(WidgetConfigSnapshot draft, List<String> keys) =>
      draft.visibleItems.isEmpty
      ? keys.take(_maxItems).toList()
      : draft.visibleItems;

  void _toggle(WidgetConfigSnapshot draft, List<String> keys, String key) {
    final current = _visible(draft, keys);
    final next = current.contains(key)
        ? [
            for (final item in current)
              if (item != key) item,
          ]
        : current.length >= _maxItems
        ? current
        : [...current, key];
    _update(draft.copyWith(visibleItems: next));
  }

  static List<Color> _swatchColors(String accent) => switch (accent) {
    'match' => [for (final color in WidgetTokens.accents.values) Color(color)],
    'lime' => const [Color(WidgetTokens.lime)],
    'neutral' => [Color(WidgetTokens.themes['light']?['text2'] ?? 0)],
    final key => [Color(WidgetTokens.accents[key] ?? WidgetTokens.lime)],
  };
}

class _Wallpaper extends StatelessWidget {
  const _Wallpaper({
    required this.height,
    required this.label,
    required this.child,
  });

  static const _top = Color(0xFFA9C4E8);
  static const _bottom = Color(0xFFD7C6F2);

  final double height;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    height: height,
    padding: const EdgeInsets.all(AppSpacing.s16),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(AppRadius.hero),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_top, _bottom],
      ),
    ),
    child: Stack(
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.overline.copyWith(
            color: const Color(WidgetTokens.ink),
          ),
        ),
        Center(child: child),
      ],
    ),
  );
}

class _Label extends StatelessWidget {
  const _Label(this.text, {this.trailing});

  final String text;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final style = AppTextStyles.label.copyWith(color: context.colors.text2);
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.s20,
        bottom: AppSpacing.s8,
      ),
      child: Row(
        children: [
          Expanded(child: Text(text, style: style)),
          if (trailing case final value?)
            Text(
              value,
              style: AppTextStyles.tabular(style)
                  .copyWith(color: context.colors.text),
            ),
        ],
      ),
    );
  }
}

class _ItemChip extends StatelessWidget {
  const _ItemChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  static const double _height = 40;

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
          decoration: BoxDecoration(
            color: selected ? colors.text : colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: selected ? colors.text : colors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: AppSpacing.s4,
            children: [
              if (selected) Icon(LucideIcons.check, size: 16, color: colors.bg),
              Text(
                label,
                style: AppTextStyles.chip.copyWith(
                  color: selected ? colors.bg : colors.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
