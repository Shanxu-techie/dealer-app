import 'package:dealer_app/shared/utils/dimensions.dart';
import 'package:dealer_app/shared/utils/spacing.dart';
import 'package:flutter/material.dart';

class PriceUploadParseError extends StatelessWidget {
  final String message;
  final VoidCallback onChooseAnotherFile;

  const PriceUploadParseError({
    super.key,
    required this.message,
    required this.onChooseAnotherFile,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingMedium),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.insert_drive_file_outlined,
              size: 52,
              color: colorScheme.error,
            ),

            Spacing.largeY,

            Text(
              'File could not be read',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),

            Spacing.smallY,

            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),

            Spacing.largeY,

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onChooseAnotherFile,
                icon: const Icon(Icons.refresh),
                label: const Text('Choose another file'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
