import 'dart:math';
import 'dart:typed_data';

/// ============================================================================
/// Helpers top-level (no anidar en NoiseAudio)
/// ============================================================================

class _EnvTone {
  final double freq; // Hz
  final int len;     // muestras
  final double amp;  // 0..1
  final double attack; // s
  final double decay;  // s

  int _i = 0;
  double _phase = 0;

  _EnvTone(this.freq, this.len, this.amp, {this.attack = 0.010, this.decay = 0.020});

  bool get done => _i >= len;

  double next(int sampleRate) {
    if (done) return 0.0;

    final aS = (attack * sampleRate).clamp(1, len).toInt();
    final dS = (decay  * sampleRate).clamp(1, len).toInt();

    double env;
    if (_i < aS) {
      final x = _i / aS;
      env = sin(x * pi * 0.5);
    } else if (_i > len - dS) {
      final x = (len - _i) / dS;
      env = max(0.0, sin(x * pi * 0.5));
    } else {
      env = 1.0;
    }

    _phase += 2 * pi * freq / sampleRate;
    final y = sin(_phase) * amp * env;

    _i++;
    return y;
  }
}

class _NoiseBurst {
  final double cutoffHz; // Hz (LPF a ruido)
  final int len;         // muestras
  final double amp;      // 0..1

  int _i = 0;
  double _lp = 0.0;
  final Random _rng = Random();

  _NoiseBurst(this.cutoffHz, this.len, this.amp);

  bool get done => _i >= len;

  double next(int sampleRate) {
    if (done) return 0.0;

    // LPF 1er orden por RC
    final rc    = 1.0 / (2 * pi * max(1.0, cutoffHz));
    final dt    = 1.0 / sampleRate;
    final alpha = dt / (rc + dt);

    final x  = _rng.nextDouble() * 2 - 1; // blanco
    _lp      = _lp + alpha * (x - _lp);

    // Ventana Hann para forma suave
    final w = 0.5 * (1 - cos(2 * pi * (_i / max(1, len - 1))));

    _i++;
    return _lp * w * amp;
  }
}

class _BirdChirp {
  final double f0;  // Hz inicio
  final double f1;  // Hz fin
  final int len;    // muestras
  final double amp; // 0..1
  int _i = 0;

  _BirdChirp({required this.f0, required this.f1, required this.len, required this.amp});

  bool get done => _i >= len;

  double next(int sampleRate) {
    if (done) return 0.0;
    final t = _i / sampleRate;
    final T = len / sampleRate;
    final k = (f1 - f0) / max(1e-6, T);
    final phi = 2 * pi * (f0 * t + 0.5 * k * t * t);

    final w = 0.5 * (1 - cos(2 * pi * (_i / max(1, len - 1))));
    _i++;
    return sin(phi) * w * amp;
  }
}

/// ============================================================================
/// Generador principal
/// ============================================================================

/// Sintesiza varios ruidos/ambientes y devuelve audio en WAV PCM 16-bit.
/// Todos los métodos devuelven `Uint8List` listo para `BytesSource`.
class NoiseAudio {
  final int sampleRate;
  NoiseAudio({this.sampleRate = 44100});

  // --------------------------------------------------------------------------
  // WAV wrappers
  Uint8List _wavFromMono(List<double> mono) {
    final data = _floatTo16PCMInterleaved(mono, null);
    return _wrapWav(data, channels: 1);
  }

  Uint8List _wavFromStereo(List<double> left, List<double> right) {
    final data = _floatTo16PCMInterleaved(left, right);
    return _wrapWav(data, channels: 2);
  }

  Uint8List _floatTo16PCMInterleaved(List<double> left, List<double>? right) {
    final twoCh = right != null;
    final out = BytesBuilder();
    final n = left.length;
    for (int i = 0; i < n; i++) {
      final l = (left[i]).clamp(-1.0, 1.0);
      final li = (l * 32767.0).round();
      out.add(_int16LE(li));
      if (twoCh) {
        final r = (right![i]).clamp(-1.0, 1.0);
        final ri = (r * 32767.0).round();
        out.add(_int16LE(ri));
      }
    }
    return out.toBytes();
  }

