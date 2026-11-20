import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/core/hoyolab/game_region.dart';

class CheckInEndpoint {
  const CheckInEndpoint({
    required this.host,
    required this.basePath,
    required this.actId,
    required this.signGame,
    this.paramsInBody = false,
  });

  final String host;
  final String basePath;
  final String actId;
  final String? signGame;
  final bool paramsInBody;

  Uri get signUri => Uri.https(host, '$basePath/sign');
  Uri get infoUri => Uri.https(host, '$basePath/info');
  Uri get homeUri => Uri.https(host, '$basePath/home');
}

abstract final class HoyolabConfig {
  static const gameRecordHost = 'bbs-api-os.hoyoverse.com';
  static const zzzRecordHost = 'sg-act-nap-api.hoyolab.com';
  static const genshinEventHost = 'sg-hk4e-api.hoyolab.com';
  static const publicEventHost = 'sg-public-api.hoyolab.com';

  static const allowedHosts = {
    gameRecordHost,
    zzzRecordHost,
    genshinEventHost,
    publicEventHost,
  };

  static const webViewHosts = {
    'm.hoyolab.com',
    'www.hoyolab.com',
    'account.hoyolab.com',
  };
  static const webViewLoginUrl = 'https://m.hoyolab.com/#/timeline';
  static const webViewCookieUrl = 'https://www.hoyolab.com/';

  static const dsSalt = '6cqshh5dhw73bzxn20oexa9k516chk7s';

  static const appVersion = '1.5.0';
  static const clientTypeGameRecord = '4';
  static const clientTypeCheckIn = '5';
  static const platformCheckIn = '5';
  static const gameRecordReferer = 'https://webstatic-sea.hoyolab.com/';
  static const actOrigin = 'https://act.hoyolab.com';
  static const actReferer = 'https://act.hoyolab.com/';

  static const languageEnglish = 'en-us';
  static const languageIndonesian = 'id-id';

  static const recordCardPath = '/game_record/card/wapi/getGameRecordCard';
  static const changeDataSwitchPath = '/game_record/card/wapi/changeDataSwitch';
  static const genshinNotePath = '/game_record/genshin/api/dailyNote';
  static const starRailNotePath = '/game_record/hkrpg/api/note';
  static const zzzNotePath = '/event/game_record_zzz/api/zzz/note';

  static const checkIn = <Game, CheckInEndpoint>{
    Game.genshin: CheckInEndpoint(
      host: genshinEventHost,
      basePath: '/event/sol',
      actId: 'e202102251931481',
      signGame: null,
    ),
    Game.starRail: CheckInEndpoint(
      host: publicEventHost,
      basePath: '/event/luna/os',
      actId: 'e202303301540311',
      signGame: 'hkrpg',
    ),
    Game.zzz: CheckInEndpoint(
      host: publicEventHost,
      basePath: '/event/luna/zzz/os',
      actId: 'e202406031448091',
      signGame: 'zzz',
      paramsInBody: true,
    ),
    Game.hi3: CheckInEndpoint(
      host: publicEventHost,
      basePath: '/event/mani',
      actId: 'e202110291205111',
      signGame: 'bh3',
    ),
  };

  static const gameIds = <Game, int>{
    Game.hi3: 1,
    Game.genshin: 2,
    Game.starRail: 6,
    Game.zzz: 8,
  };

  static const serverIds = <Game, Map<GameRegion, String>>{
    Game.genshin: {
      GameRegion.asia: 'os_asia',
      GameRegion.america: 'os_usa',
      GameRegion.europe: 'os_euro',
      GameRegion.twHkMo: 'os_cht',
    },
    Game.starRail: {
      GameRegion.asia: 'prod_official_asia',
      GameRegion.america: 'prod_official_usa',
      GameRegion.europe: 'prod_official_eur',
      GameRegion.twHkMo: 'prod_official_cht',
    },
    Game.zzz: {
      GameRegion.asia: 'prod_gf_jp',
      GameRegion.america: 'prod_gf_us',
      GameRegion.europe: 'prod_gf_eu',
      GameRegion.twHkMo: 'prod_gf_sg',
    },
  };

  static const notesDataSwitchId = <Game, int>{Game.genshin: 3};

  static const staminaRecovery = <Game, Duration>{
    Game.genshin: Duration(minutes: 8),
    Game.starRail: Duration(minutes: 6),
    Game.zzz: Duration(minutes: 6),
  };

  static const checkInResetUtcOffset = Duration(hours: 8);
}
