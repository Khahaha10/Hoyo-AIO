import 'package:hoyo_aio/features/home_widgets/domain/widget_snapshot.dart';

abstract interface class WidgetConfigRepository {
  Future<List<WidgetConfigSnapshot>> all();
}

abstract interface class HomeWidgetBridge {
  Future<void> publish(WidgetSnapshot snapshot);
}
