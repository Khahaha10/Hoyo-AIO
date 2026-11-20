import 'package:hoyo_aio/core/design_system/components/app_badge.dart';
import 'package:hoyo_aio/core/design_system/components/app_checkbox.dart';
import 'package:hoyo_aio/core/design_system/components/app_segmented_control.dart';
import 'package:hoyo_aio/core/design_system/components/app_slider.dart';
import 'package:hoyo_aio/core/design_system/components/app_swatch_picker.dart';
import 'package:hoyo_aio/core/design_system/components/app_toggle.dart';
import 'package:hoyo_aio/core/design_system/components/game_switcher_chip.dart';
import 'package:hoyo_aio/core/design_system/components/radio_option_card.dart';
import 'package:hoyo_aio/core/design_system/gallery/gallery_section.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:hoyo_aio/core/design_system/tokens/brand_colors.dart';
import 'package:hoyo_aio/core/hoyolab/game.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

class ControlsDemo extends StatefulWidget {
  const ControlsDemo({super.key});

  @override
  State<ControlsDemo> createState() => _ControlsDemoState();
}

class _ControlsDemoState extends State<ControlsDemo> {
  static const _gameLabels = {
    Game.genshin: 'Genshin',
    Game.starRail: 'Star Rail',
    Game.zzz: 'ZZZ',
    Game.hi3: 'HI3',
  };

  var _game = Game.genshin;
  var _toggle = true;
  var _checkbox = true;
  var _threshold = 90.0;
  var _theme = 'system';
  var _accent = 'match';
  var _method = 0;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: AppSpacing.s12,
    children: [
      const GalleryLabel('Game switcher'),
      Wrap(
        spacing: AppSpacing.s8,
        children: [
          for (final MapEntry(key: game, value: label) in _gameLabels.entries)
            GameSwitcherChip(
              game: game,
              label: label,
              selected: _game == game,
              onTap: () => setState(() => _game = game),
            ),
        ],
      ),
      const GalleryLabel('Toggle · checkbox'),
      Wrap(
        spacing: AppSpacing.s12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          AppToggle(
            value: _toggle,
            onChanged: (v) => setState(() => _toggle = v),
            semanticLabel: 'Demo toggle',
          ),
          const AppToggle(
            value: true,
            onChanged: null,
            semanticLabel: 'Locked toggle',
          ),
          AppCheckbox(
            value: _checkbox,
            onChanged: (v) => setState(() => _checkbox = v),
            semanticLabel: 'Demo checkbox',
          ),
        ],
      ),
      GalleryLabel('Slider · ${_threshold.round()}%'),
      AppSlider(
        value: _threshold,
        min: 50,
        max: 100,
        onChanged: (v) => setState(() => _threshold = v),
        semanticLabel: 'Stamina threshold',
      ),
      const GalleryLabel('Segmented · swatches'),
      Align(
        alignment: Alignment.centerLeft,
        child: AppSegmentedControl<String>(
          options: const [
            SegmentOption(value: 'system', label: 'System'),
            SegmentOption(value: 'light', label: 'Light'),
            SegmentOption(value: 'dark', label: 'Dark'),
          ],
          selected: _theme,
          onChanged: (v) => setState(() => _theme = v),
        ),
      ),
      Align(
        alignment: Alignment.centerLeft,
        child: AppSwatchPicker<String>(
          options: const [
            SwatchOption(
              value: 'match',
              label: 'Match game',
              colors: [
                Color(0xFF4A90E2),
                Color(0xFF8B7CF6),
                Color(0xFFF5C518),
                Color(0xFFE94B6A),
              ],
            ),
            SwatchOption(
              value: 'lime',
              label: 'Lime',
              colors: [BrandColors.lime],
            ),
            SwatchOption(
              value: 'blue',
              label: 'Blue',
              colors: [Color(0xFF4A90E2)],
            ),
            SwatchOption(
              value: 'violet',
              label: 'Violet',
              colors: [Color(0xFF8B7CF6)],
            ),
          ],
          selected: _accent,
          onChanged: (v) => setState(() => _accent = v),
        ),
      ),
      const GalleryLabel('Radio option cards'),
      RadioOptionCard(
        title: 'Log In With HoYoLAB',
        subtitle: 'Sign in on the HoYoLAB page inside the app. We pick up the session cookie for you.',
        icon: LucideIcons.logIn,
        highlightIcon: true,
        badge: const AppBadge(label: 'Recommended'),
        selected: _method == 0,
        onTap: () => setState(() => _method = 0),
      ),
      RadioOptionCard(
        title: 'Paste Cookie',
        subtitle: 'For advanced users. Copy your cookie from a desktop browser and paste it here.',
        icon: LucideIcons.cookie,
        selected: _method == 1,
        onTap: () => setState(() => _method = 1),
      ),
    ],
  );
}
