import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../core/demo_store.dart';
import '../../core/app_config.dart';
import '../../data/repositories/opportunity_repository.dart';
import '../discover/opportunity_interaction_repository.dart';
import '../../shared/widgets/badges.dart';
import '../collaboration/ai_collaboration_screen.dart';
import 'business_chat_screen.dart';
import 'mock_matching_repository.dart';
import '../../data/models/opportunity.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  final DemoStore _demo = DemoStore.instance;
  final OpportunityRepository _opportunityRepository = OpportunityRepository();
  final OpportunityInteractionRepository _interactionRepository = OpportunityInteractionRepository();
  List<Opportunity> _matches = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    if (!AppConfig.hasSupabase) {
      if (mounted) setState(() { _matches = _demo.interestedOpportunities; _loading = false; });
      return;
    }
    try {
      final ids = await _interactionRepository.getInterestedOpportunityIds();
      final opportunities = await _opportunityRepository.getOpportunities();
      final idSet = ids.toSet();
      if (mounted) setState(() { _matches = opportunities.where((o) => o.id != null && idSet.contains(o.id)).toList(); _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _matches = []; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final matches = _matches;
    final profileSkills = _demo.skills;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        children: [
          Text('Your Matches', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 6),
          const Text(
            'Opportunities and businesses you chose to work with.',
            style: TextStyle(fontSize: 17),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              color: const Color(0xFFFFE7EB),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.favorite_rounded, color: AppColors.rose, size: 30),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    matches.isEmpty
                        ? 'Your interested opportunities will appear here.'
                        : '${matches.length} active match${matches.length == 1 ? '' : 'es'} based on ${profileSkills.isEmpty ? 'your profile' : profileSkills.join(', ')}.',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(30),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (matches.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 31,
                      backgroundColor: AppColors.mist,
                      child: Icon(Icons.swipe_rounded, color: AppColors.teal, size: 32),
                    ),
                    const SizedBox(height: 13),
                    const Text(
                      'No matches yet',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Go to Discover and tap Interested on an opportunity that fits your skills.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, height: 1.4),
                    ),
                  ],
                ),
              ),
            )
          else
            ...matches.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 13),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(
                                item.imageUrl,
                                width: 78,
                                height: 78,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => const SizedBox(
                                  width: 78,
                                  height: 78,
                                  child: ColoredBox(color: Color(0xFFE4DDD2)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 13),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(item.seller),
                                  const SizedBox(height: 5),
                                  Row(
                                    children: [
                                      Text('${item.matchScore}% match', style: const TextStyle(color: AppColors.teal, fontWeight: FontWeight.w900)),
                                      const SizedBox(width: 9),
                                      const VerificationBadge(),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.mist,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            item.recommendationReasons.take(2).join(' • '),
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => BusinessChatScreen(
                                      opportunity: item,
                                      business: _businessFor(item),
                                    ),
                                  ),
                                ),
                                icon: const Icon(Icons.chat_bubble_outline_rounded),
                                label: const Text('Chat'),
                              ),
                            ),
                            if (item.sellersRequired > 1) ...[
                              const SizedBox(width: 9),
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AICollaborationScreen(
                                        opportunity: item,
                                      ),
                                    ),
                                  ),
                                  icon: const Icon(Icons.groups_rounded),
                                  label: const Text('Collaborate'),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  BusinessProfile _businessFor(dynamic item) => BusinessProfile(
        businessName: item.seller,
        contactName: 'Business representative',
        description: item.description,
        orderRequirements: [
          item.subtitle,
          item.price,
          'Confirm quantity and delivery date',
          item.sellersRequired > 1 ? 'Multiple sellers can collaborate' : 'Work can be completed independently',
        ],
        collaborationNote: item.sellersRequired > 1
            ? 'AI found compatible SilverHands sellers who can share this order.'
            : 'This opportunity can be completed independently.',
      );
}
