// lib/mixer/mixer_page.dart
import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:FocusNoise/i18n/locale_controller.dart';

import '../ads/ads_helper.dart';
import '../audio/noise_audio.dart';

class MixerPage extends StatefulWidget {
  const MixerPage({super.key, this.localeCtrl});
  final LocaleController? localeCtrl;

  @override
  State<MixerPage> createState() => _MixerPageState();
}

/// ==== UI Theme (3 styles) ====
class _UiTheme {
  final String name;
  final Color main;
  final Color lite;
  final Color chipSelectedBg; // with alpha
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
    name: 'Ocean',
    main: Color(0xFF64B5F6),
    lite: Color(0xFF90CAF9),
    chipSelectedBg: Color(0x2A64B5F6),
    headerGradient: [Color(0xFF90CAF9), Color(0xFF64B5F6)],
    visBar: Color(0xFF90CAF9),
    visBgOverlay: Color(0x143A86D1),
  ),
  _UiTheme(
    name: 'Sunset',
    main: Color(0xFFFF8A65),
    lite: Color(0xFFFFAB91),
    chipSelectedBg: Color(0x2AFF8A65),
    headerGradient: [Color(0xFFFFAB91), Color(0xFFFF7043)],
    visBar: Color(0xFFFFAB91),
    visBgOverlay: Color(0x14FF6E40),
  ),
  _UiTheme(
    name: 'Forest',
    main: Color(0xFF66BB6A),
    lite: Color(0xFFA5D6A7),
    chipSelectedBg: Color(0x2A66BB6A),
    headerGradient: [Color(0xFFA5D6A7), Color(0xFF66BB6A)],
    visBar: Color(0xFFA5D6A7),
    visBgOverlay: Color(0x143E8E41),
  ),
];

class _MixerPageState extends State<MixerPage> {
  // ======= Persistence keys =======
  static const _kPresetIndexKey = 'presets_index';
  static const _kThemeIdxKey = 'ui_theme_idx';
  static const _kLangKey = 'app_lang'; // saved language code

  final TextEditingController _presetNameCtrl = TextEditingController();

  // Current theme
  int _themeIndex = 0;
  _UiTheme get T => _themes[_themeIndex];

  // Current language (only for local Mixer UI selector)
  String? _langCode; // en|es|pt

  // ======= Offline generators =======
  final gen = NoiseAudio(sampleRate: 48000);

  // Main players
  late final AudioPlayer whitePlayer;
  late final AudioPlayer pinkPlayer;
  late final AudioPlayer brownPlayer;
  late final AudioPlayer binauralPlayer;

  // Bytes on-demand
  Uint8List? whiteBytes, pinkBytes, brownBytes, binauralBytes;

  bool whiteOn = false, pinkOn = false, brownOn = false, binauralOn = false;
  double whiteVol = 0.5, pinkVol = 0.4, brownVol = 0.4, binauralVol = 0.3;

  // Extra offline players
  late final AudioPlayer bluePlayer;
  late final AudioPlayer violetPlayer;
  late final AudioPlayer windPlayer;
  late final AudioPlayer rainPlayer;
  late final AudioPlayer wavesPlayer;
  late final AudioPlayer fireSynthPlayer;

  Uint8List? blueBytes, violetBytes, windBytes, rainBytes, wavesBytes, fireBytes;

  bool blueOn = false, violetOn = false, windOn = false, rainOn = false, wavesOn = false, fireOn = false;
  double blueVol = 0.35, violetVol = 0.30, windVol = 0.45, rainVol = 0.45, wavesVol = 0.45, fireVol = 0.40;

