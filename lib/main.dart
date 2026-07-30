import 'package:dealer_app/services/price_letter_pdf_service.dart';
import 'package:dealer_app/services/price_letter_service.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  if (supabaseUrl.isEmpty || supabasePublishableKey.isEmpty) {
    throw Exception(
      'Missing Supabase configuration. '
      'Provide SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY via --dart-define.',
    );
  }

  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabasePublishableKey,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: ElevatedButton(
            child: const Text('Generate Test PDF'),
            onPressed: () async {
              final data = PriceLetterData(
                dealerCode: 4821,
                effectiveDate: DateTime(2026, 7, 28),
                ms: const ProductPriceData(
                  indentPrice: 250.00,
                  sellingPrice: 252.50,
                ),
                hsd: const ProductPriceData(
                  indentPrice: 255.00,
                  sellingPrice: 258.00,
                ),
              );

              final pdfBytes = await generatePriceLetterPdf(data);

              await Printing.layoutPdf(onLayout: (_) async => pdfBytes);
            },
          ),
        ),
      ),
    );
  }
}
