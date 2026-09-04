import 'package:flutter/material.dart';

import '../../app/app_theme.dart';

class BusinessScreen extends StatefulWidget {
  const BusinessScreen({super.key});

  @override
  State<BusinessScreen> createState() => _BusinessScreenState();
}

class _BusinessScreenState extends State<BusinessScreen> {
  String _skill = 'Home cooking';
  String? _recommendation;

  static const _ideas = {
    'Home cooking':
        'Make 20 traditional gift hampers this week. Add millet laddoos, murukku and a handwritten note.',
    'Tailoring':
        'Create 12 festive blouse sets in bright colours. Offer a simple custom-fitting option.',
    'Handmade crafts':
        'Make 25 reusable fabric gift bags. They pair beautifully with festival hampers.',
    'Teaching':
        'Offer a 4-session traditional craft workshop for children during the holiday period.',
  };

  void _getIdea() {
    setState(() {
      _recommendation = _ideas[_skill];
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sell More',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Simple ideas to grow your business.',
                      style: TextStyle(fontSize: 17),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(11),
                decoration: const BoxDecoration(
                  color: AppColors.mist,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.teal,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          const _SectionTitle('TRENDING NEAR YOU'),
          const SizedBox(height: 11),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(17),
              child: Column(
                children: const [
                  _TrendRow(
                    icon: Icons.cookie_rounded,
                    label: 'Millet Snacks',
                    percent: 42,
                    color: AppColors.saffron,
                  ),
                  Divider(height: 22),
                  _TrendRow(
                    icon: Icons.shopping_bag_rounded,
                    label: 'Handmade Bags',
                    percent: 35,
                    color: AppColors.teal,
                  ),
                  Divider(height: 22),
                  _TrendRow(
                    icon: Icons.card_giftcard_rounded,
                    label: 'Festival Hampers',
                    percent: 28,
                    color: AppColors.rose,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          const _SectionTitle('UPCOMING DEMAND'),
          const SizedBox(height: 11),

          Container(
            padding: const EdgeInsets.all(19),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFFFE2A8),
                  Color(0xFFFFF3DC),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.celebration_rounded,
                    size: 31,
                    color: AppColors.saffron,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Ganesh Chaturthi',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Traditional decorations',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 9),
                      _DemandBadge(),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          const _SectionTitle('AI SUGGESTION'),
          const SizedBox(height: 11),

          Container(
            padding: const EdgeInsets.all(19),
            decoration: BoxDecoration(
              color: AppColors.teal,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x25057B77),
                  blurRadius: 14,
                  offset: Offset(0, 7),
                ),
              ],
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Color(0xFFFFD694),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.teal,
                  ),
                ),
                SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Consider creating 20 traditional gift hampers this week.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          height: 1.35,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Festival demand is rising near you.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 26),

          Text(
            'What should I make?',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 5),

          const Text(
            'Choose a skill and let AI suggest an easy next idea.',
            style: TextStyle(fontSize: 16),
          ),

          const SizedBox(height: 14),

          Wrap(
            spacing: 8,
            runSpacing: 9,
            children: _ideas.keys.map((skill) {
              return ChoiceChip(
                label: Text(skill),
                selected: skill == _skill,
                onSelected: (_) {
                  setState(() {
                    _skill = skill;
                    _recommendation = null;
                  });
                },
                selectedColor: AppColors.teal,
                labelStyle: TextStyle(
                  color: skill == _skill
                      ? Colors.white
                      : AppColors.ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
                padding: const EdgeInsets.all(9),
                side: BorderSide.none,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 15),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _getIdea,
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text('Give me an idea'),
            ),
          ),

          if (_recommendation != null) ...[
            const SizedBox(height: 14),
            Semantics(
              liveRegion: true,
              child: _IdeaCard(
                skill: _skill,
                text: _recommendation!,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DemandBadge extends StatelessWidget {
  const _DemandBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.green,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'Expected demand +51%',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        letterSpacing: 1.1,
        fontWeight: FontWeight.w900,
        color: AppColors.teal,
      ),
    );
  }
}

class _TrendRow extends StatelessWidget {
  const _TrendRow({
    required this.icon,
    required this.label,
    required this.percent,
    required this.color,
  });

  final IconData icon;
  final String label;
  final int percent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: color.withValues(alpha: 0.13),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: percent / 50,
                  minHeight: 7,
                  color: color,
                  backgroundColor: Color(0xFFE5ECE7),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 13),
        Text(
          '↑ $percent%',
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: AppColors.green,
          ),
        ),
      ],
    );
  }
}

class _IdeaCard extends StatelessWidget {
  const _IdeaCard({
    required this.skill,
    required this.text,
  });

  final String skill;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF2D9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFFD694),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_rounded,
            color: AppColors.saffron,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Idea for $skill',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}