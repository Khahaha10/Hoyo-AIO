import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoyo_aio/app/router/app_routes.dart';
import 'package:hoyo_aio/core/design_system/components/app_badge.dart';
import 'package:hoyo_aio/core/design_system/components/app_button.dart';
import 'package:hoyo_aio/core/design_system/components/info_banner.dart';
import 'package:hoyo_aio/core/design_system/icons/app_icon.dart';
import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_radius.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:hoyo_aio/core/error/app_exception.dart';
import 'package:hoyo_aio/core/error/app_exception_l10n.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/core/storage/hoyolab_cookie.dart';
import 'package:hoyo_aio/features/accounts/presentation/providers/pending_account_provider.dart';
import 'package:hoyo_aio/features/accounts/presentation/widgets/account_flow_header.dart';
import 'package:hoyo_aio/features/accounts/presentation/widgets/cookie_guide_card.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

class PasteCookieScreen extends ConsumerStatefulWidget {
  const PasteCookieScreen({super.key});

  @override
  ConsumerState<PasteCookieScreen> createState() => _PasteCookieScreenState();
}

class _PasteCookieScreenState extends ConsumerState<PasteCookieScreen> {
  final _controller = TextEditingController();
  var _cookie = HoyolabCookie.parse('');
  var _pastedFromClipboard = false;
  var _verifying = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {
    _cookie = HoyolabCookie.parse(_controller.text);
    _error = null;
  });

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.isEmpty) return;
    _pastedFromClipboard = true;
    _controller.text = text;
  }

  Future<void> _verify() async {
    setState(() => _verifying = true);
    try {
      await ref.read(pendingAccountControllerProvider.notifier).verify(_cookie);
      _controller.clear();
      if (_pastedFromClipboard) {
        await Clipboard.setData(const ClipboardData(text: ''));
      }
      if (mounted) await context.push(AppRoutes.selectRoles);
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.localizedMessage(context.l10n));
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: AppSpacing.s24),
                children: [
                  AccountFlowHeader(title: l10n.pasteCookieTitle, large: false),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.gutter,
                      AppSpacing.s20,
                      AppSpacing.gutter,
                      0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _CookieField(
                          controller: _controller,
                          isValid: _cookie.isUsable,
                          onPaste: _paste,
                        ),
                        const SizedBox(height: AppSpacing.s12),
                        _ValidationLine(
                          cookie: _cookie,
                          hasText: _controller.text.trim().isNotEmpty,
                          error: _error,
                        ),
                        const SizedBox(height: AppSpacing.s20),
                        const CookieGuideCard(),
                        const SizedBox(height: AppSpacing.s12),
                        InfoBanner(
                          icon: LucideIcons.triangleAlert,
                          variant: InfoBannerVariant.warning,
                          message: l10n.pasteCookieWarning,
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
                AppSpacing.s8,
                AppSpacing.gutter,
                AppSpacing.s24,
              ),
              child: AppButton(
                label: l10n.pasteCookieVerify,
                isLoading: _verifying,
                onPressed: _cookie.isUsable ? _verify : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CookieField extends StatelessWidget {
  const _CookieField({
    required this.controller,
    required this.isValid,
    required this.onPaste,
  });

  static const double _height = 112;

  final TextEditingController controller;
  final bool isValid;
  final VoidCallback onPaste;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final borderColor = isValid ? colors.success : colors.border2;
    OutlineInputBorder border(double width) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.banner),
      borderSide: BorderSide(color: borderColor, width: width),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.s8,
      children: [
        Text(
          l10n.pasteCookieFieldLabel.toUpperCase(),
          style: AppTextStyles.overline.copyWith(color: colors.text3),
        ),
        SizedBox(
          height: _height,
          child: Stack(
            children: [
              TextField(
                controller: controller,
                expands: true,
                maxLines: null,
                textAlignVertical: TextAlignVertical.top,
                autocorrect: false,
                enableSuggestions: false,
                enableIMEPersonalizedLearning: false,
                keyboardType: TextInputType.visiblePassword,
                style: AppTextStyles.rowSubtitle.copyWith(
                  fontFamily: monospaceFontFamily,
                  color: colors.text,
                ),
                decoration: InputDecoration(
                  hintText: l10n.pasteCookieHint,
                  hintStyle: AppTextStyles.rowSubtitle.copyWith(
                    fontFamily: monospaceFontFamily,
                    color: colors.text3,
                  ),
                  filled: true,
                  fillColor: colors.surface,
                  contentPadding: const EdgeInsets.fromLTRB(
                    AppSpacing.s16,
                    AppSpacing.s12,
                    AppSpacing.s16,
                    AppSpacing.s40,
                  ),
                  enabledBorder: border(isValid ? 2 : 1),
                  focusedBorder: border(2),
                ),
              ),
              Positioned(
                right: AppSpacing.s8,
                bottom: AppSpacing.s8,
                child: _PasteChip(label: l10n.pasteCookiePaste, onTap: onPaste),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PasteChip extends StatelessWidget {
  const _PasteChip({required this.label, required this.onTap});

  static const double _height = 32;

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: _height,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12),
          decoration: BoxDecoration(
            color: colors.surface2,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 6,
            children: [
              AppIcon(
                LucideIcons.clipboardPaste,
                size: AppIconSize.inline,
                color: colors.text,
              ),
              Text(
                label,
                style: AppTextStyles.label.copyWith(color: colors.text),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ValidationLine extends StatelessWidget {
  const _ValidationLine({
    required this.cookie,
    required this.hasText,
    required this.error,
  });

  final HoyolabCookie cookie;
  final bool hasText;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.s8,
      children: [
        if (cookie.isUsable)
          AppBadge(
            label: l10n.pasteCookieValid(cookie.keyCount),
            variant: AppBadgeVariant.success,
            icon: LucideIcons.check,
          )
        else if (hasText)
          AppBadge(
            label: l10n.pasteCookieMissing,
            variant: AppBadgeVariant.warning,
            icon: LucideIcons.triangleAlert,
          ),
        if (error != null)
          Semantics(
            liveRegion: true,
            child: Text(
              error!,
              style: AppTextStyles.rowSubtitle.copyWith(color: colors.danger),
            ),
          ),
      ],
    );
  }
}
