import 'package:dealer_app/shared/utils/dimensions.dart';
import 'package:dealer_app/shared/utils/spacing.dart';
import 'package:flutter/material.dart';

class PriceUploadUploadError extends StatelessWidget {
  final String message;
  final VoidCallback onTryAgain;
  final VoidCallback onChooseAnotherFile;

  const PriceUploadUploadError({
    super.key,
    required this.message,
    required this.onTryAgain,
    required this.onChooseAnotherFile,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
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
              ).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
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

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(
                Dimensions.paddingMedium,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(
                  Dimensions.borderRadiusMedium,
                ),
              ),
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
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
                foregroundColor:
                Theme.of(context).colorScheme.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}