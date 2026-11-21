import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoyo_aio/app/router/app_routes.dart';
import 'package:hoyo_aio/core/design_system/components/app_icon_button.dart';
import 'package:hoyo_aio/core/design_system/components/app_snackbar.dart';
import 'package:hoyo_aio/core/design_system/components/settings_row.dart';
import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_radius.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/core/time/clock.dart';
import 'package:hoyo_aio/features/home_widgets/data/home_widget_bridge_impl.dart';
import 'package:hoyo_aio/features/home_widgets/data/widget_config_repository_impl.dart';
import 'package:hoyo_aio/features/home_widgets/domain/home_widget_repositories.dart';
import 'package:hoyo_aio/features/home_widgets/domain/widget_snapshot.dart';
import 'package:hoyo_aio/features/home_widgets/presentation/providers/widget_sync_provider.dart';
import 'package:hoyo_aio/features/home_widgets/presentation/widget_size_labels.dart';
import 'package:hoyo_aio/features/home_widgets/presentation/widgets/widget_preview.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

class WidgetGalleryScreen extends ConsumerStatefulWidget {
  const WidgetGalleryScreen({super.key});

  @override
  ConsumerState<WidgetGalleryScreen> createState() =>
      _WidgetGalleryScreenState();
}

class _WidgetGalleryScreenState extends ConsumerState<WidgetGalleryScreen> {
  HomeWidgetSize? _filter;
  late final _lifecycle = AppLifecycleListener(
    onResume: () => ref.invalidate(placedWidgetsProvider),
  );

  @override
  void initState() {
    super.initState();
    _lifecycle;
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _add(HomeWidgetSize size) async {
    if (ref.read(canPinWidgetProvider).value ?? false) {
      await ref.read(homeWidgetBridgeProvider).pin(size);
      return;
    }
    if (!mounted) return;
    showAppSnackbar(
      context,
      message: context.l10n.widgetsAddManual,
      icon: LucideIcons.layoutGrid,
    );
  }

  Future<void> _showAddSheet() => showModalBottomSheet<void>(
    context: context,
    backgroundColor: context.colors.surface,
    barrierColor: context.colors.scrim,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppRadius.dialog),
      ),
    ),
    builder: (sheetContext) {
      final l10n = sheetContext.l10n;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpacing.s12,
            children: [
              Text(
                l10n.widgetsAddTitle,
                style: AppTextStyles.titleL.copyWith(
                  color: sheetContext.colors.text,
                ),
              ),
              SettingsCard(
                children: [
                  for (final size in HomeWidgetSize.values)
                    SettingsRow(
                      icon: LucideIcons.layoutGrid,
                      title: l10n.widgetSizeTitle(size),
                      subtitle: l10n.widgetSizeContent(size),
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        unawaited(_add(size));
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );

  void _open(HomeWidgetSize size, PlacedWidget? placed) {
    if (placed == null) {
      unawaited(_add(size));
      return;
    }
    unawaited(context.push(AppRoutes.widgetEditor(placed.widgetId, size)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final snapshot = ref.watch(widgetSyncProvider).value;
    final placed = ref.watch(placedWidgetsProvider).value ?? const [];
    final configs = ref.watch(widgetConfigsProvider).value ?? const [];
    ref.watch(clockTickProvider);
    final now = ref.watch(clockProvider)();
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter,
          AppSpacing.s16,
          AppSpacing.gutter,
          AppSpacing.s24,
        ),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.navWidgets,
                  style: AppTextStyles.headline.copyWith(color: colors.text),
                ),
              ),
              AppIconButton(
                icon: LucideIcons.plus,
                semanticLabel: l10n.widgetsAddTitle,
                onPressed: () => unawaited(_showAddSheet()),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              spacing: AppSpacing.s8,
              children: [
                _FilterChip(
                  label: l10n.widgetsAll,
                  selected: _filter == null,
                  onTap: () => setState(() => _filter = null),
                ),
                for (final size in HomeWidgetSize.values)
                  _FilterChip(
                    label: l10n.widgetSizeName(size),
                    selected: _filter == size,
                    onTap: () => setState(() => _filter = size),
                  ),
              ],
            ),
          ),
          if (snapshot == null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.s24),
              child: Text(
                l10n.widgetsNoData,
                style: AppTextStyles.bodyM.copyWith(color: colors.text2),
              ),
            )
          else
            for (final size in HomeWidgetSize.values)
              if (_filter == null || _filter == size)
                _Section(
                  size: size,
                  snapshot: snapshot,
                  now: now,
                  placed: [
                    for (final widget in placed)
                      if (widget.size == size) widget,
                  ],
                  configs: configs,
                  onOpen: (widget) => _open(size, widget),
                ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.size,
    required this.snapshot,
    required this.now,
    required this.placed,
    required this.configs,
    required this.onOpen,
  });

  static const int _perRow = 2;

  final HomeWidgetSize size;
  final WidgetSnapshot snapshot;
  final DateTime now;
  final List<PlacedWidget> placed;
  final List<WidgetConfigSnapshot> configs;
  final ValueChanged<PlacedWidget?> onOpen;

  List<(PlacedWidget?, WidgetConfigSnapshot?, int?)> _entries() {
    final real = [
      for (final widget in placed)
        (
          widget,
          configs.where((c) => c.widgetId == widget.widgetId).firstOrNull,
          null,
        ),
    ];
    if (size == HomeWidgetSize.large) {
      return real.isEmpty ? const [(null, null, null)] : real;
    }
    final used = {
      for (final (_, config, _) in real)
        config?.roleId ?? snapshot.roles.firstOrNull?.roleId,
    };
    final samples = [
      for (final role in snapshot.roles)
        if (!used.contains(role.roleId)) (null, null, role.roleId),
    ];
    final missing = (_perRow - real.length % _perRow) % _perRow;
    return [...real, ...samples.take(real.isEmpty ? _perRow : missing)];
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final entries = _entries();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.s8,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.widgetSizeTitle(size).toUpperCase(),
                  style: AppTextStyles.overline.copyWith(color: colors.text2),
                ),
              ),
              Text(
                l10n.widgetSizeContent(size),
                style: AppTextStyles.caption.copyWith(color: colors.text2),
              ),
            ],
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final full = size == HomeWidgetSize.large;
              final width = full
                  ? constraints.maxWidth
                  : (constraints.maxWidth - AppSpacing.s12) / _perRow;
              final natural = WidgetPreview.sizeOf(size);
              return Wrap(
                spacing: AppSpacing.s12,
                runSpacing: AppSpacing.s12,
                children: [
                  for (final (widget, config, roleId) in entries)
                    GestureDetector(
                      onTap: () => onOpen(widget),
                      child: SizedBox(
                        width: width,
                        height: natural.height * width / natural.width,
                        child: FittedBox(
                          child: WidgetPreview(
                            snapshot: snapshot,
                            size: size,
                            config: config,
                            roleId: roleId,
                            now: now,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
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
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s20),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? colors.text : colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.pill),
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
