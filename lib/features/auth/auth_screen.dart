import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/app_theme.dart';
import '../../core/app_config.dart';
import '../onboarding/onboarding_flow.dart';
import '../guide/guide_link_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _signUp = false;
  bool _familyGuide = false;
  bool _busy = false;
  String? _error;

  Future<void> _submit() async {
    if (!AppConfig.hasSupabase) {
      setState(() {
        _busy = true;
        _error = null;
      });
      await Future<void>.delayed(const Duration(milliseconds: 650));
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const OnboardingFlow()),
      );
      return;
    }

    final email = _email.text.trim();
    final password = _password.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _error = 'Please enter your email and password.';
      });
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final auth = Supabase.instance.client.auth;

      if (_signUp) {
        final response = await auth.signUp(
          email: email,
          password: password,
          data: {'role': _familyGuide ? 'guide' : 'member'},
        );

        if (!mounted) return;

        if (response.user == null) {
          setState(() {
            _error = 'Account could not be created. Please try again.';
          });
          return;
        }

        // If email confirmation is enabled, Supabase may create
        // the user without creating an active session.
        if (response.session == null) {
          setState(() {
            _error =
                'Account created, but email confirmation is required. '
                'Disable email confirmation in Supabase for the hackathon demo.';
          });
          return;
        }

        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => _familyGuide
                ? const GuideLinkScreen()
                : const OnboardingFlow(),
          ),
        );
      } else {
        final response = await auth.signInWithPassword(
          email: email,
          password: password,
        );

        if (!mounted) return;

        if (response.session == null) {
          setState(() {
            _error = 'Sign in failed. Please try again.';
          });
          return;
        }

        final role = response.user?.userMetadata?['role']?.toString();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => role == 'guide'
                ? const GuideLinkScreen()
                : const OnboardingFlow(),
          ),
        );
      }
    } on AuthException catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.message;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'Something went wrong. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 38,
                      backgroundColor: AppColors.teal,
                      child: Icon(
                        Icons.volunteer_activism_rounded,
                        color: Color(0xFFFFD694),
                        size: 42,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'SilverHands',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppConfig.hasSupabase
                          ? (_signUp ? 'Create your account' : 'Welcome back')
                          : 'Working prototype • Demo mode',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 20),
                    if (_signUp) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'I am joining as',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment<bool>(
                            value: false,
                            label: Text('SilverHands member'),
                            icon: Icon(Icons.person_rounded),
                          ),
                          ButtonSegment<bool>(
                            value: true,
                            label: Text('Family guide'),
                            icon: Icon(Icons.family_restroom_rounded),
                          ),
                        ],
                        selected: {_familyGuide},
                        onSelectionChanged: (value) => setState(() => _familyGuide = value.first),
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _password,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: const TextStyle(color: AppColors.rose),
                      ),
                    ],
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _busy ? null : _submit,
                        child: Text(
                          _busy
                              ? 'Please wait...'
                              : (_signUp ? 'Create an account' : 'Sign in'),
                        ),
                      ),
                    ),
                    if (!AppConfig.hasSupabase)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _busy
                                ? null
                                : () => _submit(),
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: const Text('Continue with Demo Account'),
                          ),
                        ),
                      ),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () {
                              setState(() {
                                _signUp = !_signUp;
                                _error = null;
                              });
                            },
                      child: Text(
                        _signUp
                            ? 'Already have an account? Sign in'
                            : 'New to SilverHands? Create an account',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}