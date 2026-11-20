import 'package:material_ui/material_ui.dart';

enum AppIconSize {
  regular(20),
  inline(16),
  badge(14);

  const AppIconSize(this.pixels);

  final double pixels;
}

class AppIcon extends StatelessWidget {
  const AppIcon(
    this.icon, {
    this.size = AppIconSize.regular,
    this.color,
    super.key,
  });

  final IconData icon;
  final AppIconSize size;
  final Color? color;

  @override
  Widget build(BuildContext context) =>
      Icon(icon, size: size.pixels, color: color);
}
