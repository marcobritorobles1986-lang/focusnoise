import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:audio_service/audio_service.dart';

import 'mixer_audio_handler.dart';

late final AudioHandler audioHandler;

Future<void> initAudioService() async {
  // En Android: configura el canal de notificación, icono, etc.
  // En otras plataformas: usa un config “vacío” para evitar errores de compilación.
  final config = (!kIsWeb && Platform.isAndroid)
      ? AudioServiceConfig(
    androidNotificationChannelId: 'com.focusnoise.playback',
    androidNotificationChannelName: 'Focus Noise',
    androidNotificationIcon: 'mipmap/ic_launcher',
    androidStopForegroundOnPause: false,
    androidNotificationOngoing: true,
  )
      : AudioServiceConfig();

  audioHandler = await AudioService.init(
    builder: () => MixerAudioHandler(),
    config: config, // <- sin const
  );
}