  // ======= Asset-based ambiences (with categories) =======
  final List<_AssetTrack> _assetDefs = [
    _AssetTrack('Rain & Waves', 'audio/ogg/lluvia-amp-olas-110579.ogg', 'Ambient Music',
        credit: Credit('Rain & Waves', 'Author: DonRain ', 'Pixabay License', 'https://pixabay.com/es/users/donrain-26735743')),
    _AssetTrack('Waves', 'audio/ogg/olas-59925.ogg', 'Ambient Music',
        credit: Credit('Waves', 'Author: freesound_community ', 'Pixabay License', 'https://pixabay.com/es/users/freesound_community-46691455')),
    _AssetTrack('Running Water', 'audio/ogg/running-stream-water-sound-239612.ogg', 'Ambient Music',
        credit: Credit('Running Water', 'Author: AllyInNature ', 'Pixabay License', 'https://pixabay.com/es/users/allyinnature-39746607')),
    _AssetTrack('Strong Wind', 'audio/ogg/viento-fuerte-64333.ogg', 'Ambient Music',
        credit: Credit('Strong Wind', 'Author: freesound_community ', 'Pixabay License', 'https://pixabay.com/es/users/freesound_community-46691455')),
    _AssetTrack('Wind Sound', 'audio/ogg/sonido-de-viento-159611.ogg', 'Ambient Music',
        credit: Credit('Wind Sound', 'Author: Ninari ', 'Pixabay License', 'https://pixabay.com/es/users/ninari-32929677')),
    _AssetTrack('Please Calm my Mind', 'audio/ogg/please-calm-my-mind-125566.ogg', 'Relaxing Music',
        credit: Credit('Please Calm my Mind', 'Author: music_for_video', 'Pixabay License',
            'https://pixabay.com/es/users/music_for_video-22579021/?utm_source=link-attribution&utm_medium=referral&utm_campaign=music&utm_content=125566')),
    _AssetTrack('Just Relax', 'audio/ogg/just-relax-11157.ogg', 'Relaxing Music',
        credit: Credit('Just Relax', 'Author: music_for_video', 'Pixabay License',
            'https://pixabay.com/es/users/music_for_video-22579021/?utm_source=link-attribution&utm_medium=referral&utm_campaign=music&utm_content=125566')),
    _AssetTrack('Battle Of The Dragons', 'audio/ogg/battle-of-the-dragons-8037.ogg', 'Epic Music',
        credit: Credit('Battle Of The Dragons', 'Author: ', 'Pixabay License', 'https://pixabay.com/es/music/titulo-principal-battle-of-the-dragons-8037')),
    _AssetTrack('Inspirational Uplifting Calm Piano', 'audio/ogg/inspirational-uplifting-calm-piano-254764.ogg', 'Relaxing Music',
        credit: Credit('Inspirational Uplifting Calm Piano', 'Author: NikitaKondrashev', 'Pixabay License',
            'https://pixabay.com/es/users/nikitakondrashev-42823964')),
    _AssetTrack('Sedative', 'audio/ogg/sedative-110241.ogg', 'Sedative',
        credit: Credit('Sedative', 'Author: music_for_video', 'Pixabay License', 'https://pixabay.com/es/users/music_for_video-22579021')),
    _AssetTrack('The Cradle of your Soul', 'audio/ogg/the-cradle-of-your-soul-15700.ogg', 'Acoustic Guitar',
        credit: Credit('The Cradle of your Soul', 'Author: lemonmusicstudio', 'Pixabay License',
            'https://pixabay.com/es/users/lemonmusicstudio-14942887')),
    _AssetTrack('Dark Atmosphere with Rain', 'audio/ogg/dark-atmosphere-with-rain-352570.ogg', 'Soundscape',
        credit: Credit('Dark Atmosphere with Rain', 'Author: milagrosgomez', 'Pixabay License',
            'https://pixabay.com/es/users/milagrosgomez-50598653')),
    _AssetTrack('Birds Forest', 'audio/ogg/birds39-forest-20772.ogg', 'Soundscape',
        credit: Credit('Birds Forest', 'Author: ShidenBeatsMusic', 'Pixabay License',
            'https://pixabay.com/es/users/shidenbeatsmusic-25676252')),
    _AssetTrack('Sea', 'audio/ogg/sea-396080.ogg', 'Soundscape',
        credit: Credit('Sea', 'Author: uchihadace1st', 'Pixabay License',
            'https://pixabay.com/es/users/uchihadace1st-52017283')),
    _AssetTrack('YouTube Folk Music - River Knows My Name', 'audio/ogg/youtube-folk-music-river-knows-my-name-366869.ogg', 'Pop / Folk / Indie',
        credit: Credit('YouTube folk music - River Knows My Name', 'Author: Diana_Production_Music', 'Pixabay License',
            'https://pixabay.com/es/users/diana_production_music-46737158')),
    _AssetTrack('Morning Mist', 'audio/ogg/morning-mist-180089.ogg', 'Spiritual, Meditation',
        credit: Credit('Morning Mist', 'Author: The4Elements', 'Pixabay License',
            'https://pixabay.com/es/users/the4elements-38522577')),
    _AssetTrack('Epic Relaxing Flute Music', 'audio/ogg/epic-relaxing-flute-music-144009.ogg', 'Relaxing Music',
        credit: Credit('Epic Relaxing Flute Music', 'Author: Onetent', 'Pixabay License',
            'https://pixabay.com/es/users/onetent-15616180')),
    _AssetTrack('Fantasy Music Lumina', 'audio/ogg/fantasy-music-lumina-143991.ogg', 'Relaxing Music',
        credit: Credit('Fantasy Music Lumina', 'Author: Onetent', 'Pixabay License',
            'https://pixabay.com/es/users/onetent-15616180')),
    _AssetTrack('Powerful Emotional Epic', 'audio/ogg/powerful-emotional-epic-174136.ogg', 'Relaxing Music',
        credit: Credit('Epic, Emotional, Powerful', 'Author: Rockot', 'Pixabay License',
            'https://pixabay.com/es/users/rockot-1947599')),
  ];

