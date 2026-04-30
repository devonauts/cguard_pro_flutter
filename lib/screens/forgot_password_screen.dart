import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/notify.dart';
import '../services/i18n.dart';
import '../services/locale_service.dart';
import 'register_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _loading = false;
  final Map<String, String?> _fieldErrors = {};

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendReset() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      final msg = I18n.t('validator.email_required', LocaleService.current);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      return;
    }

    setState(() => _loading = true);
    try {
      final ok = await AuthService.sendPasswordReset(email);
      if (!mounted) return;
      setState(() => _loading = false);
      if (ok) {
        final msg = I18n.t('forgot.send_button', LocaleService.current);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No se pudo enviar el correo.')));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _handleApiError(e);
    }
  }

  void _handleApiError(dynamic e) {
    String raw = e?.toString() ?? 'Error desconocido';
    String friendly = 'Ocurrió un error';
    final Map<String, String?> fieldErrors = {};
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
                fieldErrors[k] = v[0].toString();
              else
                fieldErrors[k] = v.toString();
            });
          } else if (errors is List) {
            for (final it in errors) {
              if (it is Map && it['path'] != null && it['message'] != null) {
                fieldErrors[it['path']] = it['message'].toString();
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
            friendly = I18n.t(key, LocaleService.current);
          } else {
            friendly = rawMsg;
          }
        } else if (decoded['error'] != null)
          friendly = decoded['error'].toString();
        else if (fieldErrors.isNotEmpty)
          friendly = fieldErrors.values.first ?? friendly;
      }
    } catch (_) {
      // ignore: avoid_print
      print('API error raw: $raw');
    }

    final show = (friendly.isNotEmpty && friendly != 'Ocurrió un error')
        ? friendly
        : 'Error al comunicarse con el servidor';
    if (mounted) Notify.showToast(context, show, error: true);
    setState(() {
      if (fieldErrors.isNotEmpty) _fieldErrors.addAll(fieldErrors);
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final contentWidth = width > 520 ? 520.0 : width * 0.94;

    final theme = Theme.of(context);
    final accent = theme.primaryColor;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: accent),
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
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
                  Text(I18n.t('forgot.title', LocaleService.current),
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const SizedBox(height: 8),
                  Text(
                      'Usando la plataforma de gestión de seguridad física CGUARD.',
                      style: TextStyle(color: Colors.white70)),
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
                          Text(
                              I18n.t('label.email_required',
                                  LocaleService.current),
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87)),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              hintText: I18n.t('forgot.email_placeholder',
                                  LocaleService.current),
                              hintStyle: TextStyle(color: Colors.grey[600]),
                              prefixIcon: Icon(Icons.mail_outline,
                                  color: Colors.grey[700]),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0)),
                              errorText: _fieldErrors['email'],
                            ),
                            onChanged: (_) =>
                                setState(() => _fieldErrors.remove('email')),
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _sendReset,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accent,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                              child: _loading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white)
                                  : Text(
                                      I18n.t('forgot.send_button',
                                          LocaleService.current),
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white)),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(children: const [
                            Expanded(child: Divider()),
                            Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                child: Text('o')),
                            Expanded(child: Divider())
                          ]),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: Text(
                                    I18n.t('btn.back_to_login',
                                        LocaleService.current),
                                    style: TextStyle(color: accent)),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                        fullscreenDialog: true,
                                        builder: (_) =>
                                            const RegisterScreen())),
                                child: Text(
                                    I18n.t('btn.create_account',
                                        LocaleService.current),
                                    style: TextStyle(color: accent)),
                              ),
                            ],
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
