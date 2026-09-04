import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../app/app_theme.dart';
import '../../data/repositories/guide_repository.dart';
import '../auth/auth_screen.dart';
import 'guide_link_screen.dart';

class GuideProfileScreen extends StatefulWidget {
  const GuideProfileScreen({super.key});
  @override
  State<GuideProfileScreen> createState() => _GuideProfileScreenState();
}

class _GuideProfileScreenState extends State<GuideProfileScreen> {
  final _repo = GuideRepository();
  Map<String, dynamic>? _link;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final link = await _repo.activeLink();
      if (mounted) setState(() { _link = link; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _disconnect() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Disconnect guide access?'),
        content: const Text('You will no longer be able to view or help this family member until they send you a new code.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Disconnect')),
        ],
      ),
    );
    if (ok != true) return;
    await _repo.disconnectGuide();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const GuideLinkScreen()),
      (_) => false,
    );
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final guideName = _link?['guide_name']?.toString() ?? user?.email?.split('@').first ?? 'Family Guide';

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
        children: [
          Text('Guide profile', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 18),
          Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
            CircleAvatar(radius: 40, backgroundColor: const Color(0xFFFFD694), child: Text((guideName.isEmpty ? 'G' : guideName[0]).toUpperCase(), style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900))),
            const SizedBox(height: 12),
            Text(guideName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 5),
            Text(user?.email ?? ''),
            if (_link != null) ...[
              const SizedBox(height: 12),
              Text('${_link!['relationship'] ?? 'Family member'} • Connected', style: const TextStyle(color: AppColors.green, fontWeight: FontWeight.w800)),
            ],
          ]))),
          const SizedBox(height: 14),
          const _ReadOnlyCard(),
          const SizedBox(height: 10),
          Card(child: ListTile(
            leading: const Icon(Icons.link_off_rounded, color: AppColors.rose),
            title: const Text('Disconnect from family member', style: TextStyle(fontWeight: FontWeight.w900)),
            subtitle: const Text('Remove your own access'),
            onTap: _loading ? null : _disconnect,
          )),
          Card(child: ListTile(
            leading: const Icon(Icons.logout_rounded),
            title: const Text('Sign out', style: TextStyle(fontWeight: FontWeight.w900)),
            onTap: _logout,
          )),
        ],
      ),
    );
  }
}

class _ReadOnlyCard extends StatelessWidget {
  const _ReadOnlyCard();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(color: const Color(0xFFFFE7EB), borderRadius: BorderRadius.circular(18)),
    child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(Icons.lock_rounded, color: AppColors.rose), SizedBox(width: 8), Text('Protected member details', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17))]),
      SizedBox(height: 9),
      Text('You can view the member profile, but you cannot edit identity, skills, experience, verification or financial ownership.', style: TextStyle(height: 1.45)),
    ]),
  );
}
