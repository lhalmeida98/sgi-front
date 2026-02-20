import 'package:flutter/material.dart';

import '../../../domain/models/api_models.dart';

class ApiMethodBadge extends StatelessWidget {
  const ApiMethodBadge({
    super.key,
    required this.method,
    this.compact = false,
  });

  final ApiMethod method;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = _methodColor(method);
    final textStyle = Theme.of(context).textTheme.labelSmall;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        _methodLabel(method),
        style: textStyle?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Color _methodColor(ApiMethod method) {
    switch (method) {
      case ApiMethod.get:
        return const Color(0xFF2E7D32);
      case ApiMethod.post:
        return const Color(0xFFF57C00);
      case ApiMethod.patch:
        return const Color(0xFF1976D2);
    }
  }

  String _methodLabel(ApiMethod method) {
    switch (method) {
      case ApiMethod.get:
        return 'GET';
      case ApiMethod.post:
        return 'POST';
      case ApiMethod.patch:
        return 'PATCH';
    }
  }
}
