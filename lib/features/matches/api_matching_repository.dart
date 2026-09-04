import '../../core/backend_client.dart';
import '../../data/models/opportunity.dart';
import 'mock_matching_repository.dart';

class ApiMatchingRepository {
  ApiMatchingRepository({BackendClient? client})
    : client = client ?? BackendClient.instance;

  final BackendClient client;

  Future<List<BusinessProfile>> findMatches(Opportunity opportunity) async {
    final response = await client.postJson('/matching', {
      'opportunity_id': opportunity.id,
      'skills': opportunity.skills,
      'location': opportunity.location,
      'match_score': opportunity.matchScore,
    });

    final matches = response['matches'];

    if (matches is! List) {
      return [];
    }

    return matches
        .whereType<Map<String, dynamic>>()
        .map(
          (item) => BusinessProfile(
            businessName: item['business_name']?.toString() ?? 'Business',
            contactName:
                item['contact_name']?.toString() ?? 'Business representative',
            description: item['description']?.toString() ?? '',
            orderRequirements: item['order_requirements'] is List
                ? (item['order_requirements'] as List)
                      .map((value) => value.toString())
                      .toList()
                : <String>[],
            collaborationNote:
                item['collaboration_note']?.toString() ??
                'You can collaborate with other SilverHands sellers.',
          ),
        )
        .toList();
  }
}
