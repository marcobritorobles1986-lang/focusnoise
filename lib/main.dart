// lib/main.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'mixer/mixer_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Atrapa cualquier excepción temprana
  runZonedGuarded(() async {
    // Contexto global de audioplayers: mezcla con otras apps y entre players
    final ctx = AudioContext(
      android: AudioContextAndroid(
        contentType: AndroidContentType.music,
        usageType: AndroidUsageType.media,
        // No pedir audio focus para que no se pausen entre sí
        audioFocus: AndroidAudioFocus.none,
      ),
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.playback,
        options: {AVAudioSessionOptions.mixWithOthers},
      ),
    );
    await AudioPlayer.global.setAudioContext(ctx);

    runApp(const FocusNoiseApp());
  }, (e, st) {
    debugPrint('Uncaught in main: $e\n$st');
  });
}

class FocusNoiseApp extends StatelessWidget {
  const FocusNoiseApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FocusNoise',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlue),
        useMaterial3: true,
      ),
      home: const MixerPage(),
    );
  }
}