  // Player/state per asset
  late final List<AudioPlayer> _assetPlayers;
  late final List<bool> _assetOn;
  late final List<double> _assetVol;

  // ======= Categories =======
  late List<String> _categories; // ['All', 'Generators', ...unique categories]
  String _activeCategory = 'All';

  // ======= Sleep timer =======
  Timer? _sleepTimer;
  Timer? _uiTicker;
  Timer? _sleepPrefadeTimer; // pre-fade 5s before end
  DateTime? _sleepAt; // countdown

  // ======= Global player control =======
  bool _pausedAll = false;

  bool _ready = false;

  // ======= Master gain =======
  double _masterGain = 0.85; // 0..1

  // ======= Ads =======
  BannerAd? _banner;

  String _presetKey(String name) => 'preset:$name';

  // ✅ AudioContext to allow mixing across multiple AudioPlayers
  static final AudioContext _mixContext = AudioContext(
    android: AudioContextAndroid(
      isSpeakerphoneOn: false,
      contentType: AndroidContentType.music,
      usageType: AndroidUsageType.media,
      audioFocus: AndroidAudioFocus.gainTransientMayDuck,
    ),
    iOS: AudioContextIOS(
      category: AVAudioSessionCategory.playback,
      options: {AVAudioSessionOptions.mixWithOthers},
    ),
  );

  Future<AudioPlayer> _newLoopingPlayer() async {
    final p = AudioPlayer();
    await p.setAudioContext(_mixContext);
    await p.setPlayerMode(PlayerMode.mediaPlayer);
    await p.setReleaseMode(ReleaseMode.loop);
    return p;
  }

  @override
  void initState() {
    super.initState();
    _initAudio();
    _banner = AdsHelper.createBanner();
    AdsHelper.preloadInterstitial();
  }

  Future<void> _initAudio() async {
    final sp = await SharedPreferences.getInstance();

    _themeIndex = (sp.getInt(_kThemeIdxKey) ?? 0).clamp(0, _themes.length - 1);
    _langCode = sp.getString(_kLangKey) ?? 'en'; // default English

    // Main players
    whitePlayer = await _newLoopingPlayer();
    pinkPlayer = await _newLoopingPlayer();
    brownPlayer = await _newLoopingPlayer();
    binauralPlayer = await _newLoopingPlayer();

    // New offline players
    bluePlayer = await _newLoopingPlayer();
    violetPlayer = await _newLoopingPlayer();
    windPlayer = await _newLoopingPlayer();
    rainPlayer = await _newLoopingPlayer();
    wavesPlayer = await _newLoopingPlayer();
    fireSynthPlayer = await _newLoopingPlayer();

    // Asset players
    _assetPlayers = [];
    for (var i = 0; i < _assetDefs.length; i++) {
      final ap = await _newLoopingPlayer();
      _assetPlayers.add(ap);
    }

    _assetOn = List<bool>.filled(_assetDefs.length, false);
    _assetVol = List<double>.filled(_assetDefs.length, 0.4);

    // Categories (unique) + fixed
    _categories = ['All', 'Generators', ..._assetDefs.map((e) => e.category).toSet()];

    setState(() {
      _activeCategory = 'All';
      _ready = true;
    });

    _precomputeInBackground();
  }

