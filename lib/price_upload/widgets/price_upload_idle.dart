import 'package:dealer_app/shared/utils/dimensions.dart';
import 'package:dealer_app/shared/utils/spacing.dart';
import 'package:flutter/material.dart';

class PriceUploadIdle extends StatelessWidget {
  final VoidCallback onPickFile;

  const PriceUploadIdle({super.key, required this.onPickFile});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingMedium),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.upload_file_outlined,
              size: 52,
              color: Theme.of(context).colorScheme.primary,
            ),
            Spacing.largeY,
            Text(
              'Upload price letter',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            Spacing.smallY,
            Text(
              'Select an Excel price letter to upload and update dealer prices.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            Spacing.largeY,
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onPickFile,
                icon: const Icon(Icons.folder_open_outlined),
                label: const Text('Choose Excel file'),
              ),
            ),
            Spacing.mediumY,
            Text(
              'Supported format: .xlsx',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
