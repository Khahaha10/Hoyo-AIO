import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoyo_aio/app/app_settings_provider.dart';
import 'package:hoyo_aio/app/flavor.dart';
import 'package:hoyo_aio/app/no_stretch_scroll_behavior.dart';
import 'package:hoyo_aio/app/router/app_router.dart';
import 'package:hoyo_aio/core/design_system/theme/app_theme.dart';
import 'package:hoyo_aio/core/design_system/theme/extensions/game_colors.dart';
import 'package:hoyo_aio/core/l10n/l10n.dart';
import 'package:hoyo_aio/features/accounts/presentation/providers/selected_role_provider.dart';
import 'package:hoyo_aio/features/notifications/presentation/notification_channels_sync.dart';
import 'package:material_ui/material_ui.dart';

class App extends ConsumerWidget {
  const App({required this.flavor, super.key});

  final Flavor flavor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences =
        ref.watch(appPreferencesProvider).value ?? AppPreferences.fallback;
    final game = ref.watch(selectedRoleProvider)?.game;
    final accent = switch (preferences.accent) {
      AppAccent.lime => null,
      AppAccent.neutral => AppAccent.neutralColor,
      AppAccent.match => game == null ? null : GameColors.light.of(game).acc,
    };
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        final useDynamic = preferences.dynamicColor;
        return MaterialApp.router(
          title: flavor.appTitle,
          debugShowCheckedModeBanner: flavor == Flavor.dev,
          theme: AppTheme.light(
            accent: accent,
            dynamicScheme: useDynamic ? lightDynamic : null,
          ),
          darkTheme: AppTheme.dark(
            accent: accent,
            dynamicScheme: useDynamic ? darkDynamic : null,
          ),
          themeMode: preferences.themeMode,
          locale: preferences.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          scrollBehavior: const NoStretchScrollBehavior(),
          builder: (_, child) =>
              NotificationChannelsSync(child: child ?? const SizedBox.shrink()),
          routerConfig: ref.watch(appRouterProvider),
        );
      },
    );
  }
}
