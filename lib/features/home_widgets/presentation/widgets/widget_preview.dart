import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:hoyo_aio/core/design_system/tokens/widget_tokens.dart';
import 'package:hoyo_aio/features/home_widgets/domain/home_widget_repositories.dart';
import 'package:hoyo_aio/features/home_widgets/domain/widget_snapshot.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

class WidgetPreview extends StatelessWidget {
  const WidgetPreview({
    required this.snapshot,
    required this.size,
    required this.config,
    required this.now,
    super.key,
  });

  static const double cellUnit = 80;
  static const double _padding = 14;
  static const int _maxItems = 3;
  static const int _maxRoles = 3;

  final WidgetSnapshot snapshot;
  final HomeWidgetSize size;
  final WidgetConfigSnapshot? config;
  final DateTime now;

  static Size sizeOf(HomeWidgetSize size) => switch (size) {
    HomeWidgetSize.small => const Size(cellUnit * 2.1, cellUnit),
    HomeWidgetSize.medium => const Size(cellUnit * 2.1, cellUnit * 2.1),
    HomeWidgetSize.large => const Size(cellUnit * 4.4, cellUnit * 2.1),
  };

  @override
  Widget build(BuildContext context) {
    final role = _role();
    final style = _PreviewStyle.of(context, config, role?.game.name);
    final dimensions = sizeOf(size);
    return Semantics(
      container: true,
      child: Container(
        width: dimensions.width,
        height: dimensions.height,
        padding: const EdgeInsets.all(_padding),
        decoration: BoxDecoration(
          color: style.background,
          borderRadius: BorderRadius.circular(WidgetTokens.radius.toDouble()),
          border: Border.all(color: style.border),
        ),
        child: DefaultTextStyle(
          style: AppTextStyles.tabular(AppTextStyles.caption)
              .copyWith(color: style.text2, fontSize: 12 * style.scale),
          child: switch ((size, role)) {
            (_, null) => const SizedBox.shrink(),
            (HomeWidgetSize.small, final role?) => _small(role, style),
            (HomeWidgetSize.medium, final role?) => _medium(role, style),
            (HomeWidgetSize.large, _) => _large(style),
          },
        ),
      ),
    );
  }

  WidgetRoleSnapshot? _role() =>
      snapshot.roles.where((r) => r.roleId == config?.roleId).firstOrNull ??
      snapshot.roles.firstOrNull;

  String _label(String key) => snapshot.labels[key] ?? key;

  int _current(WidgetStamina stamina) {
    if (stamina.current >= stamina.max || !now.isAfter(stamina.fetchedAt)) {
      return stamina.current;
    }
    if (stamina.recoverySeconds <= 0) return stamina.current;
    final remaining = stamina.fullAt.difference(now).inSeconds;
    if (remaining <= 0) return stamina.max;
    final missing = (remaining / stamina.recoverySeconds).ceil();
    return (stamina.max - missing).clamp(stamina.current, stamina.max);
  }

  String _clock(DateTime at) => DateFormat.Hm().format(at.toLocal());

  String _full(WidgetStamina stamina) => _current(stamina) >= stamina.max
      ? _label('full')
      : '${_label('full')} ${_clock(stamina.fullAt)}';

  String _itemValue(WidgetItem item) {
    final doneAt = item.doneAt;
    return switch (item.key) {
      'videoStore' when item.state != null => _label(
        'videoStore.${item.state}',
      ),
      'scratchCard' => item.state == 'done' ? _label('done') : '0/1',
      'realm' => '${item.value ?? 0}/${item.max ?? 0}',
      _ when doneAt != null && !now.isBefore(doneAt) => _label(
        item.key == 'transformer' ? 'ready' : 'done',
      ),
      _ when doneAt != null => _clock(doneAt),
      _ => '${item.value ?? 0}/${item.max ?? 0}',
    };
  }

  Widget _header(WidgetRoleSnapshot role, _PreviewStyle style) => Row(
    children: [
      _dot(style.accentFor(role.game.name)),
      const SizedBox(width: 6),
      Text(
        _label('game.${role.game.name}'),
        style: TextStyle(fontWeight: FontWeight.w700, color: style.text2),
      ),
    ],
  );

