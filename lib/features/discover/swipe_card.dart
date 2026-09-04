import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../data/models/opportunity.dart';
import '../../shared/widgets/ai_explanation.dart';
import '../../shared/widgets/skill_chip.dart';

class SwipeCard extends StatefulWidget {
  const SwipeCard({
    super.key,
    required this.opportunity,
    required this.onDecision,
  });

  final Opportunity opportunity;
  final ValueChanged<bool> onDecision;

  @override
  State<SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<SwipeCard>
    with SingleTickerProviderStateMixin {
  Offset _drag = Offset.zero;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );

  Animation<Offset>? _exitAnimation;

  void _finishDrag(bool interested) {
    _exitAnimation = Tween<Offset>(
      begin: _drag,
      end: Offset(interested ? 820 : -820, _drag.dy),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward(from: 0).whenComplete(() {
      widget.onDecision(interested);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final drag = _exitAnimation?.value ?? _drag;
        final interested = drag.dx > 0;
        final showStamp = drag.dx.abs() > 30;

        return Transform.translate(
          offset: drag,
          child: Transform.rotate(
            angle: drag.dx * math.pi / 5000,
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  _drag += details.delta;
                });
              },
              onPanEnd: (_) {
                if (_drag.dx.abs() > 100) {
                  _finishDrag(_drag.dx > 0);
                } else {
                  setState(() {
                    _drag = Offset.zero;
                  });
                }
              },
              child: Stack(
                children: [
                  _OpportunityDetail(opportunity: widget.opportunity),
                  if (showStamp)
                    Positioned(
                      top: 46,
                      right: interested ? 20 : null,
                      left: interested ? null : 20,
                      child: Transform.rotate(
                        angle: interested ? .16 : -.16,
                        child: _DecisionStamp(interested: interested),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _OpportunityDetail extends StatelessWidget {
  const _OpportunityDetail({required this.opportunity});

  final Opportunity opportunity;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 185,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    opportunity.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const ColoredBox(
                        color: Color(0xFFE4DDD2),
                        child: Icon(Icons.image_rounded, size: 54),
                      );
                    },
                  ),
                  Positioned(
                    top: 13,
                    left: 13,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.rose,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        opportunity.demandLevel.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 13,
                    right: 13,
                    child: _AnimatedMatchScore(score: opportunity.matchScore),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    opportunity.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    opportunity.price,
                    style: const TextStyle(
                      color: AppColors.teal,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        color: AppColors.rose,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        opportunity.distance,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.groups_rounded, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '${opportunity.sellersRequired} sellers needed',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 25),
                  const Text(
                    'Required',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: opportunity.skills
                        .map((skill) => SkillChip(label: skill))
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => AIExplanation.show(context, opportunity),
                    icon: const Icon(Icons.auto_awesome_rounded),
                    label: const Text('Why this?'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(49),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedMatchScore extends StatelessWidget {
  const _AnimatedMatchScore({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: score.toDouble()),
      duration: const Duration(milliseconds: 950),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.green,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            '${value.round()}% AI MATCH',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        );
      },
    );
  }
}

class _DecisionStamp extends StatelessWidget {
  const _DecisionStamp({required this.interested});

  final bool interested;

  @override
  Widget build(BuildContext context) {
    final color = interested ? AppColors.green : AppColors.rose;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        interested ? 'INTERESTED' : 'SKIP',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 20,
        ),
      ),
    );
  }
}
