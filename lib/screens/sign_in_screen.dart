import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/i18n.dart';
import '../services/locale_service.dart';
import '../services/notify.dart';
import 'home_screen.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  static const Color _accent = Color(0xFFC8860A);
  static const Color _bg = Color(0xFF0F1923);
  static const Color _cardText = Color(0xFF0F1923);
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  bool _formValid = false;
  final Map<String, String?> _fieldErrors = {};

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? v) {
    final lang = LocaleService.current;
    if (v == null || v.trim().isEmpty) return I18n.t('validator.email_required', lang);
    final email = v.trim();
    final emailRegex = RegExp(r"^[^@\s]+@[^@\s]+\.[^@\s]+$");
    if (!emailRegex.hasMatch(email)) return I18n.t('validator.email_invalid', lang);
    return null;
  }

  String? _validatePassword(String? v) {
    final lang = LocaleService.current;
    if (v == null || v.isEmpty) return I18n.t('validator.password_required', lang);
    if (v.length < 6) return I18n.t('validator.password_short', lang);
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      final result = await AuthService.signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (!mounted) return;
      final user = result['user'] as Map<String, dynamic>?;

      // Determinar idioma: preferencia del backend, si no usar current app lang
      String lang = LocaleService.current;
      try {
        if (user != null && user['language'] != null) {
          final raw = (user['language'] as String).toLowerCase();
          if (raw.startsWith('es'))
            lang = 'es';
          else if (raw.startsWith('pt'))
            lang = 'pt';
          else
            lang = 'en';
        } else {
          // keep app-level language
        }
      } catch (_) {}

      // Comprobar roles/permiso de admin
      bool allowed = false;
      try {
        if (user != null) {
          // superadmin flag
          if (user['isSuperadmin'] == true) allowed = true;

          // top-level roles
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

          // tenant-scoped roles
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
      } catch (e) {
        allowed = false;
      }

      if (!allowed) {
        // Usuario no autorizado para la app móvil
        await AuthService.signOut();
        final msg = I18n.t('auth.access_denied', lang);
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
        return;
      }
      final ok = I18n.t('snack.login_ok', lang);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok)));
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => HomeScreen(user: user),
      ));
    } catch (e) {
      if (!mounted) return;
      _handleApiError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final contentWidth = width > 520 ? 480.0 : width * 0.92;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Column(
              children: [
                // Top image/space with new theme colors
                Container(
                  width: double.infinity,
                  height: 220,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_bg, _accent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 6),
                            // App title and welcome (reactive to language)
                            ValueListenableBuilder<String>(
                              valueListenable: LocaleService.lang,
                              builder: (_, cur, __) => Text(I18n.t('app.title', cur), style: TextStyle(color: Color.fromRGBO(200, 134, 10, 0.95), fontSize: 14, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(height: 8),
                            ValueListenableBuilder<String>(
                              valueListenable: LocaleService.lang,
                              builder: (_, cur, __) => Text(I18n.t('welcome', cur), style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800)),
                            ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: CircleAvatar(
                              radius: 36,
                              backgroundColor: Color.fromRGBO(200, 134, 10, 0.14),
                              child: const Icon(Icons.shield, color: Colors.white, size: 36),
                            ),
                          ),
                        ),
                            // language toggle placed below avatar
                            Align(
                              alignment: Alignment.bottomRight,
                              child: ValueListenableBuilder<String>(
                                valueListenable: LocaleService.lang,
                                builder: (_, cur, __) => TextButton(
                                  onPressed: () => LocaleService.toggle(),
                                  child: Text(cur.toUpperCase()),
                                  style: TextButton.styleFrom(foregroundColor: Colors.white70),
                                ),
                              ),
                            ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Form card
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: contentWidth),
                  child: Card(
                    color: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 18.0),
                      child: Form(
                              key: _formKey,
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                              child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Email
                            TextFormField(
                              controller: _emailController,
                                    decoration: InputDecoration(
                                            labelText: I18n.t('label.email', LocaleService.current),
                                            labelStyle: const TextStyle(color: _cardText),
                                            prefixIcon: const Icon(Icons.email_outlined),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8.0),
                                              borderSide: BorderSide(color: Colors.grey.shade400, width: 1.2),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8.0),
                                              borderSide: BorderSide(color: _accent, width: 2.0),
                                            ),
                                            errorText: _fieldErrors['email'],
                                          ),
                              keyboardType: TextInputType.emailAddress,
                              validator: _validateEmail,
                                          onChanged: (_) => setState(() {
                                            _formValid = _formKey.currentState?.validate() ?? false;
                                            _fieldErrors.remove('email');
                                          }),
                            ),
                            const SizedBox(height: 12),

                            // Password with eye
                            TextFormField(
                              controller: _passwordController,
                              decoration: InputDecoration(
                                labelText: I18n.t('label.password', LocaleService.current),
                                labelStyle: const TextStyle(color: _cardText),
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                                  onPressed: () => setState(() => _obscure = !_obscure),
                                ),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                  borderSide: BorderSide(color: Colors.grey.shade400, width: 1.2),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                  borderSide: BorderSide(color: _accent, width: 2.0),
                                ),
                                errorText: _fieldErrors['password'],
                              ),
                              obscureText: _obscure,
                              validator: _validatePassword,
                              onChanged: (_) => setState(() {
                                _formValid = _formKey.currentState?.validate() ?? false;
                                _fieldErrors.remove('password');
                              }),
                            ),

                            const SizedBox(height: 10),
                            // Error placeholder handled by validator/snackbars

                            const SizedBox(height: 8),

                            // Primary button (accent color)
                            SizedBox(
                              height: 54,
                              child: Builder(builder: (ctx) {
                                final enabled = _formValid && !_loading;
                                final buttonColor = enabled ? _accent : Colors.grey[350];
                                return ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: buttonColor,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                    elevation: 0,
                                  ),
                                  onPressed: enabled ? _submit : null,
                                  child: _loading
                                      ? const CircularProgressIndicator(color: Colors.white)
                                      : Text(I18n.t('btn.sign_in', LocaleService.current), style: const TextStyle(letterSpacing: 1.2, fontWeight: FontWeight.bold)),
                                );
                              }),
                            ),

                            const SizedBox(height: 8),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(fullscreenDialog: true, builder: (_) => const ForgotPasswordScreen())),
                                  child: Text(I18n.t('link.forgot', LocaleService.current), style: const TextStyle(color: Color(0xFF0F1923))),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(fullscreenDialog: true, builder: (_) => const RegisterScreen())),
                                  child: Text(I18n.t('link.create_account', LocaleService.current), style: const TextStyle(color: Color(0xFFC8860A))),
                                ),
                              ],
                            ),

                            const SizedBox(height: 6),

                            /* Social sign-in buttons (temporarily disabled)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () {
                                    // TODO: integrar Google Sign-In
                                  },
                                  icon: const Icon(Icons.g_mobiledata, color: Color(0xFF0F1923)),
                                  label: const Text(' Google', style: TextStyle(color: Color(0xFF0F1923))),
                                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.grey)),
                                ),
                                const SizedBox(width: 12),
                                OutlinedButton.icon(
                                  onPressed: () {
                                    // TODO: integrar Facebook Sign-In
                                  },
                                  icon: const Icon(Icons.facebook, color: Color(0xFF0F1923)),
                                  label: const Text(' Facebook', style: TextStyle(color: Color(0xFF0F1923))),
                                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.grey)),
                                ),
                              ],
                            ),
                            */
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleApiError(dynamic e) {
    String raw = e?.toString() ?? 'Error desconocido';
    String friendly = 'Ocurrió un error';
    _fieldErrors.clear();
    try {
      // Sometimes the exception contains extra text before the JSON, extract JSON part
      String jsonPart = raw;
      final start = raw.indexOf('{');
      if (start != -1) jsonPart = raw.substring(start);
      final decoded = jsonDecode(jsonPart);
      if (decoded is Map) {
        // map field errors if present
        if (decoded['errors'] != null) {
          final errors = decoded['errors'];
          if (errors is Map) {
            errors.forEach((k, v) {
              if (v is List && v.isNotEmpty)
                _fieldErrors[k] = v[0].toString();
              else
                _fieldErrors[k] = v.toString();
            });
          } else if (errors is List) {
            for (final it in errors) {
              if (it is Map && it['path'] != null && it['message'] != null) {
                _fieldErrors[it['path']] = it['message'].toString();
              }
            }
          }
        }

        // prefer backend messageCode translation when available
        if (decoded['messageCode'] != null) {
          try {
            final locale = Localizations.localeOf(context).languageCode.toLowerCase();
            String lang = 'en';
            if (locale.startsWith('es')) lang = 'es';
            else if (locale.startsWith('pt')) lang = 'pt';
            friendly = I18n.t(decoded['messageCode'].toString(), lang);
          } catch (_) {
            friendly = decoded['message']?.toString() ?? decoded['error']?.toString() ?? friendly;
          }
        } else if (decoded['message'] != null) {
          final rawMsg = decoded['message'].toString();
          // If backend didn't send messageCode, try to map raw message to a known code
          final key = I18n.keyForMessage(rawMsg);
          if (key != null) {
            final locale = Localizations.localeOf(context).languageCode.toLowerCase();
            String lang = 'en';
            if (locale.startsWith('es')) lang = 'es';
            else if (locale.startsWith('pt')) lang = 'pt';
            friendly = I18n.t(key, lang);
          } else {
            friendly = rawMsg;
          }
        } else if (decoded['error'] != null) friendly = decoded['error'].toString();
        else if (_fieldErrors.isNotEmpty) friendly = _fieldErrors.values.first ?? friendly;
      }
    } catch (_) {
      // don't show raw exception to user; log for debugging
      // ignore: avoid_print
      print('API error raw: $raw');
    }

    // show concise message (prefer friendly, fallback generic)
    final show = (friendly.isNotEmpty && friendly != 'Ocurrió un error') ? friendly : 'Error al comunicarse con el servidor';
    if (mounted) Notify.showToast(context, show, error: true);
    setState(() {});
  }

}
