import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoyo_aio/core/design_system/components/app_button.dart';
import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:hoyo_aio/core/network/hoyolab_dio_provider.dart';
import 'package:hoyo_aio/features/accounts/presentation/providers/selected_role_provider.dart';
import 'package:hoyo_aio/features/databook/data/chronicle_probe.dart';
import 'package:material_ui/material_ui.dart';

class ChronicleProbeScreen extends ConsumerStatefulWidget {
  const ChronicleProbeScreen({super.key});

  @override
  ConsumerState<ChronicleProbeScreen> createState() =>
      _ChronicleProbeScreenState();
}

class _ChronicleProbeScreenState extends ConsumerState<ChronicleProbeScreen> {
  var _busy = false;
  List<String> _lines = const [];

  Future<void> _run() async {
    setState(() => _busy = true);
    final roles = ref.read(dashboardRolesProvider);
    final results = await ChronicleProbe(ref.read(hoyolabDioProvider))
        .run(roles);
    final lines = <String>[
      for (final MapEntry(key: game, value: endpoints) in results.entries)
        if (endpoints is Map)
          for (final MapEntry(key: key, value: outcome) in endpoints.entries)
            '$game · $key · '
                '${outcome is Map ? (outcome['error'] ?? 'retcode ${outcome['retcode']}') : outcome}',
    ];
    if (!mounted) return;
    setState(() {
      _lines = lines;
      _busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      appBar: AppBar(title: const Text('Chronicle Probe')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.gutter),
        children: [
          Text(
            'Calls every Battle Chronicle endpoint for one saved role per game '
            'and writes sanitized responses (IDs and names masked, lists '
            'trimmed) to ${ChronicleProbe.outputFile.path}.',
            style: AppTextStyles.bodyM.copyWith(color: colors.text2),
          ),
          const SizedBox(height: AppSpacing.s16),
          AppButton(
            label: 'Run Probe',
            onPressed: _busy ? null : _run,
            isLoading: _busy,
          ),
          const SizedBox(height: AppSpacing.s16),
          for (final line in _lines)
            Text(
              line,
              style: AppTextStyles.caption.copyWith(color: colors.text),
            ),
        ],
      ),
    );
  }
}
