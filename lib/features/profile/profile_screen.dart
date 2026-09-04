import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../core/demo_store.dart';
import '../../core/app_config.dart';
import '../../data/repositories/profile_repository.dart';
import '../../shared/widgets/badges.dart';
import '../../shared/widgets/skill_chip.dart';
import '../journey/journey_screen.dart';
import '../location/location_map_screen.dart';
import 'trusted_family_guide_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final DemoStore _demo = DemoStore.instance;
  final ProfileRepository _profileRepository = ProfileRepository();

  Map<String, dynamic> get _profile => _demo.profile;

  String _text(String key, [String fallback = '']) =>
      (_profile[key]?.toString().trim().isNotEmpty ?? false)
          ? _profile[key].toString()
          : fallback;

  List<String> get _skills => (_profile['skills'] as List? ?? [])
      .map((e) => e.toString())
      .where((e) => e.trim().isNotEmpty)
      .toList();

  Future<void> _editProfile() async {
    final name = TextEditingController(text: _text('full_name', 'Lakshmi Devi'));
    final location = TextEditingController(text: _text('location', 'Chennai, Tamil Nadu'));
    final language = TextEditingController(text: _text('language', 'English'));
    final experience = TextEditingController(text: _text('experience', '18 years'));
    final skills = TextEditingController(text: _skills.join(', '));

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit your profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Full name')),
              const SizedBox(height: 10),
              TextField(controller: location, decoration: const InputDecoration(labelText: 'Location')),
              const SizedBox(height: 10),
              TextField(controller: language, decoration: const InputDecoration(labelText: 'Preferred language')),
              const SizedBox(height: 10),
              TextField(controller: experience, decoration: const InputDecoration(labelText: 'Experience')),
              const SizedBox(height: 10),
              TextField(
                controller: skills,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Skills',
                  hintText: 'Cooking, Tailoring, Teaching',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              _demo.saveProfile(
                name: name.text.trim(),
                location: location.text.trim(),
                language: language.text.trim(),
                experience: experience.text.trim(),
                skills: skills.text
                    .split(',')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList(),
              );
              Navigator.pop(dialogContext, true);
            },
            child: const Text('Save changes'),
          ),
        ],
      ),
    );

    name.dispose();
    location.dispose();
    language.dispose();
    experience.dispose();
    skills.dispose();

    if (saved == true && mounted) {
      if (AppConfig.hasSupabase) {
        try {
          await _profileRepository.saveCurrentProfile();
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Profile saved locally, but cloud sync failed: $e')),
            );
          }
        }
      }
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully ✓')),
        );
      }
    }
  }

  void _verifyIdentity() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Identity verification'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 34,
              backgroundColor: Color(0xFFD9F1EC),
              child: Icon(Icons.verified_user_rounded, size: 38, color: AppColors.teal),
            ),
            SizedBox(height: 16),
            Text(
              'Demo verification complete',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
            ),
            SizedBox(height: 8),
            Text(
              'SilverHands uses a safe verification flow. Aadhaar numbers are never stored in this prototype.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Done')),
        ],
      ),
    );
  }

  Future<void> _showGuide() async {
    if (!AppConfig.hasSupabase) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Family guide connection needs Supabase live mode.')),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const TrustedFamilyGuideScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fullName = _text('full_name', 'Lakshmi Devi');
    final location = _text('location', 'Chennai, Tamil Nadu');
    final firstLetter = fullName.isEmpty ? 'S' : fullName[0].toUpperCase();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
        children: [
          Row(
            children: [
              Expanded(child: Text('My Profile', style: Theme.of(context).textTheme.headlineMedium)),
              IconButton(onPressed: _editProfile, icon: const Icon(Icons.edit_rounded), tooltip: 'Edit profile'),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 43,
                    backgroundColor: const Color(0xFFFFE1B6),
                    child: Text(firstLetter, style: const TextStyle(fontSize: 35, fontWeight: FontWeight.w900, color: AppColors.ink)),
                  ),
                  const SizedBox(height: 12),
                  Text(fullName, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 5),
                  Text(location, style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 10),
                  const VerificationBadge(),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF2D9),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.auto_awesome_rounded, color: AppColors.saffron, size: 21),
                            SizedBox(width: 7),
                            Text('AI profile summary', style: TextStyle(fontWeight: FontWeight.w900)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(_text('headline', 'Skilled SilverHands creator'), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 5),
                        Text(_text('bio', 'Your profile is personalised from your skills.'), style: const TextStyle(fontSize: 14, height: 1.4)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    alignment: WrapAlignment.center,
                    children: _skills.map((skill) => SkillChip(label: skill)).toList(),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(child: _Stat(label: 'Orders', value: '${_demo.ordersCompleted}')),
                      Expanded(child: _Stat(label: 'Products', value: '${_demo.publishedProducts}')),
                      Expanded(child: _Stat(label: 'Earned', value: '₹${_demo.earnings}')),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 15),
          _ActionCard(
            icon: Icons.verified_user_rounded,
            title: 'Identity verified',
            subtitle: 'Your trusted profile badge is active',
            onTap: _verifyIdentity,
          ),
          _ActionCard(
            icon: Icons.family_restroom_rounded,
            title: 'Trusted family guide',
            subtitle: 'Let someone you trust help with orders',
            onTap: _showGuide,
          ),
          _ActionCard(
            icon: Icons.local_fire_department_rounded,
            title: 'My SilverHands Journey',
            subtitle: '12-day streak • 920 community points',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const JourneyScreen())),
          ),
          _ActionCard(
            icon: Icons.map_rounded,
            title: 'Nearby opportunities',
            subtitle: 'See trusted livelihood opportunities around you',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LocationMapScreen()),
            ),
          ),
          _ActionCard(
            icon: Icons.language_rounded,
            title: 'Language & voice',
            subtitle: '${_text('language', 'English')} • Voice assistance ready',
            onTap: () => _languageDialog(),
          ),
          _ActionCard(
            icon: Icons.notifications_active_rounded,
            title: 'Notifications',
            subtitle: _demo.notificationEnabled ? 'Enabled' : 'Paused',
            trailing: Switch(
              value: _demo.notificationEnabled,
              onChanged: (value) => setState(() => _demo.notificationEnabled = value),
            ),
            onTap: () => setState(() => _demo.notificationEnabled = !_demo.notificationEnabled),
          ),
        ],
      ),
    );
  }

  void _languageDialog() {
    const languages = ['English', 'தமிழ்', 'हिन्दी', 'తెలుగు', 'മലയാളം'];
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: languages.map((language) => ListTile(
            leading: const Icon(Icons.language_rounded),
            title: Text(language, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            trailing: _text('language', 'English') == language ? const Icon(Icons.check_circle, color: AppColors.teal) : null,
            onTap: () {
              _demo.profile['language'] = language;
              Navigator.pop(context);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Language changed to $language ✓')));
            },
          )).toList(),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.teal)),
      const SizedBox(height: 3),
      Text(label, style: const TextStyle(fontSize: 13)),
    ],
  );
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      leading: CircleAvatar(
        backgroundColor: const Color(0xFFD9F1EC),
        child: Icon(icon, color: AppColors.teal),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
      subtitle: Text(subtitle),
      trailing: trailing ?? const Icon(Icons.chevron_right_rounded),
    ),
  );
}
