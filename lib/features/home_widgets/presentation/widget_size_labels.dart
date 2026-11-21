import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/features/home_widgets/domain/home_widget_repositories.dart';

extension WidgetSizeLabels on AppLocalizations {
  String widgetSizeName(HomeWidgetSize size) => switch (size) {
    HomeWidgetSize.small => widgetsSmall,
    HomeWidgetSize.medium => widgetsMedium,
    HomeWidgetSize.large => widgetsLarge,
  };

  String widgetSizeTitle(HomeWidgetSize size) => switch (size) {
    HomeWidgetSize.small => widgetsSmallTitle,
    HomeWidgetSize.medium => widgetsMediumTitle,
    HomeWidgetSize.large => widgetsLargeTitle,
  };

  String widgetAccentName(String accent) => switch (accent) {
    'match' => widgetAccentMatch,
    'lime' => widgetAccentLime,
    'genshin' => widgetAccentBlue,
    'starRail' => widgetAccentViolet,
    _ => widgetAccentNeutral,
  };

  String widgetSizeContent(HomeWidgetSize size) => switch (size) {
    HomeWidgetSize.small => widgetsSmallContent,
    HomeWidgetSize.medium => widgetsMediumContent,
    HomeWidgetSize.large => widgetsLargeContent,
  };
}
