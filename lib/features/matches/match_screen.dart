import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../data/models/opportunity.dart';
import 'business_chat_screen.dart';
import 'business_details_screen.dart';
import 'mock_matching_repository.dart';

class MatchScreen extends StatefulWidget {
  const MatchScreen({
    super.key,
    required this.opportunity,
    required this.business,
  });

  final Opportunity opportunity;
  final BusinessProfile business;

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 850),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startBusiness() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => BusinessDetailsScreen(
          opportunity: widget.opportunity,
          business: widget.business,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.teal,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final animation = CurvedAnimation(
                parent: _controller,
                curve: Curves.elasticOut,
              );

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ScaleTransition(
                    scale: animation,
                    child: const Text(
                      '✨ IT’S A MATCH ✨',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFFFD694),
                        fontSize: 29,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),

                  const SizedBox(height: 29),

                  ScaleTransition(
                    scale: animation,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircleAvatar(
                          radius: 50,
                          backgroundColor: Color(0xFFFFD694),
                          child: Text(
                            'S',
                            style: TextStyle(
                              color: AppColors.ink,
                              fontSize: 38,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),

                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(
                            Icons.favorite_rounded,
                            color: AppColors.rose,
                            size: 42,
                          ),
                        ),

                        ClipRRect(
                          borderRadius: BorderRadius.circular(50),
                          child: Image.network(
                            widget.opportunity.imageUrl,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) {
                              return const ColoredBox(
                                color: Color(0xFFE4DDD2),
                                child: SizedBox(width: 100, height: 100),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _controller,
                      curve: const Interval(.25, 1),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'You and this opportunity are\na great fit.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                            height: 1.25,
                            fontWeight: FontWeight.w900,
                          ),
                        ),

                        const SizedBox(height: 17),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 19,
                            vertical: 11,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .15),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Text(
                            '${widget.opportunity.matchScore}% compatibility',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        Text(
                          '${widget.business.businessName} also wants to work with you.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _startBusiness,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.saffron,
                        foregroundColor: AppColors.ink,
                      ),
                      child: const Text('Start Business'),
                    ),
                  ),

                  const SizedBox(height: 9),

                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => BusinessChatScreen(
                            opportunity: widget.opportunity,
                            business: widget.business,
                          ),
                        ),
                      );
                    },
                    child: const Text(
                      'Send a quick hello',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
