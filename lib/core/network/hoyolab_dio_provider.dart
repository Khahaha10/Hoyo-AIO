import 'dart:async';

import 'package:dio/dio.dart';
import 'package:hoyo_aio/app/flavor_provider.dart';
import 'package:hoyo_aio/core/database/app_database.dart';
import 'package:hoyo_aio/core/logging/app_logger.dart';
import 'package:hoyo_aio/core/network/hoyolab_dio.dart';
import 'package:hoyo_aio/core/storage/cookie_vault.dart';
import 'package:hoyo_aio/core/storage/pending_cookies.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'hoyolab_dio_provider.g.dart';

@Riverpod(keepAlive: true)
Dio hoyolabDio(Ref ref) {
  final vault = ref.watch(cookieVaultProvider);
  final pending = ref.watch(pendingCookiesProvider);
  final logger = ref.watch(appLoggerProvider);
  final db = ref.watch(appDatabaseProvider);
  final dio = buildHoyolabDio(
    cookies: (accountId) async =>
        pending.read(accountId) ?? await vault.cookieHeader(accountId),
    log: logger.network,
    verboseLogging: ref.watch(flavorProvider).verboseLogging,
    onCookieExpired: (accountId) {
      if (PendingCookies.isPending(accountId)) return;
      unawaited(db.markAccountExpired(accountId));
    },
  );
  ref.onDispose(dio.close);
  return dio;
}