  // Generate loops gradually to avoid jank
  Future<void> _precomputeInBackground() async {
    whiteBytes = await Isolate.run(() => NoiseAudio(sampleRate: 44100).whiteNoiseWav(seconds: 15));
    pinkBytes = await Isolate.run(() => NoiseAudio(sampleRate: 44100).pinkNoiseWav(seconds: 15));
    brownBytes = await Isolate.run(() => NoiseAudio(sampleRate: 44100).brownNoiseWav(seconds: 15));
    binauralBytes =
    await Isolate.run(() => NoiseAudio(sampleRate: 44100).binauralBeatWav(seconds: 15, baseHz: 220, beatHz: 10));

    blueBytes = await Isolate.run(() => NoiseAudio(sampleRate: 44100).blueNoiseWav(seconds: 18));
    violetBytes = await Isolate.run(() => NoiseAudio(sampleRate: 44100).violetNoiseWav(seconds: 18));
    windBytes = await Isolate.run(() => NoiseAudio(sampleRate: 44100).windSynthWav(seconds: 22, gustiness: 0.6));
    rainBytes = await Isolate.run(() => NoiseAudio(sampleRate: 44100).rainSynthWav(seconds: 22, density: 0.4));
    wavesBytes =
    await Isolate.run(() => NoiseAudio(sampleRate: 44100).wavesSynthWav(seconds: 28, swellHz: 0.11, choppiness: 0.42));
    fireBytes =
    await Isolate.run(() => NoiseAudio(sampleRate: 44100).fireplaceSynthWav(seconds: 22, crackleDensity: 0.7));
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

    _banner?.dispose();

    _presetNameCtrl.dispose();
    super.dispose();
  }

  // ===== Language (persist & optionally apply globally) =====
  Future<void> _applyLanguageChoice(String code) async {
    if (_langCode == code) return;
    setState(() => _langCode = code);
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kLangKey, code);

    // Apply app-wide in hot if controller is provided
    widget.localeCtrl?.setLocale(Locale(code));

