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
    final isCollapsed =
        Responsive.isDesktop(context) && controller.isMenuCollapsed;
    final visibleSections = authProvider.isAdmin
        ? appSections
        : appSections
            .where((item) => item.section != AppSection.usuarios)
            .where((item) => item.section != AppSection.empresas)
            .where((item) => item.section != AppSection.roles)
            .toList();
    return Drawer(
      backgroundColor: theme.colorScheme.surface,
      child: Column(
        children: [
          _SideMenuHeader(isCollapsed: isCollapsed),
          Expanded(
            child: ListView(
              children: [
                for (final item in visibleSections)
                  DrawerListTile(
                    title: item.title,
                    svgSrc: item.icon,
                    selected: controller.activeSection == item.section,
                    isCollapsed: isCollapsed,
                    press: () {
                      controller.setSection(item.section);
                      if (!Responsive.isDesktop(context)) {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SideMenuHeader extends StatelessWidget {
  const _SideMenuHeader({required this.isCollapsed});

  final bool isCollapsed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = context.read<MenuAppController>();
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outline.withAlpha(90)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Image.asset(
                  "assets/images/logo.png",
                  height: 36,
                ),
                if (!isCollapsed) ...[
                  const SizedBox(width: 10),
                  /* Text(
                    "Inicio",
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ), */
                ],
              ],
            ),
          ),
          if (Responsive.isDesktop(context))
            IconButton(
              tooltip: isCollapsed ? 'Expandir menu' : 'Contraer menu',
              onPressed: controller.toggleMenuCollapsed,
              icon: Icon(
                isCollapsed ? Icons.chevron_right : Icons.chevron_left,
              ),
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
    required this.isCollapsed,
  });

  final String title, svgSrc;
  final VoidCallback press;
  final bool selected;
  final bool isCollapsed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurfaceMuted =
        Theme.of(context).colorScheme.onSurface.withAlpha(179);
    final color = selected ? theme.colorScheme.primary : onSurfaceMuted;
    final tile = ListTile(
      onTap: press,
      horizontalTitleGap: isCollapsed ? 0.0 : 12.0,
      contentPadding: EdgeInsets.symmetric(horizontal: isCollapsed ? 14 : 16),
      selected: selected,
      selectedTileColor: theme.colorScheme.primary.withAlpha(26),
      leading: SvgPicture.asset(
        svgSrc,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        height: 16,
      ),
      title: isCollapsed
          ? null
          : Text(
              title,
              style: TextStyle(color: color),
            ),
    );
    if (!isCollapsed) {
      return tile;
    }
    return Tooltip(message: title, child: tile);
  }
}
