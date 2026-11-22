import 'package:cached_network_image/cached_network_image.dart';
import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:hoyo_aio/core/design_system/tokens/brand_colors.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:hoyo_aio/core/hoyolab/hoyolab_config.dart';
import 'package:hoyo_aio/features/databook/presentation/chronicle_colors.dart';
import 'package:material_ui/material_ui.dart';

class ChronicleAvatar extends StatelessWidget {
  const ChronicleAvatar({
    required this.name,
    required this.element,
    this.imageUrl,
    this.rarity,
    this.size = 42,
    this.cornerRadius,
    super.key,
  });

  static const _fade = Duration(milliseconds: 150);
  static const _tintAlpha = 0.15;
  static const _initialScale = 0.4;

  final String name;
  final String? element;
  final String? imageUrl;
  final int? rarity;
  final double size;
  final double? cornerRadius;

  static Widget _clip(double? radius, Widget child) => radius == null
      ? ClipOval(child: child)
      : ClipRRect(borderRadius: BorderRadius.circular(radius), child: child);

  static bool isAllowedImage(String? url) {
    final uri = url == null ? null : Uri.tryParse(url);
    return uri != null &&
        uri.scheme == 'https' &&
        HoyolabConfig.chronicleImageHosts.contains(uri.host);
  }

  @override
  Widget build(BuildContext context) {
    final fallback = _Initial(
      name: name,
      color: chronicleElementColor(element),
      size: size,
      fontSize: size * _initialScale,
    );
    final url = imageUrl;
    final rarityTint = switch (rarity) {
      5 => context.colors.warning,
      4 => context.gameAccent(Game.starRail).acc,
      _ => context.colors.surface3,
    };
    final radius = cornerRadius;
    final shape = radius == null ? BoxShape.circle : BoxShape.rectangle;
    return Semantics(
      image: true,
      label: name,
      excludeSemantics: true,
      child: SizedBox(
        width: size,
        height: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: shape,
            borderRadius: radius == null ? null : BorderRadius.circular(radius),
            color: rarityTint.withValues(alpha: _tintAlpha),
          ),
          child: _clip(
            radius,
            isAllowedImage(url)
                ? CachedNetworkImage(
                    imageUrl: url!,
                    width: size,
                    height: size,
                    fit: radius == null ? BoxFit.cover : BoxFit.contain,
                    fadeInDuration: _fade,
                    fadeOutDuration: _fade,
                    placeholder: (_, _) => fallback,
                    errorWidget: (_, _, _) => fallback,
                  )
                : fallback,
          ),
        ),
      ),
    );
  }
}

class _Initial extends StatelessWidget {
  const _Initial({
    required this.name,
    required this.color,
    required this.size,
    required this.fontSize,
  });

  final String name;
  final Color color;
  final double size;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final initial = name.isEmpty
        ? '?'
        : String.fromCharCode(name.runes.first).toUpperCase();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      color: color,
      child: Text(
        initial,
        style: AppTextStyles.bodyL.copyWith(
          color: BrandColors.ink,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
