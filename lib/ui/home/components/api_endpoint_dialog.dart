import 'package:flutter/material.dart';

import '../../../data/api/api_catalog.dart';
import '../../../domain/models/api_models.dart';
import 'api_method_badge.dart';

void showApiEndpointDialog({
  required BuildContext context,
  required String moduleTitle,
  required ApiEndpoint endpoint,
}) {
  showDialog(
    context: context,
    builder: (context) {
      final theme = Theme.of(context);
      final payloadText = endpoint.payload?.trim();
      final usesBody = endpoint.method == ApiMethod.post ||
          endpoint.method == ApiMethod.patch;
      final contentType = endpoint.contentType ??
          ((usesBody && endpoint.hasPayload) ? "application/json" : "N/A");
      return AlertDialog(
        title: Text(endpoint.title),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ApiMethodBadge(method: endpoint.method, compact: true),
                    Text(moduleTitle, style: theme.textTheme.bodySmall),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  "${apiBaseUrl}${endpoint.path}",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  endpoint.description,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                Text(
                  "Content-Type",
                  style: theme.textTheme.labelSmall,
                ),
                Text(
                  contentType,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Payload de ejemplo",
                  style: theme.textTheme.labelSmall,
                ),
                const SizedBox(height: 6),
                if (payloadText != null && payloadText.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withAlpha(10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SelectableText(
                      payloadText,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: "monospace",
                      ),
                    ),
                  )
                else
                  Text(
                    "Sin payload",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(153),
                    ),
                  ),
              ],
            ),
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
