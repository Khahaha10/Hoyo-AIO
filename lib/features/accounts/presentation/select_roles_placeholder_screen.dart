import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/core/logging/redactor.dart';
import 'package:hoyo_aio/features/accounts/presentation/providers/pending_account_provider.dart';
import 'package:hoyo_aio/features/accounts/presentation/widgets/account_flow_header.dart';
import 'package:material_ui/material_ui.dart';

class SelectRolesPlaceholderScreen extends ConsumerWidget {
  const SelectRolesPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = context.l10n;
    final roles =
        ref.watch(pendingAccountControllerProvider)?.roles ?? const [];
    return Scaffold(
      body: SafeArea(
        child: ListView(
          children: [
            AccountFlowHeader(
              title: l10n.selectRolesPlaceholderTitle,
              subtitle: l10n.selectRolesFound(roles.length),
            ),
            const SizedBox(height: AppSpacing.s16),
            for (final role in roles)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.gutter,
                  vertical: AppSpacing.s4,
                ),
                child: Text(
                  '${role.game.name} · ${role.server} · Lv ${role.level} · '
                  '${Redactor.maskId(role.uid)}',
                  style: AppTextStyles.tabular(AppTextStyles.bodyM)
                      .copyWith(color: colors.text),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
