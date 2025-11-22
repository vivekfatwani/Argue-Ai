import 'package:flutter/material.dart';
import 'dart:math' as math;

/// A radar/spider chart widget for displaying skill levels
class SkillRadarChart extends StatelessWidget {
  final Map<String, double> skills;
  final double size;
  final Color fillColor;
  final Color strokeColor;
  final Color gridColor;
  final Color textColor;

  const SkillRadarChart({
    Key? key,
    required this.skills,
    this.size = 300,
    this.fillColor = const Color(0x4D3F51B5),
    this.strokeColor = const Color(0xFF3F51B5),
    this.gridColor = const Color(0x1A000000),
    this.textColor = const Color(0xFF000000),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (skills.isEmpty) {
      return SizedBox(
        width: size,
        height: size,
        child: const Center(
          child: Text('No skills data available'),
        ),
      );
    }

    return CustomPaint(
      size: Size(size, size),
      painter: _RadarChartPainter(
        skills: skills,
        fillColor: fillColor,
        strokeColor: strokeColor,
        gridColor: gridColor,
        textColor: textColor,
      ),
    );
  }
}

class _RadarChartPainter extends CustomPainter {
  final Map<String, double> skills;
  final Color fillColor;
  final Color strokeColor;
  final Color gridColor;
  final Color textColor;

  _RadarChartPainter({
    required this.skills,
    required this.fillColor,
    required this.strokeColor,
    required this.gridColor,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 * 0.7;
    final skillCount = skills.length;
    final angleStep = 2 * math.pi / skillCount;

    // Draw grid circles
    _drawGrid(canvas, center, radius, skillCount, angleStep);

    // Draw skill polygon
    _drawSkillPolygon(canvas, center, radius, angleStep);

    // Draw labels
    _drawLabels(canvas, center, radius, angleStep);
  }

  void _drawGrid(Canvas canvas, Offset center, double radius, int skillCount, double angleStep) {
    final gridPaint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw concentric circles
    for (int i = 1; i <= 5; i++) {
      final path = Path();
      final currentRadius = radius * i / 5;

      for (int j = 0; j < skillCount; j++) {
        final angle = j * angleStep - math.pi / 2;
        final x = center.dx + currentRadius * math.cos(angle);
        final y = center.dy + currentRadius * math.sin(angle);

        if (j == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    // Draw radial lines
    for (int i = 0; i < skillCount; i++) {
      final angle = i * angleStep - math.pi / 2;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      canvas.drawLine(center, Offset(x, y), gridPaint);
    }
  }

  void _drawSkillPolygon(Canvas canvas, Offset center, double radius, double angleStep) {
    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    final skillEntries = skills.entries.toList();

    for (int i = 0; i < skillEntries.length; i++) {
      final angle = i * angleStep - math.pi / 2;
      final value = skillEntries[i].value.clamp(0.0, 1.0);
      final currentRadius = radius * value;
      final x = center.dx + currentRadius * math.cos(angle);
      final y = center.dy + currentRadius * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }

      // Draw point
      canvas.drawCircle(Offset(x, y), 4, strokePaint..style = PaintingStyle.fill);
    }
    path.close();

    canvas.drawPath(path, fillPaint);
    strokePaint.style = PaintingStyle.stroke;
    canvas.drawPath(path, strokePaint);
  }

  void _drawLabels(Canvas canvas, Offset center, double radius, double angleStep) {
    final skillEntries = skills.entries.toList();
    final labelRadius = radius + 30;

    for (int i = 0; i < skillEntries.length; i++) {
      final angle = i * angleStep - math.pi / 2;
      final x = center.dx + labelRadius * math.cos(angle);
      final y = center.dy + labelRadius * math.sin(angle);

      final textPainter = TextPainter(
        text: TextSpan(
          text: _formatLabel(skillEntries[i].key),
          style: TextStyle(
            color: textColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      // Center the text
      final offset = Offset(
        x - textPainter.width / 2,
        y - textPainter.height / 2,
      );
      textPainter.paint(canvas, offset);

      // Draw percentage below label
      final percentPainter = TextPainter(
        text: TextSpan(
          text: '${(skillEntries[i].value * 100).toInt()}%',
          style: TextStyle(
            color: textColor.withOpacity(0.7),
            fontSize: 10,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      percentPainter.layout();
      
      final percentOffset = Offset(
        x - percentPainter.width / 2,
        y - percentPainter.height / 2 + 12,
      );
      percentPainter.paint(canvas, percentOffset);
    }
  }

  String _formatLabel(String label) {
    return label.substring(0, 1).toUpperCase() + label.substring(1);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
