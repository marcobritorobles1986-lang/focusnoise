import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Controla el Locale manual de la app (persistido en SharedPreferences).
class LocaleController extends ChangeNotifier {
  static const _kKey = 'app_locale_code';

  Locale? _locale;
  Locale? get locale => _locale; // null => usa el del sistema

  /// Idiomas que tu app soporta (EN, ES, PT)
  static const supported = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('pt'),
  ];

  /// Carga el locale guardado (si existe)
  Future<void> load() async {
    final sp = await SharedPreferences.getInstance();
    final code = sp.getString(_kKey);
    if (code == null || code.isEmpty) {
      _locale = null; // usa sistema
    } else {
      // valida que esté soportado
      final match =
      supported.firstWhere((l) => l.languageCode == code, orElse: () => supported.first);
      _locale = Locale(match.languageCode);
    }
    notifyListeners();
  }

  /// Cambia el locale (null = seguir sistema)
  Future<void> setLocale(Locale? loc) async {
    _locale = loc;
    final sp = await SharedPreferences.getInstance();
    if (loc == null) {
      await sp.remove(_kKey);
    } else {
      await sp.setString(_kKey, loc.languageCode);
    }
    notifyListeners();
  }
}
