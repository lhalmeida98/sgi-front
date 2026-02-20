import 'package:flutter/material.dart';

enum ApiMethod { get, post, patch }

class ApiEndpoint {
  const ApiEndpoint({
    required this.method,
    required this.path,
    required this.title,
    required this.description,
    required this.actionLabel,
    this.payload,
    this.contentType,
  });

  final ApiMethod method;
  final String path;
  final String title;
  final String description;
  final String actionLabel;
  final String? payload;
  final String? contentType;

  bool get hasPayload => payload != null && payload!.trim().isNotEmpty;
}

class ApiModule {
  const ApiModule({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.endpoints,
  });

  final String title;
  final String description;
  final String icon;
  final Color color;
  final List<ApiEndpoint> endpoints;

  int get endpointCount => endpoints.length;
}
