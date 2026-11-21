import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoyo_aio/core/design_system/components/app_button.dart';
import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_radius.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:hoyo_aio/core/error/app_exception.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/core/hoyolab/hoyolab_config.dart';
import 'package:hoyo_aio/core/logging/app_logger.dart';
import 'package:hoyo_aio/core/logging/redactor.dart';
import 'package:hoyo_aio/core/network/hoyolab_dio.dart';
import 'package:hoyo_aio/core/network/hoyolab_request.dart';
import 'package:hoyo_aio/core/storage/hoyolab_cookie.dart';
import 'package:material_ui/material_ui.dart';

class ApiDebugScreen extends ConsumerStatefulWidget {
  const ApiDebugScreen({super.key});

  @override
  ConsumerState<ApiDebugScreen> createState() => _ApiDebugScreenState();
}

class _ApiDebugScreenState extends ConsumerState<ApiDebugScreen> {
  static const _debugAccountId = 'debug';

  final _controller = TextEditingController();
  var _busy = false;
  String? _result;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _fetchRecordCard() async {
    final cookie = HoyolabCookie.parse(_controller.text);
    _controller.clear();
    final uid = cookie.hoyolabUid;
    if (!cookie.isUsable || uid == null) {
      setState(() => _result = 'Cookie not usable (keys: ${cookie.keyCount})');
      return;
    }
    setState(() => _busy = true);
    final logger = ref.read(appLoggerProvider);
    final dio = buildHoyolabDio(
      cookies: (_) async => cookie.serialize(),
      log: logger.network,
      verboseLogging: true,
    );
    try {
      final response = await guardHoyolab(
        () => dio.getUri<Map<String, dynamic>>(
          Uri.https(
            HoyolabConfig.gameRecordHost,
            HoyolabConfig.recordCardPath,
            {'uid': uid},
          ),
          options: hoyolabOptions(
            accountId: _debugAccountId,
            profile: HeaderProfile.gameRecord,
          ),
        ),
      );
      setState(() => _result = _describe(response));
    } on AppException catch (e) {
      setState(() => _result = 'Failed: ${_describeError(e)}');
    } finally {
      dio.close();
      if (mounted) setState(() => _busy = false);
    }
  }

  String _describe(Response<Map<String, dynamic>> response) {
    final data = response.data?['data'];
    final list = data is Map ? data['list'] : null;
    if (list is! List) return 'retcode 0, no role list';
    final roles = list.whereType<Map<String, dynamic>>().map((card) {
      final game = gameFromHoyolabId((card['game_id'] as num?)?.toInt() ?? -1);
      final uid = Redactor.maskId('${card['game_role_id'] ?? ''}');
      return '${game?.name ?? card['game_id']} · ${card['region']} · '
          'Lv ${card['level']} · uid $uid';
    });
    return 'retcode 0 · ${list.length} role(s)\n${roles.join('\n')}';
  }

  String _describeError(AppException e) => switch (e) {
    ServerException(:final retcode, :final message) =>
      'server $retcode $message',
    CookieExpiredException(:final retcode) => 'cookie expired ($retcode)',
    NoRolesException(:final retcode) => 'no roles ($retcode)',
    RateLimitedException(:final retryable) =>
      'rate limited (retryable $retryable)',
    _ => e.runtimeType.toString(),
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      appBar: AppBar(title: const Text('API Debug')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.gutter),
        children: [
          Text(
            'Paste a HoYoLAB cookie. It is used for one record-card request, '
            'never stored, and the field is cleared.',
            style: AppTextStyles.bodyM.copyWith(color: colors.text2),
          ),
          const SizedBox(height: AppSpacing.s12),
          TextField(
            controller: _controller,
            minLines: 3,
            maxLines: 5,
            autocorrect: false,
            enableSuggestions: false,
            enableIMEPersonalizedLearning: false,
            keyboardType: TextInputType.visiblePassword,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.banner),
              ),
              hintText: 'ltuid_v2=…; ltoken_v2=…',
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          AppButton(
            label: 'Fetch Game Record Card',
            isLoading: _busy,
            onPressed: _fetchRecordCard,
          ),
          const SizedBox(height: AppSpacing.s16),
          if (_result != null)
            SelectableText(
              _result!,
              style: AppTextStyles.tabular(AppTextStyles.bodyM)
                  .copyWith(color: colors.text),
            ),
        ],
      ),
    );
  }
}
