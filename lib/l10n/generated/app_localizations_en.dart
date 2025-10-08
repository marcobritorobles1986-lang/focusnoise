// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'FocusNoise';

  @override
  String get credits => 'Credits';

  @override
  String get savePreset => 'Save preset';

  @override
  String get myPresets => 'My presets';

  @override
  String get theme => 'Theme';

  @override
  String get timer => 'Timer';

  @override
  String get fadeStopAll => 'Fade-out & stop all';

  @override
  String get masterVolume => 'Master volume';

  @override
  String get generators => 'Generators (offline)';

  @override
  String get tipMix =>
      'Tip: mix 2–3 sources at moderate volumes (0.3–0.6) to avoid clipping.';

  @override
  String get language => 'Language';

  @override
  String get language_en => 'English';

  @override
  String get language_es => 'Spanish';

  @override
  String get changeLanguage => 'Change language';

  @override
  String get useSystemLanguage => 'Use system language';

  @override
  String get helloWorld => 'Hello world';

  @override
  String get followingSystem => 'Following system language';

  @override
  String get currentLanguage => 'Current language';
}
