import 'dart:math' as math;

import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:hoyo_aio/core/design_system/tokens/widget_tokens.dart';
import 'package:hoyo_aio/features/home_widgets/domain/home_widget_repositories.dart';
import 'package:hoyo_aio/features/home_widgets/domain/widget_snapshot.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

class WidgetPreview extends StatelessWidget {
  const WidgetPreview({
    required this.snapshot,
    required this.size,
    required this.config,
    required this.now,
    this.roleId,
    super.key,
  });

  static const double cellWidth = 169;
  static const double smallHeight = 80;
  static const double largeWidth = 350;
  static const double _padding = 16;
  static const double _smallRing = 44;
  static const double _mediumRing = 52;
  static const double _ringStroke = 7;
  static const double _barHeight = 6;
  static const double _labelWidth = 72;
  static const double _dot = 8;
  static const double _gap = 8;
  static const double _rowPadding = 3;
  static const double _checkIcon = 14;
  static const double _smallValue = 20;
  static const double _mediumValue = 24;
  static const int _maxItems = 3;
  static const int _maxRoles = 3;

  final WidgetSnapshot snapshot;
  final HomeWidgetSize size;
  final WidgetConfigSnapshot? config;
  final DateTime now;
  final int? roleId;

  static Size sizeOf(HomeWidgetSize size) => switch (size) {
    HomeWidgetSize.small => const Size(cellWidth, smallHeight),
    HomeWidgetSize.medium => const Size(cellWidth, cellWidth),
    HomeWidgetSize.large => const Size(largeWidth, cellWidth),
  };

