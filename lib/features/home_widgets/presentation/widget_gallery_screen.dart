import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoyo_aio/app/router/app_routes.dart';
import 'package:hoyo_aio/core/design_system/components/app_button.dart';
import 'package:hoyo_aio/core/design_system/components/app_segmented_control.dart';
import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final snapshot = ref.watch(widgetSyncProvider).value;
    final placed = ref.watch(placedWidgetsProvider).value ?? const [];
    final configs = ref.watch(widgetConfigsProvider).value ?? const [];
    final canPin = ref.watch(canPinWidgetProvider).value ?? false;
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
          Text(
            l10n.navWidgets,
            style: AppTextStyles.titleL.copyWith(color: context.colors.text),
          ),
          const SizedBox(height: AppSpacing.s12),
          AppSegmentedControl<HomeWidgetSize?>(
            options: [
              SegmentOption(value: null, label: l10n.widgetsAll),
              for (final size in HomeWidgetSize.values)
                SegmentOption(value: size, label: l10n.widgetSizeName(size)),
            ],
            selected: _filter,
            onChanged: (size) => setState(() => _filter = size),
          ),
          if (snapshot == null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.s24),
              child: Text(
                l10n.widgetsNoData,
                style: AppTextStyles.bodyM.copyWith(
                  color: context.colors.text2,
                ),
              ),
            )
          else
            for (final size in HomeWidgetSize.values)
              if (_filter == null || _filter == size)
                _SizeSection(
                  size: size,
                  snapshot: snapshot,
                  now: now,
                  placed: [
                    for (final widget in placed)
                      if (widget.size == size) widget,
                  ],
                  configs: configs,
                  canPin: canPin,
                ),
        ],
      ),
    );
  }
}

class _SizeSection extends ConsumerWidget {
  const _SizeSection({
    required this.size,
    required this.snapshot,
    required this.now,
    required this.placed,
    required this.configs,
    required this.canPin,
  });

  final HomeWidgetSize size;
  final WidgetSnapshot snapshot;
  final DateTime now;
  final List<PlacedWidget> placed;
  final List<WidgetConfigSnapshot> configs;
  final bool canPin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = context.l10n;
    final caption = AppTextStyles.caption.copyWith(color: colors.text2);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
              Text(l10n.widgetSizeContent(size), style: caption),
            ],
          ),
          Wrap(
            spacing: AppSpacing.s12,
            runSpacing: AppSpacing.s12,
            children: [
              if (placed.isEmpty)
                _preview(context, null)
              else
                for (final widget in placed)
                  GestureDetector(
                    onTap: () => context.push(
                      AppRoutes.widgetEditor(widget.widgetId, size),
                    ),
                    child: _preview(
                      context,
                      configs
                          .where((c) => c.widgetId == widget.widgetId)
                          .firstOrNull,
                    ),
                  ),
            ],
          ),
          Text(
            placed.isEmpty ? l10n.widgetsNotPlaced : l10n.widgetsTapToEdit,
            style: caption,
          ),
          if (canPin)
            AppButton(
              label: l10n.widgetsAdd(l10n.widgetSizeName(size)),
              icon: LucideIcons.plus,
              size: AppButtonSize.small,
              variant: AppButtonVariant.secondary,
              expand: false,
              onPressed: () =>
                  unawaited(ref.read(homeWidgetBridgeProvider).pin(size)),
            ),
        ],
      ),
    );
  }

  Widget _preview(BuildContext context, WidgetConfigSnapshot? config) =>
      LayoutBuilder(
        builder: (context, constraints) {
          final natural = WidgetPreview.sizeOf(size);
          final width = natural.width > constraints.maxWidth
              ? constraints.maxWidth
              : natural.width;
          return SizedBox(
            width: width,
            height: natural.height * width / natural.width,
            child: FittedBox(
              child: WidgetPreview(
                snapshot: snapshot,
                size: size,
                config: config,
                now: now,
              ),
            ),
          );
        },
      );
}
