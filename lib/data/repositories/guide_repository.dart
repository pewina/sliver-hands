import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_config.dart';

class GuideRepository {
  GuideRepository({SupabaseClient? client})
      : _client = client ??
            (AppConfig.hasSupabase ? Supabase.instance.client : null);

  final SupabaseClient? _client;

  bool get enabled => AppConfig.hasSupabase && _client != null;

  Future<Map<String, dynamic>?> activeLink() async {
    if (!enabled) return null;
    final user = _client!.auth.currentUser;
    if (user == null) return null;
    final rows = await _client.from('guide_links').select().eq('guide_id', user.id).eq('status', 'active').limit(1);
    return rows.isEmpty ? null : Map<String, dynamic>.from(rows.first);
  }

  Future<Map<String, dynamic>?> linkedProfile() async {
    final link = await activeLink();
    if (link == null) return null;
    final rows = await _client!.from('profiles').select().eq('id', link['owner_id']).limit(1);
    return rows.isEmpty ? null : Map<String, dynamic>.from(rows.first);
  }

  Future<List<Map<String, dynamic>>> linkedOpportunities() async {
    final link = await activeLink();
    if (link == null) return [];
    final rows = await _client!.from('opportunities').select().eq('owner_id', link['owner_id']).order('created_at', ascending: false);
    return rows.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<List<Map<String, dynamic>>> linkedMatches() async {
    final link = await activeLink();
    if (link == null) return [];
    final rows = await _client!.from('matches').select('*, opportunities(title, business_name, price, description, category)').eq('user_id', link['owner_id']).order('created_at', ascending: false);
    return rows.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<List<Map<String, dynamic>>> guideRequests({
  bool pendingOnly = false,
}) async {
  if (!enabled) return [];

  final user = _client!.auth.currentUser;
  if (user == null) return [];

  final rows = pendingOnly
      ? await _client!
          .from('guide_help_requests')
          .select()
          .eq('guide_id', user.id)
          .eq('status', 'pending')
          .order('created_at', ascending: false)
          .limit(50)
      : await _client!
          .from('guide_help_requests')
          .select()
          .eq('guide_id', user.id)
          .order('created_at', ascending: false)
          .limit(50);

  return rows
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
}

  Future<List<Map<String, dynamic>>> memberRequests() async {
    if (!enabled) return [];
    final user = _client!.auth.currentUser;
    if (user == null) return [];
    final rows = await _client.from('guide_help_requests').select().eq('owner_id', user.id).eq('status', 'pending').order('created_at', ascending: false).limit(20);
    return rows.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<Map<String, dynamic>> createHelpRequest({
    required String type,
    required String title,
    required String message,
    Map<String, dynamic>? payload,
  }) async {
    if (!enabled) throw StateError('Supabase is not configured.');
    final result = await _client!.rpc('create_guide_help_request', params: {
      'p_request_type': type,
      'p_title': title,
      'p_message': message,
      'p_payload': payload ?? <String, dynamic>{},
    });
    if (result is List && result.isNotEmpty) return Map<String, dynamic>.from(result.first as Map);
    return Map<String, dynamic>.from(result as Map);
  }

  Future<Map<String, dynamic>> respondToRequest({required String requestId, required String status}) async {
    final result = await _client!.rpc('respond_to_guide_help_request', params: {'p_request_id': requestId, 'p_status': status});
    if (result is List && result.isNotEmpty) return Map<String, dynamic>.from(result.first as Map);
    return Map<String, dynamic>.from(result as Map);
  }

  Future<void> cancelRequest(String requestId) async {
    await _client!.rpc('cancel_guide_help_request', params: {'p_request_id': requestId});
  }

  Future<Map<String, dynamic>> acceptCode({required String code, required String name, required String relationship}) async {
    if (!enabled) throw StateError('Supabase is not configured.');
    final result = await _client!.rpc('accept_guide_code', params: {'p_code': code.trim(), 'p_guide_name': name.trim(), 'p_relationship': relationship.trim()});
    if (result is List && result.isNotEmpty) return Map<String, dynamic>.from(result.first as Map);
    return Map<String, dynamic>.from(result as Map);
  }

  Future<Map<String, dynamic>?> ownerActiveLink() async {
    if (!enabled) return null;
    final user = _client!.auth.currentUser;
    if (user == null) return null;
    final rows = await _client.from('guide_links').select().eq('owner_id', user.id).eq('status', 'active').limit(1);
    return rows.isEmpty ? null : Map<String, dynamic>.from(rows.first);
  }

  Future<String> createInvite({required String relationship}) async {
    if (!enabled) throw StateError('Supabase is not configured.');
    final user = _client!.auth.currentUser;
    if (user == null) throw StateError('Please sign in first.');
    final cleanRelationship = relationship.trim().isEmpty ? 'Family member' : relationship.trim();
    try {
      final result = await _client.rpc('create_guide_code', params: {'p_relationship': cleanRelationship});
      final code = _extractCode(result);
      if (code != null) return code;
    } on PostgrestException catch (e) {
      debugPrint('create_guide_code RPC unavailable: ${e.message}');
    }
    await _client.from('guide_links').update({'status': 'expired', 'updated_at': DateTime.now().toUtc().toIso8601String()}).eq('owner_id', user.id).eq('status', 'pending');
    for (var attempt = 0; attempt < 5; attempt++) {
      final code = _randomSixDigitCode();
      try {
        await _client.from('guide_links').insert({'owner_id': user.id, 'relationship': cleanRelationship, 'invite_code': code, 'status': 'pending', 'expires_at': DateTime.now().toUtc().add(const Duration(minutes: 30)).toIso8601String()});
        return code;
      } on PostgrestException catch (e) {
        if (!e.message.toLowerCase().contains('duplicate') && !e.message.toLowerCase().contains('unique')) {
          throw StateError('Could not create the family guide code: ${e.message}');
        }
      }
    }
    throw StateError('Could not create a unique family guide code. Please try again.');
  }

  String? _extractCode(dynamic result) {
    if (result is String && result.trim().isNotEmpty) return result.trim();
    if (result is List && result.isNotEmpty) {
      final value = result.first;
      if (value is String && value.trim().isNotEmpty) return value.trim();
      if (value is Map && value['create_guide_code'] != null) return value['create_guide_code'].toString().trim();
    }
    if (result is Map && result['create_guide_code'] != null) return result['create_guide_code'].toString().trim();
    return null;
  }

  String _randomSixDigitCode() => (100000 + Random().nextInt(900000)).toString();

  Future<void> revokeLink(String linkId) async {
    if (!enabled) return;
    await _client!.rpc('revoke_guide_link', params: {'p_link_id': linkId});
  }

  Future<void> disconnectGuide() async {
    final link = await activeLink();
    if (link == null) return;
    await revokeLink(link['id'].toString());
  }

  Future<void> logActivity({required String ownerId, required String action, String? details}) async {
    if (!enabled) return;
    final user = _client!.auth.currentUser;
    if (user == null) return;
    await _client.from('guide_activity').insert({'owner_id': ownerId, 'guide_id': user.id, 'action': action, 'details': details});
  }
}
