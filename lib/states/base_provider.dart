import 'package:flutter/material.dart';

import '../services/api_client.dart';

class BaseProvider extends ChangeNotifier {
  bool isLoading = false;
  String? errorMessage;

  void setLoading(bool value) {
    if (isLoading == value) {
      return;
    }
    isLoading = value;
    notifyListeners();
  }

  void setError(String? message) {
    if (errorMessage == message) {
      return;
    }
    errorMessage = message;
    notifyListeners();
  }

  String resolveError(Object error) {
    if (error is ApiException) {
      return error.message;
    }
    final message = error.toString();
    if (message.contains('Failed to fetch')) {
      return 'No se pudo conectar al servidor. Revisa CORS/red en produccion.';
    }
    return message;
  }
}
