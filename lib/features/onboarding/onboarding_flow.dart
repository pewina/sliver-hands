import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../core/app_config.dart';
import '../../core/demo_store.dart';
import '../../core/backend_client.dart';
import '../../shared/widgets/skill_chip.dart';
import '../profile/aadhaar_verification_screen.dart';
import '../home/home_shell.dart';
import 'onboarding_repository.dart';
import '../../data/repositories/profile_repository.dart';
import '../guide/guide_link_screen.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({
    super.key,
    this.repository,
  });

  final OnboardingRepository? repository;

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  late final OnboardingRepository _repository =
      widget.repository ?? HybridOnboardingRepository();
  final ProfileRepository _profileRepository = ProfileRepository();
  int _step = 0;
  bool _processing = false;

  String _name = '';
  String _age = '';
  String _language = 'English';
  String _userType = 'Senior citizen';
  String _location = 'Chennai, Tamil Nadu';
  String _familyMember = '';

  String? _error;
  DetectedProfile? _profile;

  final List<String> _skills = [];

  void _next() {
    // A Family Guide is a separate role. Never send a guide through the
    // member-only voice/skills/profile onboarding flow.
    if (_step == 3 && _userType == 'Trusted family guide') {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const GuideLinkScreen()),
        (_) => false,
      );
      return;
    }

    setState(() {
      _error = null;
      _step++;
    });
  }

  void _back() {
    setState(() {
      _error = null;
      _step--;
    });
  }

  Future<void> _analyseVoice() async {
  setState(() {
    _processing = true;
    _error = null;
  });

  try {
    debugPrint('Sending voice language: $_language');

    // Demo mode still uses the REAL backend voice pipeline when it is
    // running. The mock repository is only the last-resort fallback.
    DetectedProfile profile;
    try {
      profile = await _repository.analyseIntroduction(_language);
    } catch (apiError) {
      debugPrint('Real voice pipeline unavailable: $apiError');
      profile = await const MockOnboardingRepository().analyseIntroduction(_language);
    }

    if (!mounted) return;

    setState(() {
      _profile = profile;

      _skills
        ..clear()
        ..addAll(profile.skills);

      _processing = false;
      _step = 5;
    });
  } catch (e) {
    debugPrint('Voice analysis error: $e');

    if (!mounted) return;

    setState(() {
      _processing = false;
      _error =
          'We could not understand that. Please try speaking again.';
    });
  }
}

  Future<void> _finish() async {
    if (_processing) return;

    setState(() {
      _processing = true;
      _error = null;
    });

    final detected = _profile;
    if (detected != null) {
      // This is the hand-off point: voice-derived skills become the user's
      // profile and drive every downstream demo feature.
      DemoStore.instance.profile['full_name'] = _name.trim();
      DemoStore.instance.profile['display_name'] = _name.trim();
      DemoStore.instance.profile['age'] = int.tryParse(_age.trim());
      DemoStore.instance.profile['location'] = _location;
      DemoStore.instance.profile['user_type'] = _userType;
      DemoStore.instance.updateVoiceProfile(
        skills: _skills,
        experience: detected.experience,
        languages: detected.languages,
        transcript: detected.transcript,
      );

      // Supabase must never be allowed to trap the user on this screen.
      // A bad/missing migration or a temporary network issue should not
      // destroy the live hackathon journey. The repository itself writes
      // the core profile first and treats optional fields as best-effort.
      if (AppConfig.hasSupabase) {
        try {
          await _profileRepository
              .saveCurrentProfile()
              .timeout(const Duration(seconds: 6));
        } catch (e) {
          debugPrint('Supabase profile save deferred: $e');
        }
      }

      // Ask Gemini for a polished profile summary when the backend is running.
      // The local profile remains available even if the AI call is unavailable.
      try {
        final years = DemoStore.instance.experienceYears;
        final result = await BackendClient.instance
            .postJson(
              '/profile/generate',
              {
                'name': DemoStore.instance.profile['full_name'],
                'skills': _skills,
                'location': _location,
                'experience_years': years,
                'language': DemoStore.instance.language,
              },
            )
            .timeout(const Duration(seconds: 6));
        final headline = result['headline']?.toString().trim() ?? '';
        final bio = result['bio']?.toString().trim() ?? '';
        if (headline.isNotEmpty && bio.isNotEmpty) {
          DemoStore.instance.applyGeneratedProfile(
            headline: headline,
            bio: bio,
          );
          if (AppConfig.hasSupabase) {
            try {
              await _profileRepository
                  .saveCurrentProfile()
                  .timeout(const Duration(seconds: 6));
            } catch (e) {
              debugPrint('Supabase AI profile update deferred: $e');
            }
          }
        }
      } catch (e) {
        debugPrint('AI profile generation unavailable; keeping local profile: $e');
      }
    }

    if (!mounted) return;

    setState(() {
      _processing = false;
    });

    // Keep the intended identity-verification demo step when Supabase is
    // enabled. Navigation is deliberately independent of network/database
    // success so a demo cannot get stuck on the final onboarding screen.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => AppConfig.hasSupabase
            ? const AadhaarVerificationScreen()
            : const HomeShell(),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _welcome(),
      _basicProfilePage(),
      _languagePage(),
      _userTypePage(),
      _voicePage(),
      _skillsPage(),
      _locationPage(),
      _verificationPage(),
      _familyPage(),
      _completePage(),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (_step > 0 && _step < 9)
              _ProgressHeader(step: _step, onBack: _back),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                child: KeyedSubtree(key: ValueKey(_step), child: pages[_step]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _page({
    required String title,
    required String subtitle,
    required Widget child,
    Widget? action,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 10),
          Text(subtitle, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 28),
          Expanded(child: child),
          if (_error != null) _ErrorMessage(message: _error!),
          if (action != null) ...[
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: action),
          ],
        ],
      ),
    );
  }

  Widget _welcome() {
    return Container(
      color: AppColors.teal,
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),

          const CircleAvatar(
            radius: 40,
            backgroundColor: Color(0xFFFFD694),
            child: Icon(
              Icons.volunteer_activism_rounded,
              size: 46,
              color: AppColors.teal,
            ),
          ),

          const SizedBox(height: 25),

          const Text(
            'Welcome to\nSilverHands',
            style: TextStyle(
              fontSize: 39,
              height: 1.04,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 16),

          const Text(
            "Your skills can open new doors. Let's create your "
            "work profile in a few simple steps.",
            style: TextStyle(fontSize: 19, height: 1.4, color: Colors.white),
          ),

          const Spacer(),

          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _next,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.saffron,
                foregroundColor: AppColors.ink,
              ),
              child: const Text("Let's begin"),
            ),
          ),

          const SizedBox(height: 15),

          const Center(
            child: Text(
              'You can ask a family member for help anytime.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _basicProfilePage() {
    return _page(
      title: 'Let’s get to know you',
      subtitle: 'Tell us your name and age. This helps us personalise SilverHands for you.',
      child: ListView(
        children: [
          TextField(
            onChanged: (value) => _name = value,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Your name',
              hintText: 'For example, Lakshmi',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            onChanged: (value) => _age = value,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Your age',
              hintText: 'For example, 62',
              prefixIcon: Icon(Icons.cake_outlined),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.record_voice_over_rounded),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'You can type these details now. Later, SilverHands can also help you complete your profile using voice.',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      action: FilledButton(
        onPressed: () {
          final age = int.tryParse(_age.trim());
          if (_name.trim().isEmpty) {
            setState(() => _error = 'Please enter your name.');
            return;
          }
          if (age == null || age < 18 || age > 120) {
            setState(() => _error = 'Please enter a valid age.');
            return;
          }
          setState(() {
            _error = null;
            DemoStore.instance.profile['full_name'] = _name.trim();
            DemoStore.instance.profile['display_name'] = _name.trim();
            DemoStore.instance.profile['age'] = age;
            _step++;
          });
        },
        child: const Text('Continue'),
      ),
    );
  }

  Widget _languagePage() {
  return _page(
    title: 'Choose your language',
    subtitle: 'You can change this later whenever you wish.',
    child: _optionList(
      ['English', 'Tamil', 'Hindi'],
      _language,
      (value) {
        setState(() {
          _language = value;
        });

        debugPrint('Selected language: $_language');
      },
    ),
    action: FilledButton(
      onPressed: _next,
      child: const Text('Continue'),
    ),
  );
}

  Widget _userTypePage() {
    return _page(
      title: 'How will you use SilverHands?',
      subtitle: 'This helps us make the app right for you.',
      child: _optionList(
        [
          'Senior citizen',
          'Homemaker',
          'Buyer / customer',
          'Trusted family guide',
        ],
        _userType,
        (value) => setState(() => _userType = value),
      ),
      action: FilledButton(onPressed: _next, child: const Text('Continue')),
    );
  }

  Widget _voicePage() {
    return _page(
      title: 'Tell us about yourself.',
      subtitle:
          'What work or skills do you have? Speak naturally in $_language. '
          'We will turn your words into a profile.',
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              button: true,
              label: 'Start voice introduction',
              hint: 'Double tap to begin speaking about your skills',
              child: InkWell(
                onTap: _processing ? null : _analyseVoice,
                borderRadius: BorderRadius.circular(100),
                child: Ink(
                  width: 176,
                  height: 176,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.rose,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x40443338),
                        blurRadius: 22,
                        offset: Offset(0, 9),
                      ),
                    ],
                  ),
                  child: _processing
                      ? const Padding(
                          padding: EdgeInsets.all(48),
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 5,
                          ),
                        )
                      : const Icon(
                          Icons.mic_rounded,
                          color: Colors.white,
                          size: 83,
                        ),
                ),
              ),
            ),

            const SizedBox(height: 25),

            Text(
              _processing
                  ? 'AI is listening and understanding...'
                  : 'Tap the microphone to speak',
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            Text(
              'No typing needed',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.ink.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
      action: _processing
          ? null
          : OutlinedButton.icon(
              onPressed: _analyseVoice,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try a sample introduction'),
            ),
    );
  }

  Widget _skillsPage() {
    final profile = _profile;

    return _page(
      title: 'We found these skills',
      subtitle:
          'Please review them. You are always in control of what is shown '
          'on your profile.',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(17),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF2D9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.saffron,
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'AI detected:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            Wrap(
              spacing: 8,
              runSpacing: 9,
              children: _skills
                  .map(
                    (skill) => InputChip(
                      label: Text(skill),
                      onDeleted: () {
                        setState(() => _skills.remove(skill));
                      },
                      deleteIcon: const Icon(Icons.close_rounded),
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                      backgroundColor: AppColors.mist,
                      side: BorderSide.none,
                      padding: const EdgeInsets.all(8),
                    ),
                  )
                  .toList(),
            ),

            const SizedBox(height: 11),

            TextButton.icon(
              onPressed: _addSkill,
              icon: const Icon(Icons.add_circle_outline_rounded),
              label: const Text('Add another skill'),
            ),

            const SizedBox(height: 18),

            _InfoRow(
              label: 'Experience',
              value: profile?.experience ?? 'Not added',
            ),

            _InfoRow(
              label: 'Languages',
              value: profile?.languages.join(', ') ?? _language,
            ),

            if (profile?.transcript.isNotEmpty == true) ...[
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.mist.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'What we heard',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      profile!.transcript,
                      style: const TextStyle(fontSize: 16, height: 1.45),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 18),

            const Text(
              'Tip: Tap × beside a skill to remove it.',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
      action: FilledButton(
        onPressed: _skills.isEmpty ? null : _next,
        child: const Text('These look right'),
      ),
    );
  }

  void _addSkill() {
    final controller = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add a skill'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              hintText: 'For example, Embroidery',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final skill = controller.text.trim();

                if (skill.isNotEmpty) {
                  setState(() => _skills.add(skill));
                }

                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Widget _locationPage() {
    return _page(
      title: 'Where are you located?',
      subtitle:
          'We use this to show nearby opportunities. Your exact address '
          'stays private.',
      child: _optionList(
        [
          'Chennai, Tamil Nadu',
          'Coimbatore, Tamil Nadu',
          'Madurai, Tamil Nadu',
          'Use my current location',
        ],
        _location,
        (value) => setState(() => _location = value),
      ),
      action: FilledButton.icon(
        onPressed: _next,
        icon: const Icon(Icons.location_on_rounded),
        label: const Text('Confirm location'),
      ),
    );
  }

  Widget _verificationPage() {
    return _page(
      title: 'Build trust safely',
      subtitle:
          'A verified profile helps customers feel confident. Your details '
          'are protected.',
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 46,
              backgroundColor: AppColors.mist,
              child: Icon(
                Icons.verified_user_rounded,
                size: 54,
                color: AppColors.teal,
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'Verify with a phone number',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
            ),

            const SizedBox(height: 8),

            const Text(
              'We will send a one-time code. This is a demo; '
              'no details are collected yet.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
      action: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FilledButton(
            onPressed: _next,
            child: const Text('Verify phone number'),
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: _next, child: const Text('Do this later')),
        ],
      ),
    );
  }

  Widget _familyPage() {
    return _page(
      title: 'Add a trusted guide',
      subtitle:
          'A family member can help you use SilverHands. You decide what '
          'they can see and do.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.shield_outlined, color: AppColors.teal, size: 30),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'You can remove access at any time.',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          TextField(
            onChanged: (value) => _familyMember = value,
            decoration: const InputDecoration(
              labelText: 'Family member\'s name (optional)',
              hintText: 'For example, Priya',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person_add_alt_1_rounded),
            ),
            style: const TextStyle(fontSize: 18),
          ),
        ],
      ),
      action: FilledButton(
        onPressed: _next,
        child: Text(
          _familyMember.isEmpty ? 'Skip for now' : 'Add trusted guide',
        ),
      ),
    );
  }

  Widget _completePage() {
    return Container(
      color: AppColors.teal,
      padding: const EdgeInsets.all(27),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircleAvatar(
            radius: 48,
            backgroundColor: Color(0xFFFFD694),
            child: Icon(Icons.check_rounded, size: 58, color: AppColors.teal),
          ),

          const SizedBox(height: 25),

          const Text(
            'Your profile is ready!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 12),

          const Text(
            'You are ready to discover opportunities made for your skills.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 18, height: 1.4),
          ),

          const SizedBox(height: 34),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(19),
            ),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 7,
              runSpacing: 7,
              children: _skills
                  .map((skill) => SkillChip(label: skill))
                  .toList(),
            ),
          ),

          const SizedBox(height: 34),

          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _finish,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.saffron,
                foregroundColor: AppColors.ink,
              ),
              child: const Text('Explore opportunities'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _optionList(
    List<String> items,
    String selected,
    ValueChanged<String> select,
  ) {
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 11),
      itemBuilder: (context, index) {
        final item = items[index];
        final isSelected = item == selected;

        return Semantics(
          selected: isSelected,
          button: true,
          child: InkWell(
            onTap: () => select(item),
            borderRadius: BorderRadius.circular(18),
            child: Ink(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.teal : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected ? AppColors.teal : const Color(0xFFD7DDD8),
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  Icon(
                    isSelected
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    color: isSelected ? Colors.white : AppColors.teal,
                    size: 27,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.step, required this.onBack});

  final int step;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 24, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            tooltip: 'Go back',
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          Expanded(
            child: Semantics(
              label: 'Step $step of 7',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: step / 7,
                  minHeight: 8,
                  backgroundColor: AppColors.mist,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE7EB),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.rose),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
