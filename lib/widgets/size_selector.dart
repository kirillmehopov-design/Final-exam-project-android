import 'package:flutter/material.dart';

class SizeSelector extends StatelessWidget {
  final List<int> sizes;
  final int? selectedSize;
  final ValueChanged<int> onSelected;

  const SizeSelector({
    super.key,
    required this.sizes,
    required this.selectedSize,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: sizes.map((size) {
        final selected = size == selectedSize;

        return ChoiceChip(
          label: Text(size.toString()),
          selected: selected,
          showCheckmark: false,
          onSelected: (_) => onSelected(size),
          selectedColor: Colors.black,
          labelStyle: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w700,
          ),
          side: BorderSide(
            color: selected ? Colors.black : Colors.black26,
          ),
        );
      }).toList(),
    );
  }
}
