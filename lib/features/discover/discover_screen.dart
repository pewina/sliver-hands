import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../core/app_config.dart';
import '../../core/demo_store.dart';
import '../../data/models/opportunity.dart';
import '../../data/repositories/opportunity_repository.dart';
import '../../shared/widgets/opportunity_filter.dart';
import '../matches/api_matching_repository.dart';
import '../matches/match_screen.dart';
import '../matches/mock_matching_repository.dart';
import 'opportunity_interaction_repository.dart';
import 'swipe_card.dart';
import 'swipe_decision_store.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  // ------------------------------------------------------------
  // REPOSITORIES / STORES
  // ------------------------------------------------------------

  final SwipeDecisionStore _store = SwipeDecisionStore();

  final OpportunityRepository _opportunityRepository =
      OpportunityRepository();

  final OpportunityInteractionRepository _interactionRepository =
      OpportunityInteractionRepository();

  late final ApiMatchingRepository _matchingRepository =
      ApiMatchingRepository();

  // ------------------------------------------------------------
  // STATE
  // ------------------------------------------------------------

  List<Opportunity> _opportunities = [];

  int _current = 0;

  String _filter = 'For you';

  String? _notice;
  String? _error;

  bool _loading = true;
  bool _savingDecision = false;

  // ------------------------------------------------------------
  // CURRENT OPPORTUNITY
  // ------------------------------------------------------------

  List<Opportunity> get _visibleOpportunities {
    switch (_filter) {
      case 'Products':
        return _opportunities
            .where((item) => item.category.toLowerCase().contains('food') ||
                item.category.toLowerCase().contains('product'))
            .toList();
      case 'Services':
        return _opportunities
            .where((item) => item.category.toLowerCase().contains('service'))
            .toList();
      case 'Bulk orders':
        return _opportunities.where((item) => item.sellersRequired > 1).toList();
      default:
        return _opportunities;
    }
  }

  Opportunity? get _opportunity {
    final visible = _visibleOpportunities;
    if (_current >= visible.length) return null;
    return visible[_current];
  }

  // ------------------------------------------------------------
  // INIT
  // ------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _loadOpportunities();
  }

  // ------------------------------------------------------------
  // LOAD OPPORTUNITIES
  // ------------------------------------------------------------

  Future<void> _loadOpportunities() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
        _notice = null;
      });
    }

    try {
      // Get all active opportunities from Supabase.
      final opportunities =
          await _opportunityRepository.getOpportunities();

      // Get opportunities this user has already seen.
      final seenIds =
          await _interactionRepository.getSeenOpportunityIds();

      // Only show opportunities that haven't been decided on yet.
      final unseenOpportunities =
          opportunities.where((opportunity) {
        final id = opportunity.id;

        // If an opportunity has no ID, keep it visible.
        if (id == null) {
          return true;
        }

        return !seenIds.contains(id);
      }).toList();

      if (!mounted) return;

      setState(() {
        _opportunities = unseenOpportunities;
        _current = 0;
        _loading = false;
      });
    } catch (error) {
      debugPrint(
        'Load opportunities error: $error',
      );

      if (!mounted) return;

      setState(() {
        _loading = false;
        _error =
            'Could not load opportunities. Please try again.';
      });
    }
  }

  // ------------------------------------------------------------
  // INTERESTED / SKIP
  // ------------------------------------------------------------

  Future<void> _decide(bool interested) async {
    // Prevent double taps while saving.
    if (_savingDecision) {
      return;
    }

    final opportunity = _opportunity;

    if (opportunity == null) {
      return;
    }

    final opportunityId = opportunity.id;

    if (opportunityId == null) {
      _showMessage(
        'This opportunity cannot be saved yet.',
      );
      return;
    }

    setState(() {
      _savingDecision = true;
      _notice = null;
    });

    try {
      // --------------------------------------------------------
      // 1. Save locally
      // --------------------------------------------------------

      _store.save(
        opportunity,
        interested,
      );

      // --------------------------------------------------------
      // 2. Save permanently to Supabase
      // --------------------------------------------------------

      await _interactionRepository.saveDecision(
        opportunityId: opportunityId,
        interested: interested,
      );

      if (!mounted) return;

      // --------------------------------------------------------
      // 3. Move to next opportunity
      // --------------------------------------------------------

      setState(() {
        _current++;

        _savingDecision = false;

        _notice = interested
            ? 'Interest saved for ${opportunity.seller}.'
            : 'Skipped. You can undo this choice.';
      });

      // --------------------------------------------------------
      // 4. If skipped, we're done.
      // --------------------------------------------------------

      if (!interested) {
        return;
      }

      // --------------------------------------------------------
      // 5. If interested, try matching.
      // --------------------------------------------------------

      try {
        final matches = AppConfig.hasSupabase
            ? await _matchingRepository.findMatches(opportunity)
            : <BusinessProfile>[
                BusinessProfile(
                  businessName: opportunity.seller,
                  contactName: 'Business representative',
                  description: opportunity.description,
                  orderRequirements: [
                    opportunity.subtitle,
                    opportunity.price,
                    'Confirm quantity and delivery date',
                    opportunity.sellersRequired > 1
                        ? 'AI collaboration available for this bulk order'
                        : 'Flexible home-based delivery',
                  ],
                  collaborationNote: opportunity.sellersRequired > 1
                      ? 'AI can find compatible SilverHands sellers and divide the order based on skills and capacity.'
                      : 'This opportunity can be completed independently.',
                ),
              ];

        if (!mounted || matches.isEmpty) {
          return;
        }

        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => MatchScreen(
              opportunity: opportunity,
              business: matches.first,
            ),
          ),
        );
      } catch (error) {
        debugPrint(
          'Matching error: $error',
        );

        if (!mounted) return;

        setState(() {
          _notice =
              'Interest saved. Matching service is unavailable.';
        });
      }
    } catch (error) {
      debugPrint(
        'Decision save error: $error',
      );

      if (!mounted) return;

      setState(() {
        _savingDecision = false;
      });

      _showMessage(
        'Could not save your choice. Please try again.',
      );
    }
  }

  // ------------------------------------------------------------
  // UNDO
  // ------------------------------------------------------------

  Future<void> _undo() async {
    if (_savingDecision) {
      return;
    }

    final last = _store.undo();

    if (last == null) {
      setState(() {
        _notice =
            'There is no previous choice to undo.';
      });
      return;
    }

    final opportunityId = last.opportunity.id;

    if (opportunityId == null) {
      setState(() {
        _notice =
            'Restored ${last.opportunity.title}.';
      });
      return;
    }

    try {
      // Remove the persisted decision so the opportunity
      // becomes available again after refresh.
      await _interactionRepository.deleteDecision(
        opportunityId: opportunityId,
      );

      if (!mounted) return;

      setState(() {
        _current =
            (_current - 1)
                .clamp(0, _opportunities.length)
                .toInt();

        _notice =
            'Restored ${last.opportunity.title}.';
      });
    } catch (error) {
      debugPrint(
        'Undo error: $error',
      );

      if (!mounted) return;

      setState(() {
        _current =
            (_current - 1)
                .clamp(0, _opportunities.length)
                .toInt();

        _notice =
            'Restored locally, but could not update the server.';
      });
    }
  }

  // ------------------------------------------------------------
  // MESSAGE
  // ------------------------------------------------------------

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          20,
          14,
          20,
          8,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // --------------------------------------------------
            // HEADER
            // --------------------------------------------------

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Discover work for you',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge,
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Swipe to choose opportunities',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                IconButton(
                  onPressed:
                      _savingDecision
                          ? null
                          : _undo,
                  tooltip:
                      'Undo last decision',
                  style: IconButton.styleFrom(
                    backgroundColor:
                        AppColors.mist,
                    minimumSize:
                        const Size(48, 48),
                  ),
                  icon: const Icon(
                    Icons.undo_rounded,
                    color: AppColors.teal,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 13),

            // --------------------------------------------------
            // FILTER
            // --------------------------------------------------

            OpportunityFilter(
              selected: _filter,
              onChanged: (value) {
                setState(() {
                  _filter = value;
                  _current = 0;
                  _notice = 'Showing $_filter opportunities';
                });
              },
            ),

            const SizedBox(height: 11),

            // --------------------------------------------------
            // MAIN CONTENT
            // --------------------------------------------------

            Expanded(
              child: _buildContent(),
            ),

            // --------------------------------------------------
            // NOTICE
            // --------------------------------------------------

            if (_notice != null)
              Padding(
                padding:
                    const EdgeInsets.only(top: 8),
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    _notice!,
                    textAlign:
                        TextAlign.center,
                    style: const TextStyle(
                      fontWeight:
                          FontWeight.w700,
                      color:
                          AppColors.green,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 9),

            // --------------------------------------------------
            // ACTION BUTTONS
            // --------------------------------------------------

            if (!_loading &&
                _error == null &&
                _opportunity != null)
              Row(
                mainAxisAlignment:
                    MainAxisAlignment
                        .spaceEvenly,
                children: [
                  _ActionButton(
                    icon:
                        Icons.close_rounded,
                    label: 'Skip',
                    color:
                        AppColors.rose,
                    onTap:
                        _savingDecision
                            ? null
                            : () =>
                                _decide(false),
                  ),

                  _ActionButton(
                    icon: Icons
                        .favorite_rounded,
                    label: 'Interested',
                    color:
                        AppColors.green,
                    onTap:
                        _savingDecision
                            ? null
                            : () =>
                                _decide(true),
                  ),
                ],
              ),

            const SizedBox(height: 7),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // CONTENT
  // ------------------------------------------------------------

  Widget _buildContent() {
    // ----------------------------------------------------------
    // LOADING
    // ----------------------------------------------------------

    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // ----------------------------------------------------------
    // ERROR
    // ----------------------------------------------------------

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 54,
              color: AppColors.teal,
            ),

            const SizedBox(height: 14),

            Text(
              _error!,
              textAlign:
                  TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight:
                    FontWeight.w700,
              ),
            ),

            const SizedBox(height: 18),

            FilledButton.icon(
              onPressed:
                  _loadOpportunities,
              icon: const Icon(
                Icons.refresh_rounded,
              ),
              label:
                  const Text('Try again'),
            ),
          ],
        ),
      );
    }

    // ----------------------------------------------------------
    // NO MORE OPPORTUNITIES
    // ----------------------------------------------------------

    final opportunity = _opportunity;

    if (opportunity == null) {
      return Center(
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Icon(
              Icons
                  .check_circle_outline_rounded,
              size: 64,
              color: AppColors.green,
            ),

            const SizedBox(height: 16),

            const Text(
              'You have seen all opportunities!',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.w800,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Check back later for new livelihood opportunities.',
              textAlign:
                  TextAlign.center,
            ),

            const SizedBox(height: 18),

            OutlinedButton.icon(
              onPressed:
                  _loadOpportunities,
              icon: const Icon(
                Icons.refresh_rounded,
              ),
              label:
                  const Text('Refresh'),
            ),
            const SizedBox(height: 10),
            if (!AppConfig.hasSupabase)
              TextButton.icon(
                onPressed: () async {
                  DemoStore.instance.resetDemo();
                  await _loadOpportunities();
                },
                icon: const Icon(Icons.restart_alt_rounded),
                label: const Text('Reset demo journey'),
              ),
          ],
        ),
      );
    }

    // ----------------------------------------------------------
    // SWIPE CARD
    // ----------------------------------------------------------

    return AnimatedSwitcher(
      duration:
          const Duration(milliseconds: 280),
      transitionBuilder:
          (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(
              begin: .96,
              end: 1,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: Stack(
        key: ValueKey(_current),
        children: [
          SwipeCard(
            opportunity: opportunity,
            onDecision:
                _savingDecision
                    ? (_) {}
                    : _decide,
          ),

          // Small loading overlay while saving.
          if (_savingDecision)
            Positioned.fill(
              child: Container(
                decoration:
                    BoxDecoration(
                  color: Colors.black
                      .withValues(
                    alpha: 0.08,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    24,
                  ),
                ),
                child: const Center(
                  child:
                      CircularProgressIndicator(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================
// ACTION BUTTON
// ============================================================

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: FilledButton.icon(
        onPressed: onTap,
        icon: Icon(
          icon,
          size: 27,
        ),
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: color,
          minimumSize:
              const Size(150, 58),
        ),
      ),
    );
  }
}