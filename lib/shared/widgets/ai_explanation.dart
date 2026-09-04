import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../data/models/opportunity.dart';

class AIExplanation extends StatelessWidget {
  const AIExplanation({super.key, required this.opportunity});
  final Opportunity opportunity;

  static Future<void> show(BuildContext context, Opportunity opportunity) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => AIExplanation(opportunity: opportunity),
  );

  @override
  Widget build(BuildContext context) {
    final scores = opportunity.aiScore;
    return SafeArea(top: false, child: Container(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
      decoration: const BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 46, height: 5, decoration: BoxDecoration(color: const Color(0xFFB9C5BE), borderRadius: BorderRadius.circular(8)))),
        const SizedBox(height: 20),
        Row(children: [const CircleAvatar(radius: 24, backgroundColor: AppColors.saffron, child: Icon(Icons.auto_awesome_rounded, color: Colors.white)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Why this opportunity?', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900)), Text('A clear explanation from SilverHands AI', style: TextStyle(fontSize: 14, color: AppColors.ink.withValues(alpha: .7)))]))]),
        const SizedBox(height: 19),
        Center(child: TweenAnimationBuilder<double>(tween: Tween(begin: 0, end: opportunity.matchScore.toDouble()), duration: const Duration(milliseconds: 850), curve: Curves.easeOutCubic, builder: (context, value, _) => Text('${value.round()}% AI MATCH', style: const TextStyle(fontSize: 25, color: AppColors.teal, fontWeight: FontWeight.w900)))),
        const SizedBox(height: 16),
        _ScoreRow(label: 'Skill compatibility', value: scores.skillCompatibility),
        _ScoreRow(label: 'Local demand', value: scores.localDemand),
        _ScoreRow(label: 'Seasonal demand', value: scores.seasonalDemand),
        _ScoreRow(label: 'Distance', value: scores.distance),
        _ScoreRow(label: 'Experience', value: scores.experience),
        const SizedBox(height: 19),
        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFFFFF2D9), borderRadius: BorderRadius.circular(18)), child: Text('We recommend this opportunity because it matches your traditional cooking skills, demand for this product is currently high in your area, and the opportunity is nearby.', style: const TextStyle(fontSize: 16, height: 1.42, fontWeight: FontWeight.w600))),
      ]),
    ));
  }
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow({required this.label, required this.value});
  final String label;
  final int value;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 11), child: Row(children: [SizedBox(width: 155, child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))), Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: value / 35, minHeight: 9, color: AppColors.teal, backgroundColor: AppColors.mist))), const SizedBox(width: 10), SizedBox(width: 36, child: Text('$value%', textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)))]));
}
