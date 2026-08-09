import 'package:dealer_app/price_upload/price_importer_parser.dart';
import 'package:dealer_app/shared/utils/dimensions.dart';
import 'package:dealer_app/shared/utils/spacing.dart';
import 'package:flutter/material.dart';

class PriceUploadErrorView extends StatelessWidget {
  final ParseResult result;
  final VoidCallback onChooseAnotherFile;

  const PriceUploadErrorView({
    super.key,
    required this.result,
    required this.onChooseAnotherFile,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingMedium),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              size: 52,
              color: Theme.of(context).colorScheme.error,
            ),

            Spacing.largeY,

            Text(
              'File could not be validated',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),

            Spacing.smallY,

            Text(
              '${result.errors.length} error(s) found. '
                  'Fix the Excel file and try again.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),

            Spacing.largeY,

            Expanded(
              child: ListView.separated(
                itemCount: result.errors.length,
                separatorBuilder: (_, _) => Spacing.smallY,
                itemBuilder: (context, index) {
                  final error = result.errors[index];

                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(Dimensions.paddingMedium),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(
                        Dimensions.borderRadiusMedium,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${error.sheet} • Row ${error.rowNumber}',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Spacing.smallY,
                        Text(error.message),
                      ],
                    ),
                  );
                },
              ),
            ),

            Spacing.mediumY,

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
