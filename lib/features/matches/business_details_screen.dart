import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../data/models/opportunity.dart';
import '../../shared/widgets/badges.dart';
import '../../core/demo_store.dart';
import '../collaboration/ai_collaboration_screen.dart';
import 'business_chat_screen.dart';
import 'mock_matching_repository.dart';

class BusinessDetailsScreen extends StatelessWidget {
  const BusinessDetailsScreen({
    super.key,
    required this.opportunity,
    required this.business,
  });
  final Opportunity opportunity;
  final BusinessProfile business;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Business details'),
      backgroundColor: AppColors.cream,
    ),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(19),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 26,
                        backgroundColor: AppColors.mist,
                        child: Icon(
                          Icons.storefront_rounded,
                          color: AppColors.teal,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              business.businessName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const Text('T. Nagar, Chennai'),
                            const SizedBox(height: 3),
                            const VerificationBadge(),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Text(
                    business.description,
                    style: const TextStyle(fontSize: 16, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Order requirements',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 9),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(17),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: business.orderRequirements
                    .map(
                      (requirement) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.green,
                              size: 20,
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                requirement,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 18),
          if (opportunity.sellersRequired > 1)
            Container(
              padding: const EdgeInsets.all(17),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF2D9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.groups_rounded, color: AppColors.saffron, size: 27),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('AI collaboration available', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
                        const SizedBox(height: 4),
                        Text(
                          'This is a bulk order. SilverHands AI can find compatible sellers and split the work using skills and reliability.',
                          style: const TextStyle(fontSize: 15, height: 1.35),
                        ),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => AICollaborationScreen(opportunity: opportunity),
                            ),
                          ),
                          child: const Text('See AI collaboration plan'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          if (opportunity.sellersRequired > 1) const SizedBox(height: 20),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => BusinessChatScreen(
                    opportunity: opportunity,
                    business: business,
                  ),
                ),
              ),
              icon: const Icon(Icons.chat_bubble_rounded),
              label: const Text('Open business chat'),
            ),
          ),
        ],
      ),
    ),
  );
}
