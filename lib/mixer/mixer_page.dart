import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart' show rootBundle; // verificación de assets
import 'dart:io' show Platform;                         // aviso iOS
import '../audio/noise_audio.dart';

class MixerPage extends StatefulWidget {
  const MixerPage({super.key});
  @override
  State<MixerPage> createState() => _MixerPageState();
}

/// ==== Tema UI (3 estilos) ====
class _UiTheme {
  final String name;
  final Color main;
  final Color lite;
  final Color chipSelectedBg; // con alpha
  final List<Color> headerGradient;
  final Color visBar;
  final Color visBgOverlay;

  const _UiTheme({
    required this.name,
    required this.main,
    required this.lite,
    required this.chipSelectedBg,
    required this.headerGradient,
    required this.visBar,
    required this.visBgOverlay,
  });
}

const _themes = <_UiTheme>[
  _UiTheme(
    name: 'Océano',
    main: Color(0xFF64B5F6),
    lite: Color(0xFF90CAF9),
    chipSelectedBg: Color(0x2A64B5F6),
    headerGradient: [Color(0xFF90CAF9), Color(0xFF64B5F6)],
    visBar: Color(0xFF90CAF9),
    visBgOverlay: Color(0x143A86D1),
  ),
  _UiTheme(
    name: 'Atardecer',
    main: Color(0xFFFF8A65),
    lite: Color(0xFFFFAB91),
    chipSelectedBg: Color(0x2AFF8A65),
    headerGradient: [Color(0xFFFFAB91), Color(0xFFFF7043)],
    visBar: Color(0xFFFFAB91),
    visBgOverlay: Color(0x14FF6E40),
  ),
  _UiTheme(
    name: 'Bosque',
    main: Color(0xFF66BB6A),
    lite: Color(0xFFA5D6A7),
    chipSelectedBg: Color(0x2A66BB6A),
    headerGradient: [Color(0xFFA5D6A7), Color(0xFF66BB6A)],
    visBar: Color(0xFFA5D6A7),
    visBgOverlay: Color(0x143E8E41),
  ),
];

class _MixerPageState extends State<MixerPage> {
  // ======= Claves de persistencia =======
  static const _kPresetIndexKey = 'presets_index'; // lista de nombres guardados
  static const _kThemeIdxKey = 'ui_theme_idx';

  // Control de nombre para presets
  final TextEditingController _presetNameCtrl = TextEditingController();

  // Tema actual
  int _themeIndex = 0;
  _UiTheme get T => _themes[_themeIndex];

  // ======= Generadores offline =======
  final gen = NoiseAudio(sampleRate: 44100);

  // Players principales
  late final AudioPlayer whitePlayer;
  late final AudioPlayer pinkPlayer;
  late final AudioPlayer brownPlayer;
  late final AudioPlayer binauralPlayer;

  // Bytes on-demand (nullable para diferir generación)
  Uint8List? whiteBytes, pinkBytes, brownBytes, binauralBytes;

  bool whiteOn = false, pinkOn = false, brownOn = false, binauralOn = false;
  double whiteVol = 0.5, pinkVol = 0.4, brownVol = 0.4, binauralVol = 0.3;

  // Players adicionales offline
  late final AudioPlayer bluePlayer;
  late final AudioPlayer violetPlayer;
  late final AudioPlayer windPlayer;
  late final AudioPlayer rainPlayer;
  late final AudioPlayer wavesPlayer;
  late final AudioPlayer fireSynthPlayer;

  Uint8List? blueBytes, violetBytes, windBytes, rainBytes, wavesBytes, fireBytes;

  bool blueOn = false, violetOn = false, windOn = false, rainOn = false, wavesOn = false, fireOn = false;
  double blueVol = 0.35, violetVol = 0.30, windVol = 0.45, rainVol = 0.45, wavesVol = 0.45, fireVol = 0.40;

  // ======= Ambientes por assets (con categorías) =======
  final List<_AssetTrack> _assetDefs = [
    _AssetTrack(
      'Please Calm my Mind',
      'audio/ogg/please-calm-my-mind-125566.ogg',
      'Musica Relajante',
      credit: Credit(
        'Please Calm my Mind',
        'Autor: music_for_video',
        'Pixabay License',
        'https://pixabay.com/es/users/music_for_video-22579021/?utm_source=link-attribution&utm_medium=referral&utm_campaign=music&utm_content=125566',
      ),
    ),
    _AssetTrack(
      'Just Relax',
      'audio/ogg/just-relax-11157.ogg',
      'Musica Relajante',
      credit: Credit(
        'Just Relax',
        'Autor: music_for_video',
        'Pixabay License',
        'https://pixabay.com/es/users/music_for_video-22579021/?utm_source=link-attribution&utm_medium=referral&utm_campaign=music&utm_content=125566',
      ),
    ),
    _AssetTrack(
      'Battle Of The Dragons',
      'audio/ogg/battle-of-the-dragons-8037.ogg',
      'Musica Epica',
      credit: Credit(
        'Battle Of The Dragons',
        'Autor: ',
        'Pixabay License',
        'https://pixabay.com/es/music/titulo-principal-battle-of-the-dragons-8037',
      ),
    ),
    _AssetTrack(
      'Inspirational Uplifting Calm Piano',
      'audio/ogg/inspirational-uplifting-calm-piano-254764.ogg',
      'Musica Relajante',
      credit: Credit(
        'Inspirational Uplifting Calm Piano',
        'Autor: NikitaKondrashev',
        'Pixabay License',
        'https://pixabay.com/es/users/nikitakondrashev-42823964',
      ),
    ),
    _AssetTrack(
      'Epic- 3',
      'audio/ogg/epic-3-226201.ogg',
      'Musica Relajante',
      credit: Credit(
        'Epic- 3',
        'Autor: SenorMusica81',
        'Pixabay License',
        'https://pixabay.com/es/users/senormusica81-44746308',
      ),
    ),
    _AssetTrack(
      'Epic Emoctional_Long',
      'audio/ogg/epic-relaxing-flute-music-144009.ogg',
      'Musica Epica',
      credit: Credit(
        'Epic Emoctional_Long',
        'Autor: Grand_Project',
        'Pixabay License',
        'https://pixabay.com/es/users/grand_project-19033897',
      ),
    ),
    _AssetTrack(
      'Flute Meditation Music 5',
      'audio/ogg/flute-meditation-music-5-229769.ogg',
      'Musica Espiritual',
      credit: Credit(
        'Epic Emoctional_Long',
        'Autor: Ønetent',
        'Pixabay License',
        'https://pixabay.com/es/users/ønetent-38250704',
      ),
    ),
    _AssetTrack(
      'Epic Relaxing Flute Music',
      'audio/ogg/epic-relaxing-flute-music-144009.ogg',
      'Flauta Relajante',
      credit: Credit(
        'Epic Relaxing Flute Music',
        'Autor: Onetent',
        'Pixabay License',
        'https://pixabay.com/es/users/onetent-15616180',
      ),
    ),
    _AssetTrack(
      'Relaxing Music',
      'audio/ogg/epic-relaxing-flute-music-144009.ogg',
      'Meditación',
      credit: Credit(
        'Relaxing Music',
        'Autor: RelaxingTime',
        'Pixabay License',
        'https://pixabay.com/es/users/relaxingtime-17430502',
      ),
    ),
    _AssetTrack(
      'Sedative',
      'audio/ogg/sedative-110241.ogg',
      'Sedante',
      credit: Credit(
        'Sedative',
        'Autor: music_for_video',
        'Pixabay License',
        'https://pixabay.com/es/users/music_for_video-22579021',
      ),
    ),
    _AssetTrack(
      'The Cradle of your soul',
      'audio/ogg/the-cradle-of-your-soul-15700.ogg',
      'Guitarra Acustica',
      credit: Credit(
        'The Cradle of your soul',
        'Autor: lemonmusicstudio',
        'Pixabay License',
        'https://pixabay.com/es/users/lemonmusicstudio-14942887',
      ),
    ),
    _AssetTrack(
      'Dark atmosphere with rain',
      'audio/ogg/dark-atmosphere-with-rain-352570.ogg',
      'Sonido ambiente',
      credit: Credit(
        'Dark atmosphere with rain',
        'Autor: milagrosgomez',
        'Pixabay License',
        'https://pixabay.com/es/users/milagrosgomez-50598653',
      ),
    ),
    _AssetTrack(
      'Birds forest',
      'audio/ogg/birds39-forest-20772.ogg',
      'Sonido ambiente',
      credit: Credit(
        'Birds forest',
        'Autor: ShidenBeatsMusic',
        'Pixabay License',
        'https://pixabay.com/es/users/shidenbeatsmusic-25676252',
      ),
    ),
    _AssetTrack(
      'sea',
      'audio/ogg/sea-396080.ogg',
      'Sonido ambiente',
      credit: Credit(
        'Birds forest',
        'Autor: uchihadace1st',
        'Pixabay License',
        'https://pixabay.com/es/users/uchihadace1st-52017283',
      ),
    ),
  ];

