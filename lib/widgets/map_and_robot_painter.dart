import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class LabelPoint {
  final String label;
  final Offset offset;
  LabelPoint({required this.label, required this.offset});
}

class MapAndRobotPainter extends CustomPainter {
  final ui.Image mapImage;
  final List<Offset> trailPoints;
  final List<LabelPoint> fixedPoints;

  MapAndRobotPainter({
    required this.mapImage,
    required this.trailPoints,
    required this.fixedPoints,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final mapSourceRect = Rect.fromLTWH(0, 0, mapImage.width.toDouble(), mapImage.height.toDouble());
    final canvasDestRect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawImageRect(mapImage, mapSourceRect, canvasDestRect, paint);

    final scaleX = size.width / mapImage.width;
    final scaleY = size.height / mapImage.height;

    for (final point in fixedPoints) {
      final scaledPosition = Offset(point.offset.dx * scaleX, point.offset.dy * scaleY);
      final paintDot = Paint()..color = Colors.red;
      canvas.drawCircle(scaledPosition, 5, paintDot);
      final textPainter = TextPainter(
        text: TextSpan(text: point.label, style: const TextStyle(fontSize: 10, color: Colors.red, backgroundColor: Color(0x99FFFFFF))),
        textDirection: ui.TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, scaledPosition + const Offset(8, -18));
    }

    if (trailPoints.isNotEmpty) {
        final path = Path();
        final firstPoint = trailPoints.first;
        path.moveTo(firstPoint.dx * scaleX, firstPoint.dy * scaleY);
        for (int i = 1; i < trailPoints.length; i++) {
            path.lineTo(trailPoints[i].dx * scaleX, trailPoints[i].dy * scaleY);
        }
        final trailPaint = Paint()..color = Colors.blue.withOpacity(0.8)..style = PaintingStyle.stroke..strokeWidth = 2.0;
        canvas.drawPath(path, trailPaint);

        final currentPosition = Offset(trailPoints.last.dx * scaleX, trailPoints.last.dy * scaleY);
        final paintDot = Paint()..style = PaintingStyle.fill..color = const Color(0xFF2E7D32);
        canvas.drawCircle(currentPosition, 6, paintDot);
        final paintHalo = Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = const Color(0x802E7D32);
        canvas.drawCircle(currentPosition, 10, paintHalo);
    }
  }

  @override
  bool shouldRepaint(covariant MapAndRobotPainter oldDelegate) {
    return oldDelegate.mapImage != mapImage ||
           oldDelegate.trailPoints != trailPoints ||
           oldDelegate.fixedPoints != fixedPoints;
  }
}
