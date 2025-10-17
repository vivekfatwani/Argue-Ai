import 'package:flutter/material.dart';
import 'dart:math' as math;

class VoiceWave extends StatefulWidget {
  final bool isActive;
  final Color color;
  final int barCount;

  const VoiceWave({
    Key? key,
    required this.isActive,
    this.color = const Color(0xFF6750A4),
    this.barCount = 30,
  }) : super(key: key);

  @override
  State<VoiceWave> createState() => _VoiceWaveState();
}

class _VoiceWaveState extends State<VoiceWave> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<double> _barHeights;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _generateBarHeights();
    
    if (widget.isActive) {
      _controller.repeat(reverse: true);
    }
  }
  
  @override
  void didUpdateWidget(VoiceWave oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  void _generateBarHeights() {
    _barHeights = List.generate(
      widget.barCount,
      (_) => _random.nextDouble() * 0.8 + 0.2, // Heights between 0.2 and 1.0
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        if (widget.isActive) {
          // Regenerate heights on each animation frame when active
          _generateBarHeights();
        }
        
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.barCount,
            (index) {
              final height = _barHeights[index] * 30; // Scale to max height of 30
              
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 1),
                width: 3,
                height: height,
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(1.5),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
