import 'package:dealer_app/price_upload/price_importer_parser.dart';
import 'package:dealer_app/shared/utils/dimensions.dart';
import 'package:dealer_app/shared/utils/spacing.dart';
import 'package:flutter/material.dart';

import 'price_upload_summary.dart';

class ValidatedPriceUploadView extends StatelessWidget {
  final String fileName;
  final DateTime effectiveDate;
  final ParseResult result;
  final VoidCallback onUpload;
  final VoidCallback onChooseAnotherFile;

  const ValidatedPriceUploadView({
    super.key,
    required this.fileName,
    required this.effectiveDate,
    required this.result,
    required this.onUpload,
    required this.onChooseAnotherFile,
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
              'File validated',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),

            Spacing.smallY,

            Text(
              'The price letter is ready to upload.',
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
                onPressed: onUpload,
                icon: const Icon(Icons.cloud_upload_outlined),
                label: const Text('Upload prices'),
              ),
            ),

            Spacing.smallY,

            TextButton.icon(
              onPressed: onChooseAnotherFile,
              icon: const Icon(Icons.swap_horiz),
              label: const Text('Choose another file'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
