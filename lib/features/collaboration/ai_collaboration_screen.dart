import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../core/demo_store.dart';
import '../../core/app_config.dart';
import '../../core/backend_client.dart';
import '../../data/models/opportunity.dart';
import 'collaboration_models.dart';
import 'collaborative_order_dashboard.dart';

class AICollaborationScreen extends StatefulWidget {
  const AICollaborationScreen({super.key, this.opportunity});

  final Opportunity? opportunity;

  @override
  State<AICollaborationScreen> createState() => _AICollaborationScreenState();
}

class _AICollaborationScreenState extends State<AICollaborationScreen> {
  CollaborativeOrder? _order;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCollaboration();
  }

  Future<void> _loadCollaboration() async {
    final selected = widget.opportunity ?? DemoStore.instance.recommendedOpportunities.firstWhere(
      (item) => item.sellersRequired > 1,
      orElse: () => DemoStore.instance.recommendedOpportunities.first,
    );
    try {
      if (AppConfig.hasSupabase && selected.id != null) {
        final response = await BackendClient.instance.postJson('/collaboration/suggest', {
          'opportunity_id': selected.id,
          'units_required': selected.sellersRequired * 30,
          'required_skills': selected.skills.isEmpty ? DemoStore.instance.skills : selected.skills,
        });
        final sellers = (response['sellers'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map((item) => SquadSeller(
                  name: item['seller_name']?.toString() ?? 'SilverHands Partner',
                  contribution: (item['contribution'] as num?)?.toInt() ?? 0,
                  skills: (item['skills'] as List<dynamic>? ?? const []).join(', '),
                  location: item['location']?.toString() ?? 'Nearby',
                  reliability: (item['reliability_score'] as num?)?.toInt() ?? 90,
                ))
            .toList();
        final total = (response['units_required'] as num?)?.toInt() ?? selected.sellersRequired * 30;
        final allocated = (response['allocated_units'] as num?)?.toInt() ?? sellers.fold<int>(0, (sum, s) => sum + s.contribution);
        if (sellers.isNotEmpty) {
          if (mounted) setState(() {
            _order = CollaborativeOrder(title: selected.title, totalUnits: total, sellers: sellers);
            _loading = false;
          });
          return;
        }
      }

      final local = DemoStore.instance.collaborationFor(selected);
      if (mounted) setState(() { _order = local; _loading = false; });
    } catch (e) {
      final local = DemoStore.instance.collaborationFor(selected);
      if (mounted) setState(() { _order = local; _error = 'Cloud collaboration unavailable; showing the safe local demo.'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('AI Collaboration')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final order = _order!;
    final skills = DemoStore.instance.skills;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Collaboration'),
        backgroundColor: AppColors.cream,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
          children: [
            const Center(
              child: CircleAvatar(
                radius: 32,
                backgroundColor: Color(0xFFFFD694),
                child: Icon(Icons.auto_awesome_rounded, size: 36, color: AppColors.teal),
              ),
            ),
            const SizedBox(height: 13),
            const Center(
              child: Text(
                'AI COLLABORATION',
                style: TextStyle(color: AppColors.teal, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 1.1),
              ),
            ),
            const SizedBox(height: 8),
            Text(order.title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Center(
              child: Text(
                '${order.totalUnits} units required',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 18),
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(color: const Color(0xFFFFF2D9), borderRadius: BorderRadius.circular(14)),
                child: Text(_error!, style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: const Color(0xFFFFF2D9), borderRadius: BorderRadius.circular(22)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.groups_rounded, color: AppColors.saffron, size: 29),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'AI matched ${order.sellers.length} compatible sellers using your ${skills.isEmpty ? 'profile' : skills.join(', ')} skills and the order requirements.',
                      style: const TextStyle(fontSize: 17, height: 1.38, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 21),
            const Text('Your business squad', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            ...order.sellers.map((seller) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _SellerAllocationCard(seller: seller),
                )),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(17),
              decoration: BoxDecoration(color: AppColors.teal, borderRadius: BorderRadius.circular(20)),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Color(0xFFFFD694), size: 29),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      'Total  →  ${order.allocatedUnits} of ${order.totalUnits} units',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                  ),
                  const Text('✓', style: TextStyle(color: Color(0xFFFFD694), fontSize: 26, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
            const SizedBox(height: 21),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute<void>(builder: (_) => CollaborativeOrderDashboard(order: order)),
                ),
                icon: const Icon(Icons.groups_rounded),
                label: const Text('Create Business Squad'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SellerAllocationCard extends StatelessWidget {
  const _SellerAllocationCard({required this.seller});
  final SquadSeller seller;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.mist,
                child: Text(seller.name[0], style: const TextStyle(color: AppColors.teal, fontWeight: FontWeight.w900, fontSize: 20)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(seller.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 3),
                    Text(seller.skills, style: const TextStyle(fontSize: 15)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 16),
                        const SizedBox(width: 3),
                        Expanded(child: Text(seller.location, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${seller.contribution}', style: const TextStyle(color: AppColors.teal, fontSize: 21, fontWeight: FontWeight.w900)),
                  const Text('units', style: TextStyle(fontSize: 13)),
                  const SizedBox(height: 7),
                  Text('${seller.reliability}% reliable', style: const TextStyle(color: AppColors.green, fontSize: 12, fontWeight: FontWeight.w900)),
                ],
              ),
            ],
          ),
        ),
      );
}
