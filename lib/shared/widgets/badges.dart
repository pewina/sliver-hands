import 'package:flutter/material.dart';

import '../../app/app_theme.dart';

class SellerBadge extends StatelessWidget {
  const SellerBadge({super.key, required this.name});
  final String name;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: .92), borderRadius: BorderRadius.circular(14)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.storefront_rounded, size: 17, color: AppColors.teal), const SizedBox(width: 5), Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13))]),
  );
}

class VerificationBadge extends StatelessWidget {
  const VerificationBadge({super.key});
  @override
  Widget build(BuildContext context) => const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.verified_rounded, color: AppColors.teal, size: 18), SizedBox(width: 4), Text('Verified', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.teal))]);
}

class MatchScore extends StatelessWidget {
  const MatchScore({super.key, required this.score});
  final int score;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(color: AppColors.green, borderRadius: BorderRadius.circular(16)),
    child: Text('$score% match', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
  );
}
