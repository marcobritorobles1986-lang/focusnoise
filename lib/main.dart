// lib/main.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'mixer/mixer_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Envía errores de Flutter al Zone (para no crashear silencioso).
  FlutterError.onError = (details) {
    Zone.current.handleUncaughtError(
      details.exception,
      details.stack ?? StackTrace.current,
    );
  };

  runZonedGuarded(() {
    // 1) Render inmediato (sin awaits)
    runApp(const FocusNoiseApp());

    // 2) Trabajo no-crítico después del primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // ignore: discarded_futures
      _initAudioContext(); // no bloquea la UI
      // Aquí podrías agregar otros warmups no críticos:
      // - precacheImage(...)
      // - Isolate.run(() => parsear algo grande)
    });
  }, (e, st) {
    // Log centralizado
    // ignore: avoid_print
    print('Uncaught in zone: $e\n$st');
  });
}

Future<void> _initAudioContext() async {
  try {
    final ctx = AudioContext(
      android: AudioContextAndroid(
        contentType: AndroidContentType.music,
        usageType: AndroidUsageType.media,
        audioFocus: AndroidAudioFocus.none, // no interrumpe otras apps
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
      title: 'FocusNoise',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlue),
        useMaterial3: true,
      ),
      // Mostramos una pantalla mínima para asegurar primer frame rápido
      home: const _BootScreen(),
    );
  }
}

/// Pantalla mínima que se muestra 1 frame y salta al home real.
class _BootScreen extends StatefulWidget {
  const _BootScreen({super.key});
  @override
  State<_BootScreen> createState() => _BootScreenState();
}

class _BootScreenState extends State<_BootScreen> {
  @override
  void initState() {
    super.initState();
    // Navega al home real en el siguiente microtask (no bloquea)
    scheduleMicrotask(() {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => MixerPage()), // <- sin const
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Ultra liviano para asegurar que el primer frame salga YA
    return const Scaffold(
      body: Center(
        child: Text('FocusNoise', style: TextStyle(fontSize: 22)),
      ),
    );
  }
}
