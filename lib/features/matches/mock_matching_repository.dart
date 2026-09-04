import '../../data/models/opportunity.dart';

class BusinessProfile {
  const BusinessProfile({
    required this.businessName,
    required this.contactName,
    required this.description,
    required this.orderRequirements,
    required this.collaborationNote,
  });
  final String businessName;
  final String contactName;
  final String description;
  final List<String> orderRequirements;
  final String collaborationNote;
}

abstract class MatchingRepository {
  Future<BusinessProfile?> checkForMutualMatch(Opportunity opportunity);
}

class MockMatchingRepository implements MatchingRepository {
  const MockMatchingRepository();
  @override
  Future<BusinessProfile?> checkForMutualMatch(Opportunity opportunity) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (opportunity.matchScore < 90) return null;
    return const BusinessProfile(
      businessName: 'Anand Celebrations',
      contactName: 'Radhika Anand',
      description: 'A Chennai-based festive gifting studio creating thoughtful local gift boxes for families and companies.',
      orderRequirements: [
        '120 festival hampers',
        'Ready by 28 October',
        'Vegetarian savouries preferred',
        'Packaging material will be provided',
      ],
      collaborationNote: 'Three other SilverHands sellers are joining this order. You can share work and fulfil it together.',
    );
  }
}
