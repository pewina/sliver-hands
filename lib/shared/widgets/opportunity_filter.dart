import 'package:flutter/material.dart';

import '../../app/app_theme.dart';

class OpportunityFilter extends StatelessWidget {
  const OpportunityFilter({super.key, required this.selected, required this.onChanged});
  final String selected;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 43,
    child: ListView(
      scrollDirection: Axis.horizontal,
      children: ['For you', 'Products', 'Services', 'Bulk orders']
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(item),
                selected: item == selected,
                onSelected: (_) => onChanged(item),
                selectedColor: AppColors.teal,
                labelStyle: TextStyle(
                  color: item == selected ? Colors.white : AppColors.ink,
                  fontWeight: FontWeight.w800,
                ),
                side: BorderSide.none,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          )
          .toList(),
    ),
  );
}
