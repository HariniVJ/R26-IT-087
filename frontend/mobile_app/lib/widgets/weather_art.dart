import 'dart:math' as math;

import 'package:flutter/material.dart';

enum WeatherArtType {
  sunny,
  partlyCloudy,
  cloudy,
  rain,
  heavyRain,
  thunderstorm,
  irrigate,
  plant,
  thermometer,
}

class WeatherArt extends StatelessWidget {
  final WeatherArtType type;
  final double size;

  const WeatherArt({super.key, required this.type, this.size = 132});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _WeatherArtPainter(type)),
    );
  }
}

class _WeatherArtPainter extends CustomPainter {
  final WeatherArtType type;
  const _WeatherArtPainter(this.type);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    switch (type) {
      case WeatherArtType.sunny:
        _sun(canvas, c, size.width * 0.18, drawRays: true);
        break;
      case WeatherArtType.partlyCloudy:
        _sun(canvas, Offset(c.dx + 18, c.dy - 16), size.width * 0.13, drawRays: true);
        _cloud(canvas, Offset(c.dx - 4, c.dy + 10), size.width * 0.34, const Color(0xFFF3F4F6));
        break;
      case WeatherArtType.cloudy:
        _cloud(canvas, Offset(c.dx, c.dy + 4), size.width * 0.36, const Color(0xFFE5E7EB));
        _cloud(canvas, Offset(c.dx - 10, c.dy + 14), size.width * 0.30, const Color(0xFFD1D5DB));
        break;
      case WeatherArtType.rain:
        _cloud(canvas, Offset(c.dx, c.dy - 10), size.width * 0.34, const Color(0xFFD1D5DB));
        _rain(canvas, c, size, 5, const Color(0xFF60A5FA));
        break;
      case WeatherArtType.heavyRain:
        _cloud(canvas, Offset(c.dx, c.dy - 12), size.width * 0.36, const Color(0xFF6B7280));
        _rain(canvas, c, size, 8, const Color(0xFF2563EB));
        break;
      case WeatherArtType.thunderstorm:
        _cloud(canvas, Offset(c.dx, c.dy - 16), size.width * 0.36, const Color(0xFF374151));
        _rain(canvas, c, size, 4, const Color(0xFF3B82F6));
        _bolt(canvas, Offset(c.dx + 4, c.dy + 8), size.width * 0.16);
        break;
      case WeatherArtType.irrigate:
        _drop(canvas, c, size.width * 0.22, const Color(0xFF7DD3FC));
        break;
      case WeatherArtType.plant:
        _plant(canvas, c, size.width);
        break;
      case WeatherArtType.thermometer:
        _thermometer(canvas, c, size.width);
        break;
    }
  }

  void _sun(Canvas canvas, Offset center, double radius, {required bool drawRays}) {
    if (drawRays) {
      final ray = Paint()
        ..color = const Color(0xFFFBBF24)
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < 8; i++) {
        final a = i * math.pi / 4;
        canvas.drawLine(
          center + Offset(math.cos(a), math.sin(a)) * (radius + 6),
          center + Offset(math.cos(a), math.sin(a)) * (radius + 16),
          ray,
        );
      }
    }
    canvas.drawCircle(center, radius, Paint()..color = const Color(0xFFF59E0B));
    canvas.drawCircle(center, radius * 0.72, Paint()..color = const Color(0xFFFBBF24));
  }

  void _cloud(Canvas canvas, Offset center, double scale, Color color) {
    final paint = Paint()..color = color;
    canvas.drawOval(Rect.fromCenter(center: center, width: scale * 2.1, height: scale * 1.15), paint);
    canvas.drawCircle(center + Offset(-scale * 0.55, -scale * 0.18), scale * 0.52, paint);
    canvas.drawCircle(center + Offset(scale * 0.15, -scale * 0.38), scale * 0.62, paint);
    canvas.drawCircle(center + Offset(scale * 0.68, -scale * 0.08), scale * 0.42, paint);
  }

  void _rain(Canvas canvas, Offset c, Size size, int drops, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final startY = c.dy + 18;
    for (var i = 0; i < drops; i++) {
      final x = c.dx - 28 + i * 8.5;
      canvas.drawLine(Offset(x, startY), Offset(x - 3, startY + 18), paint);
    }
  }

  void _bolt(Canvas canvas, Offset origin, double scale) {
    final path = Path()
      ..moveTo(origin.dx, origin.dy)
      ..lineTo(origin.dx - scale * 0.35, origin.dy + scale * 0.7)
      ..lineTo(origin.dx + scale * 0.05, origin.dy + scale * 0.7)
      ..lineTo(origin.dx - scale * 0.2, origin.dy + scale * 1.55)
      ..lineTo(origin.dx + scale * 0.55, origin.dy + scale * 0.55)
      ..lineTo(origin.dx + scale * 0.12, origin.dy + scale * 0.55)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFFFBBF24));
  }

  void _drop(Canvas canvas, Offset c, double scale, Color color) {
    final path = Path()
      ..moveTo(c.dx, c.dy - scale * 1.15)
      ..cubicTo(
        c.dx + scale,
        c.dy - scale * 0.1,
        c.dx + scale * 0.85,
        c.dy + scale * 0.85,
        c.dx,
        c.dy + scale,
      )
      ..cubicTo(
        c.dx - scale * 0.85,
        c.dy + scale * 0.85,
        c.dx - scale,
        c.dy - scale * 0.1,
        c.dx,
        c.dy - scale * 1.15,
      );
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawOval(
      Rect.fromCenter(center: c + Offset(-scale * 0.22, -scale * 0.15), width: scale * 0.28, height: scale * 0.42),
      Paint()..color = Colors.white.withValues(alpha: 0.28),
    );
  }

  void _plant(Canvas canvas, Offset c, double width) {
    final stem = Paint()
      ..color = const Color(0xFF16A34A)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(c + Offset(0, 28), c + Offset(0, -8), stem);
    canvas.drawOval(
      Rect.fromCenter(center: c + const Offset(-16, -6), width: 28, height: 16),
      Paint()..color = const Color(0xFF22C55E),
    );
    canvas.drawOval(
      Rect.fromCenter(center: c + const Offset(16, 2), width: 26, height: 15),
      Paint()..color = const Color(0xFF4ADE80),
    );
    canvas.drawCircle(c + const Offset(0, 32), 10, Paint()..color = const Color(0xFF9B1230).withValues(alpha: 0.18));
  }

  void _thermometer(Canvas canvas, Offset c, double width) {
    final scale = width * 0.11;
    final tube = RRect.fromRectAndRadius(
      Rect.fromCenter(center: c + Offset(0, -scale * 0.6), width: scale * 1.15, height: scale * 5.2),
      Radius.circular(scale),
    );
    canvas.drawRRect(tube, Paint()..color = const Color(0xFFE5E7EB));
    canvas.drawCircle(c + Offset(0, scale * 2.15), scale * 1.55, Paint()..color = const Color(0xFFE5E7EB));
    canvas.drawCircle(c + Offset(0, scale * 2.15), scale * 1.15, Paint()..color = const Color(0xFFF59E0B));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: c + Offset(0, scale * 0.35), width: scale * 0.55, height: scale * 3.4),
        Radius.circular(scale),
      ),
      Paint()..color = const Color(0xFFF59E0B),
    );
  }

  @override
  bool shouldRepaint(covariant _WeatherArtPainter oldDelegate) => oldDelegate.type != type;
}
