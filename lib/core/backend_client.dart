import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http_parser/http_parser.dart';

import 'app_config.dart';

class BackendClient {
  const BackendClient._();

  static final BackendClient instance = BackendClient._();

  Uri _uri(String path) => Uri.parse('${AppConfig.backendUrl}/api$path');

  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    final headers = await _headers();

    final response = await http.post(
      _uri(path),
      headers: {...headers, 'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    return _decode(response);
  }

  Future<Map<String, dynamic>> postMultipart(
  String path, {
  required Uint8List bytes,
  required String filename,
  required String field,
  required Map<String, String> fields,
}) async {
  final request = http.MultipartRequest(
    'POST',
    _uri(path),
  );

  request.headers.addAll(await _headers());

  request.fields.addAll(fields);

  request.files.add(
  http.MultipartFile.fromBytes(
    field,
    bytes,
    filename: filename,
    contentType: MediaType('audio', 'wav'),
  ),
);

  final response = await request.send();

  return _decode(
    await http.Response.fromStream(response),
  );
}
Future<Map<String, dynamic>> transcribeVoice({
  required Uint8List bytes,
  required String filename,
  String language = 'English',
}) async {
  return postMultipart(
    '/voice/transcribe',
    bytes: bytes,
    filename: filename,
    field: 'audio',
    fields: {
      'language': language,
    },
  );
}

  Future<Map<String, String>> _headers() async {
    final session = AppConfig.hasSupabase
        ? Supabase.instance.client.auth.currentSession
        : null;

    final headers = <String, String>{'Accept': 'application/json'};

    final accessToken = session?.accessToken;

    if (accessToken != null && accessToken.isNotEmpty) {
      headers[HttpHeaders.authorizationHeader] = 'Bearer $accessToken';
    }

    return headers;
  }

  Map<String, dynamic> _decode(http.Response response) {
    final data = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw BackendException(
        response.statusCode,
        data['detail']?.toString() ?? 'Request failed',
      );
    }

    return data;
  }
}

class BackendException implements Exception {
  const BackendException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => 'BackendException($statusCode): $message';
}
