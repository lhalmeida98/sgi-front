import 'package:flutter/material.dart';

import '../../../data/api/api_catalog.dart';
import '../../../domain/models/api_models.dart';
import '../../../resource/theme/dimens.dart';
import 'api_endpoint_dialog.dart';
import 'api_method_badge.dart';

class ApiOverviewPanel extends StatelessWidget {
  const ApiOverviewPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final quickEndpoints = _quickEndpoints();
    return Container(
      padding: const EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Entorno",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: defaultPadding),
          _InfoRow(label: "Base URL", value: apiBaseUrl),
          _InfoRow(label: "Modulos", value: apiModules.length.toString()),
          _InfoRow(label: "Endpoints", value: apiEndpointCount.toString()),
          const SizedBox(height: defaultPadding),
          Text(
            "Acciones rapidas",
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: defaultPadding / 2),
          Wrap(
            spacing: defaultPadding / 2,
            runSpacing: defaultPadding / 2,
            children: quickEndpoints
                .map(
                  (item) => OutlinedButton.icon(
                    onPressed: () => showApiEndpointDialog(
                      context: context,
                      moduleTitle: item.moduleTitle,
                      endpoint: item.endpoint,
                    ),
                    icon: ApiMethodBadge(
                      method: item.endpoint.method,
                      compact: true,
                    ),
                    label: Text(item.endpoint.title),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  List<_QuickEndpoint> _quickEndpoints() {
    return [
      _QuickEndpoint(
        moduleTitle: "Salud",
        endpoint: _findEndpoint("/api/ping"),
      ),
      _QuickEndpoint(
        moduleTitle: "Catalogos",
        endpoint: _findEndpoint("/api/productos"),
      ),
      _QuickEndpoint(
        moduleTitle: "Facturacion",
        endpoint: _findEndpoint(
          "/api/facturas/empresa/{empresaId}/en-proceso",
        ),
      ),
    ];
  }

  ApiEndpoint _findEndpoint(String path) {
    return apiEndpoints.firstWhere((endpoint) => endpoint.path == path);
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: defaultPadding / 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(153),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickEndpoint {
  const _QuickEndpoint({
    required this.moduleTitle,
    required this.endpoint,
  });

  final String moduleTitle;
  final ApiEndpoint endpoint;
}
