import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../resource/theme/dimens.dart';
import '../../../routing/app_sections.dart';
import '../../../states/auth_provider.dart';
import '../../../states/menu_app_controller.dart';
import '../../../utils/responsive.dart';

class QuickActionsPanel extends StatelessWidget {
  const QuickActionsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final authProvider = context.watch<AuthProvider>();
    final acciones = authProvider.menuAcciones;
    final resolvedSections = resolveSectionsFromAcciones(acciones);
    final actions = acciones.isEmpty
        ? appSections
            .where((item) => item.section != AppSection.dashboard)
            .where(
              (item) =>
                  authProvider.isAdmin ||
                  (item.section != AppSection.usuarios &&
                      item.section != AppSection.empresas &&
                      item.section != AppSection.roles),
            )
            .toList()
        : resolvedSections
            .where((item) => item.section != AppSection.dashboard)
            .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Accesos rapidos',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: defaultPadding),
        Responsive(
          mobile: _QuickActionGrid(
            actions: actions,
            crossAxisCount: size.width < 650 ? 1 : 2,
            childAspectRatio: size.width < 650 ? 2.4 : 2.1,
          ),
          tablet: _QuickActionGrid(actions: actions),
          desktop: _QuickActionGrid(
            actions: actions,
            childAspectRatio: size.width < 1400 ? 1.8 : 2.3,
          ),
        ),
      ],
    );
  }
}

class _QuickActionGrid extends StatelessWidget {
  const _QuickActionGrid({
    required this.actions,
    this.crossAxisCount = 3,
    this.childAspectRatio = 1.8,
  });

  final List<AppSectionItem> actions;
  final int crossAxisCount;
  final double childAspectRatio;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: actions.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: defaultPadding,
        mainAxisSpacing: defaultPadding,
        childAspectRatio: childAspectRatio,
      ),
      itemBuilder: (context, index) {
        final item = actions[index];
        return _QuickActionCard(item: item);
      },
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({required this.item});

  final AppSectionItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = context.read<MenuAppController>();
    return InkWell(
      borderRadius: const BorderRadius.all(Radius.circular(12)),
      onTap: () => controller.setSection(item.section),
      child: Container(
        padding: const EdgeInsets.all(defaultPadding),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.all(Radius.circular(12)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(defaultPadding * 0.6),
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: item.color.withAlpha(26),
                borderRadius: const BorderRadius.all(Radius.circular(10)),
              ),
              child: SvgPicture.asset(
                item.icon,
                colorFilter: ColorFilter.mode(item.color, BlendMode.srcIn),
              ),
            ),
            const SizedBox(width: defaultPadding),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(153),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
