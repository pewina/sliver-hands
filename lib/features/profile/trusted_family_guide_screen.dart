import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/app_theme.dart';
import '../../core/app_config.dart';
import '../../data/repositories/guide_repository.dart';

/// Member-owned Trusted Family Guide connection screen.
///
/// The member generates a short-lived code. A separate Family Guide account
/// enters that code to establish a link to this exact member. No member
/// profile details are edited by the guide through this flow.
class TrustedFamilyGuideScreen extends StatefulWidget {
  const TrustedFamilyGuideScreen({super.key});

  @override
  State<TrustedFamilyGuideScreen> createState() =>
      _TrustedFamilyGuideScreenState();
}

class _TrustedFamilyGuideScreenState extends State<TrustedFamilyGuideScreen> {
  final _relationship = TextEditingController(text: 'Family member');
  final _repo = GuideRepository();

  bool _loading = true;
  bool _generating = false;
  Map<String, dynamic>? _active;
  String? _code;
  String? _error;
  List<Map<String, dynamic>> _requests = [];

  @override
  void initState() {
    super.initState();
    _loadConnection();
  }

  Future<void> _loadConnection() async {
    if (!AppConfig.hasSupabase) {
      setState(() {
        _loading = false;
        _error = 'Connect Supabase to create a real family guide code.';
      });
      return;
    }

    try {
      final active = await _repo.ownerActiveLink();
      final requests = await _repo.memberRequests();
      if (!mounted) return;
      setState(() {
        _active = active;
        _requests = requests;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load your guide connection. Please try again.';
      });
    }
  }

  Future<void> _generateCode() async {
    if (_generating) return;

    setState(() {
      _generating = true;
      _error = null;
    });

    try {
      final generated = await _repo.createInvite(
        relationship: _relationship.text.trim().isEmpty
            ? 'Family member'
            : _relationship.text.trim(),
      );

      if (!mounted) return;
      setState(() {
        _code = generated;
        _generating = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _generating = false;
        _error = _friendlyError(e);
      });
    }
  }


  String _friendlyError(Object error) {
    if (error is PostgrestException) {
      return 'Could not generate a code: ${error.message}';
    }
    return error.toString().replaceFirst('Exception: ', '');
  }

  Future<void> _revoke() async {
    final linkId = _active?['id']?.toString();
    if (linkId == null) return;

    try {
      await _repo.revokeLink(linkId);
      if (!mounted) return;
      setState(() => _active = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Family Guide access revoked ✓')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not revoke access. Please try again.')),
      );
    }
  }

  @override
  void dispose() {
    _relationship.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Trusted Family Guide'),
        backgroundColor: AppColors.cream,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(22, 18, 22, 30),
                    children: [
                      const CircleAvatar(
                        radius: 38,
                        backgroundColor: Color(0xFFD9F1EC),
                        child: Icon(
                          Icons.family_restroom_rounded,
                          size: 42,
                          color: AppColors.teal,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Let someone you trust help you',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 9),
                      const Text(
                        'Your Family Guide can help with opportunities, messages and content. You remain the owner of your SilverHands account.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, height: 1.45),
                      ),
                      const SizedBox(height: 22),
                      if (_active != null) _connectedCard() else _codeCard(),
                      const SizedBox(height: 18),
                      if (_requests.isNotEmpty) _approvalCard(),
                      _protectionCard(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _connectedCard() {
    final name = _active?['guide_name']?.toString().trim();
    final relationship = _active?['relationship']?.toString() ?? 'Family member';
    final displayName = name == null || name.isEmpty ? 'Family Guide' : name;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            const Icon(Icons.check_circle_rounded, size: 52, color: AppColors.green),
            const SizedBox(height: 10),
            const Text('Family Guide Connected', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text(displayName, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
            Text(relationship),
            const SizedBox(height: 16),
            const Text(
              'Your guide can view and assist with SilverHands, but cannot change your name, skills, experience, verification or financial ownership.',
              textAlign: TextAlign.center,
              style: TextStyle(height: 1.4),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: _revoke,
              icon: const Icon(Icons.link_off_rounded),
              label: const Text('Revoke Guide Access'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _codeCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('1. Generate your code', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text(
              'Your family member will use this code from their own Family Guide account. The code identifies your account without exposing your password or personal credentials.',
              style: TextStyle(height: 1.4),
            ),
            const SizedBox(height: 18),
            if (_code == null) ...[
              TextField(
                controller: _relationship,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Relationship',
                  hintText: 'Daughter, Son, Spouse, etc.',
                  prefixIcon: Icon(Icons.family_restroom_rounded),
                ),
              ),
              const SizedBox(height: 15),
              FilledButton.icon(
                onPressed: _generating ? null : _generateCode,
                icon: const Icon(Icons.key_rounded),
                label: Text(_generating ? 'Generating...' : 'Generate 6-digit code'),
              ),
            ] else ...[
              const Text(
                '2. Give this code to your trusted family member',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFD9F1EC),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: SelectableText(
                  _code!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 42,
                    letterSpacing: 9,
                    fontWeight: FontWeight.w900,
                    color: AppColors.teal,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'This code expires in 30 minutes and can only be used to create the guide connection.',
                textAlign: TextAlign.center,
                style: TextStyle(height: 1.4),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: _generateCode,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Generate a new code'),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppColors.rose, fontWeight: FontWeight.w700)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _approvalCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Icon(Icons.pending_actions_rounded, color: AppColors.teal),
            SizedBox(width: 8),
            Text('Guide requests your approval', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          ]),
          const SizedBox(height: 8),
          const Text('Your guide can prepare help, but you decide whether a sensitive action should go ahead.'),
          const SizedBox(height: 10),
          ..._requests.take(5).map((request) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(request['title']?.toString() ?? 'Help request', style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text(request['message']?.toString() ?? ''),
              isThreeLine: true,
              trailing: Wrap(spacing: 4, children: [
                IconButton(tooltip: 'Reject', icon: const Icon(Icons.close_rounded, color: AppColors.rose), onPressed: () => _respond(request, 'rejected')),
                IconButton(tooltip: 'Approve', icon: const Icon(Icons.check_circle_rounded, color: AppColors.green), onPressed: () => _respond(request, 'approved')),
              ]),
            ),
          )),
        ]),
      ),
    );
  }

  Future<void> _respond(Map<String, dynamic> request, String status) async {
    try {
      await _repo.respondToRequest(requestId: request['id'].toString(), status: status);
      await _loadConnection();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(status == 'approved' ? 'Approved. Your guide can continue with this help.' : 'Request rejected.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not update request: $e')));
    }
  }

  Widget _protectionCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE7EB),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lock_rounded, color: AppColors.rose),
              SizedBox(width: 8),
              Text('You stay in control', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            ],
          ),
          SizedBox(height: 10),
          Text(
            'A Family Guide cannot change your name, identity verification, skills, experience, password, payout or financial ownership, or your guide permissions.',
            style: TextStyle(height: 1.5),
          ),
        ],
      ),
    );
  }
}
