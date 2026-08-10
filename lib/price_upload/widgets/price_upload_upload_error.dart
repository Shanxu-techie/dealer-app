import 'package:dealer_app/price_upload/price_upsert_service.dart';
import 'package:dealer_app/shared/utils/dimensions.dart';
import 'package:dealer_app/shared/utils/spacing.dart';
import 'package:flutter/material.dart';

class PriceUploadUploadError extends StatelessWidget {
  final List<BatchResult> errors;
  final VoidCallback onTryAgain;
  final VoidCallback onChooseAnotherFile;

  const PriceUploadUploadError({
    super.key,
    required this.errors,
    required this.onTryAgain,
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
              Icons.cloud_off_outlined,
              size: 52,
              color: Theme.of(context).colorScheme.error,
            ),

            Spacing.largeY,

            Text(
              'Upload failed',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),

            Spacing.smallY,

            Text(
              'The price letter was validated, but the dealer prices '
              'could not be uploaded.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),

            Spacing.largeY,

            Column(
              children: errors.map((error) {
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(
                    bottom: Dimensions.paddingMedium,
                  ),
                  padding: const EdgeInsets.all(Dimensions.paddingMedium),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.errorContainer,
                    ),
                    borderRadius: BorderRadius.circular(
                      Dimensions.borderRadiusMedium,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Batch ${error.batchNumber}',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),

                      Spacing.smallY,

                      Text(
                        '${error.sheet} • Rows ${error.startRow}-${error.endRow}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      Spacing.smallY,

                      Text(
                        error.errorMessage ?? 'Unknown upload error.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),

            Spacing.largeY,

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onTryAgain,
                icon: const Icon(Icons.refresh),
                label: const Text('Try upload again'),
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
