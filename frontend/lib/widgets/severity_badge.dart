import 'package:flutter/material.dart';

class SeverityBadge extends StatelessWidget {
  final String severity;
  final bool compact;

  const SeverityBadge({
    super.key,
    required this.severity,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (severity.toLowerCase()) {
      'low' => const Color(0xFF2EAD6B),
      'medium' => const Color(0xFFF2A33A),
      'high' => const Color(0xFFE5484D),
      _ => const Color(0xFF7A8491),
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 14,
        vertical: compact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        severity.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: compact ? 11 : 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}