    final name = switch (code) { 'es' => 'Español', 'pt' => 'Português', _ => 'English' };
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Language changed to $name.')),
    );
  }

  // ======= Volume/mix helpers =======
  Future<void> _applyVolume(AudioPlayer p, double vol) async {
    final v = (vol * _masterGain).clamp(0.0, 1.0);
    await p.setVolume(v);
  }

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
        throw StateError('unknown id: $id');
    }
  }

  Future<void> _toggleBytes(AudioPlayer p, String id, Uint8List? src, bool on, double vol) async {
    if (on) {
      try {
        await p.setVolume(0.0);
        final bytes = src ?? await _ensureBytes(id);
        await p.play(BytesSource(bytes));
        await _fade(p: p, from: 0.0, to: (vol * _masterGain).clamp(0.0, 1.0), ms: 280);
        if (_pausedAll) _pausedAll = false;
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not play $id.')));
        }
      }
    } else {
      await _fade(p: p, from: (vol * _masterGain).clamp(0.0, 1.0), to: 0.0, ms: 220);
      await p.stop();
      await p.setVolume(vol);
    }
    if (mounted) setState(() {});
  }

  Future<void> _toggleAsset(AudioPlayer p, String assetPath, bool on, double vol) async {
    final String relPath = assetPath.startsWith('assets/') ? assetPath.substring('assets/'.length) : assetPath;
    final String bundlePath = assetPath.startsWith('assets/') ? assetPath : 'assets/$assetPath';

    if (on) {
      try {
        await p.setVolume(0.0);
        await p.play(AssetSource(relPath));
      } catch (_) {
        try {
          await p.play(AssetSource(bundlePath));
        } catch (e2) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not play: $relPath')));
            final idx = _assetDefs.indexWhere((t) => t.assetPath == assetPath);
            if (idx >= 0) _assetOn[idx] = false;
          }
          setState(() {});
          return;
        }
      }
      await _fade(p: p, from: 0.0, to: (vol * _masterGain).clamp(0.0, 1.0), ms: 280);
      if (_pausedAll) _pausedAll = false;
    } else {
      await _fade(p: p, from: (vol * _masterGain).clamp(0.0, 1.0), to: 0.0, ms: 220);
      await p.stop();
      await p.setVolume(vol);
    }
    if (mounted) setState(() {});
  }

  Future<void> _fadeAllOut({int ms = 800}) async {
    final steps = 16;
    final delay = Duration(milliseconds: (ms / steps).round());

    final w = whiteVol * _masterGain, p = pinkVol * _masterGain, b = brownVol * _masterGain, bb = binauralVol * _masterGain;
    final bl = blueVol * _masterGain, vi = violetVol * _masterGain, wi = windVol * _masterGain, ra = rainVol * _masterGain, wa = wavesVol * _masterGain, fi = fireVol * _masterGain;
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

  Future<void> _fadeDownOnly({int ms = 5000}) async {
    final steps = 24;
    final delay = Duration(milliseconds: (ms / steps).round());

    final w = whiteVol * _masterGain, p = pinkVol * _masterGain, b = brownVol * _masterGain, bb = binauralVol * _masterGain;
    final bl = blueVol * _masterGain, vi = violetVol * _masterGain, wi = windVol * _masterGain, ra = rainVol * _masterGain, wa = wavesVol * _masterGain, fi = fireVol * _masterGain;
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

  Future<void> _setMasterGain(double g) async {
    setState(() => _masterGain = g.clamp(0.0, 1.0));
    await _applyAllCurrentVolumes();
  }

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
    if (whiteOn || pinkOn || brownOn || binauralOn || blueOn || violetOn || windOn || rainOn || wavesOn || fireOn) {
      return true;
    }
    for (final b in _assetOn) {
      if (b) return true;
    }
    return false;
  }

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

  // ======= Presets (quick & named) =======
  Future<void> _savePreset() async {
    final sp = await SharedPreferences.getInstance();
    final data = _currentPresetPayload();
    await sp.setString('preset_default', jsonEncode(data));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preset saved.')));
    }
    AdsHelper.maybeShowInterstitial();
  }

  Future<void> _loadPreset() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString('preset_default');
    if (raw == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No preset saved.')));
      }
      return;
    }
    final data = jsonDecode(raw);
    await _applyPresetData(Map<String, dynamic>.from(data));
  }

  Map<String, dynamic> _currentPresetPayload() {
    return {
      'whiteOn': whiteOn,
      'whiteVol': whiteVol,
      'pinkOn': pinkOn,
      'pinkVol': pinkVol,
      'brownOn': brownOn,
      'brownVol': brownVol,
      'binauralOn': binauralOn,
      'binauralVol': binauralVol,
      'blueOn': blueOn,
      'blueVol': blueVol,
      'violetOn': violetOn,
      'violetVol': violetVol,
      'windOn': windOn,
      'windVol': windVol,
      'rainOn': rainOn,
      'rainVol': rainVol,
      'wavesOn': wavesOn,
      'wavesVol': wavesVol,
      'fireOn': fireOn,
      'fireVol': fireVol,
      'assets': List.generate(_assetDefs.length, (i) => {'on': _assetOn[i], 'vol': _assetVol[i], 'key': _assetDefs[i].assetPath}),
    };
  }

  Future<void> _applyPresetData(Map<String, dynamic> data) async {
    setState(() {
      whiteOn = data['whiteOn'] ?? false;
      whiteVol = (data['whiteVol'] ?? 0.5).toDouble();
      pinkOn = data['pinkOn'] ?? false;
      pinkVol = (data['pinkVol'] ?? 0.4).toDouble();
      brownOn = data['brownOn'] ?? false;
      brownVol = (data['brownVol'] ?? 0.4).toDouble();
      binauralOn = data['binauralOn'] ?? false;
      binauralVol = (data['binauralVol'] ?? 0.3).toDouble();

      blueOn = data['blueOn'] ?? false;
      blueVol = (data['blueVol'] ?? 0.35).toDouble();
      violetOn = data['violetOn'] ?? false;
      violetVol = (data['violetVol'] ?? 0.30).toDouble();
      windOn = data['windOn'] ?? false;
      windVol = (data['windVol'] ?? 0.45).toDouble();
      rainOn = data['rainOn'] ?? false;
      rainVol = (data['rainVol'] ?? 0.45).toDouble();
      wavesOn = data['wavesOn'] ?? false;
      wavesVol = (data['wavesVol'] ?? 0.45).toDouble();
      fireOn = data['fireOn'] ?? false;
      fireVol = (data['fireVol'] ?? 0.40).toDouble();

      if (data['assets'] is List) {
        final list = data['assets'] as List;
        for (int i = 0; i < _assetDefs.length && i < list.length; i++) {
          _assetOn[i] = (list[i]['on'] ?? false) as bool;
          _assetVol[i] = (list[i]['vol'] ?? 0.4).toDouble();
        }
      }
    });

    await _toggleBytes(whitePlayer, 'white', whiteBytes, whiteOn, whiteVol);
    await _toggleBytes(pinkPlayer, 'pink', pinkBytes, pinkOn, pinkVol);
    await _toggleBytes(brownPlayer, 'brown', brownBytes, brownOn, brownVol);
    await _toggleBytes(binauralPlayer, 'binaural', binauralBytes, binauralOn, binauralVol);

    await _toggleBytes(bluePlayer, 'blue', blueBytes, blueOn, blueVol);
    await _toggleBytes(violetPlayer, 'violet', violetBytes, violetOn, violetVol);
    await _toggleBytes(windPlayer, 'wind', windBytes, windOn, windVol);
    await _toggleBytes(rainPlayer, 'rain', rainBytes, rainOn, rainVol);
    await _toggleBytes(wavesPlayer, 'waves', wavesBytes, wavesOn, wavesVol);
    await _toggleBytes(fireSynthPlayer, 'fire', fireBytes, fireOn, fireVol);

    for (int i = 0; i < _assetDefs.length; i++) {
      await _toggleAsset(_assetPlayers[i], _assetDefs[i].assetPath, _assetOn[i], _assetVol[i]);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preset loaded.')));
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Preset "$name" saved.')));
    }
    AdsHelper.maybeShowInterstitial();
  }

  Future<void> _loadPresetNamed(String name) async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_presetKey(name));
    if (raw == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('"$name" not found.')));
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Preset "$name" deleted.')));
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Renamed to "$newName".')));
    }
  }

  Future<bool> _confirmOverwrite(String name) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Overwrite preset'),
        content: Text('A preset named "$name" already exists. Overwrite it?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Overwrite')),
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
        title: const Text('Save preset'),
        content: TextField(
          controller: _presetNameCtrl,
          autofocus: true,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(labelText: 'Preset name', hintText: 'e.g., Soft Focus'),
          onSubmitted: (_) => Navigator.pop(ctx, _presetNameCtrl.text.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, _presetNameCtrl.text.trim()), child: const Text('Save')),
        ],
      ),
    );

    if (name == null) return;
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name cannot be empty.')));
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
              title: Text('Your presets'),
              subtitle: Text('Tap to load. Long-press to rename.'),
            ),
            if (names.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('You have no presets yet. Save one with the star button.'),
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
                            title: const Text('Rename preset'),
                            content: TextField(
                              controller: _presetNameCtrl,
                              autofocus: true,
                              decoration: const InputDecoration(labelText: 'New name'),
                              onSubmitted: (_) => Navigator.pop(dCtx, _presetNameCtrl.text.trim()),
                            ),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Cancel')),
                              FilledButton(onPressed: () => Navigator.pop(dCtx, _presetNameCtrl.text.trim()), child: const Text('Save')),
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
                              title: const Text('Delete preset'),
                              content: Text('Delete "$n"?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(dCtx, false), child: const Text('Cancel')),
                                FilledButton(onPressed: () => Navigator.pop(dCtx, true), child: const Text('Delete')),
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
                label: const Text('New preset'),
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

  // ======= Theme =======
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
              title: Text('Player theme'),
              subtitle: Text('Affects colors, gradient and visualizer'),
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

  void _pickTimer() async {
    final minutes = await showModalBottomSheet<int>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const ListTile(title: Text('Timer')),
          for (final m in [15, 30, 45, 60, 90])
            ListTile(leading: const Icon(Icons.timer), title: Text('$m min'), onTap: () => Navigator.pop(ctx, m)),
          ListTile(leading: const Icon(Icons.clear), title: const Text('Cancel timer'), onTap: () => Navigator.pop(ctx, -1)),
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
        AdsHelper.maybeShowInterstitial();
      });
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

  // ======= Link helpers (Credits) =======
  bool _isHttpUrl(String? s) {
    if (s == null) return false;
    final u = Uri.tryParse(s);
    return u != null && (u.scheme == 'http' || u.scheme == 'https');
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open link.')));
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
        gradient: LinearGradient(colors: T.headerGradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Focus mix', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.white)),
              ),
              IconButton(tooltip: 'Change theme', onPressed: _pickTheme, icon: const Icon(Icons.palette_outlined, color: Colors.white)),
              IconButton(tooltip: 'Timer', onPressed: _pickTimer, icon: const Icon(Icons.timer_outlined, color: Colors.white)),
              IconButton(
                  tooltip: _pausedAll ? 'Resume mix' : 'Pause mix',
                  onPressed: _anyTrackOn() ? (_pausedAll ? _resumeAll : _pauseAll) : null,
                  icon: Icon(_pausedAll ? Icons.play_arrow : Icons.pause, color: Colors.white)),
              IconButton(
                  tooltip: 'Fade-out & stop all',
                  onPressed: _anyTrackOn() ? () => _fadeAllOut(ms: 600) : null,
                  icon: const Icon(Icons.stop_circle_outlined, color: Colors.white)),
            ],
          ),
          if (timerCaption != null) const SizedBox(height: 6),
          if (timerCaption != null) const Text('Timer running', style: TextStyle(color: Colors.white70)),
          Expanded(
            child: _VibesVisualizer(
              color: T.visBar,
              bgOverlay: T.visBgOverlay,
              active: _anyTrackOn() && !_pausedAll,
              level: _activityLevel,
              bars: 28,
              height: 80,
              speed: const Duration(milliseconds: 100),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: T.main.withOpacity(0.15))),
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
                    data: SliderTheme.of(context).copyWith(activeTrackColor: T.main, thumbColor: T.main),
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
              ? const Text('No external tracks. Add CC0/CC-BY audio files under assets/audio/ and declare them in pubspec.yaml.')
              : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Credits', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
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
                        ? const Text('CC0 (no attribution)')
                        : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${c.title} — ${c.author}'),
                      Text(c.license),
                      if (_isHttpUrl(c.source))
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(onPressed: () => _openUrl(c.source!), child: const Text('View source')),
                        ),
                    ]),
                  );
                },
              ),
            ),
          ]),
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

    final List<_AssetTrack> filteredAssets = (_activeCategory == 'All')
        ? _assetDefs
        : (_activeCategory == 'Generators')
        ? <_AssetTrack>[]
        : _assetDefs.where((t) => t.category == _activeCategory).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(timerCaption == null ? 'FocusNoise Mixer' : 'FocusNoise • $timerCaption'),
        actions: [
          IconButton(tooltip: 'Credits', onPressed: _showCredits, icon: const Icon(Icons.info_outline)),
          IconButton(tooltip: 'Save named preset', onPressed: _savePresetFlow, icon: const Icon(Icons.star_border)),
          IconButton(tooltip: 'My presets', onPressed: _showPresetPicker, icon: const Icon(Icons.playlist_add_check)),

          // ===== Theme selector =====
          PopupMenuButton<String>(
            tooltip: 'Theme',
            onSelected: (v) {
              final idx = _themes.indexWhere((t) => t.name == v);
              if (idx >= 0) _pickThemeDirect(idx);
            },
            itemBuilder: (ctx) => _themes
                .map((t) => PopupMenuItem<String>(
              value: t.name,
              child: Row(children: [CircleAvatar(radius: 6, backgroundColor: t.main), const SizedBox(width: 8), Text(t.name)]),
            ))
                .toList(),
            icon: const Icon(Icons.palette_outlined),
          ),

          // ===== Language selector (Mixer) =====
        ],
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _visualHeader(),
          const SizedBox(height: 12),

          // Master volume
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Master volume', style: TextStyle(fontWeight: FontWeight.w700)),
                Row(children: [
                  const Icon(Icons.volume_mute_outlined),
                  Expanded(child: Slider(value: _masterGain, min: 0, max: 1, onChanged: (v) => _setMasterGain(v))),
                  const Icon(Icons.volume_up_outlined),
                ]),
              ]),
            ),
          ),
          const SizedBox(height: 12),

          // Category chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories
                  .map((c) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(c),
                  selected: _activeCategory == c,
                  selectedColor: T.chipSelectedBg,
                  side: BorderSide(color: _activeCategory == c ? T.main : Colors.black12),
                  onSelected: (_) => setState(() => _activeCategory = c),
                ),
              ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 12),

          // Generators
          if (_activeCategory == 'All' || _activeCategory == 'Generators') ...[
            const Text('Generators (offline)', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            _track(
              title: 'White Noise',
              subtitle: 'Flat energy across frequencies',
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
              title: 'Pink Noise',
              subtitle: 'More energy in low frequencies (1/f)',
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
              title: 'Brown Noise',
              subtitle: 'Soft, wave/wind-like',
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
              subtitle: 'Use headphones to perceive the beat',
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
              title: 'Blue Noise',
              subtitle: 'Emphasis on high frequencies (+3 dB/oct)',
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
              title: 'Violet Noise',
              subtitle: 'Highs even more present (+6 dB/oct)',
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
              title: 'Wind (synthetic)',
              subtitle: 'Soft gusts with slow envelope',
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
              title: 'Rain (synthetic)',
              subtitle: 'Hiss + random droplets',
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
              title: 'Waves (synthetic)',
              subtitle: 'Low rumble + modulated foam',
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
              title: 'Fireplace (synthetic)',
              subtitle: 'Warm bed + random crackles',
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

          // Assets filtered by category
          if (filteredAssets.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(),
            const Text('Ambiences (free assets)', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            for (final track in filteredAssets)
              Builder(builder: (_) {
                final i = _assetDefs.indexOf(track);
                return _track(
                  title: track.title,
                  subtitle: track.credit == null ? 'CC0 (no attribution)' : '${track.credit!.license} — ${track.credit!.author}',
                  on: _assetOn[i],
                  onChanged: (v) async {
                    setState(() => _assetOn[i] = v);
                    await _toggleAsset(_assetPlayers[i], track.assetPath, v, _assetVol[i]);
                  },
                  volume: _assetVol[i],
                  onVolume: (v) async {
                    setState(() => _assetVol[i] = v);
                    await _applyVolume(_assetPlayers[i], v);
                  },
                );
              }),
          ],

          const SizedBox(height: 8),
          const Text('Tip: mix 2–3 sources at moderate volumes (0.3–0.6) to avoid clipping.'),
        ],
      ),
      bottomNavigationBar: (_banner == null)
          ? null
          : SizedBox(height: _banner!.size.height.toDouble(), child: AdWidget(ad: _banner!)),
    );
  }

  Future<void> _pickThemeDirect(int idx) async {
    setState(() => _themeIndex = idx);
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_kThemeIdxKey, _themeIndex);
  }
}

