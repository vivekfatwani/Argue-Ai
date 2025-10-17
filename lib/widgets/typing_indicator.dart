import 'package:flutter/material.dart';

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({Key? key}) : super(key: key);

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _animations;
  
  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    
    _animations = List.generate(3, (index) {
      final start = index * 0.2;
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, start + 0.4, curve: Curves.easeInOut),
        ),
      );
    });
    
    _controller.repeat();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(16.0).copyWith(
            bottomLeft: const Radius.circular(4.0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            return AnimatedBuilder(
              animation: _animations[index],
              builder: (context, child) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2.0),
                  width: 8.0,
                  height: 8.0 + (_animations[index].value * 4.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                );
              },
            );
          }),
        ),
      ),
    );
  }
}
