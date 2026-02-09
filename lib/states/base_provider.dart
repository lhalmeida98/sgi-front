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
    return error.toString();
  }
}
