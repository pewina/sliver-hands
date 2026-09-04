import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_config.dart';
import '../../core/demo_store.dart';

class OpportunityInteractionRepository {
  OpportunityInteractionRepository({
    SupabaseClient? client,
  }) : _client = client ?? (AppConfig.hasSupabase ? Supabase.instance.client : null);

  final SupabaseClient? _client;

  Future<void> saveDecision({
    required String opportunityId,
    required bool interested,
  }) async {
    if (!AppConfig.hasSupabase) {
      DemoStore.instance.decide(opportunityId, interested);
      return;
    }

    final user = _client!.auth.currentUser;

    if (user == null) {
      throw Exception('User is not signed in.');
    }

    await _client
        .from('matches')
        .upsert(
          {
            'user_id': user.id,
            'opportunity_id': opportunityId,
            'interested': interested,
          },
          onConflict: 'user_id,opportunity_id',
        );
  }

  Future<List<String>> getInterestedOpportunityIds() async {
    if (!AppConfig.hasSupabase) {
      return DemoStore.instance.interestedOpportunityIds.toList();
    }

    final user = _client!.auth.currentUser;

    if (user == null) {
      return [];
    }

    final rows = await _client
        .from('matches')
        .select('opportunity_id')
        .eq('user_id', user.id)
        .eq('interested', true);

    return (rows as List)
        .whereType<Map<String, dynamic>>()
        .map(
          (row) => row['opportunity_id'].toString(),
        )
        .toList();
  }
  
  Future<void> deleteDecision({
    required String opportunityId,
  }) async {
    if (!AppConfig.hasSupabase) {
      DemoStore.instance.undo(opportunityId);
      return;
    }

    final user = _client!.auth.currentUser;

    if (user == null) {
      throw Exception('User is not signed in.');
    }

    await _client
        .from('matches')
        .delete()
        .eq('user_id', user.id)
        .eq('opportunity_id', opportunityId);
  }

  Future<List<String>> getSeenOpportunityIds() async {
    if (!AppConfig.hasSupabase) {
      return DemoStore.instance.seenOpportunityIds.toList();
    }

    final user = _client!.auth.currentUser;

    if (user == null) {
      return [];
    }

    final rows = await _client
        .from('matches')
        .select('opportunity_id')
        .eq('user_id', user.id);

    return (rows as List)
        .whereType<Map<String, dynamic>>()
        .map((row) => row['opportunity_id'].toString())
        .toList();
  }
}
