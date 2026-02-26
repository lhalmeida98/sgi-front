import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../domain/models/menu_accion.dart';
import '../../../routing/app_sections.dart';
import '../../../states/auth_provider.dart';
import '../../../states/menu_app_controller.dart';
import '../../../utils/app_responsive.dart';
import 'side_menu_layout_tokens.dart';

class SideMenu extends StatelessWidget {
  const SideMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = context.watch<MenuAppController>();
    final authProvider = context.watch<AuthProvider>();
    final responsive = AppResponsive.of(context);
    final tokens = SideMenuLayoutTokens.fromResponsive(responsive);
    final isCollapsed = responsive.isDesktop && controller.isMenuCollapsed;
    final acciones = authProvider.menuAcciones
        .where((accion) => accion.activo ?? true)
        .toList();
    final menuAcciones = _withAdminExtras(
      acciones,
      include: authProvider.isAdmin,
    );
    return Drawer(
      backgroundColor: theme.colorScheme.surface,
      child: Column(
        children: [
          _SideMenuHeader(
            isCollapsed: isCollapsed,
            tokens: tokens,
            isDesktop: responsive.isDesktop,
          ),
          Expanded(
            child: ListView(
              children: _buildGroupedMenu(
                context,
                acciones: menuAcciones,
                isCollapsed: isCollapsed,
                tokens: tokens,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

List<MenuAccion> _withAdminExtras(
  List<MenuAccion> acciones, {
  required bool include,
}) {
  if (!include) {
    return acciones;
  }
  final items = List<MenuAccion>.from(acciones);
  final adminSections = appSections.where(
    (item) =>
        item.section == AppSection.usuarios || item.section == AppSection.roles,
  );
  for (final section in adminSections) {
    final exists = items.any(section.matchesAccion);
    if (!exists) {
      items.add(
        MenuAccion(
          nombre: section.title,
          descripcion: section.description,
          url: section.codigo,
          icono: '',
          tipo: section.tipo,
          activo: true,
        ),
      );
    }
  }
  return items;
}

List<Widget> _buildGroupedMenu(
  BuildContext context, {
  required List<MenuAccion> acciones,
  required bool isCollapsed,
  required SideMenuLayoutTokens tokens,
}) {
  final controller = context.watch<MenuAppController>();
  final isDesktop = AppResponsive.of(context).isDesktop;
  final resolvedAcciones = acciones
      .where((accion) => resolveSectionForAccion(accion) != null)
      .toList();
  final grouped = <String, List<MenuAccion>>{};
  for (final accion in resolvedAcciones) {
    final matched = resolveSectionForAccion(accion);
    final tipo = accion.tipo.trim().isNotEmpty
        ? accion.tipo.trim()
        : (matched?.tipo.isNotEmpty ?? false)
            ? matched!.tipo
            : 'Otros';
    grouped.putIfAbsent(tipo, () => []).add(accion);
  }

  final widgets = <Widget>[];
  for (final entry in grouped.entries) {
    if (!isCollapsed) {
      widgets.add(_MenuGroupHeader(title: entry.key, tokens: tokens));
    } else {
      widgets.add(SizedBox(height: tokens.collapsedGroupSpacer));
    }
    for (final accion in entry.value) {
      final matched = resolveSectionForAccion(accion);
      widgets.add(
        DrawerListTile(
          title: accion.nombre,
          svgSrc: matched?.icon,
          icon: matched == null ? Icons.circle_outlined : null,
          selected:
              matched != null && controller.activeSection == matched.section,
          isCollapsed: isCollapsed,
          tokens: tokens,
          enabled: matched != null,
          press: matched == null
              ? null
              : () {
                  controller.setSection(matched.section);
                  if (!isDesktop) {
                    Navigator.of(context).pop();
                  }
                },
        ),
      );
    }
  }
  return widgets;
}

class _MenuGroupHeader extends StatelessWidget {
  const _MenuGroupHeader({
    required this.title,
    required this.tokens,
  });

  final String title;
  final SideMenuLayoutTokens tokens;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        tokens.groupHeaderHorizontalPadding,
        tokens.groupHeaderTopPadding,
        tokens.groupHeaderHorizontalPadding,
        tokens.groupHeaderBottomPadding,
      ),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurface.withAlpha(140),
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _SideMenuHeader extends StatelessWidget {
  const _SideMenuHeader({
    required this.isCollapsed,
    required this.tokens,
    required this.isDesktop,
  });

  final bool isCollapsed;
  final SideMenuLayoutTokens tokens;
  final bool isDesktop;

  Widget _buildLogo() {
    const asset = 'assets/images/LogoVuala.png';
    final alignment = isCollapsed ? Alignment.center : Alignment.centerLeft;
    final logoHeight = tokens.logoHeight(isCollapsed);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: Align(
        key: ValueKey(isCollapsed),
        alignment: alignment,
        child: SizedBox(
          height: logoHeight,
          child: Image.asset(
            asset,
            fit: BoxFit.contain,
            alignment: alignment,
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = context.read<MenuAppController>();
    return Container(
      height: tokens.headerHeight(isCollapsed),
      padding: EdgeInsets.symmetric(
        horizontal: tokens.headerHorizontalPadding(isCollapsed),
      ),
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
                _buildLogo(),
                if (!isCollapsed) ...[
                  SizedBox(width: tokens.logoTextGap),
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
          if (isDesktop)
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
    this.svgSrc,
    this.icon,
    this.press,
    required this.selected,
    required this.isCollapsed,
    required this.tokens,
    this.enabled = true,
  });

  final String title;
  final String? svgSrc;
  final IconData? icon;
  final VoidCallback? press;
  final bool selected;
  final bool isCollapsed;
  final SideMenuLayoutTokens tokens;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurfaceMuted =
        Theme.of(context).colorScheme.onSurface.withAlpha(179);
    final mutedColor =
        enabled ? onSurfaceMuted : theme.colorScheme.onSurface.withAlpha(90);
    final color = selected ? theme.colorScheme.primary : mutedColor;
    final tile = ListTile(
      onTap: enabled ? press : null,
      horizontalTitleGap: tokens.tileTitleGap(isCollapsed),
      contentPadding: EdgeInsets.symmetric(
        horizontal: tokens.tileHorizontalPadding(isCollapsed),
      ),
      selected: selected,
      selectedTileColor: theme.colorScheme.primary.withAlpha(26),
      leading: svgSrc != null
          ? SvgPicture.asset(
              svgSrc!,
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
              height: tokens.tileIconSize,
            )
          : Icon(
              icon ?? Icons.circle,
              color: color,
              size: tokens.tileIconSize,
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