  Widget _value(WidgetRoleSnapshot role, _PreviewStyle style, double size) =>
      Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '${_current(role.stamina)}',
              style: TextStyle(
                fontSize: size * style.scale,
                fontWeight: FontWeight.w700,
                color: style.text,
              ),
            ),
            TextSpan(text: '/${role.stamina.max}'),
          ],
        ),
      );

  Widget _bar(WidgetStamina stamina, Color accent, _PreviewStyle style) =>
      ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: LinearProgressIndicator(
          value: _current(stamina) / (stamina.max == 0 ? 1 : stamina.max),
          minHeight: 6,
          color: accent,
          backgroundColor: style.track,
        ),
      );

  Widget _small(WidgetRoleSnapshot role, _PreviewStyle style) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      _header(role, style),
      _value(role, style, 20),
      Text(_full(role.stamina), maxLines: 1),
    ],
  );

  Widget _medium(WidgetRoleSnapshot role, _PreviewStyle style) {
    final visible = config?.visibleItems ?? const [];
    final items = [
      if (visible.isEmpty)
        ...role.items
      else
        for (final key in visible) ...role.items.where((i) => i.key == key),
    ].take(_maxItems);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(role, style),
        const SizedBox(height: 4),
        _value(role, style, 24),
        _bar(role.stamina, style.accentFor(role.game.name), style),
        const SizedBox(height: 2),
        Text(_full(role.stamina), maxLines: 1),
        const Spacer(),
        for (final item in items)
          Row(
            children: [
              Expanded(child: Text(_label(item.key), maxLines: 1)),
              Text(
                _itemValue(item),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: style.text,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _large(_PreviewStyle style) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final role in snapshot.roles.take(_maxRoles)) ...[
        Row(
          children: [
            _dot(style.accentFor(role.game.name)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                _label(role.stamina.key),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: style.text,
                ),
              ),
            ),
            Text(
              '${_current(role.stamina)}/${role.stamina.max}  '
              '${_full(role.stamina)}',
            ),
          ],
        ),
        const SizedBox(height: 3),
        _bar(role.stamina, style.accentFor(role.game.name), style),
        const SizedBox(height: 6),
      ],
      const Spacer(),
      Text(
        _label('checkedIn')
            .replaceAll('{done}', '${snapshot.checkIn.done}')
            .replaceAll('{total}', '${snapshot.checkIn.total}'),
      ),
    ],
  );

  Widget _dot(Color color) => Container(
    width: 8,
    height: 8,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

class _PreviewStyle {
  const _PreviewStyle({
    required this.background,
    required this.border,
    required this.text,
    required this.text2,
    required this.track,
    required this.accent,
    required this.scale,
  });

  factory _PreviewStyle.of(
    BuildContext context,
    WidgetConfigSnapshot? config,
    String? game,
  ) {
    final theme = switch (config?.theme) {
      final theme? when WidgetTokens.themes.containsKey(theme) => theme,
      _ =>
        MediaQuery.platformBrightnessOf(context) == Brightness.dark
            ? 'dark'
            : 'light',
    };
    final palette =
        WidgetTokens.themes[theme] ?? WidgetTokens.themes.values.first;
    final background = Color(palette['background'] ?? 0);
    final accent = switch (config?.accent ?? 'match') {
      'match' => null,
      'lime' => const Color(WidgetTokens.lime),
      'neutral' => Color(palette['text2'] ?? 0),
      final key =>
        WidgetTokens.accents[key] == null
            ? null
            : Color(WidgetTokens.accents[key] ?? 0),
    };
    return _PreviewStyle(
      background: config == null
          ? background
          : background.withValues(alpha: background.a * config.opacity),
      border: Color(palette['border'] ?? 0),
      text: Color(palette['text'] ?? 0),
      text2: Color(palette['text2'] ?? 0),
      track: Color(palette['track'] ?? 0),
      accent: accent,
      scale: switch (config?.fontSize) {
        'small' => 0.9,
        'large' => 1.15,
        _ => 1,
      },
    );
  }

  final Color background;
  final Color border;
  final Color text;
  final Color text2;
  final Color track;
  final Color? accent;
  final double scale;

  Color accentFor(String game) =>
      accent ?? Color(WidgetTokens.accents[game] ?? WidgetTokens.lime);
}
