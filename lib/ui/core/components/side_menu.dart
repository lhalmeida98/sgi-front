import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../routing/app_sections.dart';
import '../../../states/auth_provider.dart';
import '../../../states/menu_app_controller.dart';
import '../../../utils/responsive.dart';

class SideMenu extends StatelessWidget {
  const SideMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = context.watch<MenuAppController>();
    final authProvider = context.watch<AuthProvider>();
    final visibleSections = authProvider.isAdmin
        ? appSections
        : appSections
            .where((item) => item.section != AppSection.usuarios)
            .where((item) => item.section != AppSection.empresas)
            .where((item) => item.section != AppSection.roles)
            .toList();
    return Drawer(
      backgroundColor: theme.colorScheme.surface,
      child: ListView(
        children: [
          DrawerHeader(
            child: Image.asset("assets/images/logo.png"),
          ),
          for (final item in visibleSections)
            DrawerListTile(
              title: item.title,
              svgSrc: item.icon,
              selected: controller.activeSection == item.section,
              press: () {
                controller.setSection(item.section);
                if (!Responsive.isDesktop(context)) {
                  Navigator.of(context).pop();
                }
              },
            ),
        ],
      ),
    );
  }
}

class DrawerListTile extends StatelessWidget {
  const DrawerListTile({
    super.key,
    // For selecting those three line once press "Command+D"
    required this.title,
    required this.svgSrc,
    required this.press,
    required this.selected,
  });

  final String title, svgSrc;
  final VoidCallback press;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurfaceMuted =
        Theme.of(context).colorScheme.onSurface.withAlpha(179);
    final color = selected ? theme.colorScheme.primary : onSurfaceMuted;
    return ListTile(
      onTap: press,
      horizontalTitleGap: 0.0,
      selected: selected,
      selectedTileColor: theme.colorScheme.primary.withAlpha(26),
      leading: SvgPicture.asset(
        svgSrc,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        height: 16,
      ),
      title: Text(
        title,
        style: TextStyle(color: color),
      ),
    );
  }
}
