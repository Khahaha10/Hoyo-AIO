import 'package:hoyo_aio/core/hoyolab/game.dart';

Map<String, dynamic> ok(Object? data) => {
  'retcode': 0,
  'message': 'OK',
  'data': data,
};

Map<String, dynamic> retcode(int code, [String message = 'error']) => {
  'retcode': code,
  'message': message,
  'data': null,
};

const rewardNames = <Game, List<String>>{
  Game.genshin: ['Primogem', 'Mora', "Hero's Wit"],
  Game.starRail: ['Stellar Jade', 'Credit', "Traveler's Guide"],
  Game.zzz: ['Polychrome', 'Denny', 'Senior Investigator Logs'],
  Game.hi3: ['Crystal', 'Coin', 'Asterite'],
};

Map<String, dynamic> infoJson({
  int totalSignDay = 3,
  String today = '2026-11-05',
  bool isSign = false,
  Object signCntMissed = 1,
}) => {
  'total_sign_day': totalSignDay,
  'today': today,
  'is_sign': isSign,
  'sign_cnt_missed': signCntMissed,
  'first_bind': false,
  'region': 'os_asia',
};

Map<String, dynamic> homeJson(Game game, {int month = 11, int days = 30}) {
  final names = rewardNames[game] ?? const ['Reward'];
  return {
    'month': '$month',
    'awards': [
      for (var day = 1; day <= days; day++)
        {
          'icon': 'https://example.invalid/icon.png',
          'name': names[(day - 1) % names.length],
          'cnt': day * 10,
        },
    ],
    'resign': false,
  };
}

Map<String, dynamic> awardJson(List<(String, int, String)> records) => {
  'total': records.length,
  'list': [
    for (final (name, cnt, createdAt) in records)
      {
        'id': 1,
        'name': name,
        'cnt': '$cnt',
        'img': '',
        'created_at': createdAt,
      },
  ],
};

Map<String, dynamic> signJson({bool isRisk = false, bool? gtRisk}) => {
  'code': '',
  'risk_code': 0,
  'is_risk': isRisk,
  if (gtRisk != null) 'gt_result': {'is_risk': gtRisk, 'success': 0},
};
