class I18n {
  static const Map<String, Map<String, String>> _t = {
    'access_denied': {
      'es':
          'Acceso denegado: tu cuenta no tiene permisos para usar esta app móvil. Contacta al administrador.',
      'en':
          'Access denied: your account lacks permissions to use this mobile app. Contact your administrator.',
      'pt':
          'Acesso negado: sua conta não tem permissões para usar este aplicativo móvel. Contate o administrador.',
    },
    'contact_admin': {
      'es': 'Contactar al administrador',
      'en': 'Contact administrator',
      'pt': 'Contactar o administrador',
    },
    // Backend message codes
    'auth.wrongPassword': {
      'es': 'Contraseña incorrecta.',
      'en': 'Wrong password.',
      'pt': 'Senha incorreta.',
    },
    'auth.userNotFound': {
      'es': 'El correo no está registrado.',
      'en': 'Email not registered.',
      'pt': 'Email não cadastrado.',
    },
    'auth.invalidCredentials': {
      'es': 'Credenciales inválidas.',
      'en': 'Invalid credentials.',
      'pt': 'Credenciais inválidas.',
    },
    'auth.access_denied': {
      'es':
          'Acceso denegado: tu cuenta no tiene permisos para usar esta app móvil. Contacta al administrador.',
      'en':
          'Access denied: your account lacks permissions to use this mobile app. Contact your administrator.',
      'pt':
          'Acesso negado: sua conta não tem permissões para usar este aplicativo móvel. Contate o administrador.',
    }
  };

  // UI keys
  static const Map<String, Map<String, String>> _ui = {
    'app.title': {
      'es': 'C-GUARD',
      'en': 'C-GUARD',
      'pt': 'C-GUARD',
    },
    'welcome': {
      'es': 'Bienvenido',
      'en': 'Welcome',
      'pt': 'Bem-vindo',
    },
    'label.email': {
      'es': 'Correo',
      'en': 'Email',
      'pt': 'Email',
    },
    'label.password': {
      'es': 'Contraseña',
      'en': 'Password',
      'pt': 'Senha',
    },
    'btn.sign_in': {
      'es': 'INICIAR SESIÓN',
      'en': 'SIGN IN',
      'pt': 'ENTRAR',
    },
    'link.forgot': {
      'es': '¿Olvidaste tu contraseña?',
      'en': 'Forgot password?',
      'pt': 'Esqueceu a senha?',
    },
    'link.create_account': {
      'es': 'Crear cuenta',
      'en': 'Create account',
      'pt': 'Criar conta',
    },
    'validator.email_required': {
      'es': 'Correo obligatorio',
      'en': 'Email required',
      'pt': 'Email obrigatório',
    },
    'validator.email_invalid': {
      'es': 'Correo inválido',
      'en': 'Invalid email',
      'pt': 'Email inválido',
    },
    'validator.password_required': {
      'es': 'Contraseña obligatoria',
      'en': 'Password required',
      'pt': 'Senha obrigatória',
    },
    'validator.password_short': {
      'es': 'La contraseña debe tener al menos 6 caracteres',
      'en': 'Password must be at least 6 characters',
      'pt': 'A senha deve ter pelo menos 6 caracteres',
    },
    'snack.login_ok': {
      'es': 'Inicio de sesión correcto',
      'en': 'Login successful',
      'pt': 'Login bem sucedido',
    }
  };

  // additional UI keys used by register/forgot screens
  static const Map<String, Map<String, String>> _ui_extra = {
    'label.full_name': {
      'es': 'Nombre completo*',
      'en': 'Full name*',
      'pt': 'Nome completo*'
    },
    'label.email_required': {
      'es': 'Correo electrónico*',
      'en': 'Email*',
      'pt': 'Email*'
    },
    'label.confirm_password': {
      'es': 'Confirmar contraseña*',
      'en': 'Confirm password*',
      'pt': 'Confirmar senha*'
    },
    'btn.create_account': {
      'es': 'Crear cuenta',
      'en': 'Create account',
      'pt': 'Criar conta'
    },
    'prompt.already_have_account': {
      'es': '¿Ya tienes una cuenta?',
      'en': 'Already have an account?',
      'pt': '¿Já tem conta?'
    },
    'link.sign_in': {'es': 'Iniciar sesión', 'en': 'Sign in', 'pt': 'Entrar'},
    'forgot.title': {
      'es': '¿Olvidaste tu contraseña?',
      'en': 'Forgot your password?',
      'pt': 'Esqueceu sua senha?'
    },
    'forgot.send_button': {
      'es': 'ENVIAR ENLACE DE RESTABLECIMIENTO',
      'en': 'SEND RESET LINK',
      'pt': 'ENVIAR LINK DE REDEFINIÇÃO'
    },
    'forgot.email_placeholder': {
      'es': 'tu@empresa.com',
      'en': 'you@company.com',
      'pt': 'voce@empresa.com'
    },
    'btn.back_to_login': {
      'es': 'Volver al inicio',
      'en': 'Back to login',
      'pt': 'Voltar ao login'
    }
  };

  // Merge _ui into _t for reverse lookup convenience
  static Map<String, Map<String, String>> get allTranslations {
    final m = Map<String, Map<String, String>>.from(_t);
    _ui.forEach((k, v) => m[k] = v);
    _ui_extra.forEach((k, v) => m[k] = v);
    return m;
  }

  /// Devuelve la traducción para `key` en `lang` ('es','en','pt').
  /// Si no existe, devuelve la versión en inglés o la clave.
  static String t(String key, String lang) {
    final map = allTranslations;
    final k = map[key];
    if (k == null) return key;
    final l = (lang.isNotEmpty ? lang : 'en').toLowerCase();
    if (k.containsKey(l)) return k[l]!;
    if (k.containsKey('en')) return k['en']!;
    return k.values.first;
  }

  /// Try to find a translation key by matching a message text.
  /// Returns the key if a match is found, otherwise null.
  static String? keyForMessage(String msg) {
    if (msg.isEmpty) return null;
    String normalize(String s) {
      var r = s.toLowerCase().trim();
      // remove common punctuation
      r = r.replaceAll(RegExp(r'[.,;:!?"]'), '');
      // collapse whitespace
      r = r.replaceAll(RegExp(r'\s+'), ' ');
      return r;
    }

    final normalizedMsg = normalize(msg);
    // search both backend codes and UI keys
    final searchMap = allTranslations;
    for (final entry in searchMap.entries) {
      for (final v in entry.value.values) {
        final nv = normalize(v);
        if (nv == normalizedMsg) return entry.key;
        if (nv.contains(normalizedMsg) || normalizedMsg.contains(nv))
          return entry.key;
      }
    }
    return null;
  }
}
