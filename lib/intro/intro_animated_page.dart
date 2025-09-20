// lib/intro/intro_animated_page.dart
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class IntroAnimatedPage extends StatefulWidget {
  final VoidCallback onFinished;
  final bool skippable;
  final Duration minDuration;
  const IntroAnimatedPage({
    super.key,
    required this.onFinished,
    this.skippable = true,
    this.minDuration = const Duration(seconds: 3),
  });

  @override
  State<IntroAnimatedPage> createState() => _IntroAnimatedPageState();
}

class _IntroAnimatedPageState extends State<IntroAnimatedPage>
    with TickerProviderStateMixin {
  late final AnimationController _fadeInCtl;
  late final AnimationController _holdCtl;
  late final AnimationController _fadeOutCtl;

  @override
  void initState() {
    super.initState();
    _fadeInCtl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();
    _holdCtl   = AnimationController(vsync: this, duration: widget.minDuration);
    _fadeOutCtl= AnimationController(vsync: this, duration: const Duration(milliseconds: 500));

    _fadeInCtl.addStatusListener((s) {
      if (s == AnimationStatus.completed) _holdCtl.forward();
    });
    _holdCtl.addStatusListener((s) {
      if (s == AnimationStatus.completed) _fadeOutCtl.forward();
    });
    _fadeOutCtl.addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onFinished();
    });
  }

  @override
  void dispose() {
    _fadeInCtl.dispose();
    _holdCtl.dispose();
    _fadeOutCtl.dispose();
    super.dispose();
  }

  void _skip() {
    if (widget.skippable) {
      _fadeInCtl.stop();
      _holdCtl.stop();
      _fadeOutCtl.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fadeIn = CurvedAnimation(parent: _fadeInCtl, curve: Curves.easeOutCubic);
    final fadeOut= CurvedAnimation(parent: _fadeOutCtl, curve: Curves.easeInCubic);

    return Scaffold(
      body: Stack(
        children: [
          // Fondo con gradiente
          Positioned.fill(
            child: AnimatedBuilder(
              animation: Listenable.merge([_fadeInCtl, _fadeOutCtl]),
              builder: (_, __) {
                final t = (fadeIn.value * (1 - fadeOut.value)).clamp(0.0, 1.0);
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFF0E0F14),
                        Color.lerp(const Color(0xFF0E0F14), const Color(0xFF12151A), t)!,
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Logo animado
          Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([_fadeInCtl, _fadeOutCtl]),
              builder: (_, __) {
                final scale = 0.9 + 0.1 * Curves.easeOutBack.transform(fadeIn.value);
                final opacity = (1 - fadeOut.value);
                return Opacity(
                  opacity: opacity,
                  child: Transform.scale(
                    scale: scale,
                    child: const _SpiriMixLogo(size: 220),
                  ),
                );
              },
            ),
          ),
          // Wordmark y tagline
          Positioned(
            bottom: 120, left: 0, right: 0,
            child: AnimatedBuilder(
              animation: Listenable.merge([_fadeInCtl, _fadeOutCtl]),
              builder: (_, __) {
                final dy = (1 - _fadeInCtl.value) * 20 + _fadeOutCtl.value * 20;
                final opacity = (1 - _fadeOutCtl.value).clamp(0.0,1.0);
                return Opacity(
                  opacity: opacity,
                  child: Transform.translate(
                    offset: Offset(0, dy),
                    child: Column(
                      children: [
                        _brandTitle(),
                        const SizedBox(height: 8),
                        const Text(
                          'Inner balance • Breathe • Focus',
                          style: TextStyle(color: Color(0xFFB4B9C1)),
                        ),
                        const SizedBox(height: 28),
                        const Text(
                          'Hecho por JavieraBv',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (widget.skippable)
            Positioned(
              top: 48, right: 16,
              child: FilledButton.tonal(
                onPressed: _skip,
                child: const Text('Saltar'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _brandTitle() {
    return RichText(
      text: TextSpan(
        children: [
          const TextSpan(
            text: 'Spiri',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w800, fontSize: 36),
          ),
          TextSpan(
            text: 'Mix',
            style: TextStyle(
                foreground: Paint()
                  ..shader = ui.Gradient.linear(
                    const Offset(0, 0), const Offset(160, 0),
                    const [Color(0xFF5DD2C1), Color(0xFF45B9A9)],
                  ),
                fontWeight: FontWeight.w900, fontSize: 36),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

/// Logo “loto + onda” dibujado con Canvas (sin assets).
class _SpiriMixLogo extends StatelessWidget {
  final double size;
  const _SpiriMixLogo({required this.size});
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _LotusPainter(),
    );
  }
}

class _LotusPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final petalPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, 0), Offset(size.width, size.height),
        const [Color(0xFF5DD2C1), Color(0xFF45B9A9)],
      );
    final petal = Path()..addOval(Rect.fromCenter(center: Offset(cx, cy-16), width: size.width*0.28, height: size.height*0.45));

    void drawRotated(double deg) {
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(deg * math.pi / 180);
      canvas.translate(-cx, -cy);
      canvas.drawPath(petal, petalPaint);
      canvas.restore();
    }

    drawRotated(-60);
    drawRotated(0);
    drawRotated(60);
    // pétalo inferior
    final lower = Path()..addOval(Rect.fromCenter(center: Offset(cx, cy+8), width: size.width*0.42, height: size.height*0.24));
    canvas.drawPath(lower, petalPaint);

    // Onda dorada
    final wavePaint = Paint()
      ..shader = ui.Gradient.linear(
        const Offset(0, 0), Offset(size.width, 0),
        const [Color(0xFFCDAF6B), Color(0xFFE7C984)],
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.02
      ..strokeCap = StrokeCap.round;
    final wave = Path();
    final y0 = cy + size.height * 0.26;
    for (double x = size.width*0.1; x <= size.width*0.9; x += 8) {
      final t = (x - size.width*0.1) / (size.width*0.8);
      final y = y0 + math.sin(t * math.pi * 3) * (size.height * 0.02);
      if (x == size.width*0.1) wave.moveTo(x, y); else wave.lineTo(x, y);
    }
    canvas.drawPath(wave, wavePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
