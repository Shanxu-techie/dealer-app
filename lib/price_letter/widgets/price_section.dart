import 'package:dealer_app/price_letter/price_letter_service.dart';
import 'package:flutter/material.dart';

class PriceSection extends StatelessWidget {
  const PriceSection({super.key, required this.title, this.product});

  final String title;
  final ProductPriceData? product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleMedium),

        const SizedBox(height: 16),

        if (product == null)
          const Text('Price not available')
        else ...[
          Row(
            children: [
              Expanded(child: const Text('Indent Price')),
              Text('PKR ${product!.indentPrice.toStringAsFixed(2)}'),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(child: const Text('Selling Price')),
              Text('PKR ${product!.sellingPrice.toStringAsFixed(2)}'),
            ],
          ),
        ],
      ],
    );
  }
}
