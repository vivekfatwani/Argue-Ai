import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

Future<void> main() async {
  // Need to initialize Flutter binding
  WidgetsFlutterBinding.ensureInitialized();
  
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  
  // Define the size of the logo
  const size = Size(1024, 1024);
  
  // Draw the background circle
  final bgPaint = Paint()
    ..color = const Color(0xFF3F51B5) // Indigo
    ..style = PaintingStyle.fill;
  
  canvas.drawCircle(
    Offset(size.width / 2, size.height / 2),
    size.width / 2,
    bgPaint,
  );
  
  // Draw the letter A
  final pathA = Path();
  pathA.moveTo(size.width / 2, size.height * 0.2); // Top of A
  pathA.lineTo(size.width * 0.75, size.height * 0.8); // Bottom right of A
  pathA.lineTo(size.width * 0.25, size.height * 0.8); // Bottom left of A
  pathA.close();
  
  final aPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.fill;
  
  canvas.drawPath(pathA, aPaint);
  
  // Draw the crossbar of the A
  final crossbarPaint = Paint()
    ..color = const Color(0xFF3F51B5)
    ..style = PaintingStyle.stroke
    ..strokeWidth = size.width * 0.05
    ..strokeCap = StrokeCap.round;
  
  canvas.drawLine(
    Offset(size.width * 0.35, size.height * 0.6),
    Offset(size.width * 0.65, size.height * 0.6),
    crossbarPaint,
  );
  
  // Convert to an image
  final picture = recorder.endRecording();
  final img = await picture.toImage(size.width.toInt(), size.height.toInt());
  final pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);
  
  if (pngBytes != null) {
    // Save the image
    final buffer = pngBytes.buffer.asUint8List();
    final file = File('assets/images/argumentor_logo.png');
    await file.writeAsBytes(buffer);
    print('Logo saved to ${file.path}');
  } else {
    print('Failed to generate PNG bytes');
  }
  
  // Exit the application
  exit(0);
}
