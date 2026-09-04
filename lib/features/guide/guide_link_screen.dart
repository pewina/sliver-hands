import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/app_theme.dart';
import '../../data/repositories/guide_repository.dart';
import 'guide_shell.dart';

class GuideLinkScreen extends StatefulWidget {
  const GuideLinkScreen({super.key});

  @override
  State<GuideLinkScreen> createState() => _GuideLinkScreenState();
}

class _GuideLinkScreenState extends State<GuideLinkScreen> {
  final _code = TextEditingController();
  final _name = TextEditingController();
  final _relationship = TextEditingController(text: 'Family member');
  final _repo = GuideRepository();
  bool _busy = false;
  bool _checkingConnection = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkExistingConnection();
  }

  Future<void> _checkExistingConnection() async {
    try {
      final link = await _repo.activeLink();
      if (!mounted) return;
      if (link != null) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(builder: (_) => const GuideShell()),
          (_) => false,
        );
        return;
      }
    } catch (_) {}
    if (mounted) setState(() => _checkingConnection = false);
  }

  Future<void> _connect() async {
    if (_code.text.trim().length != 6 || _name.text.trim().isEmpty) {
      setState(() => _error = 'Enter the 6-digit code and your name.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await _repo.acceptCode(
        code: _code.text,
        name: _name.text,
        relationship: _relationship.text,
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const GuideShell()),
        (_) => false,
      );
    } on PostgrestException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'That code is invalid or expired. Ask the member for a new code.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
  }

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    _relationship.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Family Guide'),
        backgroundColor: AppColors.cream,
        actions: [
          IconButton(onPressed: _signOut, icon: const Icon(Icons.logout_rounded)),
        ],
      ),
      body: _checkingConnection
          ? const Center(child: CircularProgressIndicator())
          : Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Icon(Icons.family_restroom_rounded, size: 62, color: AppColors.teal),
              const SizedBox(height: 16),
              Text(
                'Connect to your family member',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                'The member generates a one-time 6-digit code from their SilverHands profile. You can then help them without taking control of their identity or ownership.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, height: 1.45),
              ),
              const SizedBox(height: 25),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      TextField(
                        controller: _code,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        decoration: const InputDecoration(
                          labelText: '6-digit connection code',
                          prefixIcon: Icon(Icons.key_rounded),
                        ),
                      ),
                      TextField(
                        controller: _name,
                        decoration: const InputDecoration(
                          labelText: 'Your name',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _relationship,
                        decoration: const InputDecoration(
                          labelText: 'Relationship',
                          prefixIcon: Icon(Icons.family_restroom_outlined),
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(_error!, style: const TextStyle(color: AppColors.rose)),
                      ],
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _busy ? null : _connect,
                          icon: const Icon(Icons.link_rounded),
                          label: Text(_busy ? 'Connecting...' : 'Connect securely'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 15),
              const _ProtectionCard(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProtectionCard extends StatelessWidget {
  const _ProtectionCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE7EB),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.lock_rounded, color: AppColors.rose),
            SizedBox(width: 8),
            Text('What a guide cannot change', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
          ]),
          SizedBox(height: 9),
          Text('• Name and identity verification\n• Skills and experience\n• Financial ownership / payout details\n• The member’s account password\n• Guide access itself', style: TextStyle(height: 1.5)),
        ],
      ),
    );
  }
}
