import 'package:flutter/material.dart';

import '../../app/app_theme.dart';

class TrustedGuide {
  const TrustedGuide({required this.name, required this.relationship, required this.permissions});
  final String name;
  final String relationship;
  final List<String> permissions;
}

const mockTrustedGuide = TrustedGuide(
  name: 'Priya',
  relationship: 'Daughter',
  permissions: ['Help manage orders', 'Help respond to customers', 'Help upload products', 'View business activity'],
);

class TrustedGuideCard extends StatelessWidget {
  const TrustedGuideCard({super.key, required this.guide});
  final TrustedGuide guide;
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(19), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('MY TRUSTED GUIDE', style: TextStyle(fontSize: 14, letterSpacing: 1.05, color: AppColors.teal, fontWeight: FontWeight.w900)), const SizedBox(height: 15),
    Row(children: [CircleAvatar(radius: 29, backgroundColor: const Color(0xFFFFD694), child: Text(guide.name[0], style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: AppColors.ink))), const SizedBox(width: 13), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(guide.name, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900)), Text(guide.relationship, style: const TextStyle(fontSize: 16)), const SizedBox(height: 5), const Row(children: [Icon(Icons.check_circle_rounded, color: AppColors.green, size: 19), SizedBox(width: 5), Text('Status: Connected', style: TextStyle(color: AppColors.green, fontWeight: FontWeight.w900))])]))]),
    const Divider(height: 28), const Text('Permissions', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)), const SizedBox(height: 9), ...guide.permissions.map((permission) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [const Icon(Icons.check_circle_rounded, size: 20, color: AppColors.green), const SizedBox(width: 8), Expanded(child: Text(permission, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)))]))), const SizedBox(height: 10),
    Container(padding: const EdgeInsets.all(13), decoration: BoxDecoration(color: const Color(0xFFFFE7EB), borderRadius: BorderRadius.circular(15)), child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.lock_rounded, color: AppColors.rose, size: 21), SizedBox(width: 8), Expanded(child: Text('For your safety, Priya cannot change identity verification or financial ownership.', style: TextStyle(fontSize: 14, height: 1.35, fontWeight: FontWeight.w700))) ])), const SizedBox(height: 10), TextButton.icon(onPressed: () {}, icon: const Icon(Icons.tune_rounded), label: const Text('Review guide permissions')),
  ])));
}
