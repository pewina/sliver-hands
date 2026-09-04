import 'package:flutter/material.dart';

import '../../data/models/opportunity.dart';
import 'badges.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product});
  final Opportunity product;
  @override
  Widget build(BuildContext context) => SizedBox(width: 230, child: Card(clipBehavior: Clip.antiAlias, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [AspectRatio(aspectRatio: 1.45, child: Image.network(product.imageUrl, fit: BoxFit.cover, errorBuilder: (_, _, _) => const ColoredBox(color: Color(0xFFE4DDD2)))), Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(product.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)), const SizedBox(height: 4), Text(product.price, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)), const SizedBox(height: 7), const VerificationBadge()]))])));
}
