import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoyo_aio/core/design_system/components/app_button.dart';
import 'package:hoyo_aio/core/design_system/components/info_banner.dart';
import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_radius.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:hoyo_aio/core/error/app_exception.dart';
import 'package:hoyo_aio/core/error/app_exception_l10n.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/features/tracker/presentation/providers/tracker_providers.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

Future<Game?> showImportSheet(BuildContext context) =>
    showModalBottomSheet<Game>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      barrierColor: context.colors.scrim,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.dialog),
        ),
      ),
      builder: (_) => const _ImportSheet(),
    );

class _ImportSheet extends ConsumerStatefulWidget {
  const _ImportSheet();

  @override
  ConsumerState<_ImportSheet> createState() => _ImportSheetState();
}

class _ImportSheetState extends ConsumerState<_ImportSheet> {
  static const int _fieldLines = 4;

  final _controller = TextEditingController();
  String? _error;
  var _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text case final text?) _controller.text = text;
  }

  Future<void> _import() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final l10n = context.l10n;
    try {
      final game = await ref
          .read(gachaSyncProvider.notifier)
          .importLink(_controller.text);
      _controller.clear();
      await Clipboard.setData(const ClipboardData(text: ''));
      if (mounted) Navigator.of(context).pop(game);
    } on ParseException {
      setState(() => _error = l10n.trackerLinkInvalid);
    } on AppException catch (error) {
      setState(() => _error = error.localizedMessage(l10n));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final fetched = ref.watch(gachaSyncProvider).fetched;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.s24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpacing.s16,
            children: [
              Text(
                l10n.trackerImportTitle,
                style: AppTextStyles.titleL.copyWith(color: colors.text),
              ),
              Text(
                l10n.trackerImportSteps,
                style: AppTextStyles.bodyM.copyWith(color: colors.text2),
              ),
              TextField(
                controller: _controller,
                minLines: _fieldLines,
                maxLines: _fieldLines,
                autocorrect: false,
                enableSuggestions: false,
                keyboardType: TextInputType.url,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: colors.text,
                ),
                decoration: InputDecoration(
                  hintText: 'https://…authkey=…',
                  errorText: _error,
                  filled: true,
                  fillColor: colors.surface2,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.banner),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    tooltip: l10n.trackerPaste,
                    icon: const Icon(LucideIcons.clipboardPaste),
                    onPressed: () => unawaited(_paste()),
                  ),
                ),
              ),
              InfoBanner(
                icon: LucideIcons.shieldCheck,
                message: l10n.trackerImportSafety,
              ),
              AppButton(
                label: _busy
                    ? l10n.trackerFetched(fetched)
                    : l10n.trackerImport,
                isLoading: _busy,
                onPressed: () => unawaited(_import()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
