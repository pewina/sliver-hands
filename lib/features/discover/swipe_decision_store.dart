import '../../data/models/opportunity.dart';

class SwipeDecision {
  const SwipeDecision({required this.opportunity, required this.interested});
  final Opportunity opportunity;
  final bool interested;
}

/// Local-only store for the demo. Replace with a persisted repository later.
class SwipeDecisionStore {
  final List<SwipeDecision> _decisions = [];
  List<SwipeDecision> get decisions => List.unmodifiable(_decisions);
  void save(Opportunity opportunity, bool interested) => _decisions.add(
    SwipeDecision(opportunity: opportunity, interested: interested),
  );
  SwipeDecision? undo() => _decisions.isEmpty ? null : _decisions.removeLast();
}
