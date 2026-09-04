import 'package:flutter/material.dart';

import '../../data/models/opportunity.dart';
import 'badges.dart';
import 'skill_chip.dart';

class OpportunityCard extends StatelessWidget {
  const OpportunityCard({super.key, required this.opportunity, this.compact = false});
  final Opportunity opportunity;
  final bool compact;
  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      AspectRatio(aspectRatio: compact ? 1.75 : 1.38, child: Stack(fit: StackFit.expand, children: [Image.network(opportunity.imageUrl, fit: BoxFit.cover, errorBuilder: (_, _, _) => const ColoredBox(color: Color(0xFFE4DDD2), child: Icon(Icons.image_rounded, size: 50)) ,), Positioned(top: 12, left: 12, child: SellerBadge(name: opportunity.seller)), if (opportunity.matchScore > 0) Positioned(top: 12, right: 12, child: MatchScore(score: opportunity.matchScore))])),
      Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(opportunity.title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 5), Text(opportunity.subtitle, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 10), Row(children: [const Icon(Icons.location_on_outlined, size: 19), const SizedBox(width: 4), Expanded(child: Text(opportunity.location, style: const TextStyle(fontWeight: FontWeight.w600))), Text(opportunity.price, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16))]),
        if (!compact) ...[const SizedBox(height: 12), Wrap(spacing: 7, runSpacing: 7, children: opportunity.skills.map((skill) => SkillChip(label: skill)).toList()), const SizedBox(height: 12), if (opportunity.verified) const VerificationBadge()],
      ])),
    ]),
  );
}
