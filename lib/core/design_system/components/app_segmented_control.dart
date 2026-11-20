import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_radius.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_spacing.dart';
import 'package:hoyo_aio/core/design_system/tokens/app_text_styles.dart';
import 'package:material_ui/material_ui.dart';

class SegmentOption<T> {
  const SegmentOption({required this.value, required this.label});

  final T value;
  final String label;
}

class AppSegmentedControl<T> extends StatelessWidget {
  const AppSegmentedControl({
    required this.options,
    required this.selected,
    required this.onChanged,
    this.expand = false,
    super.key,
  });

  static const double _hitHeight = 44;
  static const double _inset = 3;
  static const double _segmentHeight = 32;
  static const _selectedShadow = [
    BoxShadow(
      color: Color.fromRGBO(16, 24, 40, .12),
      offset: Offset(0, 1),
      blurRadius: 2,
    ),
  ];

  final List<SegmentOption<T>> options;
  final T selected;
  final ValueChanged<T>? onChanged;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final segments = [
      for (final option in options)
        _segment(context, option, option.value == selected),
    ];
    return SizedBox(
      height: _hitHeight,
      child: Center(
        widthFactor: 1,
        child: Container(
          padding: const EdgeInsets.all(_inset),
          decoration: BoxDecoration(
            color: colors.surface2,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            children: expand
                ? [for (final s in segments) Expanded(child: s)]
                : segments,
          ),
        ),
      ),
    );
  }

  Widget _segment(BuildContext context, SegmentOption<T> option, bool isOn) {
    final colors = context.colors;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: isOn,
      label: option.label,
      onTap: onChanged == null ? null : () => onChanged!(option.value),
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onChanged == null ? null : () => onChanged!(option.value),
        child: Container(
          height: _segmentHeight,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isOn ? colors.surface : null,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: isOn ? Border.all(color: colors.border2) : null,
            boxShadow: isOn ? _selectedShadow : null,
          ),
          child: Text(
            option.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.label.copyWith(
              color: isOn ? colors.text : colors.text2,
            ),
          ),
        ),
      ),
    );
  }
}
