import 'package:dealer_app/shared/utils/dimensions.dart';
import 'package:dealer_app/shared/utils/spacing.dart';
import 'package:flutter/material.dart';

class PriceUploadFileSelected extends StatelessWidget {
  final String fileName;
  final DateTime? effectiveDate;
  final VoidCallback onPickFile;
  final VoidCallback onPickEffectiveDate;
  final VoidCallback onValidate;

  const PriceUploadFileSelected({
    super.key,
    required this.fileName,
    required this.effectiveDate,
    required this.onPickFile,
    required this.onPickEffectiveDate,
    required this.onValidate,
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
              Icons.description_outlined,
              size: 52,
              color: Theme.of(context).colorScheme.primary,
            ),
            Spacing.largeY,
            Text(
              'File selected',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            Spacing.smallY,
            Text(
              'Select an effective date, then validate the file.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            Spacing.largeY,
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(Dimensions.paddingMedium),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(
                  Dimensions.borderRadiusMedium,
                ),
                border: Border.all(
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.table_view_outlined,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  Spacing.smallX,
                  Expanded(
                    child: Text(
                      fileName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Spacing.largeY,
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onPickEffectiveDate,
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text(
                  effectiveDate == null
                      ? 'Select effective date'
                      : 'Effective date: '
                            '${effectiveDate!.day}/'
                            '${effectiveDate!.month}/'
                            '${effectiveDate!.year}',
                ),
              ),
            ),
            Spacing.mediumY,
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: effectiveDate == null ? null : onValidate,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Validate file'),
              ),
            ),
            Spacing.smallY,
            TextButton.icon(
              onPressed: onPickFile,
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
