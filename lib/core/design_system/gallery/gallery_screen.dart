import 'package:hoyo_aio/core/design_system/components/app_toggle.dart';
import 'package:hoyo_aio/core/design_system/gallery/component_sections.dart';
import 'package:hoyo_aio/core/design_system/gallery/gallery_section.dart';
import 'package:hoyo_aio/core/design_system/gallery/token_sections.dart';
import 'package:hoyo_aio/core/design_system/theme/app_theme.dart';
import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:material_ui/material_ui.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  static const _largeTextScale = 1.3;

  var _dark = false;
  var _largeText = false;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _dark ? AppTheme.dark() : AppTheme.light(),
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(_largeText ? _largeTextScale : 1),
        ),
        child: Builder(
          builder: (context) => Scaffold(
            backgroundColor: context.colors.bg,
            body: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _header(context),
                  const Expanded(child: _GalleryBody()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final colors = context.colors;
    Widget switchLabel(String text) =>
        Text(text, style: AppTextStyles.label.copyWith(color: colors.text2));
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.s8,
        AppSpacing.gutter,
        AppSpacing.s8,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        spacing: AppSpacing.s8,
        children: [
          Expanded(
            child: Text(
              'Component Gallery',
              style: AppTextStyles.titleM.copyWith(color: colors.text),
            ),
          ),
          switchLabel('Dark'),
          AppToggle(
            value: _dark,
            onChanged: (v) => setState(() => _dark = v),
            semanticLabel: 'Dark theme',
          ),
          switchLabel('1.3×'),
          AppToggle(
            value: _largeText,
            onChanged: (v) => setState(() => _largeText = v),
            semanticLabel: 'Large text',
          ),
        ],
      ),
    );
  }
}

class _GalleryBody extends StatelessWidget {
  const _GalleryBody();

  @override
  Widget build(BuildContext context) {
    final sections = [...tokenSections(), ...componentSections()];
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.s20,
        AppSpacing.gutter,
        AppSpacing.s56,
      ),
      itemCount: sections.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s32),
      itemBuilder: (_, index) => sections[index],
    );
  }
}

GallerySection gallerySection(String title, List<Widget> children) =>
    GallerySection(title: title, children: children);
