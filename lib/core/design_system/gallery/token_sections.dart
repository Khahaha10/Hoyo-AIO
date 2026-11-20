import 'package:hoyo_aio/core/design_system/gallery/gallery_section.dart';
import 'package:hoyo_aio/core/design_system/theme/extensions/app_colors.dart';
import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_radius.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:hoyo_aio/core/design_system/tokens/brand_colors.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:material_ui/material_ui.dart';

List<Widget> tokenSections() => const [
  GallerySection(title: 'Colors', children: [_ColorGrid()]),
  GallerySection(title: 'Game Accents', children: [_GameAccents()]),
  GallerySection(title: 'Typography', children: [_TypeScale()]),
  GallerySection(title: 'Spacing', children: [_SpacingScale()]),
  GallerySection(title: 'Radius', children: [_RadiusScale()]),
  GallerySection(title: 'Elevation', children: [_ElevationSamples()]),
];

List<(String, Color)> _namedColors(AppColors c) => [
  ('bg', c.bg),
  ('surface', c.surface),
  ('surface-2', c.surface2),
  ('surface-3', c.surface3),
  ('text', c.text),
  ('text-2', c.text2),
  ('text-3', c.text3),
  ('border', c.border),
  ('border-2', c.border2),
  ('success', c.success),
  ('success-bg', c.successBg),
  ('danger', c.danger),
  ('danger-bg', c.dangerBg),
  ('warning', c.warning),
  ('warning-bg', c.warningBg),
  ('inverse', c.inverse),
  ('lime', BrandColors.lime),
  ('ink', BrandColors.ink),
];

String _hex(Color c) =>
    '#${c.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';

class _Swatch extends StatelessWidget {
  const _Swatch({required this.name, required this.color});

  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      width: 100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.s4,
        children: [
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AppRadius.input),
              border: Border.all(color: colors.border2),
            ),
          ),
          Text(name, style: AppTextStyles.label.copyWith(color: colors.text)),
          Text(
            _hex(color),
            style: AppTextStyles.caption.copyWith(color: colors.text3),
          ),
        ],
      ),
    );
  }
}

class _ColorGrid extends StatelessWidget {
  const _ColorGrid();

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: AppSpacing.s12,
    runSpacing: AppSpacing.s16,
    children: [
      for (final (name, color) in _namedColors(context.colors))
        _Swatch(name: name, color: color),
    ],
  );
}

class _GameAccents extends StatelessWidget {
  const _GameAccents();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: AppSpacing.s16,
    children: [
      for (final game in Game.values)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.s8,
          children: [
            GalleryLabel(game.name),
            Wrap(
              spacing: AppSpacing.s12,
              runSpacing: AppSpacing.s12,
              children: [
                _Swatch(name: 'acc', color: context.gameAccent(game).acc),
                _Swatch(
                  name: 'acc-ink',
                  color: context.gameAccent(game).accInk,
                ),
                _Swatch(name: 'soft', color: context.gameAccent(game).soft),
              ],
            ),
          ],
        ),
    ],
  );
}

class _TypeScale extends StatelessWidget {
  const _TypeScale();

  @override
  Widget build(BuildContext context) {
    final color = context.colors.text;
    const styles = [
      ('display 34/38', AppTextStyles.display),
      ('headline 28/34', AppTextStyles.headline),
      ('title-l 22/28', AppTextStyles.titleL),
      ('title-m 17/22', AppTextStyles.titleM),
      ('body-l 16/24', AppTextStyles.bodyL),
      ('body-m 15/22', AppTextStyles.bodyM),
      ('label 13/18', AppTextStyles.label),
      ('caption 12/16', AppTextStyles.caption),
      ('overline 11/16', AppTextStyles.overline),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.s12,
      children: [
        for (final (name, style) in styles)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GalleryLabel(name),
              Text('Resin 142 / 200', style: style.copyWith(color: color)),
            ],
          ),
        Text(
          '1,840 · 0123456789',
          style: AppTextStyles.tabular(AppTextStyles.titleL)
              .copyWith(color: color),
        ),
      ],
    );
  }
}

class _SpacingScale extends StatelessWidget {
  const _SpacingScale();

  @override
  Widget build(BuildContext context) {
    const values = [
      AppSpacing.s4,
      AppSpacing.s8,
      AppSpacing.s12,
      AppSpacing.s16,
      AppSpacing.s20,
      AppSpacing.s24,
      AppSpacing.s32,
      AppSpacing.s40,
      AppSpacing.s56,
    ];
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.s8,
      children: [
        for (final v in values)
          Row(
            spacing: AppSpacing.s12,
            children: [
              SizedBox(
                width: 32,
                child: Text(
                  '${v.toInt()}',
                  style: AppTextStyles.label.copyWith(color: colors.text2),
                ),
              ),
              Container(
                width: v * 3,
                height: AppSpacing.s12,
                decoration: BoxDecoration(
                  color: BrandColors.lime,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _RadiusScale extends StatelessWidget {
  const _RadiusScale();

  @override
  Widget build(BuildContext context) {
    const values = [
      ('code', AppRadius.code),
      ('icon tile', AppRadius.iconTile),
      ('input', AppRadius.input),
      ('banner', AppRadius.banner),
      ('tile', AppRadius.tile),
      ('widget', AppRadius.widget),
      ('hero', AppRadius.hero),
      ('dialog', AppRadius.dialog),
      ('illustration', AppRadius.illustration),
    ];
    final colors = context.colors;
    return Wrap(
      spacing: AppSpacing.s12,
      runSpacing: AppSpacing.s12,
      children: [
        for (final (name, r) in values)
          Column(
            spacing: AppSpacing.s4,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(r),
                  border: Border.all(color: colors.border2),
                ),
              ),
              Text(
                '$name ${r.toInt()}',
                style: AppTextStyles.caption.copyWith(color: colors.text2),
              ),
            ],
          ),
      ],
    );
  }
}

class _ElevationSamples extends StatelessWidget {
  const _ElevationSamples();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    Widget sample(String name, List<BoxShadow> shadow) => Container(
      width: 140,
      height: 88,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.tile),
        border: Border.all(color: colors.border),
        boxShadow: shadow,
      ),
      child: Text(
        name,
        style: AppTextStyles.label.copyWith(color: colors.text),
      ),
    );
    return Wrap(
      spacing: AppSpacing.s20,
      runSpacing: AppSpacing.s20,
      children: [
        sample('flat', const []),
        sample('card', context.elevation.card),
        sample('dialog', context.elevation.dialog),
      ],
    );
  }
}
