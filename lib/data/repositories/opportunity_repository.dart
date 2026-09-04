import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../../core/backend_client.dart';
import '../../core/demo_store.dart';
import '../../core/app_config.dart';
import '../models/opportunity.dart';

class OpportunityRepository {
  OpportunityRepository({
    SupabaseClient? client,
    BackendClient? backendClient,
  })  : _client = client ?? (AppConfig.hasSupabase ? Supabase.instance.client : null),
        _backendClient = backendClient ?? BackendClient.instance;

  final SupabaseClient? _client;
  final BackendClient _backendClient;

  Future<List<Opportunity>> getOpportunities() async {
    // Fully interactive local demo when Supabase credentials are absent.
    if (!AppConfig.hasSupabase) {
      // Demo mode uses the exact same recommendation contract as production:
      // the current voice-derived profile is scored against opportunities.
      await Future<void>.delayed(const Duration(milliseconds: 450));
      return DemoStore.instance.recommendedOpportunities;
    }

    debugPrint('🔥 getOpportunities() START');
    final rows = await _client!
        .from('opportunities')
        .select()
        .eq('is_active', true)
        .order('created_at', ascending: false);

    final opportunities = (rows as List)
        .whereType<Map<String, dynamic>>()
        .map(_fromRow)
        .toList();

    debugPrint(
    '🔥 getOpportunities() loaded ${opportunities.length} opportunities',
  );


    return _applyAiRecommendations(opportunities);
  }

  Future<List<Opportunity>> _applyAiRecommendations(
    List<Opportunity> opportunities,
  ) async {
    debugPrint(
  '🔥 _applyAiRecommendations() START: ${opportunities.length} opportunities',
);
    if (opportunities.isEmpty) {
      return opportunities;
    }

    final user = _client!.auth.currentUser;

    // If there is no logged-in user, keep the normal opportunity list.
    if (user == null) {
      return opportunities;
    }

    try {
      final profileRows = await _client!
          .from('profiles')
          .select()
          .eq('id', user.id)
          .limit(1);

      final profile = profileRows.isNotEmpty
    ? Map<String, dynamic>.from(profileRows.first)
    : <String, dynamic>{};

      final skills = profile['skills'] is List
          ? (profile['skills'] as List)
              .map((value) => value.toString())
              .where((value) => value.trim().isNotEmpty)
              .toList()
          : <String>[];

      final location = profile['location']?.toString().trim().isNotEmpty == true
          ? profile['location'].toString()
          : 'India';

      final latitude = (profile['latitude'] as num?)?.toDouble();
      final longitude = (profile['longitude'] as num?)?.toDouble();

      debugPrint(
  '🔥 Calling POST /api/recommendations for user ${user.id}',
);

      final response = await _backendClient.postJson(
        '/recommendations',
        {
          'user_id': user.id,
          'skills': skills,
          'location': location,
          'latitude': latitude,
          'longitude': longitude,
        },
      );

      final recommendations = response['recommendations'];

      if (recommendations is! List) {
        return opportunities;
      }

      final recommendationMap = <String, Map<String, dynamic>>{};

      for (final item in recommendations) {
        if (item is Map<String, dynamic>) {
          final id = item['opportunity_id']?.toString();

          if (id != null && id.isNotEmpty) {
            recommendationMap[id] = item;
          }
        }
      }

      final updated = opportunities.map((opportunity) {
        final id = opportunity.id;

        if (id == null || !recommendationMap.containsKey(id)) {
          return opportunity;
        }

        final recommendation = recommendationMap[id]!;

        final score =
            (recommendation['match_percentage'] as num?)?.toInt() ??
                opportunity.matchScore;

        final explanation =
            recommendation['explanation']?.toString().trim() ?? '';

        final reasons = explanation.isNotEmpty
            ? <String>[explanation]
            : opportunity.recommendationReasons;

        return Opportunity(
          id: opportunity.id,
          title: opportunity.title,
          subtitle: opportunity.subtitle,
          location: opportunity.location,
          price: opportunity.price,
          seller: opportunity.seller,
          category: opportunity.category,
          imageUrl: opportunity.imageUrl,
          skills: opportunity.skills,
          matchScore: score,
          verified: opportunity.verified,
          description: opportunity.description,
          distance: opportunity.distance,
          demandLevel: opportunity.demandLevel,
          sellersRequired: opportunity.sellersRequired,
          recommendationReasons: reasons,
          aiScore: _buildAiScore(score),
        );
      }).toList();

      // Put the AI-recommended opportunities first.
      updated.sort((a, b) {
        final aRecommended = recommendationMap.containsKey(a.id);
        final bRecommended = recommendationMap.containsKey(b.id);

        if (aRecommended && !bRecommended) return -1;
        if (!aRecommended && bRecommended) return 1;

        return b.matchScore.compareTo(a.matchScore);
      });

      return updated;
        } catch (error, stackTrace) {
      debugPrint('AI recommendation error: $error');
      debugPrint('AI recommendation stack trace: $stackTrace');

      // AI recommendations should never prevent opportunities
      // from loading. Fall back to the existing Supabase data.
      return opportunities;
    }
  }

