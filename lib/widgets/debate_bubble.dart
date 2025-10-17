import 'package:flutter/material.dart';
import '../core/utils.dart';

class DebateBubble extends StatelessWidget {
  final String message;
  final bool isUser;
  final DateTime timestamp;

  const DebateBubble({
    Key? key,
    required this.message,
    required this.isUser,
    required this.timestamp,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: isUser
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(16.0).copyWith(
            bottomRight: isUser ? const Radius.circular(4.0) : null,
            bottomLeft: !isUser ? const Radius.circular(4.0) : null,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: TextStyle(
                color: isUser
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 16.0,
              ),
            ),
            const SizedBox(height: 4.0),
            Text(
              Utils.formatTimestamp(timestamp),
              style: TextStyle(
                color: isUser
                    ? Theme.of(context).colorScheme.onPrimary.withOpacity(0.7)
                    : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                fontSize: 12.0,
              ),
              textAlign: TextAlign.right,
            ),
          ],
        ),
      ),
    );
  }
}
