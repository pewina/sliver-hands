import 'package:flutter/material.dart';

import '../../app/app_theme.dart';

class VoiceButton extends StatelessWidget {
  const VoiceButton({super.key, this.label = 'Speak', this.onTap});
  final String label;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => FilledButton.icon(onPressed: onTap, icon: const Icon(Icons.mic_rounded, size: 24), label: Text(label), style: FilledButton.styleFrom(backgroundColor: AppColors.rose));
}
