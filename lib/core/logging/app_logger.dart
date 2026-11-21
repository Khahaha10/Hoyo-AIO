import 'package:hoyo_aio/app/flavor_provider.dart';
import 'package:hoyo_aio/core/logging/redactor.dart';
import 'package:logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_logger.g.dart';

class AppLogger {
  AppLogger({required bool verbose, LogOutput? output})
    : _logger = Logger(
        filter: _ThresholdFilter(verbose ? Level.debug : Level.warning),
        printer: _RedactingPrinter(SimplePrinter(colors: false)),
        output: output ?? ConsoleOutput(),
      );

  final Logger _logger;

  void debug(String message) => _logger.d(message);

  void info(String message) => _logger.i(message);

  void warning(String message) => _logger.w(message);

  void error(String message, [Object? error]) =>
      _logger.e(message, error: error?.runtimeType);

  void network(String message, {bool isError = false}) =>
      isError ? warning(message) : debug(message);
}

class _ThresholdFilter extends LogFilter {
  _ThresholdFilter(this.threshold);

  final Level threshold;

  @override
  bool shouldLog(LogEvent event) => event.level.value >= threshold.value;
}

class _RedactingPrinter extends LogPrinter {
  _RedactingPrinter(this._inner);

  final LogPrinter _inner;

  @override
  List<String> log(LogEvent event) => _inner
      .log(
        LogEvent(
          event.level,
          Redactor.redact('${event.message}'),
          time: event.time,
          error: event.error == null ? null : Redactor.redact('${event.error}'),
        ),
      )
      .map(Redactor.redact)
      .toList();
}

@Riverpod(keepAlive: true)
AppLogger appLogger(Ref ref) =>
    AppLogger(verbose: ref.watch(flavorProvider).verboseLogging);