  Opportunity _fromRow(Map<String, dynamic> row) {
    final skills = row['skills'] is List
        ? (row['skills'] as List)
            .map((value) => value.toString())
            .toList()
        : <String>[];

    final demandScore =
        (row['demand_score'] as num?)?.toInt() ?? 10;

    final seasonalScore =
        (row['seasonal_score'] as num?)?.toInt() ?? 10;

    final fallbackMatchScore =
        ((demandScore + seasonalScore) * 3.3)
            .round()
            .clamp(0, 100);

    return Opportunity(
      id: row['id']?.toString(),
      title: row['title']?.toString() ?? 'Opportunity',
      subtitle: row['subtitle']?.toString() ?? '',
      location: _location(row),
      price: row['price']?.toString() ?? '',
      seller: row['business_name']?.toString() ?? 'Business',
      category: row['category']?.toString() ?? 'Service',
      imageUrl: row['image_url']?.toString() ?? '',
      skills: skills,
      matchScore: fallbackMatchScore,
      verified: row['verified'] == true,
      description: row['description']?.toString() ?? '',
      distance: 'Nearby',
      demandLevel: _demandLevel(demandScore),
      sellersRequired:
          (row['sellers_required'] as num?)?.toInt() ?? 1,
      recommendationReasons: _recommendationReasons(
        skills: skills,
        demandScore: demandScore,
        seasonalScore: seasonalScore,
      ),
      aiScore: RecommendationScore(
        skillCompatibility: skills.isEmpty ? 10 : 35,
        localDemand: demandScore.clamp(0, 25),
        seasonalDemand: seasonalScore.clamp(0, 25),
        distance: 8,
        experience: 7,
      ),
    );
  }

  RecommendationScore _buildAiScore(int totalScore) {
    final normalized = totalScore.clamp(0, 100);

    return RecommendationScore(
      skillCompatibility: (normalized * 0.50).round(),
      localDemand: (normalized * 0.15).round(),
      seasonalDemand: (normalized * 0.10).round(),
      distance: (normalized * 0.15).round(),
      experience: (normalized * 0.10).round(),
    );
  }

  String _location(Map<String, dynamic> row) {
    final latitude = row['latitude'];
    final longitude = row['longitude'];

    if (latitude != null && longitude != null) {
      return 'Nearby';
    }

    return 'India';
  }

  String _demandLevel(int score) {
    if (score >= 14) {
      return 'High demand';
    }

    if (score >= 9) {
      return 'Growing demand';
    }

    return 'Emerging demand';
  }

  List<String> _recommendationReasons({
    required List<String> skills,
    required int demandScore,
    required int seasonalScore,
  }) {
    final reasons = <String>[];

    if (skills.isNotEmpty) {
      reasons.add('Matches your skills');
    }

    if (demandScore >= 14) {
      reasons.add('High local demand');
    }

    if (seasonalScore >= 10) {
      reasons.add('Good seasonal opportunity');
    }

    if (reasons.isEmpty) {
      reasons.add('Recommended for SilverHands sellers');
    }

    return reasons;
  }
}