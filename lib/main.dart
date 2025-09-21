// lib/main.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'mixer/mixer_page.dart';

// i18n:
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/generated/app_localizations.dart'; // generado por gen_l10n

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    // ignore: avoid_print
    print('FlutterError: ${details.exception}\n${details.stack}');
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    // ignore: avoid_print
    print('Platform error: $error\n$stack');
    return true;
  };

  runApp(const FocusNoiseApp());

  WidgetsBinding.instance.addPostFrameCallback((_) {
    // ignore: discarded_futures
    _initAudioContext();
  });
}

Future<void> _initAudioContext() async {
  try {
    final ctx = AudioContext(
      android: AudioContextAndroid(
        contentType: AndroidContentType.music,
        usageType: AndroidUsageType.media,
        audioFocus: AndroidAudioFocus.none,
      ),
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.playback,
        options: {AVAudioSessionOptions.mixWithOthers},
      ),
    );
    await AudioPlayer.global.setAudioContext(ctx);
  } catch (e) {
    // ignore: avoid_print
    print('Audio init failed: $e');
  }
}

class FocusNoiseApp extends StatelessWidget {
  const FocusNoiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Usa onGenerateTitle para acceder a context:
      onGenerateTitle: (ctx) => AppLocalizations.of(ctx)?.appTitle ?? 'FocusNoise',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlue),
        useMaterial3: true,
      ),
      // Delegados y locales soportados del código generado
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const MixerPage(),
    );
  }
}
