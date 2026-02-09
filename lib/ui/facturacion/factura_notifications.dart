import 'dart:ui';

import 'package:flutter/material.dart';

enum FacturaNoticeVariant { processing, success, error, info }

class FacturaNoticeAction {
  const FacturaNoticeAction({
    required this.label,
    required this.onPressed,
    this.isPrimary = false,
    this.isDestructive = false,
    this.icon,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;
  final bool isDestructive;
  final IconData? icon;
}

Future<void> showFacturaNoticeDialog({
  required BuildContext context,
  required FacturaNoticeVariant variant,
  required String title,
  required String message,
  String? detail,
  String? statusLabel,
  Color? statusColor,
  List<FacturaNoticeAction> actions = const [],
  bool barrierDismissible = true,
}) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (dialogContext) {
      return _FacturaNoticeCard(
        variant: variant,
        title: title,
        message: message,
        detail: detail,
        statusLabel: statusLabel,
        statusColor: statusColor,
        actions: actions,
      );
    },
  );
}

void showFacturaProcessingDialog({
  required BuildContext context,
  required String title,
  required String message,
  String? detail,
}) {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return _FacturaNoticeCard(
        variant: FacturaNoticeVariant.processing,
        title: title,
        message: message,
        detail: detail,
      );
    },
  );
}

class _FacturaNoticeCard extends StatelessWidget {
  const _FacturaNoticeCard({
    required this.variant,
    required this.title,
    required this.message,
    this.detail,
    this.statusLabel,
    this.statusColor,
    this.actions = const [],
  });

  final FacturaNoticeVariant variant;
  final String title;
  final String message;
  final String? detail;
  final String? statusLabel;
  final Color? statusColor;
  final List<FacturaNoticeAction> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = _accentColor(theme, variant);
    final surface = theme.colorScheme.surface;
    final titleColor = (variant == FacturaNoticeVariant.success ||
            variant == FacturaNoticeVariant.error)
        ? accent
        : theme.colorScheme.onSurface;
    final gradient = LinearGradient(
      colors: [
        surface,
        Color.alphaBlend(accent.withAlpha(26), surface),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: theme.colorScheme.outline.withAlpha(120),
                ),
                boxShadow: [
                  BoxShadow(
                    color: accent.withAlpha(36),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: Colors.black.withAlpha(40),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _LeadingIcon(variant: variant, accent: accent),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: titleColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              message,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color:
                                    theme.colorScheme.onSurface.withAlpha(170),
                              ),
                            ),
                            if (detail != null &&
                                detail!.trim().isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                detail!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withAlpha(150),
                                ),
                              ),
                            ],
                            if (statusLabel != null) ...[
                              const SizedBox(height: 12),
                              _StatusPill(
                                label: statusLabel!,
                                color: statusColor ?? accent,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (actions.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 12,
                      runSpacing: 12,
                      children: actions
                          .map((action) => _buildAction(context, action))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAction(BuildContext context, FacturaNoticeAction action) {
    final theme = Theme.of(context);
    if (action.isPrimary) {
      final style = action.isDestructive
          ? FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            )
          : null;
      if (action.icon == null) {
        return FilledButton(
          onPressed: action.onPressed,
          style: style,
          child: Text(action.label),
        );
      }
      return FilledButton.icon(
        onPressed: action.onPressed,
        icon: Icon(action.icon),
        label: Text(action.label),
        style: style,
      );
    }
    if (action.isDestructive) {
      return OutlinedButton(
        onPressed: action.onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: theme.colorScheme.error,
          side: BorderSide(color: theme.colorScheme.error.withAlpha(160)),
        ),
        child: Text(action.label),
      );
    }
    if (action.icon == null) {
      return OutlinedButton(
        onPressed: action.onPressed,
        child: Text(action.label),
      );
    }
    return OutlinedButton.icon(
      onPressed: action.onPressed,
      icon: Icon(action.icon),
      label: Text(action.label),
    );
  }

  Color _accentColor(ThemeData theme, FacturaNoticeVariant variant) {
    switch (variant) {
      case FacturaNoticeVariant.success:
        return Colors.green;
      case FacturaNoticeVariant.error:
        return theme.colorScheme.error;
      case FacturaNoticeVariant.processing:
        return Colors.blue;
      case FacturaNoticeVariant.info:
      default:
        return theme.colorScheme.onSurface.withAlpha(140);
    }
  }
}

class _LeadingIcon extends StatelessWidget {
  const _LeadingIcon({
    required this.variant,
    required this.accent,
  });

  final FacturaNoticeVariant variant;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = Color.alphaBlend(accent.withAlpha(36), theme.colorScheme.surface);
    return Container(
      height: 52,
      width: 52,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withAlpha(120)),
      ),
      child: Center(
        child: _buildIcon(),
      ),
    );
  }

  Widget _buildIcon() {
    switch (variant) {
      case FacturaNoticeVariant.processing:
        return SizedBox(
          height: 26,
          width: 26,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(accent),
          ),
        );
      case FacturaNoticeVariant.success:
        return Icon(Icons.check_circle, color: accent, size: 30);
      case FacturaNoticeVariant.error:
        return Icon(Icons.error_rounded, color: accent, size: 30);
      case FacturaNoticeVariant.info:
      default:
        return Icon(Icons.cloud_upload_rounded, color: accent, size: 30);
    }
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = Color.alphaBlend(color.withAlpha(40), theme.colorScheme.surface);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(140)),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
