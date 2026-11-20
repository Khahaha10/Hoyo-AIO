import 'package:hoyo_aio/core/design_system/components/pressable.dart';
import 'package:hoyo_aio/core/design_system/icons/app_icon.dart';
import 'package:hoyo_aio/core/design_system/theme/theme_context.dart';
import 'package:material_ui/material_ui.dart';

class AppIconButton extends StatelessWidget {
  const AppIconButton({
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    super.key,
  });

  static const double size = 44;

  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final enabled = onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel,
      onTap: onPressed,
      excludeSemantics: true,
      child: Pressable(
        onTap: onPressed,
        builder: (context, pressed) => Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: pressed ? colors.surface2 : colors.surface,
            border: Border.all(color: colors.border),
          ),
          child: AppIcon(icon, color: enabled ? colors.text : colors.text3),
        ),
      ),
    );
  }
}
