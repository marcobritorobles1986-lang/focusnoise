import 'package:audio_service/audio_service.dart';

class MixerBus {
  static Future<void> Function()? onPlayAll;
  static Future<void> Function()? onPauseAll;
  static Future<void> Function()? onStopAll;
  static bool Function()? isAnyOn;
}

class MixerAudioHandler extends BaseAudioHandler {
  MixerAudioHandler() {
    mediaItem.add(const MediaItem(
      id: 'focusnoise.mix',
      title: 'Focus Noise',
      album: 'Mix en curso',
      artist: 'Mezclador',
    ));
    _broadcast(playing: false, processing: AudioProcessingState.ready);
  }

  void _broadcast({required bool playing, required AudioProcessingState processing}) {
    playbackState.add(PlaybackState(
      controls: playing
          ? const [MediaControl.pause, MediaControl.stop]
          : const [MediaControl.play, MediaControl.stop],
      androidCompactActionIndices: const [0, 1],
      processingState: processing,
      playing: playing,
    ));
  }

  @override
  Future<void> play() async {
    await MixerBus.onPlayAll?.call();
    _broadcast(playing: true, processing: AudioProcessingState.ready);
  }

  @override
  Future<void> pause() async {
    await MixerBus.onPauseAll?.call();
    _broadcast(playing: false, processing: AudioProcessingState.ready);
  }

  @override
  Future<void> stop() async {
    await MixerBus.onStopAll?.call();
    _broadcast(playing: false, processing: AudioProcessingState.idle);
  }
}
