import 'package:hoyo_aio/features/home_widgets/domain/widget_snapshot.dart';

enum HomeWidgetSize { small, medium, large }

class PlacedWidget {
  const PlacedWidget({required this.widgetId, required this.size});

  final int widgetId;
  final HomeWidgetSize size;
}

abstract interface class WidgetConfigRepository {
  Future<List<WidgetConfigSnapshot>> all();

  Stream<List<WidgetConfigSnapshot>> watch();

  Future<void> save(WidgetConfigSnapshot config, {required String? accountId});
}

abstract interface class HomeWidgetBridge {
  Future<void> publish(WidgetSnapshot snapshot);

  Future<List<PlacedWidget>> placed();

  Future<bool> canPin();

  Future<void> pin(HomeWidgetSize size);
}