  Uint8List _wrapWav(Uint8List pcmData, {required int channels}) {
    final byteRate   = sampleRate * channels * 2;
    final blockAlign = channels * 2;
    final dataSize   = pcmData.lengthInBytes;
    final riffSize   = 36 + dataSize;

    final h = BytesBuilder();
    h.add(_ascii('RIFF'));
    h.add(_uint32LE(riffSize));
    h.add(_ascii('WAVE'));
    h.add(_ascii('fmt '));
    h.add(_uint32LE(16)); // subchunk size
    h.add(_uint16LE(1));  // PCM
    h.add(_uint16LE(channels));
    h.add(_uint32LE(sampleRate));
    h.add(_uint32LE(byteRate));
    h.add(_uint16LE(blockAlign));
    h.add(_uint16LE(16)); // bits per sample
    h.add(_ascii('data'));
    h.add(_uint32LE(dataSize));

    final out = BytesBuilder();
    out.add(h.toBytes());
    out.add(pcmData);
    return out.toBytes();
  }

  Uint8List _ascii(String s) => Uint8List.fromList(s.codeUnits);
  Uint8List _uint16LE(int v) {
    final b = ByteData(2)..setUint16(0, v, Endian.little);
    return b.buffer.asUint8List();
  }
  Uint8List _uint32LE(int v) {
    final b = ByteData(4)..setUint32(0, v, Endian.little);
    return b.buffer.asUint8List();
  }
  Uint8List _int16LE(int v) {
    final b = ByteData(2)..setInt16(0, v, Endian.little);
    return b.buffer.asUint8List();
  }

  // --------------------------------------------------------------------------
  // Ruidos básicos

  Uint8List whiteNoiseWav({int seconds = 15}) {
    final samples = _whiteNoiseMono(seconds);
    return _wavFromMono(samples);
  }

  Uint8List pinkNoiseWav({int seconds = 15, int rows = 16}) {
    final samples = _pinkNoiseVoss(seconds, rows: rows);
    return _wavFromMono(samples);
  }

  Uint8List brownNoiseWav({int seconds = 15}) {
    final samples = _brownianNoiseMono(seconds);
    return _wavFromMono(samples);
  }

  Uint8List binauralBeatWav({
    int seconds = 15,
    double baseHz = 220.0,
    double beatHz = 10.0,
  }) {
    final pair = _binauralStereo(seconds, baseHz: baseHz, beatHz: beatHz);
    return _wavFromStereo(pair.$1, pair.$2);
  }

  // --------------------------------------------------------------------------
  // Ruidos extendidos (Azul/Violeta)

  Uint8List blueNoiseWav({int seconds = 18}) {
    final s = _blueNoiseMono(seconds);
    return _wavFromMono(s);
  }

  Uint8List violetNoiseWav({int seconds = 18}) {
    final s = _violetNoiseMono(seconds);
    return _wavFromMono(s);
  }

  // --------------------------------------------------------------------------
  // Ambientes sintéticos

  /// Viento con ráfagas lentas (ruido filtrado + envolvente lenta).
  Uint8List windSynthWav({int seconds = 22, double gustiness = 0.6}) {
    final n = seconds * sampleRate;
    final out = List<double>.filled(n, 0.0);

    // Base: ruido rosa suavizado (grave)
    final base = _lowpass(_white(n, amp: 0.9), cutoffHz: 500);

    // Envolvente lenta estocástica
    final env = _slowEnvelope(n, minV: 0.4, maxV: 1.0, smooth: 0.995);
    final gust = gustiness.clamp(0.0, 1.0);

    for (int i = 0; i < n; i++) {
      final g = 0.7 * env[i] + 0.3 * (env[i] * (1.0 + gust * (sin(2 * pi * i / (sampleRate * 1.7)) * 0.5 + 0.5)));
      out[i] = base[i] * g * 0.5; // nivel moderado
    }
    return _wavFromMono(out);
  }

