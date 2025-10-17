import 'package:flutter/material.dart';

class PageIndicator extends StatelessWidget {
  final int count;
  final int currentIndex;
  final Color activeColor;
  final Color inactiveColor;
  final double size;
  final double spacing;

  const PageIndicator({
    Key? key,
    required this.count,
    required this.currentIndex,
    this.activeColor = const Color(0xFF6750A4),
    this.inactiveColor = const Color(0xFFE0E0E0),
    this.size = 8.0,
    this.spacing = 4.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (index) {
        return Container(
          margin: EdgeInsets.symmetric(horizontal: spacing),
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index == currentIndex ? activeColor : inactiveColor,
          ),
        );
      }),
    );
  }
}
