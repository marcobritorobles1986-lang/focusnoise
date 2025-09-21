// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'FocusNoise';

  @override
  String get credits => 'Créditos';

  @override
  String get savePreset => 'Guardar preset';

  @override
  String get myPresets => 'Mis presets';

  @override
  String get theme => 'Tema';

  @override
  String get timer => 'Temporizador';

  @override
  String get fadeStopAll => 'Fade-out y detener todo';

  @override
  String get masterVolume => 'Volumen maestro';

  @override
  String get generators => 'Generadores (offline)';

  @override
  String get tipMix =>
      'Tip: mezcla 2–3 fuentes a volúmenes moderados (0.3–0.6) para evitar clipping.';

  @override
  String get language => 'Idioma';

  @override
  String get language_en => 'Inglés';

  @override
  String get language_es => 'Español';
}
