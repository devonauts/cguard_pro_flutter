import 'package:flutter/foundation.dart';

class LocaleService {
  // default language
  static final ValueNotifier<String> lang = ValueNotifier<String>('es');

  static String get current => lang.value;

  static void setLang(String l) {
    lang.value = (l.isNotEmpty ? l.substring(0, 2).toLowerCase() : 'en');
  }

  static void toggle() {
    lang.value = (lang.value == 'es') ? 'en' : 'es';
  }
}