  // Player/estado para cada asset
  late final List<AudioPlayer> _assetPlayers;
  late final List<bool> _assetOn;
  late final List<double> _assetVol;

  // ======= Categorías =======
  late List<String> _categories; // ['Todos','Generadores', ...categorías únicas]
  String _activeCategory = 'Todos';

  // ======= Timer de sueño =======
  Timer? _sleepTimer;
  Timer? _uiTicker;
  Timer? _sleepPrefadeTimer; // pre-fade 5s antes de terminar
  DateTime? _sleepAt; // mostrar cuenta atrás

  // ======= Control global (reproductor) =======
  bool _pausedAll = false;

  bool _ready = false;

  // ======= Master gain =======
  double _masterGain = 0.85; // volumen maestro 0..1

  String _presetKey(String name) => 'preset:$name';

  // ---- Helper: crear players listos para mezclar ----
  Future<AudioPlayer> _newLoopingPlayer() async {
    final p = AudioPlayer();
    await p.setPlayerMode(PlayerMode.mediaPlayer); // permite mezcla
    await p.setReleaseMode(ReleaseMode.loop);
    return p;
  }

  @override
  void initState() {
    super.initState();
    _initAudio();
  }

  Future<void> _initAudio() async {
    // Cargar tema persistido
    final sp = await SharedPreferences.getInstance();
    _themeIndex = (sp.getInt(_kThemeIdxKey) ?? 0).clamp(0, _themes.length - 1);

    // Players principales
    whitePlayer = await _newLoopingPlayer();
    pinkPlayer = await _newLoopingPlayer();
    brownPlayer = await _newLoopingPlayer();
    binauralPlayer = await _newLoopingPlayer();

    // Players nuevos offline
    bluePlayer = await _newLoopingPlayer();
    violetPlayer = await _newLoopingPlayer();
    windPlayer = await _newLoopingPlayer();
    rainPlayer = await _newLoopingPlayer();
    wavesPlayer = await _newLoopingPlayer();
    fireSynthPlayer = await _newLoopingPlayer();

    // Players para assets
    _assetPlayers = [];
    for (var i = 0; i < _assetDefs.length; i++) {
      _assetPlayers.add(await _newLoopingPlayer());
    }

    _assetOn = List<bool>.filled(_assetDefs.length, false);
    _assetVol = List<double>.filled(_assetDefs.length, 0.4);

    // Categorías (únicas) + fijos
    _categories = [
      'Todos',
      'Generadores',
      ..._assetDefs.map((e) => e.category).toSet(),
    ];

    setState(() {
      _activeCategory = 'Todos';
      _ready = true;
    });

    // Precalentamiento en background (no bloquea UI)
    _precomputeInBackground();
  }

  // Genera todos los loops poco a poco para no congelar
  Future<void> _precomputeInBackground() async {
    whiteBytes = gen.whiteNoiseWav(seconds: 15); await Future.delayed(const Duration(milliseconds: 1));
    pinkBytes  = gen.pinkNoiseWav(seconds: 15);  await Future.delayed(const Duration(milliseconds: 1));
    brownBytes = gen.brownNoiseWav(seconds: 15); await Future.delayed(const Duration(milliseconds: 1));
    binauralBytes = gen.binauralBeatWav(seconds: 15, baseHz: 220, beatHz: 10); await Future.delayed(const Duration(milliseconds: 1));

    blueBytes   = gen.blueNoiseWav(seconds: 18);   await Future.delayed(const Duration(milliseconds: 1));
    violetBytes = gen.violetNoiseWav(seconds: 18); await Future.delayed(const Duration(milliseconds: 1));
    windBytes   = gen.windSynthWav(seconds: 22, gustiness: 0.6); await Future.delayed(const Duration(milliseconds: 1));
    rainBytes   = gen.rainSynthWav(seconds: 22, density: 0.4);    await Future.delayed(const Duration(milliseconds: 1));
    wavesBytes  = gen.wavesSynthWav(seconds: 28, swellHz: 0.11, choppiness: 0.42); await Future.delayed(const Duration(milliseconds: 1));
    fireBytes   = gen.fireplaceSynthWav(seconds: 22, crackleDensity: 0.7);
  }

