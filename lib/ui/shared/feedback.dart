import 'package:flutter/material.dart';

void showAppSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  final theme = Theme.of(context);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? theme.colorScheme.error : null,
    ),
  );
}

void showAppToast(
  BuildContext context,
  String message, {
  bool isError = false,
  Alignment alignment = Alignment.topRight,
  Duration duration = const Duration(seconds: 2),
}) {
  final overlay = Overlay.of(context);
  final theme = Theme.of(context);
  final entry = OverlayEntry(
    builder: (context) {
      return Positioned.fill(
        child: IgnorePointer(
          child: Align(
            alignment: alignment,
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: isError
                    ? theme.colorScheme.error
                    : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outline.withAlpha(140),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(38),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: DefaultTextStyle(
                style: theme.textTheme.bodyMedium!.copyWith(
                  color: isError
                      ? theme.colorScheme.onError
                      : theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
                child: Text(message),
              ),
            ),
          ),
        ),
      );
    },
  );
  overlay.insert(entry);
  Future.delayed(duration, entry.remove);
}