  @override
  Widget build(BuildContext context) {
    final role = _role();
    final style = _PreviewStyle.of(context, config);
    final dimensions = sizeOf(size);
    return Container(
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
          (HomeWidgetSize.large, _) => _large(style),
          (_, null) => const SizedBox.shrink(),
          (HomeWidgetSize.small, final role?) => _small(role, style),
          (HomeWidgetSize.medium, final role?) => _medium(role, style),
        },
      ),
    );
  }

  WidgetRoleSnapshot? _role() {
    final wanted = roleId ?? config?.roleId;
    return snapshot.roles.where((r) => r.roleId == wanted).firstOrNull ??
        snapshot.roles.firstOrNull;
  }

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

  double _progress(WidgetStamina stamina) =>
      stamina.max == 0 ? 0 : _current(stamina) / stamina.max;

  String _clock(DateTime at) => DateFormat.Hm().format(at.toLocal());

  String _number(int value) => NumberFormat.decimalPattern().format(value);

  String _full(WidgetStamina stamina) => _current(stamina) >= stamina.max
      ? _label('full')
      : '${_label('full')} ${_clock(stamina.fullAt)}';

  String _itemValue(WidgetItem item) {
    final doneAt = item.doneAt;
    final max = item.max ?? 0;
    final allBack = doneAt != null && !now.isBefore(doneAt);
    return switch (item.key) {
      'videoStore' when item.state != null => _label(
        'videoStore.${item.state}',
      ),
      'scratchCard' => item.state == 'done' ? _label('done') : '0/1',
      'realm' => _number(item.value ?? 0),
      'transformer' when doneAt == null || allBack => _label('ready'),
      'transformer' => _clock(doneAt ?? now),
      'expeditions' ||
      'assignments' => '${allBack ? max : item.value ?? 0}/$max',
      _ => '${item.value ?? 0}/$max',
    };
  }

  Widget _dotView(Color color) => Container(
    width: _dot,
    height: _dot,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );

  Widget _ring(
    WidgetStamina stamina,
    Color accent,
    _PreviewStyle style,
    double size,
  ) => CustomPaint(
    size: Size.square(size),
    painter: _RingPainter(
      progress: _progress(stamina),
      color: accent,
      track: style.track,
      stroke: _ringStroke,
    ),
  );

  Widget _small(WidgetRoleSnapshot role, _PreviewStyle style) => Row(
    spacing: _gap * 1.5,
    children: [
      _ring(role.stamina, style.accentFor(role.game.name), style, _smallRing),
      Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${_current(role.stamina)}',
                    style: TextStyle(
                      fontSize: _smallValue * style.scale,
                      fontWeight: FontWeight.w800,
                      color: style.text,
                    ),
                  ),
                  TextSpan(text: '/${role.stamina.max}'),
                ],
              ),
              maxLines: 1,
            ),
            Text(_full(role.stamina), maxLines: 1),
          ],
        ),
      ),
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
    final accent = style.accentFor(role.game.name);
    final strong = TextStyle(fontWeight: FontWeight.w700, color: style.text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          spacing: _gap * 0.75,
          children: [
            _dotView(accent),
            Expanded(
              child: Text(_label('game.${role.game.name}'), style: strong),
            ),
            Text(_clock(role.fetchedAt)),
          ],
        ),
        const Spacer(),
        Row(
          spacing: _gap * 1.25,
          children: [
            _ring(role.stamina, accent, style, _mediumRing),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_current(role.stamina)}',
                    style: TextStyle(
                      fontSize: _mediumValue * style.scale,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                      color: style.text,
                    ),
                  ),
                  Text(_full(role.stamina), maxLines: 1),
                ],
              ),
            ),
          ],
        ),
        const Spacer(),
        for (final item in items)
          Row(
            children: [
              Expanded(
                child: Text(
                  _label(item.key),
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(_itemValue(item), style: strong),
            ],
          ),
      ],
    );
  }

  Widget _large(_PreviewStyle style) {
    final latest = snapshot.roles.isEmpty
        ? snapshot.generatedAt
        : snapshot.roles
              .map((role) => role.fetchedAt)
              .reduce((a, b) => a.isAfter(b) ? a : b);
    final strong = TextStyle(fontWeight: FontWeight.w700, color: style.text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _label('app'),
                style: strong.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            Text(_label('updated').replaceAll('{time}', _clock(latest))),
          ],
        ),
        const SizedBox(height: _gap),
        for (final role in snapshot.roles.take(_maxRoles))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: _rowPadding),
            child: Row(
              spacing: _gap,
              children: [
                _dotView(style.accentFor(role.game.name)),
                SizedBox(
                  width: _labelWidth,
                  child: Text(
                    _label('short.${role.stamina.key}'),
                    maxLines: 1,
                    style: strong.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(_barHeight / 2),
                    child: LinearProgressIndicator(
                      value: _progress(role.stamina),
                      minHeight: _barHeight,
                      color: style.accentFor(role.game.name),
                      backgroundColor: style.track,
                    ),
                  ),
                ),
                Text(
                  '${_current(role.stamina)}/${role.stamina.max}',
                  style: strong,
                ),
              ],
            ),
          ),
        const Spacer(),
        if (snapshot.checkIn.total > 0)
          Row(
            spacing: _gap * 0.75,
            children: [
              Icon(LucideIcons.check, size: _checkIcon, color: style.success),
              Text(
                _label('checkedIn')
                    .replaceAll('{done}', '${snapshot.checkIn.done}')
                    .replaceAll('{total}', '${snapshot.checkIn.total}'),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: style.success,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.color,
    required this.track,
    required this.stroke,
  });

  final double progress;
  final Color color;
  final Color track;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final arc = (Offset.zero & size).deflate(stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawArc(arc, 0, math.pi * 2, false, paint..color = track)
      ..drawArc(
        arc,
        -math.pi / 2,
        math.pi * 2 * progress.clamp(0, 1),
        false,
        paint..color = color,
      );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color || old.track != track;
}

class _PreviewStyle {
  const _PreviewStyle({
    required this.background,
    required this.border,
    required this.text,
    required this.text2,
    required this.track,
    required this.success,
    required this.accent,
    required this.scale,
  });

  factory _PreviewStyle.of(BuildContext context, WidgetConfigSnapshot? config) {
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
      success: Color(palette['success'] ?? 0),
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
  final Color success;
  final Color? accent;
  final double scale;

  Color accentFor(String game) =>
      accent ?? Color(WidgetTokens.accents[game] ?? WidgetTokens.lime);
}
