import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import 'collaboration_models.dart';

class CollaborativeOrderDashboard extends StatelessWidget {
  const CollaborativeOrderDashboard({
    super.key,
    required this.order,
  });

  final CollaborativeOrder order;

  @override
  Widget build(BuildContext context) {
    final progress = order.totalUnits == 0
        ? 0.0
        : (order.allocatedUnits / order.totalUnits).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Squad'),
        backgroundColor: AppColors.cream,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.teal,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.groups_rounded,
                        color: Color(0xFFFFD694),
                        size: 30,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Your squad is ready!',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 21,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 17),
                  Text(
                    order.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      color: const Color(0xFFFFD694),
                      backgroundColor: const Color(0x557CE0D5),
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    '${order.allocatedUnits} of ${order.totalUnits} units allocated',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            Text(
              'Everyone’s contribution',
              style: Theme.of(context).textTheme.titleLarge,
            ),

            const SizedBox(height: 10),

            ...order.sellers.map(
              (seller) => Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: AppColors.mist,
                    child: Text(
                      seller.name[0],
                      style: const TextStyle(
                        color: AppColors.teal,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  title: Text(
                    seller.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                    ),
                  ),
                  subtitle: Text(
                    '${seller.contribution} units • ${seller.skills}',
                  ),
                  trailing: const Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: AppColors.teal,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Next step',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),

            const SizedBox(height: 9),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(17),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Confirm your contribution',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Tell your squad when you can have your share ready.',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Your contribution has been confirmed!',
                              ),
                            ),
                          );
                        },
                        child: const Text('Confirm my contribution'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Squad chat coming soon.'),
                  ),
                );
              },
              icon: const Icon(Icons.forum_rounded),
              label: const Text('Open squad chat'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
              ),
            ),
          ],
        ),
      ),
    );
  }
}