import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:intl/intl.dart';

const codePayloadHost = 'code';

String codePayload(Game game, String code) => Uri(
  scheme: 'hoyoaio',
  host: codePayloadHost,
  queryParameters: {'game': game.name, 'code': code},
).toString();

(Game, String)? parseCodePayload(String? payload) {
  final uri = payload == null ? null : Uri.tryParse(payload);
  if (uri == null || uri.host != codePayloadHost) return null;
  final game = Game.values.asNameMap()[uri.queryParameters['game']];
  final code = uri.queryParameters['code'];
  if (game == null || code == null || code.isEmpty) return null;
  return (game, code);
}

extension CodeFormat on AppLocalizations {
  String codeRewards(List<int> rewards) => rewards.isEmpty
      ? codesNoRewardInfo
      : rewards
            .map(
              (amount) =>
                  '×${NumberFormat.decimalPattern(localeName).format(amount)}',
            )
            .join(' · ');
}
