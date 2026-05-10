import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A styled card container used for grouping settings tiles.
class SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const SettingsCard({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(children: children),
    );
  }
}