  @override
  void dispose() {
    for (final p in _assetPlayers) {
      p.dispose();
    }
    whitePlayer.dispose();
    pinkPlayer.dispose();
    brownPlayer.dispose();
    binauralPlayer.dispose();

    bluePlayer.dispose();
    violetPlayer.dispose();
    windPlayer.dispose();
    rainPlayer.dispose();
    wavesPlayer.dispose();
    fireSynthPlayer.dispose();

    _sleepTimer?.cancel();
    _sleepPrefadeTimer?.cancel();
    _uiTicker?.cancel();

    _presetNameCtrl.dispose();
    super.dispose();
  }

  // ======= Helpers de volumen/mezcla =======

  // Aplica volumen real = volumen de pista * master
  Future<void> _applyVolume(AudioPlayer p, double vol) async {
    final v = (vol * _masterGain).clamp(0.0, 1.0);
    await p.setVolume(v);
  }

  // Reaplica volúmenes actuales a TODO lo activo (tras cambiar master o cancelar timer)
  Future<void> _applyAllCurrentVolumes() async {
    if (whiteOn) await _applyVolume(whitePlayer, whiteVol);
    if (pinkOn) await _applyVolume(pinkPlayer, pinkVol);
    if (brownOn) await _applyVolume(brownPlayer, brownVol);
    if (binauralOn) await _applyVolume(binauralPlayer, binauralVol);

    if (blueOn) await _applyVolume(bluePlayer, blueVol);
    if (violetOn) await _applyVolume(violetPlayer, violetVol);
    if (windOn) await _applyVolume(windPlayer, windVol);
    if (rainOn) await _applyVolume(rainPlayer, rainVol);
    if (wavesOn) await _applyVolume(wavesPlayer, wavesVol);
    if (fireOn) await _applyVolume(fireSynthPlayer, fireVol);

    for (int a = 0; a < _assetPlayers.length; a++) {
      if (_assetOn[a]) await _applyVolume(_assetPlayers[a], _assetVol[a]);
    }
  }

  // MINI FADE para acciones puntuales (encender/apagar pista)
  Future<void> _fade({
    required AudioPlayer p,
    required double from,
    required double to,
    int ms = 300,
    int steps = 18,
  }) async {
    final dt = Duration(milliseconds: (ms / steps).round());
    for (var i = 0; i <= steps; i++) {
      final v = (from + (to - from) * (i / steps)).clamp(0.0, 1.0);
      await p.setVolume(v);
      await Future.delayed(dt);
    }
  }

  // Genera bytes si aún no existen
  Future<Uint8List> _ensureBytes(String id) async {
    switch (id) {
      case 'white':
        return whiteBytes ??= gen.whiteNoiseWav(seconds: 15);
      case 'pink':
        return pinkBytes ??= gen.pinkNoiseWav(seconds: 15);
      case 'brown':
        return brownBytes ??= gen.brownNoiseWav(seconds: 15);
      case 'binaural':
        return binauralBytes ??= gen.binauralBeatWav(seconds: 15, baseHz: 220, beatHz: 10);
      case 'blue':
        return blueBytes ??= gen.blueNoiseWav(seconds: 18);
      case 'violet':
        return violetBytes ??= gen.violetNoiseWav(seconds: 18);
      case 'wind':
        return windBytes ??= gen.windSynthWav(seconds: 22, gustiness: 0.6);
      case 'rain':
        return rainBytes ??= gen.rainSynthWav(seconds: 22, density: 0.4);
      case 'waves':
        return wavesBytes ??= gen.wavesSynthWav(seconds: 28, swellHz: 0.11, choppiness: 0.42);
      case 'fire':
        return fireBytes ??= gen.fireplaceSynthWav(seconds: 22, crackleDensity: 0.7);
      default:
        throw StateError('id desconocido: $id');
    }
  }

