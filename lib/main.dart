import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// generado por gen-l10n (no debe fallar porque solo usamos appTitle y language)
import 'l10n/generated/app_localizations.dart';

// tu controlador de idioma
import 'i18n/locale_controller.dart';

// tu mixer
import 'mixer/mixer_page.dart';

final _localeCtrl = LocaleController();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _localeCtrl.load();
  runApp(MyApp(localeCtrl: _localeCtrl));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.localeCtrl});
  final LocaleController localeCtrl;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: localeCtrl,
      builder: (_, __) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'FocusNoise',
          locale: localeCtrl.locale,
          supportedLocales: LocaleController.supported,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
            useMaterial3: true,
          ),
          routes: {
            '/': (_) => LanguageScreen(localeCtrl: localeCtrl),
            '/mixer': (_) => const MixerPage(),
          },
        );
      },
    );
  }
}

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key, required this.localeCtrl});
  final LocaleController localeCtrl;

  // nombres sin depender de ARB
  String _langDisplay(String code) {
    switch (code) {
      case 'es':
        return 'Español';
      case 'pt':
        return 'Português';
      default:
        return 'English';
    }
  }

  // textos de bienvenida sin ARB extra
  String _welcomeText(String code) {
    switch (code) {
      case 'es':
        return 'Bienvenid@s a Focus Noise.\nTe recomiendo usar audífonos para una mejor sensación.';
      case 'pt':
        return 'Bem-vind@s ao Focus Noise.\nRecomendo usar fones de ouvido para uma melhor sensação.';
      default:
        return 'Welcome to Focus Noise.\nWe recommend using headphones for a better experience.';
    }
  }

  String _continueLabel(String code) {
    switch (code) {
      case 'es':
        return 'Continuar';
      case 'pt':
        return 'Continuar';
      default:
        return 'Continue';
    }
  }

  String _youAreInLabel(String code) {
    switch (code) {
      case 'es':
        return 'Estás en';
      case 'pt':
        return 'Você está em';
      default:
        return 'You are in';
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!; // solo usamos appTitle y language
    final currentCode = localeCtrl.locale?.languageCode ?? _systemFallbackCode(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.appTitle),
        actions: [
          PopupMenuButton<String?>(
            tooltip: t.language, // “Idioma / Language”
            icon: const Icon(Icons.language),
            onSelected: (code) {
              if (code == null) {
                localeCtrl.setLocale(null);
              } else {
                localeCtrl.setLocale(Locale(code));
              }
            },
            itemBuilder: (_) {
              final supportedCodes = ['es', 'en', 'pt'];
              final isSystem = localeCtrl.locale == null;
              final systemCode = _systemFallbackCode(context);
              return <PopupMenuEntry<String?>>[
                CheckedPopupMenuItem<String?>(
                  value: null,
                  checked: isSystem,
                  child: Text(
                    // etiqueta “Sistema / System / Sistema”
                    '${t.language}: ${_langDisplay(systemCode)} (Sistema)',
                  ),
                ),
                const PopupMenuDivider(),
                ...supportedCodes.map((code) {
                  final checked = localeCtrl.locale?.languageCode == code;
                  return CheckedPopupMenuItem<String?>(
                    value: code,
                    checked: checked,
                    child: Text(_langDisplay(code)),
                  );
                }),
              ];
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _welcomeText(currentCode),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                Text(
                  '${_youAreInLabel(currentCode)}: ${_langDisplay(currentCode)}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(height: 28),
                FilledButton.icon(
                  icon: const Icon(Icons.arrow_forward),
                  label: Text(_continueLabel(currentCode)),
                  onPressed: () => Navigator.pushReplacementNamed(context, '/mixer'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _systemFallbackCode(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode;
    if (['es', 'en', 'pt'].contains(code)) return code;
    return 'en';
  }
}