  /// Lluvia: hiss + gotitas (bursts cortos de alta frecuencia).
  Uint8List rainSynthWav({int seconds = 22, double density = 0.4}) {
    final n = seconds * sampleRate;
    final out = List<double>.filled(n, 0.0);

    // Hiss de fondo (azul/violeta suave)
    final hiss = _blueNoiseMono(seconds, amp: 0.20);

    // Gotitas
    final rnd = Random();
    final numDrops = (seconds * (8 + 50 * density.clamp(0, 1))).round();
    final drops = <_NoiseBurst>[];
    for (int k = 0; k < numDrops; k++) {
      final pos = rnd.nextInt(max(1, n - 2000));
      final dur = (sampleRate * (0.010 + rnd.nextDouble() * 0.040)).round(); // 10–50ms
      final cutoff = 6000 + rnd.nextDouble() * 6000;  // agudas
      final amp = 0.25 + rnd.nextDouble() * 0.35;
      drops.add(_NoiseBurst(cutoff, dur, amp).._i = 0);
      // Mezclar a partir del pos
      var i = 0;
      while (i < dur && pos + i < n) {
        out[pos + i] += drops.last.next(sampleRate);
        i++;
      }
    }

    // Sumar hiss
    for (int i = 0; i < n; i++) {
      out[i] += hiss[i];
      // Limitar suave
      out[i] = out[i].clamp(-1.0, 1.0);
    }

    return _wavFromMono(out);
  }

  /// Olas: rumble grave + espuma modulada periódicamente.
  Uint8List wavesSynthWav({
    int seconds = 28,
    double swellHz = 0.10,
    double choppiness = 0.42,
  }) {
    final n = seconds * sampleRate;
    final out = List<double>.filled(n, 0.0);

    // Rumble (muy grave)
    final rumble = _lowpass(_white(n, amp: 0.9), cutoffHz: 180); // base grave
    // Espuma (hiss alto filtrado)
    final foam = _highpass(_white(n, amp: 0.7), cutoffHz: 3000);

    for (int i = 0; i < n; i++) {
      final t = i / sampleRate;
      final swell = 0.55 + 0.45 * (sin(2 * pi * swellHz * t) * 0.5 + 0.5); // 0.55..1.0
      final chop = 0.50 + 0.50 * (sin(2 * pi * (swellHz * 7) * t + sin(2 * pi * swellHz * t)) * choppiness);
      final y = rumble[i] * 0.6 * swell + foam[i] * 0.20 * chop;
      out[i] = y.clamp(-1.0, 1.0);
    }
    return _wavFromMono(out);
  }

  /// Chimenea: base cálida + crackles/pops.
  Uint8List fireplaceSynthWav({int seconds = 22, double crackleDensity = 0.7}) {
    final n = seconds * sampleRate;
    final out = List<double>.filled(n, 0.0);
    final rnd = Random();

    // Base cálida: LPF de ruido + pequeña modulación lenta
    final base = _lowpass(_white(n, amp: 0.7), cutoffHz: 1200);
    final env = _slowEnvelope(n, minV: 0.7, maxV: 1.0, smooth: 0.999);

    // Crackles (bursts agudos muy cortos)
    final numCrackles = (seconds * (200 * crackleDensity)).round();
    for (int k = 0; k < numCrackles; k++) {
      final pos = rnd.nextInt(max(1, n - 1000));
      final dur = (sampleRate * (0.006 + rnd.nextDouble() * 0.015)).round(); // 6–21ms
      final cut = 3000 + rnd.nextDouble() * 7000;
      final amp = 0.3 + rnd.nextDouble() * 0.6;
      final nb = _NoiseBurst(cut, dur, amp);
      var i = 0;
      while (i < dur && pos + i < n) {
        out[pos + i] += nb.next(sampleRate);
        i++;
      }
    }

    // Pops graves (senos muy cortos)
    final numPops = (seconds * (6 + 10 * crackleDensity)).round();
    for (int k = 0; k < numPops; k++) {
      final pos = rnd.nextInt(max(1, n - 3000));
      final f = 80 + rnd.nextDouble() * 160;
      final durS = 0.030 + rnd.nextDouble() * 0.090;
      final len = (durS * sampleRate).round();
      final amp = 0.25 + rnd.nextDouble() * 0.35;
      final tone = _EnvTone(f, len, amp, attack: 0.004, decay: 0.045);
      var i = 0;
      while (!tone.done && pos + i < n) {
        out[pos + i] += tone.next(sampleRate);
        i++;
      }
    }

    for (int i = 0; i < n; i++) {
      out[i] += base[i] * env[i] * 0.45;
      out[i] = out[i].clamp(-1.0, 1.0);
    }
    return _wavFromMono(out);
  }

  // --------------------------------------------------------------------------
  // Extras opcionales (no usados por tu MixerPage actual, pero disponibles)

