import 'package:flutter/material.dart';

import '../../../data/api/api_catalog.dart';
import '../../../domain/models/api_models.dart';
import '../../../resource/theme/dimens.dart';
import 'api_endpoint_dialog.dart';
import 'api_method_badge.dart';

class ApiEndpointsTable extends StatelessWidget {
  const ApiEndpointsTable({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "Endpoints disponibles",
                style: theme.textTheme.titleMedium,
              ),
              const Spacer(),
              Text(
                "$apiEndpointCount rutas",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha(153),
                ),
              ),
            ],
          ),
          const SizedBox(height: defaultPadding),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: defaultPadding,
              columns: const [
                DataColumn(label: Text("Modulo")),
                DataColumn(label: Text("Metodo")),
                DataColumn(label: Text("Endpoint")),
                DataColumn(label: Text("Accion")),
                DataColumn(label: Text("Detalle")),
              ],
              rows: _buildRows(context),
            ),
          ),
        ],
      ),
    );
  }

  List<DataRow> _buildRows(BuildContext context) {
    final rows = <DataRow>[];
    for (final module in apiModules) {
      for (final endpoint in module.endpoints) {
        rows.add(_buildRow(context, module.title, endpoint));
      }
    }
    return rows;
  }

  DataRow _buildRow(
    BuildContext context,
    String moduleTitle,
    ApiEndpoint endpoint,
  ) {
    return DataRow(
      cells: [
        DataCell(Text(moduleTitle)),
        DataCell(ApiMethodBadge(method: endpoint.method, compact: true)),
        DataCell(Text(endpoint.path)),
        DataCell(Text(endpoint.actionLabel)),
        DataCell(
          TextButton(
            onPressed: () => showApiEndpointDialog(
              context: context,
              moduleTitle: moduleTitle,
              endpoint: endpoint,
            ),
            child: const Text("Ver"),
          ),
        ),
      ],
    );
  }
}
