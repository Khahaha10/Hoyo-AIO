import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/core/hoyolab/game_region.dart';

class CheckInEndpoint {
  const CheckInEndpoint({
    required this.host,
    required this.basePath,
    required this.actId,
    required this.signGame,
    required this.headers,
    this.paramsInBody = false,
    this.sendsTimestamp = false,
  });

  final String host;
  final String basePath;
  final String actId;
  final String? signGame;
  final Map<String, String> headers;
  final bool paramsInBody;
  final bool sendsTimestamp;

  Uri get signUri => Uri.https(host, '$basePath/sign');
  Uri get infoUri => Uri.https(host, '$basePath/info');
  Uri get homeUri => Uri.https(host, '$basePath/home');
  Uri get awardUri => Uri.https(host, '$basePath/award');
}

abstract final class HoyolabConfig {
  static const gameRecordHost = 'bbs-api-os.hoyoverse.com';
  static const zzzRecordHost = 'sg-act-nap-api.hoyolab.com';
  static const genshinEventHost = 'sg-hk4e-api.hoyolab.com';
  static const publicEventHost = 'sg-public-api.hoyolab.com';
  static const communityHost = 'bbs-api-os.hoyolab.com';
  static const gachaHosts = <Game, String>{
    Game.genshin: 'public-operation-hk4e-sg.hoyoverse.com',
    Game.starRail: 'public-operation-hkrpg-sg.hoyoverse.com',
    Game.zzz: 'public-operation-nap-sg.hoyoverse.com',
  };

  static final allowedHosts = {
    gameRecordHost,
    zzzRecordHost,
    genshinEventHost,
    publicEventHost,
    communityHost,
    ...gachaHosts.values,
  };

  static const communityGameIds = <Game, int>{
    Game.genshin: 2,
    Game.starRail: 6,
    Game.zzz: 8,
  };
  static const codesPath =
      '/community/painter/wapi/circle/channel/guide/material';
  static const codesModuleType = 7;
  static const eventsPath = '/community/community_contribution/wapi/event/list';
  static const eventsPageSize = 15;
  static const hoyolabWebHost = 'www.hoyolab.com';
  static const hoyolabWebUrl = 'https://$hoyolabWebHost';
  static const redeemUrls = <Game, String>{
    Game.genshin: 'https://genshin.hoyoverse.com/en/gift?code=',
    Game.starRail: 'https://hsr.hoyoverse.com/gift?code=',
    Game.zzz: 'https://zenless.hoyoverse.com/redemption?code=',
  };
  static const gachaPaths = <Game, String>{
    Game.genshin: '/gacha_info/api/getGachaLog',
    Game.starRail: '/common/gacha_record/api/getGachaLog',
    Game.zzz: '/common/gacha_record/api/getGachaLog',
  };
  static const gachaGameBiz = <Game, String>{
    Game.starRail: 'hkrpg_global',
    Game.zzz: 'nap_global',
  };
  static const gachaPageSize = 20;
  static const gachaLinkHostSuffix = 'hoyoverse.com';
  static const gachaKeptParams = {
    'authkey',
    'authkey_ver',
    'sign_type',
    'auth_appid',
    'region',
    'game_biz',
  };
  static const gachaGameBizToGame = <String, Game>{
    'hk4e_global': Game.genshin,
    'hkrpg_global': Game.starRail,
    'nap_global': Game.zzz,
  };
  static const gachaPathMarkers = <String, Game>{
    'genshin': Game.genshin,
    'hk4e': Game.genshin,
    'hkrpg': Game.starRail,
    'nap': Game.zzz,
  };
  static const gachaBannerParam = <Game, String>{
    Game.genshin: 'gacha_type',
    Game.starRail: 'gacha_type',
    Game.zzz: 'real_gacha_type',
  };
  static const gachaBanners = <Game, List<String>>{
    Game.genshin: ['301', '302', '500', '200', '100'],
    Game.starRail: ['11', '12', '1', '2'],
    Game.zzz: ['2', '3', '1', '5'],
  };
  static const gachaAuthkeyLifetime = Duration(hours: 24);
  static const gachaPity = <String, (int, int)>{
    'genshin.301': (90, 74),
    'genshin.302': (80, 63),
    'genshin.500': (90, 74),
    'genshin.200': (90, 74),
    'genshin.100': (90, 74),
    'starRail.11': (90, 74),
    'starRail.12': (80, 66),
    'starRail.1': (90, 74),
    'starRail.2': (90, 74),
    'zzz.2': (90, 74),
    'zzz.3': (80, 64),
    'zzz.1': (90, 74),
    'zzz.5': (80, 64),
  };
  static const gachaPullCost = <Game, int>{
    Game.genshin: 160,
    Game.starRail: 160,
    Game.zzz: 160,
  };
  static const gachaExpiredRetcodes = {-100, -101};

  static const webViewHosts = {
    'm.hoyolab.com',
    'www.hoyolab.com',
    'account.hoyolab.com',
  };
  static const webViewHostSuffixes = {'hoyolab.com', 'hoyoverse.com'};
  static const webViewLoginUrl = 'https://m.hoyolab.com/#/timeline';
  static const hoyolabHomeUrl = 'https://www.hoyolab.com/';
  static const webViewCookieUrls = [
    'https://www.hoyolab.com/',
    'https://m.hoyolab.com/',
  ];

  static const dsSalt = '6cqshh5dhw73bzxn20oexa9k516chk7s';

  static const cookieKeys = {
    'ltuid',
    'ltoken',
    'cookie_token',
    'account_id',
    'ltuid_v2',
    'ltoken_v2',
    'ltmid_v2',
    'account_id_v2',
    'account_mid_v2',
    'cookie_token_v2',
  };
  static const cookieUidKeys = ['ltuid', 'ltuid_v2', 'account_id_v2'];
  static const cookieTokenKeys = ['ltoken', 'ltoken_v2'];

  static const appVersion = '1.5.0';
  static const clientTypeGameRecord = '4';
  static const clientTypeCheckIn = '5';
  static const platformCheckIn = '5';
  static const gameRecordReferer = 'https://webstatic-sea.hoyolab.com/';
  static const actOrigin = 'https://act.hoyolab.com';
  static const actReferer = 'https://act.hoyolab.com/';

  static const mobileChromeUserAgent =
      'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) '
      'Chrome/124.0.0.0 Mobile Safari/537.36';

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
      headers: {
        'Referer': actReferer,
        'x-rpc-platform': platformCheckIn,
        'User-Agent': mobileChromeUserAgent,
      },
    ),
    Game.starRail: CheckInEndpoint(
      host: publicEventHost,
      basePath: '/event/luna/os',
      actId: 'e202303301540311',
      signGame: 'hkrpg',
      headers: {'Referer': gameRecordReferer},
    ),
    Game.zzz: CheckInEndpoint(
      host: publicEventHost,
      basePath: '/event/luna/zzz/os',
      actId: 'e202406031448091',
      signGame: 'zzz',
      headers: {
        'Origin': actOrigin,
        'Referer': actReferer,
        'x-rpc-client_type': clientTypeCheckIn,
        'x-rpc-platform': platformCheckIn,
      },
      paramsInBody: true,
      sendsTimestamp: true,
    ),
    Game.hi3: CheckInEndpoint(
      host: publicEventHost,
      basePath: '/event/mani',
      actId: 'e202110291205111',
      signGame: 'bh3',
      headers: {'Referer': gameRecordReferer},
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

  static const starRailReservedPowerMax = 2400;
  static const genshinTransformerCooldown = Duration(days: 7);

  static const checkInResetUtcOffset = Duration(hours: 8);
}
