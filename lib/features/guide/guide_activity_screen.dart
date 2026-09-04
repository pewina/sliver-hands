import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../app/app_theme.dart';
import '../../data/repositories/guide_repository.dart';

class GuideActivityScreen extends StatefulWidget {
  const GuideActivityScreen({super.key});
  @override
  State<GuideActivityScreen> createState() => _GuideActivityScreenState();
}

class _GuideActivityScreenState extends State<GuideActivityScreen> {
  final _repo = GuideRepository();
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final link = await _repo.activeLink();
      if (link == null) {
        if (mounted) setState(() { _items = []; _loading = false; });
        return;
      }
      final rows = await Supabase.instance.client
          .from('guide_activity')
          .select()
          .eq('owner_id', link['owner_id'])
          .order('created_at', ascending: false)
          .limit(30);
      if (mounted) setState(() { _items = rows.map((e) => Map<String, dynamic>.from(e)).toList(); _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help activity')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _items.isEmpty
                  ? ListView(children: const [
                      SizedBox(height: 120),
                      Icon(Icons.task_alt_rounded, size: 60, color: AppColors.teal),
                      SizedBox(height: 12),
                      Center(child: Text('No help activity yet.', style: TextStyle(fontSize: 17))),
                    ])
                  : ListView.builder(
                      padding: const EdgeInsets.all(18),
                      itemCount: _items.length,
                      itemBuilder: (_, i) {
                        final item = _items[i];
                        return Card(
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFFD9F1EC),
                              child: Icon(Icons.check_rounded, color: AppColors.teal),
                            ),
                            title: Text(_friendly(item['action']?.toString() ?? 'Help action'), style: const TextStyle(fontWeight: FontWeight.w800)),
                            subtitle: Text(item['details']?.toString() ?? 'Help recorded'),
                            trailing: Text(_date(item['created_at']?.toString())),
                          ),
                        );
                      },
                    ),
            ),
    );
  }

  String _friendly(String value) => value.replaceAll('_', ' ').replaceFirst(value[0], value[0].toUpperCase());

  String _date(String? value) {
    if (value == null) return '';
    final date = DateTime.tryParse(value)?.toLocal();
    if (date == null) return '';
    return '${date.day}/${date.month}';
  }
}
