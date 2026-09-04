import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_config.dart';
import '../../core/demo_store.dart';

class ProfileRepository {
  ProfileRepository({SupabaseClient? client})
      : _client = client ??
            (AppConfig.hasSupabase ? Supabase.instance.client : null);

  final SupabaseClient? _client;

  Future<void> saveCurrentProfile() async {
    final profile = DemoStore.instance.profile;
    final user = _client?.auth.currentUser;

    if (!AppConfig.hasSupabase || user == null) {
      return;
    }

    final skills = DemoStore.instance.skills;
    final years = DemoStore.instance.experienceYears;
    final location = profile['location']?.toString() ?? 'Chennai, Tamil Nadu';
    final language = profile['language']?.toString() ?? 'English';

    // Write the core schema first. These columns are present in the base
    // SilverHands migration, so profile creation still works even if the
    // optional live-prototype migration has not been run yet.
    await _client!.from('profiles').upsert({
      'id': user.id,
      'display_name': profile['display_name']?.toString() ?? 'SilverHands Member',
      'user_type': profile['user_type']?.toString() ?? 'Senior citizen',
      'language': language,
      'location': location,
      'skills': skills,
      'experience_years': years,
      'verified': profile['verified'] == true,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });

    // Age is stored by the newer profile migration. Keep it best-effort so
    // an older demo database can still complete onboarding.
    try {
      await _client.from('profiles').update({
        'age': profile['age'],
      }).eq('id', user.id);
    } catch (e) {
      print('Age field unavailable; profile basics already saved: $e');
    }

    // Optional AI/profile fields are best-effort. This prevents an older
    // Supabase schema from blocking the onboarding flow.
    try {
      await _client.from('profiles').update({
        'headline': profile['headline']?.toString(),
        'bio': profile['bio']?.toString(),
        'transcript': profile['transcript']?.toString(),
      }).eq('id', user.id);
    } catch (e) {
      // 002_live_prototype.sql adds these columns. Core profile data is
      // already safely stored, so continue for the hackathon demo.
      // ignore: avoid_print
      print('Optional profile fields unavailable: $e');
    }

    // Keep the user represented in the seller pool so collaboration can
    // use the same real profile and skill set as recommendations.
    try {
      await _client.from('seller_profiles').upsert({
        'id': user.id,
        'display_name': profile['display_name']?.toString() ?? 'SilverHands Member',
        'skills': skills,
        'location': location,
        'capacity_units': 30,
        'reliability_score': 100,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      // Collaboration can still use the verified partner directory.
      // ignore: avoid_print
      print('Seller profile save deferred: $e');
    }
  }

  Future<bool> hasCurrentProfile() async {
    final user = _client?.auth.currentUser;
    if (!AppConfig.hasSupabase || user == null) return false;
    final rows = await _client!.from('profiles').select('id').eq('id', user.id).limit(1);
    return rows.isNotEmpty;
  }

  Future<void> loadCurrentProfile() async {
    final user = _client?.auth.currentUser;
    if (!AppConfig.hasSupabase || user == null) return;

    final rows = await _client!
        .from('profiles')
        .select()
        .eq('id', user.id)
        .limit(1);

    if (rows.isEmpty) return;

    final row = Map<String, dynamic>.from(rows.first);
    DemoStore.instance.profile = {
      ...DemoStore.instance.profile,
      ...row,
      'full_name': row['display_name'] ?? DemoStore.instance.profile['full_name'],
      'experience': '${row['experience_years'] ?? 0} years',
    };
  }
}
