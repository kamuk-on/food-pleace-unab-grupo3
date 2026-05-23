// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_environment.dart';
import 'api_exception.dart';

typedef TokenProvider = Future<String?> Function();

class ApiClient {
  ApiClient({
    http.Client? httpClient,
    AppEnvironment? environment,
    TokenProvider? tokenProvider,
  }) : _httpClient = httpClient ?? http.Client(),
       _environment = environment ?? AppEnvironmentX.current,
       _tokenProvider = tokenProvider;

  final http.Client _httpClient;
  final AppEnvironment _environment;
  final TokenProvider? _tokenProvider;

  Uri resolve(String path, [Map<String, String>? queryParameters]) {
    final Uri baseUri = Uri.parse(_environment.baseUrl);
    return baseUri.replace(
      path: _joinPaths(baseUri.path, path),
      queryParameters: queryParameters,
    );
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? queryParameters,
    bool authenticated = false,
  }) async {
    final http.Response response = await _send(
      () async => _httpClient.get(
        resolve(path, queryParameters),
        headers: await _buildHeaders(authenticated: authenticated),
      ),
    );
    return _decodeJsonObject(response);
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = false,
  }) async {
    final http.Response response = await _send(
      () async => _httpClient.post(
        resolve(path),
        headers: await _buildHeaders(authenticated: authenticated),
        body: jsonEncode(body ?? const <String, dynamic>{}),
      ),
    );
    return _decodeJsonObject(response);
  }

  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = false,
  }) async {
    final http.Response response = await _send(
      () async => _httpClient.put(
        resolve(path),
        headers: await _buildHeaders(authenticated: authenticated),
        body: jsonEncode(body ?? const <String, dynamic>{}),
      ),
    );
    return _decodeJsonObject(response);
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    bool authenticated = false,
  }) async {
    final http.Response response = await _send(
      () async => _httpClient.delete(
        resolve(path),
        headers: await _buildHeaders(authenticated: authenticated),
      ),
    );
    return _decodeJsonObject(response);
  }

  Future<Map<String, String>> _buildHeaders({
    required bool authenticated,
  }) async {
    final Map<String, String> headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (!authenticated) {
      return headers;
    }

    final String? token = await _tokenProvider?.call();
    if (token == null || token.isEmpty) {
      throw const ApiException(
        message: 'No existe una sesion autenticada para esta operacion.',
        code: 'missing_token',
      );
    }

    headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      final http.Response response = await request().timeout(
        _environment.receiveTimeout,
      );
      _throwIfNeeded(response);
      return response;
    } on TimeoutException {
      throw const ApiException(
        message: 'La solicitud excedio el tiempo de espera.',
        code: 'request_timeout',
      );
    } on ApiException {
      rethrow;
    } catch (error) {
      throw ApiException(
        message: 'No fue posible conectar con el servidor.',
        code: 'network_error',
        details: <String, dynamic>{'cause': error.toString()},
      );
    }
  }

  Map<String, dynamic> _decodeJsonObject(http.Response response) {
    if (response.body.trim().isEmpty) {
      return const <String, dynamic>{};
    }

    final Object? decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    throw ApiException(
      message: 'La respuesta del servidor no tiene el formato esperado.',
      statusCode: response.statusCode,
      code: 'invalid_response',
    );
  }

  void _throwIfNeeded(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    try {
      final Map<String, dynamic> payload = _decodeJsonObject(response);
      final Map<String, dynamic>? error =
          payload['error'] as Map<String, dynamic>?;
      throw ApiException(
        message: error?['message'] as String? ?? 'Ocurrio un error con la API.',
        statusCode: response.statusCode,
        code: error?['code'] as String?,
        details:
            error?['details'] as Map<String, dynamic>? ??
            <String, dynamic>{'body': response.body},
      );
    } on FormatException {
      throw ApiException(
        message: 'La API devolvio un error no parseable.',
        statusCode: response.statusCode,
        code: 'invalid_error_payload',
        details: <String, dynamic>{'body': response.body},
      );
    }
  }

  String _joinPaths(String basePath, String path) {
    final String normalizedBase = basePath.endsWith('/')
        ? basePath.substring(0, basePath.length - 1)
        : basePath;
    final String normalizedPath = path.startsWith('/')
        ? path.substring(1)
        : path;
    return '$normalizedBase/$normalizedPath';
  }
}