  /// Trinos de pájaros esparcidos.
  Uint8List birdsChirpsWav({int seconds = 18, int count = 40}) {
    final n = seconds * sampleRate;
    final out = List<double>.filled(n, 0.0);
    final rnd = Random();

    for (int k = 0; k < count; k++) {
      final pos = rnd.nextInt(max(1, n - 4000));
      final durS = 0.06 + rnd.nextDouble() * 0.22;
      final len = (durS * sampleRate).round();
      final f0 = 2200 + rnd.nextDouble() * 900; // 2.2–3.1 kHz
      final f1 = f0 + (200 + rnd.nextDouble() * 1000) * (rnd.nextBool() ? 1 : -1);
      final amp = 0.15 + rnd.nextDouble() * 0.25;
      final chirp = _BirdChirp(f0: f0, f1: f1, len: len, amp: amp);

      var i = 0;
      while (!chirp.done && pos + i < n) {
        out[pos + i] += chirp.next(sampleRate);
        i++;
      }
    }

    // Suave LPF para quitar asperezas
    final smooth = _lowpass(out, cutoffHz: 6000);
    return _wavFromMono(smooth);
  }

  /// Bosque = viento suave + pájaros suaves.
  Uint8List forestSynthWav({int seconds = 24}) {
    final n = seconds * sampleRate;
    final wind = windSynthWav(seconds: seconds, gustiness: 0.4);
    final birds = birdsChirpsWav(seconds: seconds, count: (seconds * 1.6).round());
    // Mezclar (ambos están ya en WAV -> decodificar no; mejor rehacer internamente).
    // Para mantener simple, volvemos a generar versiones internas:
    final windMono = _fromWavMono(wind);
    final birdsMono = _fromWavMono(birds);

    final out = List<double>.filled(n, 0.0);
    for (int i = 0; i < n; i++) {
      out[i] = (windMono[i] * 0.8 + birdsMono[i] * 0.6).clamp(-1.0, 1.0);
    }
    return _wavFromMono(out);
  }

  // --------------------------------------------------------------------------
  // Implementaciones internas básicas

  List<double> _whiteNoiseMono(int seconds, {double amp = 0.35}) {
    final n = seconds * sampleRate;
    final rnd = Random();
    final out = List<double>.filled(n, 0.0);
    for (int i = 0; i < n; i++) {
      out[i] = (rnd.nextDouble() * 2 - 1) * amp;
    }
    return out;
  }

  List<double> _pinkNoiseVoss(int seconds, {int rows = 16}) {
    final n = seconds * sampleRate;
    final rnd = Random();
    final table = List<double>.generate(rows, (_) => rnd.nextDouble() * 2 - 1);
    int counter = 0;
    final out = List<double>.filled(n, 0.0);

    for (int i = 0; i < n; i++) {
      final tz = _trailingZeros(counter);
      if (tz < rows) table[tz] = rnd.nextDouble() * 2 - 1;
      counter++;

      double sum = 0.0;
      for (final v in table) sum += v;
      out[i] = (sum / rows) * 0.35;
    }
    return out;
  }

  List<double> _brownianNoiseMono(int seconds) {
    final n = seconds * sampleRate;
    final rnd = Random();
    final out = List<double>.filled(n, 0.0);
    double y = 0.0;
    for (int i = 0; i < n; i++) {
      y = (y + (rnd.nextDouble() * 2 - 1) * 0.02) * 0.997; // leve damping
      if (y > 1) y = 1;
      if (y < -1) y = -1;
      out[i] = y * 0.6;
    }
    return out;
  }

  (List<double>, List<double>) _binauralStereo(
      int seconds, {
        required double baseHz,
        required double beatHz,
      }) {
    final n = seconds * sampleRate;
    final left = List<double>.filled(n, 0.0);
    final right = List<double>.filled(n, 0.0);

    final f1 = baseHz - beatHz / 2;
    final f2 = baseHz + beatHz / 2;
    const amp = 0.35;

    for (int i = 0; i < n; i++) {
      final t = i / sampleRate;
      left[i] = sin(2 * pi * f1 * t) * amp;
      right[i] = sin(2 * pi * f2 * t) * amp;
    }
    return (left, right);
  }