// ======= Vibes visualizer (optimized) =======
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
    _maybeStartTicker();
  }

  @override
  void didUpdateWidget(covariant _VibesVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.bars != oldWidget.bars) {
      _vals = List<double>.filled(widget.bars, 0);
    }

    final speedChanged = widget.speed != oldWidget.speed;

    if (widget.active) {
      if (speedChanged) _restartTicker();
      if (_ticker == null) _maybeStartTicker();
    } else {
      _stopTicker();
    }
  }

  void _maybeStartTicker() {
    if (_ticker != null) return;
    _ticker = Timer.periodic(widget.speed, (_) => _tick());
  }

  void _restartTicker() {
    _stopTicker();
    _maybeStartTicker();
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  void _tick() {
    if (!mounted) return;

    if (!widget.active) {
      setState(() {
        for (int i = 0; i < _vals.length; i++) {
          _vals[i] *= 0.85;
        }
      });
      return;
    }

    final base = 0.15 + 0.85 * widget.level.clamp(0, 1);
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
    _stopTicker();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final barColor = (widget.color ?? Theme.of(context).colorScheme.primary).withOpacity(0.9);
    final bgColor = widget.bgOverlay ?? Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.08);

    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: bgColor),
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
                decoration: BoxDecoration(color: barColor, borderRadius: BorderRadius.circular(3)),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ======= Models for assets & credits =======
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
