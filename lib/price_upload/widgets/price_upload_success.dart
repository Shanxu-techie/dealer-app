import 'package:dealer_app/price_upload/price_importer_parser.dart';
import 'package:dealer_app/price_upload/widgets/price_upload_summary.dart';
import 'package:dealer_app/shared/utils/dimensions.dart';
import 'package:dealer_app/shared/utils/spacing.dart';
import 'package:flutter/material.dart';

class PriceUploadSuccess extends StatelessWidget {
  final String fileName;
  final DateTime effectiveDate;
  final ParseResult result;
  final VoidCallback onUploadAnother;

  const PriceUploadSuccess({
    super.key,
    required this.fileName,
    required this.effectiveDate,
    required this.result,
    required this.onUploadAnother,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Dimensions.paddingMedium),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 52,
              color: Theme.of(context).colorScheme.primary,
            ),

            Spacing.largeY,

            Text(
              'Upload successful',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),

            Spacing.smallY,

            Text(
              'Dealer prices have been updated successfully.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),

            Spacing.largeY,

            PriceUploadSummary(
              fileName: fileName,
              effectiveDate: effectiveDate,
              result: result,
            ),

            Spacing.largeY,

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onUploadAnother,
                icon: const Icon(Icons.upload_file_outlined),
                label: const Text('Upload another price letter'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
