import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/notify.dart';
import '../services/i18n.dart';
import '../services/locale_service.dart';
import 'home_screen.dart';
import 'sign_in_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();
  final TextEditingController _pass2Ctrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  final Map<String, String?> _fieldErrors = {};

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _pass2Ctrl.dispose();
    super.dispose();
  }

  String? _emailValidator(String? v) {
    final lang = LocaleService.current;
    if (v == null || v.trim().isEmpty)
      return I18n.t('validator.email_required', lang);
    final re = RegExp(r"^[^@\s]+@[^@\s]+\.[^@\s]+$");
    if (!re.hasMatch(v.trim())) return I18n.t('validator.email_invalid', lang);
    return null;
  }

  String? _passValidator(String? v) {
    final lang = LocaleService.current;
    if (v == null || v.isEmpty)
      return I18n.t('validator.password_required', lang);
    if (v.length < 8) return I18n.t('validator.password_short', lang);
    final upper = RegExp(r'[A-Z]');
    final lower = RegExp(r'[a-z]');
    final digit = RegExp(r'\d');
    final special = RegExp(r'[^A-Za-z0-9]');
    if (!upper.hasMatch(v) ||
        !lower.hasMatch(v) ||
        !digit.hasMatch(v) ||
        !special.hasMatch(v)) {
      return 'La contraseña debe incluir mayúscula, minúscula, número y carácter especial';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passCtrl.text != _pass2Ctrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Las contraseñas no coinciden')));
      return;
    }
    setState(() => _loading = true);
    try {
      final result = await AuthService.register(
        _nameCtrl.text.trim(),
        _emailCtrl.text.trim(),
        _passCtrl.text,
      );

      if (!mounted) return;

      final token = result['token'] as String?;
      final user = result['user'] as Map<String, dynamic>?;

      if (token != null && token.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(I18n.t('snack.login_ok', LocaleService.current))));
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => HomeScreen(user: user)));
        return;
      }

      // If no token but user created, show success and go back
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(I18n.t('btn.create_account', LocaleService.current))));
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      _handleApiError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _handleApiError(dynamic e) {
    String raw = e?.toString() ?? 'Error desconocido';
    String friendly = 'Ocurrió un error';
    _fieldErrors.clear();
    try {
      String jsonPart = raw;
      final start = raw.indexOf('{');
      if (start != -1) jsonPart = raw.substring(start);
      final decoded = jsonDecode(jsonPart);
      if (decoded is Map) {
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

        if (decoded['messageCode'] != null) {
          try {
            final locale =
                Localizations.localeOf(context).languageCode.toLowerCase();
            String lang = 'en';
            if (locale.startsWith('es'))
              lang = 'es';
            else if (locale.startsWith('pt')) lang = 'pt';
            friendly = I18n.t(decoded['messageCode'].toString(), lang);
          } catch (_) {
            friendly = decoded['message']?.toString() ??
                decoded['error']?.toString() ??
                friendly;
          }
        } else if (decoded['message'] != null) {
          final rawMsg = decoded['message'].toString();
          final key = I18n.keyForMessage(rawMsg);
          if (key != null) {
            final locale =
                Localizations.localeOf(context).languageCode.toLowerCase();
            String lang = 'en';
            if (locale.startsWith('es'))
              lang = 'es';
            else if (locale.startsWith('pt')) lang = 'pt';
            friendly = I18n.t(key, lang);
          } else {
            friendly = rawMsg;
          }
        } else if (decoded['error'] != null)
          friendly = decoded['error'].toString();
        else if (_fieldErrors.isNotEmpty)
          friendly = _fieldErrors.values.first ?? friendly;
      }
    } catch (_) {
      // ignore raw details for users; log for debugging
      // ignore: avoid_print
      print('API error raw: $raw');
    }

    final show = (friendly.isNotEmpty && friendly != 'Ocurrió un error')
        ? friendly
        : 'Error al comunicarse con el servidor';
    if (mounted) Notify.showToast(context, show, error: true);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final contentWidth = width > 520 ? 520.0 : width * 0.94;
    final theme = Theme.of(context);
    final accent = theme.primaryColor;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: accent),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: contentWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),
                  Text('Crea tu cuenta',
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const SizedBox(height: 8),
                  Text(
                      'Usando la plataforma de gestión de seguridad física CGUARD.',
                      style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 18),
                  const SizedBox(height: 18),
                  Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18.0, vertical: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          /* Social Google button placeholder (temporarily disabled)
                          SizedBox(
                            height: 44,
                            child: OutlinedButton.icon(
                              icon: Image.asset('assets/google.png', width: 18, height: 18, errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata)),
                              label: const Text(' Google'),
                              onPressed: () {},
                              style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                            ),
                          ),

                          const SizedBox(height: 14),
                          */
                          Row(children: const [
                            Expanded(child: Divider()),
                            Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                child: Text('o')),
                            Expanded(child: Divider())
                          ]),
                          const SizedBox(height: 12),
                          Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TextFormField(
                                  controller: _nameCtrl,
                                  decoration: InputDecoration(
                                      labelText: I18n.t('label.full_name',
                                          LocaleService.current),
                                      prefixIcon:
                                          const Icon(Icons.person_outline),
                                      errorText: _fieldErrors['fullName']),
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                          ? 'Nombre obligatorio'
                                          : null,
                                  onChanged: (_) => setState(
                                      () => _fieldErrors.remove('fullName')),
                                ),
                                const SizedBox(height: 10),
                                TextFormField(
                                  controller: _emailCtrl,
                                  decoration: InputDecoration(
                                      labelText: I18n.t('label.email_required',
                                          LocaleService.current),
                                      prefixIcon:
                                          const Icon(Icons.mail_outline),
                                      errorText: _fieldErrors['email']),
                                  keyboardType: TextInputType.emailAddress,
                                  validator: _emailValidator,
                                  onChanged: (_) => setState(
                                      () => _fieldErrors.remove('email')),
                                ),
                                const SizedBox(height: 10),
                                TextFormField(
                                  controller: _passCtrl,
                                  decoration: InputDecoration(
                                      labelText: I18n.t('label.password',
                                              LocaleService.current) +
                                          '*',
                                      prefixIcon:
                                          const Icon(Icons.lock_outline),
                                      suffixIcon: IconButton(
                                          icon: Icon(_obscure
                                              ? Icons.visibility_off
                                              : Icons.visibility),
                                          onPressed: () => setState(
                                              () => _obscure = !_obscure)),
                                      errorText: _fieldErrors['password']),
                                  obscureText: _obscure,
                                  validator: _passValidator,
                                  onChanged: (_) => setState(
                                      () => _fieldErrors.remove('password')),
                                ),
                                const SizedBox(height: 10),
                                TextFormField(
                                  controller: _pass2Ctrl,
                                  decoration: InputDecoration(
                                      labelText: I18n.t(
                                          'label.confirm_password',
                                          LocaleService.current),
                                      prefixIcon:
                                          const Icon(Icons.lock_outline),
                                      suffixIcon: IconButton(
                                          icon: Icon(_obscure
                                              ? Icons.visibility_off
                                              : Icons.visibility),
                                          onPressed: () => setState(
                                              () => _obscure = !_obscure)),
                                      errorText:
                                          _fieldErrors['passwordConfirmation']),
                                  obscureText: _obscure,
                                  validator: (v) => v == null || v.isEmpty
                                      ? 'Confirma la contraseña'
                                      : null,
                                  onChanged: (_) => setState(() => _fieldErrors
                                      .remove('passwordConfirmation')),
                                ),
                                const SizedBox(height: 14),
                                SizedBox(
                                  height: 48,
                                  child: ElevatedButton(
                                    onPressed: _loading ? null : _submit,
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: accent,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8))),
                                    child: _loading
                                        ? const CircularProgressIndicator(
                                            color: Colors.white)
                                        : Text(
                                            I18n.t('btn.create_account',
                                                LocaleService.current),
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white)),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(I18n.t('prompt.already_have_account',
                                            LocaleService.current) +
                                        ' '),
                                    GestureDetector(
                                        onTap: () => Navigator.of(context)
                                            .pushReplacement(MaterialPageRoute(
                                                builder: (_) =>
                                                    const SignInScreen())),
                                        child: Text(
                                            I18n.t('link.sign_in',
                                                LocaleService.current),
                                            style: TextStyle(color: accent))),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
