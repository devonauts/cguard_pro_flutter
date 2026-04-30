import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import 'auth_service.dart';

class ApiService {
  ApiService._();

  static final Map<String, String> _baseHeaders = {
    'Content-Type': 'application/json',
  };

  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();
    final headers = Map<String, String>.from(_baseHeaders);
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// Llama al endpoint de sign-in: POST /auth/sign-in
  static Future<http.Response> signIn(String email, String password) {
    final uri = Uri.parse(Config.signIn);
    final body = jsonEncode({'email': email, 'password': password});
    return http.post(uri, headers: _baseHeaders, body: body);
  }

  /// GET helper que añade Authorization si hay token
  static Future<http.Response> get(String path) async {
    final uri =
        Uri.parse(path.startsWith('http') ? path : '${Config.apiBase}$path');
    final h = await _headers();
    return http.get(uri, headers: h);
  }

  /// POST helper que añade Authorization si hay token
  static Future<http.Response> post(
      String path, Map<String, dynamic> body) async {
    final uri =
        Uri.parse(path.startsWith('http') ? path : '${Config.apiBase}$path');
    final h = await _headers();
    return http.post(uri, headers: h, body: jsonEncode(body));
  }
}
