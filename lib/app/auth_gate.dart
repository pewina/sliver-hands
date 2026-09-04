import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/app_config.dart';
import '../features/auth/auth_screen.dart';
import '../features/onboarding/onboarding_flow.dart';
import '../features/home/home_shell.dart';
import '../data/repositories/profile_repository.dart';
import '../features/guide/guide_link_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<bool> _loadProfileAndCheck() async {
    final repository = ProfileRepository();
    final exists = await repository.hasCurrentProfile();
    if (exists) {
      await repository.loadCurrentProfile();
    }
    return exists;
  }

  @override
  Widget build(BuildContext context) {
    if (!AppConfig.hasSupabase) {
      return const AuthScreen();
    }

    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = Supabase.instance.client.auth.currentSession;
        if (session == null) return const AuthScreen();

        final role = session.user.userMetadata?['role']?.toString();
        if (role == 'guide') {
          return const GuideLinkScreen();
        }

        return FutureBuilder<bool>(
          future: _loadProfileAndCheck(),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState != ConnectionState.done) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (profileSnapshot.data == true) {
              return const HomeShell();
            }
            return const OnboardingFlow();
          },
        );
      },
    );
  }
}
