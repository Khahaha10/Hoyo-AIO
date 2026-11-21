import 'package:dio/dio.dart';
import 'package:hoyo_aio/core/error/app_exception.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/core/hoyolab/hoyolab_config.dart';
import 'package:hoyo_aio/core/network/hoyolab_dio.dart';
import 'package:hoyo_aio/core/network/hoyolab_dio_provider.dart';
import 'package:hoyo_aio/core/network/hoyolab_request.dart';
import 'package:hoyo_aio/features/checkin/data/dto/check_in_dto.dart';
import 'package:hoyo_aio/features/checkin/domain/check_in_month.dart';
import 'package:hoyo_aio/features/checkin/domain/check_in_repository.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'check_in_repository_impl.g.dart';

class CheckInRepositoryImpl implements CheckInRepository {
  const CheckInRepositoryImpl(this._dio);

  static const _awardPageSize = 10;
  static const _maxAwardPages = 4;

  final Dio _dio;

  @override
  Future<CheckInMonth> month({
    required String accountId,
    required Game game,
  }) async {
    final endpoint = _endpoint(game);
    final (infoJson, homeJson) = await (
      _get(endpoint.infoUri, endpoint, accountId, game),
      _get(endpoint.homeUri, endpoint, accountId, game),
    ).wait;
    final (info, home) = _parse(
      () => (
        CheckInInfoDto.fromJson(infoJson),
        CheckInHomeDto.fromJson(homeJson),
      ),
    );
    final claimedOn = await _claimedThisMonth(
      endpoint,
      accountId,
      game,
      DateTime.tryParse(info.today),
    );
    return CheckInMonth(
      game: game,
      month: home.month,
      signedDays: info.totalSignDay,
      signedToday: info.isSign,
      missedDays: info.signCntMissed,
      today: info.today,
      rewards: [
        for (final (index, award) in home.awards.indexed)
          CheckInReward(day: index + 1, name: award.name, count: award.cnt),
      ],
      claimedOn: claimedOn,
    );
  }

  Future<Map<int, CheckInReward>?> _claimedThisMonth(
    CheckInEndpoint endpoint,
    String accountId,
    Game game,
    DateTime? today,
  ) async {
    if (today == null) return null;
    final claimed = <int, CheckInReward>{};
    try {
      for (var page = 1; page <= _maxAwardPages; page++) {
        final json = await _get(
          endpoint.awardUri,
          endpoint,
          accountId,
          game,
          extra: {'current_page': '$page', 'page_size': '$_awardPageSize'},
        );
        final records = _parse(() => CheckInAwardPageDto.fromJson(json)).list;
        for (final record in records) {
          final at = DateTime.tryParse(record.createdAt);
          if (at == null) continue;
          if (at.year != today.year || at.month != today.month) return claimed;
          claimed[at.day] = CheckInReward(
            day: at.day,
            name: record.name,
            count: record.cnt,
          );
        }
        if (records.length < _awardPageSize) break;
      }
      return claimed;
    } on ServerException {
      return null;
    } on ParseException {
      return null;
    }
  }

  @override
  Future<ClaimOutcome> claim({
    required String accountId,
    required Game game,
  }) async {
    final endpoint = _endpoint(game);
    final params = _params(endpoint);
    try {
      final response = await guardHoyolab(
        () => _dio.postUri<Map<String, dynamic>>(
          endpoint.paramsInBody
              ? endpoint.signUri
              : endpoint.signUri.replace(queryParameters: params),
          data: endpoint.paramsInBody ? params : null,
          options: _options(accountId, game),
        ),
      );
      final data = response.data?['data'];
      final sign = data is Map<String, dynamic>
          ? _parse(() => CheckInSignDto.fromJson(data))
          : const CheckInSignDto();
      return sign.needsCaptcha ? ClaimOutcome.captcha : ClaimOutcome.claimed;
    } on AlreadyCheckedInException {
      return ClaimOutcome.alreadyClaimed;
    }
  }

  Future<Map<String, dynamic>> _get(
    Uri uri,
    CheckInEndpoint endpoint,
    String accountId,
    Game game, {
    Map<String, String> extra = const {},
  }) async {
    final response = await guardHoyolab(
      () => _dio.getUri<Map<String, dynamic>>(
        uri.replace(queryParameters: {..._params(endpoint), ...extra}),
        options: _options(accountId, game),
      ),
    );
    final data = response.data?['data'];
    if (data is! Map<String, dynamic>) {
      throw ParseException('check-in ${game.name}: missing data');
    }
    return data;
  }

  static CheckInEndpoint _endpoint(Game game) {
    final endpoint = HoyolabConfig.checkIn[game];
    if (endpoint == null) {
      throw ArgumentError.value(game, 'game', 'has no check-in');
    }
    return endpoint;
  }

  static Map<String, String> _params(CheckInEndpoint endpoint) => {
    'lang': HoyolabConfig.languageEnglish,
    'act_id': endpoint.actId,
  };

  static Options _options(String accountId, Game game) => hoyolabOptions(
    accountId: accountId,
    profile: HeaderProfile.checkIn,
    game: game,
  );

  static T _parse<T>(T Function() parse) {
    try {
      return parse();
    } on CheckedFromJsonException catch (e) {
      throw ParseException('check-in: ${e.key}');
    }
  }
}

@Riverpod(keepAlive: true)
CheckInRepository checkInRepository(Ref ref) =>
    CheckInRepositoryImpl(ref.watch(hoyolabDioProvider));
