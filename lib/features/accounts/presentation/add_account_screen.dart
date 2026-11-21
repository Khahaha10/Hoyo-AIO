import 'package:go_router/go_router.dart';
import 'package:hoyo_aio/app/router/app_routes.dart';
import 'package:hoyo_aio/core/design_system/components/app_badge.dart';
import 'package:hoyo_aio/core/design_system/components/app_button.dart';
import 'package:hoyo_aio/core/design_system/components/info_banner.dart';
import 'package:hoyo_aio/core/design_system/components/radio_option_card.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/features/accounts/presentation/widgets/account_flow_header.dart';
import 'package:hoyo_aio/features/accounts/presentation/widgets/why_cookie_sheet.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

enum _SignInMethod { webView, paste }

class AddAccountScreen extends StatefulWidget {
  const AddAccountScreen({required this.showDevTools, super.key});

  final bool showDevTools;

  @override
  State<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends State<AddAccountScreen> {
  var _method = _SignInMethod.webView;

  void _continue() => context.push(
    _method == _SignInMethod.webView
        ? AppRoutes.webViewLogin
        : AppRoutes.pasteCookie,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  AccountFlowHeader(
                    title: l10n.addAccountTitle,
                    subtitle: l10n.addAccountSubtitle,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.gutter,
                      AppSpacing.s24,
                      AppSpacing.gutter,
                      0,
                    ),
                    child: Column(
                      spacing: AppSpacing.s12,
                      children: [
                        RadioOptionCard(
                          title: l10n.addAccountWebViewTitle,
                          subtitle: l10n.addAccountWebViewBody,
                          icon: LucideIcons.logIn,
                          highlightIcon: true,
                          badge: AppBadge(label: l10n.addAccountRecommended),
                          selected: _method == _SignInMethod.webView,
                          onTap: () =>
                              setState(() => _method = _SignInMethod.webView),
                        ),
                        RadioOptionCard(
                          title: l10n.addAccountPasteTitle,
                          subtitle: l10n.addAccountPasteBody,
                          icon: LucideIcons.cookie,
                          selected: _method == _SignInMethod.paste,
                          onTap: () =>
                              setState(() => _method = _SignInMethod.paste),
                        ),
                        const SizedBox(height: AppSpacing.s4),
                        InfoBanner(
                          icon: LucideIcons.shieldCheck,
                          message: l10n.addAccountStorageNote,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                AppSpacing.s12,
                AppSpacing.gutter,
                AppSpacing.s24,
              ),
              child: Column(
                spacing: AppSpacing.s8,
                children: [
                  AppButton(
                    label: l10n.addAccountContinue,
                    onPressed: _continue,
                  ),
                  AppButton(
                    label: l10n.addAccountWhy,
                    variant: AppButtonVariant.text,
                    onPressed: () => showWhyCookieSheet(context),
                  ),
                  if (widget.showDevTools)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppButton(
                          label: 'Gallery',
                          variant: AppButtonVariant.text,
                          expand: false,
                          onPressed: () => context.push(AppRoutes.gallery),
                        ),
                        AppButton(
                          label: 'API Debug',
                          variant: AppButtonVariant.text,
                          expand: false,
                          onPressed: () => context.push(AppRoutes.apiDebug),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
