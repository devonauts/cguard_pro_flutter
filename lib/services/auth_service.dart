import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthService {
  static const _tokenKey = 'auth_token';

  /// Llama al backend, guarda token y retorna el usuario
  static Future<Map<String, dynamic>> signIn(
      String email, String password) async {
    final resp = await ApiService.signIn(email, password);
    if (resp.statusCode == 200) {
      final body = jsonDecode(resp.body);
      final token = body['token'];
      final user = body['user'];
      // Validate user roles: only allow admins/superadmins
      bool allowed = false;
      try {
        if (user is Map) {
          if (user['isSuperadmin'] == true) allowed = true;

          final rolesTop = user['roles'];
          if (!allowed && rolesTop is List) {
            for (final r in rolesTop) {
              final rs = r.toString().toLowerCase();
              if (rs == 'admin' || rs == 'superadmin' || rs == 'super_admin') {
                allowed = true;
                break;
              }
            }
          }

          if (!allowed && user['tenant'] != null) {
            final tenant = user['tenant'];
            final troles = tenant is Map ? tenant['roles'] : null;
            if (troles is List) {
              for (final r in troles) {
                final rs = r.toString().toLowerCase();
                if (rs == 'admin' ||
                    rs == 'superadmin' ||
                    rs == 'super_admin') {
                  allowed = true;
                  break;
                }
              }
            }
          }
        }
      } catch (_) {
        allowed = false;
      }

      final prefs = await SharedPreferences.getInstance();
      if (!allowed) {
        // Ensure token is not persisted if present
        if (prefs.getString(_tokenKey) != null) await prefs.remove(_tokenKey);
        // Throw a structured error so UI shows a friendly message
        final msg = jsonEncode({
          'message':
              'Acceso denegado: solo administradores pueden usar esta app',
          'messageCode': 'auth.access_denied',
          'code': 403
        });
        throw Exception(msg);
      }

      if (token != null) await prefs.setString(_tokenKey, token);
      return {'token': token, 'user': user};
    }
    throw Exception(
        resp.body.isNotEmpty ? resp.body : 'Error: ${resp.statusCode}');
  }

  /// Registra un nuevo usuario usando el endpoint /auth/sign-up.
  /// Guarda el token si el backend lo retorna y devuelve el usuario cargado desde /auth/me.
  static Future<Map<String, dynamic>> register(
      String fullName, String email, String password) async {
    final resp = await ApiService.post('/auth/sign-up', {
      'email': email,
      'password': password,
      'fullName': fullName,
    });

    if (resp.statusCode == 200) {
      final prefs = await SharedPreferences.getInstance();

      String? token;
      try {
        // Algunos endpoints devuelven JSON, otros devuelven el token crudo.
        final decoded = jsonDecode(resp.body);
        if (decoded is Map && decoded['token'] != null) {
          token = decoded['token'];
        } else if (decoded is String) {
          token = decoded;
        }
      } catch (_) {
        // not JSON -> treat body as token string
        if (resp.body.isNotEmpty) token = resp.body;
      }

      if (token != null && token.isNotEmpty) {
        await prefs.setString(_tokenKey, token);
        // Fetch current user
        final meResp = await ApiService.get('/auth/me');
        if (meResp.statusCode == 200) {
          try {
            final meBody = jsonDecode(meResp.body);
            return {'token': token, 'user': meBody};
          } catch (e) {
            return {'token': token, 'user': null};
          }
        }
        return {'token': token, 'user': null};
      }

      // If no token returned, try to parse user object from response body
      try {
        final body = jsonDecode(resp.body);
        return {'token': null, 'user': body};
      } catch (e) {
        return {'token': null, 'user': null};
      }
    }

    throw Exception(
        resp.body.isNotEmpty ? resp.body : 'Error: ${resp.statusCode}');
  }

  /// Envía solicitud de restablecimiento de contraseña al backend.
  /// Llama a POST /auth/send-password-reset-email con { email }.
  /// Devuelve true si el backend responde con éxito.
  static Future<bool> sendPasswordReset(String email) async {
    final resp = await ApiService.post('/auth/send-password-reset-email', {
      'email': email,
    });

    if (resp.statusCode == 200) {
      try {
        final body = jsonDecode(resp.body);
        return body == true || body == 'true';
      } catch (_) {
        return resp.body.isNotEmpty;
      }
    }

    throw Exception(
        resp.body.isNotEmpty ? resp.body : 'Error: ${resp.statusCode}');
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }
}