  // Azul/Violeta aproximados con pre-énfasis (HP leves)
  List<double> _blueNoiseMono(int seconds, {double amp = 0.30}) {
    final n = seconds * sampleRate;
    final rnd = Random();
    final out = List<double>.filled(n, 0.0);
    double prev = 0.0;
    for (int i = 0; i < n; i++) {
      final x = (rnd.nextDouble() * 2 - 1);
      // High-pass suave: y = x - 0.5 * x[n-1]
      final y = x - 0.5 * prev;
      prev = x;
      out[i] = (y * amp).clamp(-1.0, 1.0);
    }
    return out;
  }

  List<double> _violetNoiseMono(int seconds, {double amp = 0.28}) {
    final n = seconds * sampleRate;
    final rnd = Random();
    final out = List<double>.filled(n, 0.0);
    double prev = 0.0;
    for (int i = 0; i < n; i++) {
      final x = (rnd.nextDouble() * 2 - 1);
      // Diferenciador (aprox +6 dB/oct): y = x - x[n-1]
      final y = x - prev;
      prev = x;
      out[i] = (y * amp).clamp(-1.0, 1.0);
    }
    return out;
  }

  // --------------------------------------------------------------------------
  // Utilidades DSP simples

  List<double> _white(int n, {double amp = 1.0}) {
    final rnd = Random();
    final out = List<double>.filled(n, 0.0);
    for (int i = 0; i < n; i++) {
      out[i] = (rnd.nextDouble() * 2 - 1) * amp;
    }
    return out;
  }

  List<double> _lowpass(List<double> x, {double cutoffHz = 1000}) {
    final out = List<double>.filled(x.length, 0.0);
    final rc    = 1.0 / (2 * pi * max(1.0, cutoffHz));
    final dt    = 1.0 / sampleRate;
    final alpha = dt / (rc + dt);
    double y = 0.0;
    for (int i = 0; i < x.length; i++) {
      y = y + alpha * (x[i] - y);
      out[i] = y;
    }
    return out;
    // Nota: es un LPF 1er orden sencillo.
  }

  List<double> _highpass(List<double> x, {double cutoffHz = 1000}) {
    final out = List<double>.filled(x.length, 0.0);
    final rc    = 1.0 / (2 * pi * max(1.0, cutoffHz));
    final dt    = 1.0 / sampleRate;
    final alpha = rc / (rc + dt);
    double y = 0.0;
    double prevX = x.isNotEmpty ? x[0] : 0.0;
    for (int i = 0; i < x.length; i++) {
      final hp = alpha * (y + x[i] - prevX);
      out[i] = hp;
      y = hp;
      prevX = x[i];
    }
    return out;
  }

  /// Envolvente lenta pseudo-aleatoria entre [minV, maxV]
  List<double> _slowEnvelope(int n, {double minV = 0.5, double maxV = 1.0, double smooth = 0.998}) {
    final rnd = Random();
    final out = List<double>.filled(n, 0.0);
    double v = (minV + maxV) * 0.5;
    for (int i = 0; i < n; i++) {
      final target = minV + rnd.nextDouble() * (maxV - minV);
      v = v * smooth + target * (1 - smooth);
      out[i] = v;
    }
    return out;
  }

  int _trailingZeros(int x) {
    if (x == 0) return 32;
    int c = 0;
    while ((x & 1) == 0) {
      c++;
      x >>= 1;
    }
    return c;
  }

  /// Decodifica WAV mono 16-bit PCM fabricado por este mismo archivo (rápido y sucio).
  List<double> _fromWavMono(Uint8List wav) {
    // Encuentra 'data' chunk; asumimos formato correcto (como el que generamos)
    int i = 12; // después de 'RIFF....WAVE'
    int dataOffset = -1;
    int dataSize = 0;
    while (i + 8 <= wav.length) {
      final id = String.fromCharCodes(wav.sublist(i, i + 4));
      final size = ByteData.sublistView(wav, i + 4, i + 8).getUint32(0, Endian.little);
      if (id == 'data') {
        dataOffset = i + 8;
        dataSize = size;
        break;
      }
      i += 8 + size;
    }
    if (dataOffset < 0) return <double>[];

    final samples = dataSize ~/ 2;
    final out = List<double>.filled(samples, 0.0);
    final bd = ByteData.sublistView(wav, dataOffset, dataOffset + dataSize);
    for (int k = 0; k < samples; k++) {
      final v = bd.getInt16(k * 2, Endian.little);
      out[k] = (v / 32767.0).clamp(-1.0, 1.0);
    }
    return out;
  }
}
