import 'package:dio/dio.dart';
import 'package:hoyo_aio/app/flavor_provider.dart';
import 'package:hoyo_aio/core/logging/app_logger.dart';
import 'package:hoyo_aio/core/network/hoyolab_dio.dart';
import 'package:hoyo_aio/core/storage/cookie_vault.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'hoyolab_dio_provider.g.dart';

@Riverpod(keepAlive: true)
Dio hoyolabDio(Ref ref) {
  final vault = ref.watch(cookieVaultProvider);
  final logger = ref.watch(appLoggerProvider);
  final dio = buildHoyolabDio(
    cookies: vault.cookieHeader,
    log: logger.network,
    verboseLogging: ref.watch(flavorProvider).verboseLogging,
  );
  ref.onDispose(dio.close);
  return dio;
}
