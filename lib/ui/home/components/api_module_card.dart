import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../data/api/api_catalog.dart';
import '../../../domain/models/api_models.dart';
import '../../../resource/theme/dimens.dart';
import 'api_method_badge.dart';

class ApiModuleCard extends StatelessWidget {
  const ApiModuleCard({
    super.key,
    required this.module,
  });

  final ApiModule module;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final endpointShare = apiEndpointCount == 0
        ? 0
        : (module.endpointCount / apiEndpointCount);
    final sharePercent = (endpointShare * 100).round();

    return InkWell(
      borderRadius: const BorderRadius.all(Radius.circular(12)),
      onTap: () => _showModuleDialog(context),
      child: Container(
        padding: const EdgeInsets.all(defaultPadding),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.all(Radius.circular(12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(defaultPadding * 0.65),
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: module.color.withAlpha(26),
                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                  ),
                  child: SvgPicture.asset(
                    module.icon,
                    colorFilter:
                        ColorFilter.mode(module.color, BlendMode.srcIn),
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: module.color.withAlpha(26),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "${module.endpointCount} endpoints",
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: module.color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: defaultPadding),
            Text(
              module.title,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              module.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(153),
              ),
            ),
            const SizedBox(height: defaultPadding),
            _ProgressLine(
              color: module.color,
              percentage: sharePercent,
            ),
          ],
        ),
      ),
    );
  }

  void _showModuleDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          title: Text(module.title),
          content: SizedBox(
            width: 420,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: module.endpoints.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final endpoint = module.endpoints[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ApiMethodBadge(method: endpoint.method, compact: true),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            endpoint.title,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      endpoint.path,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withAlpha(153),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      endpoint.description,
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Accion: ${endpoint.actionLabel}",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withAlpha(153),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cerrar"),
            ),
          ],
        );
      },
    );
  }
}

class _ProgressLine extends StatelessWidget {
  const _ProgressLine({
    required this.color,
    required this.percentage,
  });

  final Color color;
  final int percentage;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: 5,
          decoration: BoxDecoration(
            color: color.withAlpha(26),
            borderRadius: const BorderRadius.all(Radius.circular(10)),
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) => Container(
            width: constraints.maxWidth * (percentage / 100),
            height: 5,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.all(Radius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }
}
