import 'package:dealer_app/shared/utils/dimensions.dart';
import 'package:dealer_app/shared/utils/spacing.dart';
import 'package:flutter/material.dart';

class PriceUploadUploading extends StatelessWidget {
  const PriceUploadUploading({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingMedium),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_upload_outlined,
              size: 52,
              color: Theme.of(context).colorScheme.primary,
            ),
            Spacing.largeY,
            Text(
              'Updating dealer prices. Please wait...',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            Spacing.mediumY,
            const CircularProgressIndicator(),
            Spacing.mediumY,

            Text(
              'Updating dealer prices with the validated price letter.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
