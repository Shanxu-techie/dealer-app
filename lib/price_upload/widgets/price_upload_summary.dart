import 'package:dealer_app/price_upload/price_importer_parser.dart';
import 'package:dealer_app/shared/utils/dimensions.dart';
import 'package:dealer_app/shared/utils/spacing.dart';
import 'package:flutter/material.dart';


class PriceUploadSummary extends StatelessWidget {
  final String fileName;
  final DateTime effectiveDate;
  final ParseResult result;

  const PriceUploadSummary({
    super.key,
    required this.fileName,
    required this.effectiveDate,
    required this.result,
  });

  Widget _buildSummaryRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        Spacing.mediumX,
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          textAlign: TextAlign.end,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final msCount = result.rows.where((row) => row.product == 'MS').length;
    final hsdCount = result.rows.where((row) => row.product == 'HSD').length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Dimensions.paddingMedium),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(Dimensions.borderRadiusMedium),
        border: Border.all(color: Theme.of(context).colorScheme.secondary),
      ),
      child: Column(
        children: [
          _buildSummaryRow(
            context,
            Icons.description_outlined,
            'File',
            fileName,
          ),
          Spacing.mediumY,
          _buildSummaryRow(
            context,
            Icons.calendar_today_outlined,
            'Effective date',
            '${effectiveDate.day}/'
                '${effectiveDate.month}/'
                '${effectiveDate.year}',
          ),
          Spacing.mediumY,
          _buildSummaryRow(
            context,
            Icons.table_rows_outlined,
            'Total records',
            '${result.rows.length}',
          ),
          Spacing.mediumY,
          _buildSummaryRow(
            context,
            Icons.local_gas_station_outlined,
            'MS',
            '$msCount records',
          ),
          Spacing.mediumY,
          _buildSummaryRow(
            context,
            Icons.local_gas_station_outlined,
            'HSD',
            '$hsdCount records',
          ),
        ],
      ),
    );
  }
}
