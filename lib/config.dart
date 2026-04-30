import 'package:flutter_dotenv/flutter_dotenv.dart';

class Config {
  /// Base API URL: usa `FLUTTER_API_URL` si está definido,
  /// si no, intenta derivar la base desde `SIGN_IN_URL`,
  /// si no existe ninguno, usa el valor por defecto.
  static String get apiBase {
    final envBase = dotenv.env['FLUTTER_API_URL'];
    if (envBase != null && envBase.trim().isNotEmpty) {
      return envBase.trim().replaceAll(RegExp(r'/$'), '');
    }

    final signInFull = dotenv.env['SIGN_IN_URL'];
    if (signInFull != null && signInFull.trim().isNotEmpty) {
      final v = signInFull.trim();
      return v
          .replaceFirst(RegExp(r'/auth/sign-in/?$'), '')
          .replaceAll(RegExp(r'/$'), '');
    }

    return 'https://api.cguardpro.com/api';
  }

  /// Endpoint completo para sign-in
  static String get signIn {
    final explicit = dotenv.env['SIGN_IN_URL'];
    if (explicit != null && explicit.trim().isNotEmpty) return explicit.trim();
    return '${apiBase.replaceAll(RegExp(r'/$'), '')}/auth/sign-in';
  }
}
