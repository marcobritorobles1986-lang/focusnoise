import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleController extends ChangeNotifier {
  static const _kKey = 'app_locale_code';
  Locale? _locale;
  Locale? get locale => _locale;

  static const supported = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  Future<void> load() async {
    final sp = await SharedPreferences.getInstance();
    final code = sp.getString(_kKey);
    if (code == null || code.isEmpty) {
      _locale = null; // usa resolución del sistema
    } else {
      _locale = Locale(code);
    }
    notifyListeners();
  }

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
