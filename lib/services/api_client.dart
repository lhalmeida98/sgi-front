import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../config/api_config.dart';
import 'auth_session.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.details});

  final String message;
  final int? statusCode;
  final dynamic details;

  @override
  String toString() {
    if (statusCode == null) {
      return message;
    }
    return '$message (HTTP $statusCode)';
  }
}

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<dynamic> get(String path, {Map<String, String>? query}) async {
    final uri = _buildUri(path, query);
    final response = await _client.get(uri, headers: _simpleHeaders());
    return _process(response);
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    final uri = _buildUri(path);
    final response = await _client.post(
      uri,
      headers: _jsonHeaders(),
      body: jsonEncode(body ?? {}),
    );
    return _process(response);
  }

  Future<dynamic> put(String path, {Map<String, dynamic>? body}) async {
    final uri = _buildUri(path);
    final response = await _client.put(
      uri,
      headers: _jsonHeaders(),
      body: jsonEncode(body ?? {}),
    );
    return _process(response);
  }

  Future<dynamic> postMultipart(
    String path, {
    required List<int> bytes,
    required String filename,
    required Map<String, String> fields,
    String? contentType,
  }) async {
    final uri = _buildUri(path);
    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(_simpleHeaders());
    request.fields.addAll(fields);
    request.files.add(
      http.MultipartFile.fromBytes(
        'archivo',
        bytes,
        filename: filename,
        contentType: _resolveMediaType(contentType, filename),
      ),
    );
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    return _process(response);
  }

  Future<List<int>> getBytes(
    String path, {
    Map<String, String>? query,
  }) async {
    final uri = _buildUri(path, query);
    final response = await _client.get(uri, headers: _simpleHeaders());
    _ensureSuccess(response);
    return response.bodyBytes;
  }

  Uri _buildUri(String path, [Map<String, String>? query]) {
    final normalized = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse('${ApiConfig.baseUrl}$normalized');
    return query == null ? uri : uri.replace(queryParameters: query);
  }

  Map<String, String> _jsonHeaders() {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final authHeader = AuthSession.authHeader;
    if (authHeader != null) {
      headers['Authorization'] = authHeader;
    }
    return headers;
  }

  Map<String, String> _simpleHeaders() {
    final headers = {
      'Accept': 'application/json',
    };
    final authHeader = AuthSession.authHeader;
    if (authHeader != null) {
      headers['Authorization'] = authHeader;
    }
    return headers;
  }

  MediaType _resolveMediaType(String? contentType, String filename) {
    if (contentType != null && contentType.contains('/')) {
      final parts = contentType.split('/');
      return MediaType(parts.first, parts.last);
    }
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) {
      return MediaType('image', 'png');
    }
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return MediaType('image', 'jpeg');
    }
    if (lower.endsWith('.gif')) {
      return MediaType('image', 'gif');
    }
    if (lower.endsWith('.webp')) {
      return MediaType('image', 'webp');
    }
    if (lower.endsWith('.svg')) {
      return MediaType('image', 'svg+xml');
    }
    if (lower.endsWith('.p12')) {
      return MediaType('application', 'x-pkcs12');
    }
    return MediaType('application', 'octet-stream');
  }

  dynamic _process(http.Response response) {
    final statusCode = response.statusCode;
    final body = utf8.decode(response.bodyBytes);
    if (statusCode < 200 || statusCode >= 300) {
      throw ApiException(
        _extractErrorMessage(body) ?? 'Error en la solicitud',
        statusCode: statusCode,
        details: _decodeBody(body),
      );
    }
    if (body.isEmpty) {
      return null;
    }
    return _decodeBody(body);
  }

  void _ensureSuccess(http.Response response) {
    final statusCode = response.statusCode;
    if (statusCode < 200 || statusCode >= 300) {
      final body = utf8.decode(response.bodyBytes);
      throw ApiException(
        _extractErrorMessage(body) ?? 'Error en la solicitud',
        statusCode: statusCode,
        details: _decodeBody(body),
      );
    }
  }

  dynamic _decodeBody(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return body;
    }
  }

  String? _extractErrorMessage(String body) {
    final decoded = _decodeBody(body);
    if (decoded is Map) {
      final message = decoded['message'] ?? decoded['error'] ?? decoded['detalle'];
      if (message != null) {
        return message.toString();
      }
    }
    if (body.isNotEmpty) {
      return body;
    }
    return null;
  }
}
