import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoyo_aio/core/design_system/components/app_dialog.dart';
import 'package:hoyo_aio/core/design_system/components/app_snackbar.dart';
import 'package:hoyo_aio/core/design_system/components/pressable.dart';
import 'package:hoyo_aio/core/design_system/components/settings_row.dart';
import 'package:hoyo_aio/core/design_system/icons/app_icon.dart';
import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_radius.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/features/settings/data/backup_service.dart';
import 'package:hoyo_aio/features/settings/domain/backup_schema.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

class BackupRow extends ConsumerStatefulWidget {
  const BackupRow({super.key});

  @override
  ConsumerState<BackupRow> createState() => _BackupRowState();
}

class _BackupRowState extends ConsumerState<BackupRow> {
  var _busy = false;

  Future<void> _run(Future<void> Function(BackupService service) task) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await task(ref.read(backupServiceProvider));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import(BackupService service) async {
    final l10n = context.l10n;
    final BackupData? data;
    try {
      data = await service.pick();
    } on BackupFormatException {
      if (mounted) {
        showAppSnackbar(
          context,
          message: l10n.backupInvalidFile,
          icon: LucideIcons.fileWarning,
        );
      }
      return;
    }
    if (data == null || !mounted) return;
    final confirmed = await showAppConfirmDialog(
      context,
      icon: LucideIcons.download,
      title: l10n.backupImportTitle,
      body: l10n.backupImportBody(data.accounts.length),
      cancelLabel: l10n.commonCancel,
      confirmLabel: l10n.backupImport,
      isDestructive: false,
    );
    if (!confirmed) return;
    final result = await service.apply(data);
    if (!mounted) return;
    showAppSnackbar(
      context,
      message: l10n.backupImported(result.needsLogin),
      icon: LucideIcons.check,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final onExport = _busy ? null : () => _run((s) => s.export());
    final onImport = _busy ? null : () => _run(_import);
    return SettingsRow(
      icon: LucideIcons.hardDriveDownload,
      title: l10n.backupTitle,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.s8,
        children: [
          _Pill(
            icon: LucideIcons.upload,
            label: l10n.backupExport,
            onTap: onExport,
          ),
          _Pill(
            icon: LucideIcons.download,
            label: l10n.backupImport,
            onTap: onImport,
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label, required this.onTap});

  static const double _hitHeight = 44;
  static const double _height = 32;

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      enabled: onTap != null,
      child: Pressable(
        onTap: onTap,
        builder: (context, _) => SizedBox(
          height: _hitHeight,
          child: Center(
            child: Container(
              height: _height,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(color: colors.border2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: AppSpacing.s4,
                children: [
                  AppIcon(
                    icon,
                    size: AppIconSize.inline,
                    color: onTap == null ? colors.text3 : colors.text,
                  ),
                  Text(
                    label,
                    style: AppTextStyles.label.copyWith(
                      color: onTap == null ? colors.text3 : colors.text,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
