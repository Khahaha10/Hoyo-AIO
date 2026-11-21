@Tags(['golden'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:hoyo_aio/core/design_system/theme/app_theme.dart';
import 'package:hoyo_aio/features/home_widgets/domain/home_widget_repositories.dart';
import 'package:hoyo_aio/features/home_widgets/presentation/widgets/widget_preview.dart';
import 'package:material_ui/material_ui.dart';

import '../features/home_widgets/_support/widget_fixtures.dart';
import '../features/home_widgets/_support/widget_overrides.dart';

class _Sheet extends StatelessWidget {
  const _Sheet({required this.theme});

  final String theme;

  @override
  Widget build(BuildContext context) {
    final snapshot = previewSnapshot();
    WidgetPreview preview(HomeWidgetSize size, {int roleId = 1}) =>
        WidgetPreview(
          snapshot: snapshot,
          size: size,
          config: config(size: size.name, roleId: roleId, theme: theme),
          now: widgetNow,
        );
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFFA9C4E8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 12,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 12,
            children: [
              preview(HomeWidgetSize.small),
              preview(HomeWidgetSize.small, roleId: 3),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 12,
            children: [
              preview(HomeWidgetSize.medium),
              preview(HomeWidgetSize.medium, roleId: 2),
            ],
          ),
          preview(HomeWidgetSize.large),
        ],
      ),
    );
  }
}

void main() {
  for (final theme in ['light', 'dark']) {
    testWidgets('widget previews ($theme)', (tester) async {
      tester.view
        ..physicalSize = const Size(420, 560)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: theme == 'dark' ? AppTheme.dark() : AppTheme.light(),
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: Center(child: _Sheet(theme: theme)),
          ),
        ),
      );

      await expectLater(
        find.byType(_Sheet),
        matchesGoldenFile('widget_preview_$theme.png'),
      );
    });
  }
}
