import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'pending_cookies.g.dart';

class PendingCookies {
  static const idPrefix = 'pending:';

  static String idFor(String hoyolabUid) => '$idPrefix$hoyolabUid';

  static bool isPending(String accountId) => accountId.startsWith(idPrefix);

  final _cookies = <String, String>{};

  String? read(String accountId) => _cookies[accountId];

  void put(String accountId, String cookieHeader) =>
      _cookies[accountId] = cookieHeader;

  void remove(String accountId) => _cookies.remove(accountId);
}

@Riverpod(keepAlive: true)
PendingCookies pendingCookies(Ref ref) => PendingCookies();
