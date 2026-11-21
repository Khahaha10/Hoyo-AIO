import 'package:hoyo_aio/app/flavor.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'flavor_provider.g.dart';

@Riverpod(keepAlive: true)
Flavor flavor(Ref ref) => throw StateError('flavorProvider must be overridden');