  // Reproducir/parar con generación on-demand (con fade y manejo de errores)
  Future<void> _toggleBytes(AudioPlayer p, String id, Uint8List? src, bool on, double vol) async {
    if (on) {
      try {
        await p.setVolume(0.0);
        final bytes = src ?? await _ensureBytes(id);
        await p.play(BytesSource(bytes));
        await _fade(p: p, from: 0.0, to: (vol * _masterGain).clamp(0.0, 1.0), ms: 280);
        if (_pausedAll) _pausedAll = false;
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No se pudo reproducir $id')),
          );
        }
      }
    } else {
      await _fade(p: p, from: (vol * _masterGain).clamp(0.0, 1.0), to: 0.0, ms: 220);
      await p.stop();
      await p.setVolume(vol); // valor lógico base
    }
    if (mounted) setState(() {});
  }

  Future<void> _toggleAsset(AudioPlayer p, String assetPath, bool on, double vol) async {
    // En pubspec declaraste: assets/audio/ogg/
    // audioplayers v6 suele esperar el path SIN 'assets/' → 'audio/ogg/...'
    final String relPath = assetPath.startsWith('assets/')
        ? assetPath.substring('assets/'.length)
        : assetPath;
    final String bundlePath = assetPath.startsWith('assets/')
        ? assetPath
        : 'assets/$assetPath';

    if (on) {
      try {
        await p.setVolume(0.0);

        // 1) intento estándar (lo que te funcionaba antes)
        await p.play(AssetSource(relPath));
      } catch (e1, st1) {
        // 2) plan B: algunos entornos esperan el prefijo (no debería, pero probamos)
        try {
          await p.play(AssetSource(bundlePath));
        } catch (e2, st2) {
          // Log útil para saber exactamente qué pasó
          // ignore: avoid_print
          print('[Mixer] Asset play failed\n'
              ' - rel: $relPath  err: $e1\n$st1\n'
              ' - bun: $bundlePath err: $e2\n$st2\n');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('No se pudo reproducir: $relPath')),
            );
            final idx = _assetDefs.indexWhere((t) => t.assetPath == assetPath);
            if (idx >= 0) _assetOn[idx] = false;
          }
          setState(() {});
          return; // aborta
        }
      }

      await _fade(
        p: p,
        from: 0.0,
        to: (vol * _masterGain).clamp(0.0, 1.0),
        ms: 280,
      );
      if (_pausedAll) _pausedAll = false;
    } else {
      await _fade(
        p: p,
        from: (vol * _masterGain).clamp(0.0, 1.0),
        to: 0.0,
        ms: 220,
      );
      await p.stop();
      await p.setVolume(vol);
    }
    if (mounted) setState(() {});
  }


  // Fade-out global (considera master)
  Future<void> _fadeAllOut({int ms = 800}) async {
    final steps = 16;
    final delay = Duration(milliseconds: (ms / steps).round());

    final w = whiteVol * _masterGain,
        p = pinkVol * _masterGain,
        b = brownVol * _masterGain,
        bb = binauralVol * _masterGain;
    final bl = blueVol * _masterGain,
        vi = violetVol * _masterGain,
        wi = windVol * _masterGain,
        ra = rainVol * _masterGain,
        wa = wavesVol * _masterGain,
        fi = fireVol * _masterGain;
    final assetsVolCopy = _assetVol.map((v) => v * _masterGain).toList(growable: false);

    for (int i = 0; i < steps; i++) {
      final k = 1 - (i + 1) / steps;
      if (whiteOn) await whitePlayer.setVolume(w * k);
      if (pinkOn) await pinkPlayer.setVolume(p * k);
      if (brownOn) await brownPlayer.setVolume(b * k);
      if (binauralOn) await binauralPlayer.setVolume(bb * k);

      if (blueOn) await bluePlayer.setVolume(bl * k);
      if (violetOn) await violetPlayer.setVolume(vi * k);
      if (windOn) await windPlayer.setVolume(wi * k);
      if (rainOn) await rainPlayer.setVolume(ra * k);
      if (wavesOn) await wavesPlayer.setVolume(wa * k);
      if (fireOn) await fireSynthPlayer.setVolume(fi * k);

      for (int a = 0; a < _assetPlayers.length; a++) {
        if (_assetOn[a]) await _assetPlayers[a].setVolume(assetsVolCopy[a] * k);
      }
      await Future.delayed(delay);
    }

    if (whiteOn) await whitePlayer.stop();
    if (pinkOn) await pinkPlayer.stop();
    if (brownOn) await brownPlayer.stop();
    if (binauralOn) await binauralPlayer.stop();

    if (blueOn) await bluePlayer.stop();
    if (violetOn) await violetPlayer.stop();
    if (windOn) await windPlayer.stop();
    if (rainOn) await rainPlayer.stop();
    if (wavesOn) await wavesPlayer.stop();
    if (fireOn) await fireSynthPlayer.stop();

    for (int a = 0; a < _assetPlayers.length; a++) {
      if (_assetOn[a]) await _assetPlayers[a].stop();
    }

    setState(() {
      whiteOn = pinkOn = brownOn = binauralOn = false;
      blueOn = violetOn = windOn = rainOn = wavesOn = fireOn = false;
      for (int a = 0; a < _assetOn.length; a++) {
        _assetOn[a] = false;
      }
      _pausedAll = false;
    });
  }

  // Pre-fade global (baja volumen, no detiene)
  Future<void> _fadeDownOnly({int ms = 5000}) async {
    final steps = 24;
    final delay = Duration(milliseconds: (ms / steps).round());

    final w = whiteVol * _masterGain,
        p = pinkVol * _masterGain,
        b = brownVol * _masterGain,
        bb = binauralVol * _masterGain;
    final bl = blueVol * _masterGain,
        vi = violetVol * _masterGain,
        wi = windVol * _masterGain,
        ra = rainVol * _masterGain,
        wa = wavesVol * _masterGain,
        fi = fireVol * _masterGain;
    final assetsVolCopy = _assetVol.map((v) => v * _masterGain).toList(growable: false);

    for (int i = 0; i < steps; i++) {
      final k = 1 - (i + 1) / steps;
      if (whiteOn) await whitePlayer.setVolume(w * k);
      if (pinkOn) await pinkPlayer.setVolume(p * k);
      if (brownOn) await brownPlayer.setVolume(b * k);
      if (binauralOn) await binauralPlayer.setVolume(bb * k);

      if (blueOn) await bluePlayer.setVolume(bl * k);
      if (violetOn) await violetPlayer.setVolume(vi * k);
      if (windOn) await windPlayer.setVolume(wi * k);
      if (rainOn) await rainPlayer.setVolume(ra * k);
      if (wavesOn) await wavesPlayer.setVolume(wa * k);
      if (fireOn) await fireSynthPlayer.setVolume(fi * k);

      for (int a = 0; a < _assetPlayers.length; a++) {
        if (_assetOn[a]) await _assetPlayers[a].setVolume(assetsVolCopy[a] * k);
      }
      await Future.delayed(delay);
    }
  }

  // Master gain setter
  Future<void> _setMasterGain(double g) async {
    setState(() => _masterGain = g.clamp(0.0, 1.0));
    await _applyAllCurrentVolumes();
  }

  // Pausar/Reanudar TODO lo encendido
  Future<void> _pauseAll() async {
    if (!_anyTrackOn()) return;
    if (whiteOn) await whitePlayer.pause();
    if (pinkOn) await pinkPlayer.pause();
    if (brownOn) await brownPlayer.pause();
    if (binauralOn) await binauralPlayer.pause();

    if (blueOn) await bluePlayer.pause();
    if (violetOn) await violetPlayer.pause();
    if (windOn) await windPlayer.pause();
    if (rainOn) await rainPlayer.pause();
    if (wavesOn) await wavesPlayer.pause();
    if (fireOn) await fireSynthPlayer.pause();

    for (int i = 0; i < _assetPlayers.length; i++) {
      if (_assetOn[i]) await _assetPlayers[i].pause();
    }
    setState(() => _pausedAll = true);
  }

  Future<void> _resumeAll() async {
    if (!_anyTrackOn()) return;
    if (whiteOn) await whitePlayer.resume();
    if (pinkOn) await pinkPlayer.resume();
    if (brownOn) await brownPlayer.resume();
    if (binauralOn) await binauralPlayer.resume();

    if (blueOn) await bluePlayer.resume();
    if (violetOn) await violetPlayer.resume();
    if (windOn) await windPlayer.resume();
    if (rainOn) await rainPlayer.resume();
    if (wavesOn) await wavesPlayer.resume();
    if (fireOn) await fireSynthPlayer.resume();

    for (int i = 0; i < _assetPlayers.length; i++) {
      if (_assetOn[i]) await _assetPlayers[i].resume();
    }
    setState(() => _pausedAll = false);
  }

  bool _anyTrackOn() {
    if (whiteOn || pinkOn || brownOn || binauralOn || blueOn || violetOn || windOn || rainOn || wavesOn || fireOn) return true;
    for (final b in _assetOn) {
      if (b) return true;
    }
    return false;
  }

  // Nivel de “actividad” aproximado de la mezcla para animar la visual
  double get _activityLevel {
    double sum = 0;
    if (whiteOn) sum += whiteVol;
    if (pinkOn) sum += pinkVol;
    if (brownOn) sum += brownVol;
    if (binauralOn) sum += binauralVol;

    if (blueOn) sum += blueVol;
    if (violetOn) sum += violetVol;
    if (windOn) sum += windVol;
    if (rainOn) sum += rainVol;
    if (wavesOn) sum += wavesVol;
    if (fireOn) sum += fireVol;

    for (int i = 0; i < _assetVol.length; i++) {
      if (_assetOn[i]) sum += _assetVol[i];
    }
    return (sum * _masterGain).clamp(0.0, 4.0) / 4.0;
  }

  // ======= Presets "rápidos" (compat) =======
  Future<void> _savePreset() async {
    final sp = await SharedPreferences.getInstance();
    final data = _currentPresetPayload();
    await sp.setString('preset_default', jsonEncode(data));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preset guardado')));
    }
  }

  Future<void> _loadPreset() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString('preset_default');
    if (raw == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No hay preset guardado')));
      }
      return;
    }
    final data = jsonDecode(raw);
    await _applyPresetData(Map<String, dynamic>.from(data));
  }

  // ======= Presets con nombre (helpers) =======
  Map<String, dynamic> _currentPresetPayload() {
    return {
      'whiteOn': whiteOn, 'whiteVol': whiteVol,
      'pinkOn': pinkOn, 'pinkVol': pinkVol,
      'brownOn': brownOn, 'brownVol': brownVol,
      'binauralOn': binauralOn, 'binauralVol': binauralVol,

      'blueOn': blueOn, 'blueVol': blueVol,
      'violetOn': violetOn, 'violetVol': violetVol,
      'windOn': windOn, 'windVol': windVol,
      'rainOn': rainOn, 'rainVol': rainVol,
      'wavesOn': wavesOn, 'wavesVol': wavesVol,
      'fireOn': fireOn, 'fireVol': fireVol,

      'assets': List.generate(_assetDefs.length, (i) => {
        'on': _assetOn[i],
        'vol': _assetVol[i],
        'key': _assetDefs[i].assetPath,
      }),
    };
  }

  Future<void> _applyPresetData(Map<String, dynamic> data) async {
    setState(() {
      whiteOn = data['whiteOn'] ?? false;   whiteVol = (data['whiteVol'] ?? 0.5).toDouble();
      pinkOn  = data['pinkOn']  ?? false;   pinkVol  = (data['pinkVol']  ?? 0.4).toDouble();
      brownOn = data['brownOn'] ?? false;   brownVol = (data['brownVol'] ?? 0.4).toDouble();
      binauralOn = data['binauralOn'] ?? false; binauralVol = (data['binauralVol'] ?? 0.3).toDouble();

      blueOn   = data['blueOn']   ?? false; blueVol   = (data['blueVol']   ?? 0.35).toDouble();
      violetOn = data['violetOn'] ?? false; violetVol = (data['violetVol'] ?? 0.30).toDouble();
      windOn   = data['windOn']   ?? false; windVol   = (data['windVol']   ?? 0.45).toDouble();
      rainOn   = data['rainOn']   ?? false; rainVol   = (data['rainVol']   ?? 0.45).toDouble();
      wavesOn  = data['wavesOn']  ?? false; wavesVol  = (data['wavesVol']  ?? 0.45).toDouble();
      fireOn   = data['fireOn']   ?? false; fireVol   = (data['fireVol']   ?? 0.40).toDouble();

      if (data['assets'] is List) {
        final list = data['assets'] as List;
        for (int i = 0; i < _assetDefs.length && i < list.length; i++) {
          _assetOn[i]  = (list[i]['on']  ?? false) as bool;
          _assetVol[i] = (list[i]['vol'] ?? 0.4).toDouble();
        }
      }
    });

    // Ajusta reproducción según el estado cargado (on-demand)
    await _toggleBytes(whitePlayer,   'white',   whiteBytes,    whiteOn,    whiteVol);
    await _toggleBytes(pinkPlayer,    'pink',    pinkBytes,     pinkOn,     pinkVol);
    await _toggleBytes(brownPlayer,   'brown',   brownBytes,    brownOn,    brownVol);
    await _toggleBytes(binauralPlayer,'binaural',binauralBytes, binauralOn, binauralVol);

    await _toggleBytes(bluePlayer,    'blue',    blueBytes,     blueOn,     blueVol);
    await _toggleBytes(violetPlayer,  'violet',  violetBytes,   violetOn,   violetVol);
    await _toggleBytes(windPlayer,    'wind',    windBytes,     windOn,     windVol);
    await _toggleBytes(rainPlayer,    'rain',    rainBytes,     rainOn,     rainVol);
    await _toggleBytes(wavesPlayer,   'waves',   wavesBytes,    wavesOn,    wavesVol);
    await _toggleBytes(fireSynthPlayer,'fire',   fireBytes,     fireOn,     fireVol);

    for (int i = 0; i < _assetDefs.length; i++) {
      await _toggleAsset(_assetPlayers[i], _assetDefs[i].assetPath, _assetOn[i], _assetVol[i]);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preset cargado')));
    }
  }

  Future<List<String>> _getPresetNames() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getStringList(_kPresetIndexKey) ?? <String>[];
  }

  Future<void> _setPresetNames(List<String> names) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setStringList(_kPresetIndexKey, names);
  }

  Future<void> _savePresetNamed(String name, {bool silent = false}) async {
    final sp = await SharedPreferences.getInstance();
    final names = await _getPresetNames();
    if (!names.contains(name)) {
      names.add(name);
      names.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      await _setPresetNames(names);
    }
    final data = _currentPresetPayload();
    await sp.setString(_presetKey(name), jsonEncode(data));
    if (mounted && !silent) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Preset "$name" guardado')));
    }
  }

  Future<void> _loadPresetNamed(String name) async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_presetKey(name));
    if (raw == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se encontró "$name"')));
      }
      return;
    }
    final data = jsonDecode(raw) as Map<String, dynamic>;
    await _applyPresetData(data);
  }

  Future<void> _deletePreset(String name) async {
    final sp = await SharedPreferences.getInstance();
    final names = await _getPresetNames();
    names.remove(name);
    await _setPresetNames(names);
    await sp.remove(_presetKey(name));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Preset "$name" eliminado')));
    }
  }

  Future<void> _renamePreset(String oldName, String newName) async {
    if (oldName == newName) return;
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_presetKey(oldName));
    if (raw == null) return;

    final names = await _getPresetNames();
    if (!names.contains(oldName)) return;
    if (!names.contains(newName)) names.add(newName);
    names.remove(oldName);
    names.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    await _setPresetNames(names);

    await sp.setString(_presetKey(newName), raw);
    await sp.remove(_presetKey(oldName));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Renombrado a "$newName"')));
    }
  }

  // ======= UI flujos de presets con nombre =======
  Future<bool> _confirmOverwrite(String name) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sobrescribir preset'),
        content: Text('Ya existe un preset llamado "$name". ¿Quieres sobrescribirlo?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sobrescribir')),
        ],
      ),
    ) ?? false;
  }

  void _savePresetFlow() async {
    _presetNameCtrl.text = '';
    final names = await _getPresetNames();

    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Guardar preset'),
        content: TextField(
          controller: _presetNameCtrl,
          autofocus: true,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'Nombre del preset',
            hintText: 'Ej.: Foco Suave',
          ),
          onSubmitted: (_) => Navigator.pop(ctx, _presetNameCtrl.text.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, _presetNameCtrl.text.trim()), child: const Text('Guardar')),
        ],
      ),
    );

    if (name == null) return;
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El nombre no puede estar vacío')));
      return;
    }

    if (names.contains(trimmed)) {
      final ok = await _confirmOverwrite(trimmed);
      if (!ok) return;
    }
    await _savePresetNamed(trimmed);
  }

  void _showPresetPicker() async {
    final names = await _getPresetNames();
    // ignore: use_build_context_synchronously
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          children: [
            const ListTile(
              leading: Icon(Icons.star_border),
              title: Text('Tus presets'),
              subtitle: Text('Toca para cargar. Mantén pulsado para renombrar.'),
            ),
            if (names.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Aún no tienes presets. Guarda uno con el botón de la estrella.'),
              ),
            if (names.isNotEmpty)
              Expanded(
                child: ListView.separated(
                  itemCount: names.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final n = names[i];
                    return ListTile(
                      leading: const Icon(Icons.playlist_play),
                      title: Text(n),
                      onTap: () async {
                        Navigator.pop(ctx);
                        await _loadPresetNamed(n);
                      },
                      onLongPress: () async {
                        _presetNameCtrl.text = n;
                        final newName = await showDialog<String>(
                          context: context,
                          builder: (dCtx) => AlertDialog(
                            title: const Text('Renombrar preset'),
                            content: TextField(
                              controller: _presetNameCtrl,
                              autofocus: true,
                              decoration: const InputDecoration(labelText: 'Nuevo nombre'),
                              onSubmitted: (_) => Navigator.pop(dCtx, _presetNameCtrl.text.trim()),
                            ),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Cancelar')),
                              FilledButton(onPressed: () => Navigator.pop(dCtx, _presetNameCtrl.text.trim()), child: const Text('Guardar')),
                            ],
                          ),
                        );
                        if (newName == null) return;
                        final trimmed = newName.trim();
                        if (trimmed.isEmpty) return;
                        if (trimmed != n && names.contains(trimmed)) {
                          final ok = await _confirmOverwrite(trimmed);
                          if (!ok) return;
                        }
                        await _renamePreset(n, trimmed);
                        if (mounted) Navigator.pop(context);
                        _showPresetPicker();
                      },
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          final sure = await showDialog<bool>(
                            context: context,
                            builder: (dCtx) => AlertDialog(
                              title: const Text('Eliminar preset'),
                              content: Text('¿Eliminar "$n"?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(dCtx, false), child: const Text('Cancelar')),
                                FilledButton(onPressed: () => Navigator.pop(dCtx, true), child: const Text('Eliminar')),
                              ],
                            ),
                          ) ?? false;
                          if (!sure) return;
                          await _deletePreset(n);
                          if (mounted) Navigator.pop(context);
                          _showPresetPicker();
                        },
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: FilledButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Nuevo preset'),
                onPressed: () {
                  Navigator.pop(ctx);
                  _savePresetFlow();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ======= Cambio de tema =======
  Future<void> _pickTheme() async {
    final idx = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              leading: Icon(Icons.palette_outlined),
              title: Text('Tema del reproductor'),
              subtitle: Text('Afecta colores, gradiente y visualizador'),
            ),
            for (int i = 0; i < _themes.length; i++)
              RadioListTile<int>(
                value: i,
                groupValue: _themeIndex,
                title: Text(_themes[i].name),
                onChanged: (v) => Navigator.pop(ctx, v),
              ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
    if (idx == null) return;
    setState(() => _themeIndex = idx);
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_kThemeIdxKey, _themeIndex);
  }

  // ======= Timer =======
  void _pickTimer() async {
    final minutes = await showModalBottomSheet<int>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const ListTile(title: Text('Temporizador')),
          for (final m in [15, 30, 45, 60, 90])
            ListTile(leading: const Icon(Icons.timer), title: Text('$m min'), onTap: () => Navigator.pop(ctx, m)),
          ListTile(leading: const Icon(Icons.clear), title: const Text('Cancelar temporizador'), onTap: () => Navigator.pop(ctx, -1)),
        ]),
      ),
    );

    if (!mounted || minutes == null) return;

    _sleepTimer?.cancel();
    _uiTicker?.cancel();
    _sleepPrefadeTimer?.cancel();
    _sleepAt = null;

    if (minutes > 0) {
      _sleepAt = DateTime.now().add(Duration(minutes: minutes));
      _sleepTimer = Timer(Duration(minutes: minutes), () async {
        await _fadeAllOut();
        if (mounted) setState(() => _sleepAt = null);
      });
      // Pre-fade 5s antes de terminar
      final until = _sleepAt!.difference(DateTime.now()) - const Duration(seconds: 5);
      if (!until.isNegative) {
        _sleepPrefadeTimer = Timer(until, () async {
          await _fadeDownOnly(ms: 4800);
        });
      }
      _uiTicker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    } else {
      // Cancelado: restaura volúmenes actuales por si estaba en pre-fade
      await _applyAllCurrentVolumes();
      setState(() {});
    }
  }

  String? get _remainingStr {
    if (_sleepAt == null) return null;
    final d = _sleepAt!.difference(DateTime.now());
    if (d.isNegative) return null;
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hh = d.inHours;
    return hh > 0 ? '$hh:$mm:$ss' : '$mm:$ss';
  }

  // ======= Helpers de links (Créditos) =======
  bool _isHttpUrl(String? s) {
    if (s == null) return false;
    final u = Uri.tryParse(s);
    return u != null && (u.scheme == 'http' || u.scheme == 'https');
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el enlace')),
      );
    }
  }

  // ======= UI =======

  Widget _visualHeader() {
    final timerCaption = _remainingStr;
    return Container(
      height: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        gradient: LinearGradient(
          colors: T.headerGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Mezcla para foco', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.white)),
              ),
              IconButton(
                tooltip: 'Cambiar tema',
                onPressed: _pickTheme,
                icon: const Icon(Icons.palette_outlined, color: Colors.white),
              ),
              IconButton(
                tooltip: 'Temporizador',
                onPressed: _pickTimer,
                icon: const Icon(Icons.timer_outlined, color: Colors.white),
              ),
              IconButton(
                tooltip: _pausedAll ? 'Reanudar mezcla' : 'Pausar mezcla',
                onPressed: _anyTrackOn() ? (_pausedAll ? _resumeAll : _pauseAll) : null,
                icon: Icon(_pausedAll ? Icons.play_arrow : Icons.pause, color: Colors.white),
              ),
              IconButton(
                tooltip: 'Fade-out y detener todo',
                onPressed: _anyTrackOn() ? () => _fadeAllOut(ms: 600) : null,
                icon: const Icon(Icons.stop_circle_outlined, color: Colors.white),
              ),
            ],
          ),
          if (timerCaption != null) const SizedBox(height: 6),
          if (timerCaption != null)
            const Text(
              'Timer activo',
              style: TextStyle(color: Colors.white70),
            ),
          Expanded(
            child: _VibesVisualizer(
              color: T.visBar,
              bgOverlay: T.visBgOverlay,
              active: _anyTrackOn() && !_pausedAll,
              level: _activityLevel,
              bars: 28,
              height: 80,
              speed: const Duration(milliseconds: 100), // un pelín más liviano
            ),
          ),
        ],
      ),
    );
  }

  Widget _track({
    required String title,
    String? subtitle,
    required bool on,
    required ValueChanged<bool> onChanged,
    required double volume,
    required ValueChanged<double> onVolume,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: T.main.withOpacity(0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            SwitchListTile(
              title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              subtitle: subtitle != null ? Text(subtitle) : null,
              value: on,
              activeColor: T.main,
              onChanged: onChanged,
            ),
            Row(
              children: [
                const Icon(Icons.volume_down),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: T.main,
                      thumbColor: T.main,
                    ),
                    child: Slider(value: volume, min: 0, max: 1, onChanged: onVolume),
                  ),
                ),
                const Icon(Icons.volume_up),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCredits() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _assetDefs.isEmpty
              ? const Text('No hay pistas externas. Agrega audios CC0/CC-BY en assets/audio/ y decláralos en pubspec.yaml.')
              : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Créditos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: _assetDefs.length,
                  itemBuilder: (_, i) {
                    final c = _assetDefs[i].credit;
                    return ListTile(
                      leading: const Icon(Icons.music_note),
                      title: Text(_assetDefs[i].title),
                      subtitle: c == null
                          ? const Text('CC0 (sin atribución)')
                          : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${c.title} — ${c.author}'),
                          Text(c.license),
                          if (_isHttpUrl(c.source))
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton(
                                onPressed: () => _openUrl(c.source!),
                                child: const Text('Ver más'),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final timerCaption = _remainingStr;

    final List<_AssetTrack> filteredAssets = (_activeCategory == 'Todos')
        ? _assetDefs
        : (_activeCategory == 'Generadores')
        ? <_AssetTrack>[]
        : _assetDefs.where((t) => t.category == _activeCategory).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(timerCaption == null ? 'FocusNoise Mixer' : 'FocusNoise • $timerCaption'),
        actions: [
          IconButton(tooltip: 'Créditos', onPressed: _showCredits, icon: const Icon(Icons.info_outline)),
          IconButton(tooltip: 'Guardar preset con nombre', onPressed: _savePresetFlow, icon: const Icon(Icons.star_border)),
          IconButton(tooltip: 'Mis presets', onPressed: _showPresetPicker, icon: const Icon(Icons.playlist_add_check)),
          PopupMenuButton<String>(
            tooltip: 'Tema',
            onSelected: (v) {
              final idx = _themes.indexWhere((t) => t.name == v);
              if (idx >= 0) _pickThemeDirect(idx);
            },
            itemBuilder: (ctx) => _themes
                .map((t) => PopupMenuItem<String>(
              value: t.name,
              child: Row(
                children: [
                  CircleAvatar(radius: 6, backgroundColor: t.main),
                  const SizedBox(width: 8),
                  Text(t.name),
                ],
              ),
            ))
                .toList(),
            icon: const Icon(Icons.palette_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _visualHeader(),
          const SizedBox(height: 12),

          // Volumen Maestro
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Volumen maestro', style: TextStyle(fontWeight: FontWeight.w700)),
                  Row(
                    children: [
                      const Icon(Icons.volume_mute_outlined),
                      Expanded(
                        child: Slider(
                          value: _masterGain,
                          min: 0,
                          max: 1,
                          onChanged: (v) => _setMasterGain(v),
                        ),
                      ),
                      const Icon(Icons.volume_up_outlined),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Selector de categorías (chips)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map((c) {
                final selected = _activeCategory == c;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(c),
                    selected: selected,
                    selectedColor: T.chipSelectedBg,
                    side: BorderSide(color: selected ? T.main : Colors.black12),
                    onSelected: (_) => setState(() => _activeCategory = c),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),

          // Generadores
          if (_activeCategory == 'Todos' || _activeCategory == 'Generadores') ...[
            const Text('Generadores (offline)', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            _track(
              title: 'Ruido Blanco',
              subtitle: 'Uniforme en todas las frecuencias',
              on: whiteOn,
              onChanged: (v) async {
                setState(() => whiteOn = v);
                await _toggleBytes(whitePlayer, 'white', whiteBytes, v, whiteVol);
              },
              volume: whiteVol,
              onVolume: (v) async {
                setState(() => whiteVol = v);
                await _applyVolume(whitePlayer, v);
              },
            ),
            _track(
              title: 'Ruido Rosa',
              subtitle: 'Más energía en bajas frecuencias (1/f)',
              on: pinkOn,
              onChanged: (v) async {
                setState(() => pinkOn = v);
                await _toggleBytes(pinkPlayer, 'pink', pinkBytes, v, pinkVol);
              },
              volume: pinkVol,
              onVolume: (v) async {
                setState(() => pinkVol = v);
                await _applyVolume(pinkPlayer, v);
              },
            ),
            _track(
              title: 'Ruido Marrón',
              subtitle: 'Suave, tipo oleaje/viento',
              on: brownOn,
              onChanged: (v) async {
                setState(() => brownOn = v);
                await _toggleBytes(brownPlayer, 'brown', brownBytes, v, brownVol);
              },
              volume: brownVol,
              onVolume: (v) async {
                setState(() => brownVol = v);
                await _applyVolume(brownPlayer, v);
              },
            ),
            _track(
              title: 'Binaural (220Hz ± 5Hz)',
              subtitle: 'Usa audífonos para percibir el beat',
              on: binauralOn,
              onChanged: (v) async {
                setState(() => binauralOn = v);
                await _toggleBytes(binauralPlayer, 'binaural', binauralBytes, v, binauralVol);
              },
              volume: binauralVol,
              onVolume: (v) async {
                setState(() => binauralVol = v);
                await _applyVolume(binauralPlayer, v);
              },
            ),
            _track(
              title: 'Ruido Azul',
              subtitle: 'Énfasis en altas frecuencias (+3 dB/oct)',
              on: blueOn,
              onChanged: (v) async {
                setState(() => blueOn = v);
                await _toggleBytes(bluePlayer, 'blue', blueBytes, v, blueVol);
              },
              volume: blueVol,
              onVolume: (v) async {
                setState(() => blueVol = v);
                await _applyVolume(bluePlayer, v);
              },
            ),
            _track(
              title: 'Ruido Violeta',
              subtitle: 'Altas aún más presentes (+6 dB/oct)',
              on: violetOn,
              onChanged: (v) async {
                setState(() => violetOn = v);
                await _toggleBytes(violetPlayer, 'violet', violetBytes, v, violetVol);
              },
              volume: violetVol,
              onVolume: (v) async {
                setState(() => violetVol = v);
                await _applyVolume(violetPlayer, v);
              },
            ),
            _track(
              title: 'Viento (sintético)',
              subtitle: 'Ráfagas suaves con envolvente lenta',
              on: windOn,
              onChanged: (v) async {
                setState(() => windOn = v);
                await _toggleBytes(windPlayer, 'wind', windBytes, v, windVol);
              },
              volume: windVol,
              onVolume: (v) async {
                setState(() => windVol = v);
                await _applyVolume(windPlayer, v);
              },
            ),
            _track(
              title: 'Lluvia (sintética)',
              subtitle: 'Hiss + gotitas aleatorias',
              on: rainOn,
              onChanged: (v) async {
                setState(() => rainOn = v);
                await _toggleBytes(rainPlayer, 'rain', rainBytes, v, rainVol);
              },
              volume: rainVol,
              onVolume: (v) async {
                setState(() => rainVol = v);
                await _applyVolume(rainPlayer, v);
              },
            ),
            _track(
              title: 'Olas (sintéticas)',
              subtitle: 'Rumble grave + espuma modulada',
              on: wavesOn,
              onChanged: (v) async {
                setState(() => wavesOn = v);
                await _toggleBytes(wavesPlayer, 'waves', wavesBytes, v, wavesVol);
              },
              volume: wavesVol,
              onVolume: (v) async {
                setState(() => wavesVol = v);
                await _applyVolume(wavesPlayer, v);
              },
            ),
            _track(
              title: 'Chimenea (sintética)',
              subtitle: 'Base cálida + chasquidos aleatorios',
              on: fireOn,
              onChanged: (v) async {
                setState(() => fireOn = v);
                await _toggleBytes(fireSynthPlayer, 'fire', fireBytes, v, fireVol);
              },
              volume: fireVol,
              onVolume: (v) async {
                setState(() => fireVol = v);
                await _applyVolume(fireSynthPlayer, v);
              },
            ),
          ],

          // Assets filtrados por categoría
          if (filteredAssets.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(),
            const Text('Ambientes (assets libres)', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            for (final track in filteredAssets)
              Builder(
                builder: (_) {
                  final realIndex = _assetDefs.indexOf(track);
                  return _track(
                    title: track.title,
                    subtitle: track.credit == null ? 'CC0 (sin atribución)' : '${track.credit!.license} — ${track.credit!.author}',
                    on: _assetOn[realIndex],
                    onChanged: (v) async {
                      setState(() => _assetOn[realIndex] = v);
                      await _toggleAsset(_assetPlayers[realIndex], track.assetPath, v, _assetVol[realIndex]);
                    },
                    volume: _assetVol[realIndex],
                    onVolume: (v) async {
                      setState(() => _assetVol[realIndex] = v);
                      await _applyVolume(_assetPlayers[realIndex], v);
                    },
                  );
                },
              ),
          ],

          const SizedBox(height: 8),
          const Text('Tip: mezcla 2–3 fuentes a volúmenes moderados (0.3–0.6) para evitar clipping.'),
        ],
      ),
    );
  }

  Future<void> _pickThemeDirect(int idx) async {
    setState(() => _themeIndex = idx);
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_kThemeIdxKey, _themeIndex);
  }
}

// ======= Visualizador de “vibraciones” liviano =======
class _VibesVisualizer extends StatefulWidget {
  final bool active;
  final double level; // 0..1
  final int bars;
  final double height;
  final Duration speed;
  final Color? color;
  final Color? bgOverlay;

  const _VibesVisualizer({
    super.key,
    required this.active,
    required this.level,
    this.bars = 24,
    this.height = 80,
    this.speed = const Duration(milliseconds: 100),
    this.color,
    this.bgOverlay,
  });

  @override
  State<_VibesVisualizer> createState() => _VibesVisualizerState();
}

class _VibesVisualizerState extends State<_VibesVisualizer> {
  late List<double> _vals;
  Timer? _ticker;
  final _rnd = Random();

  @override
  void initState() {
    super.initState();
    _vals = List<double>.filled(widget.bars, 0);
    _ticker = Timer.periodic(widget.speed, (_) => _tick());
  }

  void _tick() {
    if (!mounted) return;
    final base = widget.active ? (0.15 + 0.85 * widget.level.clamp(0, 1)) : 0.0;
    setState(() {
      for (int i = 0; i < _vals.length; i++) {
        final noise = _rnd.nextDouble();
        final target = base * noise;
        _vals[i] = _vals[i] * 0.6 + target * 0.4;
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final barColor = (widget.color ?? Theme.of(context).colorScheme.primary).withOpacity(0.9);
    final bgColor = widget.bgOverlay ?? Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.08);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: bgColor,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: SizedBox(
        height: widget.height,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(widget.bars, (i) {
            final h = (widget.height * _vals[i]).clamp(2.0, widget.height);
            return Container(
              width: 6,
              height: widget.height,
              alignment: Alignment.bottomCenter,
              child: AnimatedContainer(
                duration: widget.speed,
                curve: Curves.easeOut,
                width: 6,
                height: h,
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ======= Modelos para assets y créditos =======
class _AssetTrack {
  final String title;
  final String assetPath;
  final String category;
  final Credit? credit;
  _AssetTrack(this.title, this.assetPath, this.category, {this.credit});
}

class Credit {
  final String title;
  final String author;
  final String license;
  final String? source;
  Credit(this.title, this.author, this.license, [this.source]);
}
