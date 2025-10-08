// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/generated/app_localizations.dart'; // si usas gen-l10n
import 'package:FocusNoise/i18n/locale_controller.dart';
import 'mixer/mixer_page.dart';

final _localeCtrl = LocaleController();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _localeCtrl.load();
  // Fijamos el idioma a inglés para toda la app
  await _localeCtrl.setLocale(const Locale('en'));

  runApp(MyApp(
    localeCtrl: _localeCtrl,
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.localeCtrl});
  final LocaleController localeCtrl;

  @override
  Widget build(BuildContext context) {
    // Redibuja MaterialApp cuando cambia el locale
    return AnimatedBuilder(
      animation: localeCtrl,
      builder: (_, __) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'FocusNoise',
          locale: localeCtrl.locale, // quedará en 'en'
          supportedLocales: LocaleController.supported,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF64B5F6)),
            useMaterial3: true,
          ),
          // 👇 Siempre mostramos la pantalla de bienvenida al iniciar
          home: LanguageIntroPage(localeCtrl: localeCtrl),
        );
      },
    );
  }
}

/// Pantalla de bienvenida (sin selector de idioma)
class LanguageIntroPage extends StatefulWidget {
  const LanguageIntroPage({super.key, required this.localeCtrl});
  final LocaleController localeCtrl;

  @override
  State<LanguageIntroPage> createState() => _LanguageIntroPageState();
}

class _LanguageIntroPageState extends State<LanguageIntroPage> {
  Future<void> _continue() async {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => MixerPage(localeCtrl: widget.localeCtrl)),
    );

    // Tip sobre audífonos
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tip: use headphones for the best experience.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const title = 'Welcome to FocusNoise';
    const subtitle = 'We recommend using headphones for a better experience.';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            children: [
              const Spacer(),
              CircleAvatar(
                radius: 48,
                backgroundColor: const Color(0xFF64B5F6).withOpacity(0.15),
                child: const Icon(Icons.headphones, size: 56, color: Color(0xFF64B5F6)),
              ),
              const SizedBox(height: 20),
              const Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black.withOpacity(0.65)),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: _continue,
                  label: const Text('Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
