import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/app_theme.dart';
import '../onboarding/onboarding_flow.dart';

class AadhaarVerificationScreen extends StatefulWidget {
  const AadhaarVerificationScreen({super.key});

  @override
  State<AadhaarVerificationScreen> createState() =>
      _AadhaarVerificationScreenState();
}

class _AadhaarVerificationScreenState
    extends State<AadhaarVerificationScreen> {
  final _aadhaarController = TextEditingController();

  bool _busy = false;
  bool _verified = false;
  String? _error;

  @override
  void dispose() {
    _aadhaarController.dispose();
    super.dispose();
  }

  Future<void> _verifyAadhaar() async {
    final aadhaar = _aadhaarController.text.trim();

    setState(() {
      _error = null;
    });

    if (aadhaar.length != 12) {
      setState(() {
        _error = 'Please enter a valid 12-digit Aadhaar number.';
      });
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      setState(() {
        _error = 'Your session has expired. Please sign in again.';
      });
      return;
    }

    setState(() {
      _busy = true;
    });

    try {
      /*
       * HACKATHON DEMO VERIFICATION
       *
       * In production, this step must be replaced with an authorized
       * Aadhaar/identity verification provider.
       *
       * We intentionally DO NOT store the complete Aadhaar number.
       */

      await Future<void>.delayed(
        const Duration(milliseconds: 1200),
      );

      final last4 = aadhaar.substring(aadhaar.length - 4);

      await Supabase.instance.client
          .from('profiles')
          .update({
        'aadhaar_verified': true,
        'aadhaar_last4': last4,
      }).eq('id', user.id);

      if (!mounted) return;

      setState(() {
        _verified = true;
      });

      await Future<void>.delayed(
        const Duration(milliseconds: 700),
      );

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => const OnboardingFlow(),
        ),
      );
    } on PostgrestException catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'Could not save verification: ${e.message}';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'Verification failed. Please try again.';
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 560,
              ),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 82,
                          height: 82,
                          decoration: const BoxDecoration(
                            color: AppColors.teal,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.verified_user_rounded,
                            color: Color(0xFFFFD694),
                            size: 45,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      Text(
                        'Verify your identity',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'A quick identity check helps keep SilverHands safe for sellers and buyers.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.4,
                        ),
                      ),

                      const SizedBox(height: 24),

                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.mist,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.lock_outline_rounded,
                              color: AppColors.teal,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'SilverHands stores only the last 4 digits after verification. Your complete Aadhaar number is not stored.',
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.4,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      TextField(
                        controller: _aadhaarController,
                        enabled: !_busy && !_verified,
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        maxLength: 12,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Aadhaar number',
                          hintText: 'Enter 12-digit number',
                          prefixIcon: Icon(
                            Icons.badge_outlined,
                          ),
                          counterText: '',
                        ),
                      ),

                      const SizedBox(height: 8),

                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.rose,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),

                      if (_verified)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.green,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Identity verified',
                                style: TextStyle(
                                  color: AppColors.green,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),

                      SizedBox(
                        height: 56,
                        child: FilledButton.icon(
                          onPressed:
                              _busy || _verified ? null : _verifyAadhaar,
                          icon: _busy
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.verified_rounded,
                                ),
                          label: Text(
                            _busy
                                ? 'Verifying...'
                                : 'Verify Aadhaar',
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      const Text(
                        'Demo verification for hackathon prototype',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}