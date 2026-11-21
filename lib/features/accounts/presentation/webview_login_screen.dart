import 'dart:async';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoyo_aio/app/router/app_routes.dart';
import 'package:hoyo_aio/core/design_system/components/alert_banner.dart';
import 'package:hoyo_aio/core/design_system/components/app_button.dart';
import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:hoyo_aio/core/error/app_exception.dart';
import 'package:hoyo_aio/core/error/app_exception_l10n.dart';
import 'package:hoyo_aio/core/hoyolab/hoyolab_config.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/features/accounts/data/webview_cookie_reader.dart';
import 'package:hoyo_aio/features/accounts/presentation/providers/pending_account_provider.dart';
import 'package:hoyo_aio/features/accounts/presentation/widgets/account_flow_header.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

class WebViewLoginScreen extends ConsumerStatefulWidget {
  const WebViewLoginScreen({super.key});

  @override
  ConsumerState<WebViewLoginScreen> createState() => _WebViewLoginScreenState();
}

class _WebViewLoginScreenState extends ConsumerState<WebViewLoginScreen> {
  static const _webViewMarker = '; wv';

  final _reader = WebViewCookieReader();
  InAppWebViewController? _controller;
  String? _userAgent;
  var _progress = 0.0;
  var _capturing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_prepare());
  }

  @override
  void dispose() {
    unawaited(_reader.clear());
    super.dispose();
  }

  Future<void> _prepare() async {
    await _reader.clear();
    final agent = await InAppWebViewController.getDefaultUserAgent();
    if (!mounted) return;
    setState(() => _userAgent = agent.replaceAll(_webViewMarker, ''));
  }

  Future<NavigationActionPolicy> _guardNavigation(
    NavigationAction action,
  ) async {
    final uri = action.request.url;
    if (uri == null || isAllowedWebViewUri(uri)) {
      return NavigationActionPolicy.ALLOW;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
    return NavigationActionPolicy.CANCEL;
  }

  Future<void> _checkLogin() async {
    if (_capturing) return;
    final cookie = await _reader.read();
    if (!cookie.isUsable || !mounted) return;
    setState(() {
      _capturing = true;
      _error = null;
    });
    await _reader.clear();
    try {
      await ref.read(pendingAccountControllerProvider.notifier).verify(cookie);
      if (mounted) context.pushReplacement(AppRoutes.selectRoles);
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() {
        _capturing = false;
        _error = e.localizedMessage(context.l10n);
      });
      await _reload();
    }
  }

  Future<void> _reload() async => _controller?.loadUrl(
    urlRequest: URLRequest(url: WebUri(HoyolabConfig.webViewLoginUrl)),
  );

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AccountFlowHeader(
              title: l10n.webViewLoginTitle,
              subtitle: l10n.webViewLoginHint,
              large: false,
            ),
            const SizedBox(height: AppSpacing.s12),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.gutter,
                  0,
                  AppSpacing.gutter,
                  AppSpacing.s12,
                ),
                child: AlertBanner(
                  icon: LucideIcons.circleAlert,
                  title: l10n.webViewLoginTitle,
                  body: _error!,
                  actions: [
                    AppButton(
                      label: l10n.webViewReload,
                      size: AppButtonSize.small,
                      expand: false,
                      onPressed: _reload,
                    ),
                  ],
                ),
              ),
            SizedBox(
              height: 2,
              child: _progress < 1
                  ? LinearProgressIndicator(
                      value: _progress,
                      color: colors.text,
                      backgroundColor: colors.surface3,
                    )
                  : null,
            ),
            Expanded(
              child: Stack(
                children: [
                  if (_userAgent != null) _webView(),
                  if (_capturing)
                    _CapturingOverlay(label: l10n.webViewSigningIn),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _webView() => InAppWebView(
    initialUrlRequest: URLRequest(url: WebUri(HoyolabConfig.webViewLoginUrl)),
    initialSettings: InAppWebViewSettings(
      userAgent: _userAgent,
      javaScriptEnabled: true,
      domStorageEnabled: true,
      supportMultipleWindows: false,
      javaScriptCanOpenWindowsAutomatically: true,
      useShouldOverrideUrlLoading: true,
      cacheEnabled: false,
      thirdPartyCookiesEnabled: false,
      allowFileAccess: false,
      allowContentAccess: false,
      mediaPlaybackRequiresUserGesture: true,
    ),
    onWebViewCreated: (controller) => _controller = controller,
    shouldOverrideUrlLoading: (_, action) => _guardNavigation(action),
    onProgressChanged: (_, progress) =>
        setState(() => _progress = progress / 100),
    onLoadStop: (_, _) => _checkLogin(),
    onUpdateVisitedHistory: (_, _, _) => _checkLogin(),
  );
}

class _CapturingOverlay extends StatelessWidget {
  const _CapturingOverlay({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Positioned.fill(
      child: ColoredBox(
        color: colors.bg,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: AppSpacing.s16,
            children: [
              CircularProgressIndicator(color: colors.text),
              Semantics(
                liveRegion: true,
                child: Text(
                  label,
                  style: AppTextStyles.bodyM.copyWith(color: colors.text2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
