import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/app_theme.dart';
import '../../data/repositories/guide_repository.dart';
import '../create/content_generation_service.dart';

class GuideDashboardScreen extends StatefulWidget {
  const GuideDashboardScreen({super.key});

  @override
  State<GuideDashboardScreen> createState() => _GuideDashboardScreenState();
}

class _GuideDashboardScreenState extends State<GuideDashboardScreen> {
  final _repo = GuideRepository();
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _link;
  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _opportunities = [];
  List<Map<String, dynamic>> _matches = [];
  List<Map<String, dynamic>> _requests = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final link = await _repo.activeLink();
      if (link == null) {
        if (mounted) {
          setState(() {
            _loading = false;
            _error = 'No family member is connected to this guide account.';
          });
        }
        return;
      }

      final profile = await _repo.linkedProfile();
      final opportunities = await _repo.linkedOpportunities();
      final matches = await _repo.linkedMatches();
      final requests = await _repo.guideRequests();

      if (!mounted) return;
      setState(() {
        _link = link;
        _profile = profile;
        _opportunities = opportunities;
        _matches = matches;
        _requests = requests;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Could not load the family member: $e';
        });
      }
    }
  }

  Future<void> _log(String action, [String? details]) async {
    final ownerId = _link?['owner_id']?.toString();
    if (ownerId == null) return;
    try {
      await _repo.logActivity(
        ownerId: ownerId,
        action: action,
        details: details,
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Family Guide')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.link_off_rounded,
                  size: 58,
                  color: AppColors.rose,
                ),
                const SizedBox(height: 12),
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final name = _profile?['display_name']?.toString() ?? 'Family member';
    final skills = (_profile?['skills'] as List? ?? [])
        .map((e) => e.toString())
        .toList();
    final guideName = _link?['guide_name']?.toString() ?? 'Family Guide';
    final pending = _requests.where((r) => r['status'] == 'pending').length;
    final interested = _matches.where((m) => m['interested'] == true).length;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello, $guideName 👋',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Helping $name safely',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
                const CircleAvatar(
                  backgroundColor: Color(0xFFFFD694),
                  child: Icon(Icons.family_restroom_rounded),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    const Icon(
                      Icons.verified_user_rounded,
                      color: AppColors.teal,
                      size: 30,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Connected securely',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            '${_link?['relationship'] ?? 'Family member'} • Member remains the owner',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: _Stat(value: '${_opportunities.length}', label: 'Opportunities')),
                Expanded(child: _Stat(value: '$interested', label: 'Interested')),
                Expanded(child: _Stat(value: '$pending', label: 'Pending help')),
                Expanded(child: _Stat(value: '${skills.length}', label: 'Skills')),
              ],
            ),
            const SizedBox(height: 20),
            if (pending > 0)
              _SectionCard(
                icon: Icons.pending_actions_rounded,
                title: '$pending approval request${pending == 1 ? '' : 's'}',
                subtitle: 'The member needs to approve one or more actions.',
                onTap: _showRequests,
              ),
            const _SectionTitle('Help the member'),
            _HelpCard(
              icon: Icons.person_search_rounded,
              title: 'View member profile',
              subtitle: 'Read protected details without editing them.',
              onTap: _showProfile,
            ),
            _HelpCard(
              icon: Icons.work_outline_rounded,
              title: 'Review opportunities',
              subtitle: 'Open opportunities and request member approval for help.',
              onTap: _opportunitiesSheet,
            ),
            _HelpCard(
              icon: Icons.favorite_rounded,
              title: 'Review interested opportunities',
              subtitle: 'Help decide which matches are worth pursuing.',
              onTap: _matchesSheet,
            ),
            _HelpCard(
              icon: Icons.auto_awesome_rounded,
              title: 'Create sharing content',
              subtitle: 'Generate WhatsApp and social copy from the member’s skills.',
              onTap: _contentSheet,
            ),
            _HelpCard(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'Prepare a customer reply',
              subtitle: 'Draft a safe, simple reply for the member to approve.',
              onTap: _messageHelper,
            ),
            _HelpCard(
              icon: Icons.shield_outlined,
              title: 'Safety assistant',
              subtitle: 'Check a message for OTP, payment or credential scams.',
              onTap: _safetySheet,
            ),
            const _SectionTitle('Recent guide activity'),
            if (_requests.isEmpty)
              const Text('Your assistance activity will appear here.')
            else
              ..._requests.take(4).map(
                (r) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    child: Icon(Icons.assignment_outlined),
                  ),
                  title: Text(r['title']?.toString() ?? 'Help request'),
                  subtitle: Text(
                    '${r['status']} • ${r['request_type']}',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showProfile() {
    final profile = _profile;
    if (profile == null) return;
    _log('viewed_member_profile');

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Member profile • View only',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 15),
                _row('Name', profile['display_name']?.toString() ?? '—'),
                _row('Location', profile['location']?.toString() ?? '—'),
                _row('Language', profile['language']?.toString() ?? '—'),
                _row('Experience', '${profile['experience_years'] ?? 0} years'),
                _row('Skills', (profile['skills'] as List? ?? []).join(', ')),
                _row(
                  'Verification',
                  profile['verified'] == true ? 'Verified' : 'Not verified',
                ),
                const SizedBox(height: 8),
                const Text(
                  'Protected details cannot be edited by a guide.',
                  style: TextStyle(
                    color: AppColors.rose,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _opportunitiesSheet() {
    _log('reviewed_opportunities');
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return _OpportunitySheet(
          opportunities: _opportunities,
          onHelp: _requestOpportunityApproval,
        );
      },
    );
  }

  Future<void> _requestOpportunityApproval(
    Map<String, dynamic> opportunity,
  ) async {
    try {
      await _repo.createHelpRequest(
        type: 'opportunity',
        title: 'Review opportunity: ${opportunity['title'] ?? 'Opportunity'}',
        message:
            'Your Family Guide would like to help review this opportunity. Please approve if you want the guide to assist.',
        payload: {
          'opportunity_id': opportunity['id']?.toString(),
          'opportunity_title': opportunity['title']?.toString(),
        },
      );
      await _log(
        'opportunity_help_requested',
        opportunity['title']?.toString(),
      );
      if (!mounted) return;
      Navigator.pop(context);
      _message('Approval request sent to the member.');
      await _load();
    } catch (e) {
      if (mounted) _message('Could not request approval: $e');
    }
  }

  void _matchesSheet() {
    _log('reviewed_matches');
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _MatchSheet(matches: _matches),
    );
  }

  Future<void> _contentSheet() async {
    final profile = _profile ?? <String, dynamic>{};
    final skills = (profile['skills'] as List? ?? [])
        .map((e) => e.toString())
        .join(', ');
    final product = skills.isEmpty ? 'SilverHands service' : skills.split(',').first.trim();

    final content = await const MockContentGenerationService()
        .generateFromProductPhoto(
      productName: product,
      productDescription:
          skills.isEmpty ? 'A skilled local creator' : 'Skilled in $skills',
      language: profile['language']?.toString() ?? 'English',
    );

    if (!mounted) return;
    await _log('generated_content', product);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Content assistant',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                const Text(
                  'WhatsApp Status',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 5),
                SelectableText(content.whatsAppStatus),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _shareWhatsApp(content.whatsAppStatus),
                        icon: const Icon(Icons.chat),
                        label: const Text('WhatsApp'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _message(
                            'Content is ready. The member remains the owner of what gets published.',
                          );
                        },
                        icon: const Icon(Icons.check),
                        label: const Text('Done'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _shareWhatsApp(String text) async {
    final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _messageHelper() {
    _log('opened_message_helper');
    final controller = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              8,
              20,
              MediaQuery.of(context).viewInsets.bottom + 28,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Customer reply helper',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Paste the customer message. SilverHands will prepare a simple reply; ask the member to approve before sending.',
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Example: Can you deliver 10 items by Friday?',
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () {
                    final message = controller.text.trim();
                    if (message.isEmpty) return;
                    Navigator.pop(context);
                    _showDraftReply(message);
                  },
                  child: const Text('Create safe reply draft'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDraftReply(String incoming) {
    const draft =
        'Thank you for your message. We have received your request and will confirm the details shortly. Please share the quantity, deadline and preferred delivery method if needed.';
    _log('drafted_customer_reply', incoming);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reply draft'),
        content: const SelectableText(draft),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                await _repo.createHelpRequest(
                  type: 'message',
                  title: 'Approve customer reply',
                  message: 'Your Family Guide prepared a customer reply. Please review and approve it before it is sent.',
                  payload: {'draft': draft},
                );
                if (!context.mounted) return;
                Navigator.pop(context);
                _message('Approval request sent to the member.');
                await _load();
              } catch (e) {
                if (context.mounted) _message('Could not request approval: $e');
              }
            },
            child: const Text('Request approval'),
          ),
        ],
      ),
    );
  }

  void _safetySheet() {
    final controller = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              8,
              20,
              MediaQuery.of(context).viewInsets.bottom + 28,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Safety assistant',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Paste a customer message to check for common scam signals.',
                ),
                const SizedBox(height: 12),
                TextField(controller: controller, maxLines: 4),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () {
                    final text = controller.text.toLowerCase();
                    Navigator.pop(context);
                    final risky = RegExp(
                      r'otp|one[- ]time password|upi pin|pin|password|cvv|bank|pay.*link|click.*link|aadhaar',
                    ).hasMatch(text);
                    showDialog<void>(
                      context: this.context,
                      builder: (context) => AlertDialog(
                        title: Text(
                          risky
                              ? '⚠️ Be careful'
                              : 'Looks okay — still verify',
                        ),
                        content: Text(
                          risky
                              ? 'This message contains a request for sensitive information or a payment action. Never share OTPs, passwords, UPI PINs, CVV, Aadhaar details or banking credentials.'
                              : 'No common scam keywords were detected. Still verify the customer, amount, deadline and payment terms before accepting.',
                        ),
                        actions: [
                          FilledButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Got it'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text('Check message'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRequests() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Approval requests',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                ..._requests.take(10).map(
                  (r) => ListTile(
                    leading: const Icon(Icons.pending_actions_rounded),
                    title: Text(r['title']?.toString() ?? 'Request'),
                    subtitle: Text(
                      '${r['status']} • ${r['request_type']}',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: AppColors.teal,
          ),
        ),
        Text(label, textAlign: TextAlign.center),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 9),
      child: Text(
        text,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _HelpCard extends StatelessWidget {
  const _HelpCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 9),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFD9F1EC),
          child: Icon(icon, color: AppColors.teal),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: AppColors.teal),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

class _OpportunitySheet extends StatelessWidget {
  const _OpportunitySheet({required this.opportunities, required this.onHelp});

  final List<Map<String, dynamic>> opportunities;
  final Future<void> Function(Map<String, dynamic>) onHelp;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * .72,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Opportunities',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: opportunities.isEmpty
                    ? const Center(child: Text('No opportunities published yet.'))
                    : ListView.separated(
                        itemCount: opportunities.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final opportunity = opportunities[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              opportunity['title']?.toString() ?? 'Opportunity',
                              style: const TextStyle(fontWeight: FontWeight.w900),
                            ),
                            subtitle: Text(
                              '${opportunity['business_name'] ?? ''}\n${opportunity['description'] ?? ''}\n${opportunity['price'] ?? ''}',
                            ),
                            isThreeLine: true,
                            trailing: IconButton(
                              tooltip: 'Ask member to approve help',
                              icon: const Icon(
                                Icons.volunteer_activism_rounded,
                                color: AppColors.teal,
                              ),
                              onPressed: () => onHelp(opportunity),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MatchSheet extends StatelessWidget {
  const _MatchSheet({required this.matches});
  final List<Map<String, dynamic>> matches;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * .62,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Interested opportunities',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: matches.isEmpty
                    ? const Center(child: Text('No matches yet.'))
                    : ListView(
                        children: matches.map((match) {
                          final opportunity = match['opportunities'];
                          final interested = match['interested'] == true;
                          return ListTile(
                            leading: Icon(
                              interested
                                  ? Icons.favorite
                                  : Icons.remove_circle_outline,
                              color: interested ? AppColors.rose : null,
                            ),
                            title: Text(
                              opportunity is Map
                                  ? opportunity['title']?.toString() ?? 'Opportunity'
                                  : 'Opportunity',
                            ),
                            subtitle: Text(
                              opportunity is Map
                                  ? '${opportunity['business_name'] ?? ''} • ${opportunity['price'] ?? ''}'
                                  : 'No details',
                            ),
                          );
                        }).toList(),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
