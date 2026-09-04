import 'package:flutter/material.dart';

import '../../app/app_theme.dart';

class SkillChip extends StatelessWidget {
  const SkillChip({super.key, required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
    decoration: BoxDecoration(color: AppColors.mist, borderRadius: BorderRadius.circular(14)),
    child: Text(label, style: const TextStyle(color: AppColors.teal, fontWeight: FontWeight.w700, fontSize: 13)),
  );
}
