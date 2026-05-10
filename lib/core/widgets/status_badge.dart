import 'package:flutter/material.dart';

/// A small colored label chip showing text with a background tint.
///
/// Used for status, priority, and course-code tags throughout the app.
class StatusBadge extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final double fontSize;

  const StatusBadge({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.fontSize = 10,
  });

  /// Constructs a badge from a pre-computed color pair (record).
  factory StatusBadge.fromColors({
    Key? key,
    required String label,
    required ({Color background, Color foreground}) colors,
    double fontSize = 10,
  }) {
    return StatusBadge(
      key: key,
      label: label,
      backgroundColor: colors.background,
      textColor: colors.foreground,
      fontSize: fontSize,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}
