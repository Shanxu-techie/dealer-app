import 'package:dealer_app/price_letter/price_letter_pdf_service.dart';
import 'package:dealer_app/price_letter/price_letter_service.dart';
import 'package:dealer_app/price_letter/widgets/price_section.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../shared/models/result.dart';

class PriceLetterPage extends StatefulWidget {
  const PriceLetterPage({
    super.key,
    required this.dealerCode,
    required this.supabase,
    this.dealerName,
  });

  final int dealerCode;
  final SupabaseClient supabase;
  final String? dealerName;

  @override
  State<PriceLetterPage> createState() => _PriceLetterPageState();
}

class _PriceLetterPageState extends State<PriceLetterPage> {
  PriceLetterData? priceLetter;
  String? error;
  bool loading = true;
  bool generatingPdf = false;
  Object? exception;

  @override
  void initState() {
    super.initState();
    _loadPriceLetter();
  }

  Future<void> _loadPriceLetter() async {
    final result = await fetchCurrentPriceLetterData(
      supabase: widget.supabase,
      dealerCode: widget.dealerCode,
    );

    if (!mounted) return;

    switch (result) {
      case SuccessResult(data: final data):
        setState(() {
          priceLetter = data;
          exception = null;
          error = null;
          loading = false;
        });

      case FailureResult(message: final message, exception: final exception):
        setState(() {
          this.exception = exception;
          error = message;
          loading = false;
        });
    }
  }

  Future<void> _generatePdf() async {
    if (priceLetter == null) return;

    setState(() => generatingPdf = true);

    try {
      final pdfBytes = await generatePriceLetterPdf(priceLetter!);
      await Printing.layoutPdf(onLayout: (_) async => pdfBytes);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate PDF. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => generatingPdf = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (error != null) {
      final noPriceData = exception is PriceLetterUnavailableException;

      return Scaffold(
        appBar: AppBar(title: Text(widget.dealerName ?? 'Price Letter')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                noPriceData
                    ? 'No price letter is available for this dealer yet.'
                    : error!,
                textAlign: TextAlign.center,
              ),

              if (!noPriceData) ...[
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () {
                    setState(() {
                      loading = true;
                      error = null;
                      exception = null;
                    });
                    _loadPriceLetter();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ],
          ),
        ),
      );
    }
    final data = priceLetter!;
    return Scaffold(
      appBar: AppBar(title: Text(widget.dealerName ?? 'Price Letter')),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: FilledButton.icon(
          onPressed: generatingPdf ? null : _generatePdf,
          icon: generatingPdf
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.picture_as_pdf),
          label: Text(generatingPdf ? 'Generating PDF...' : 'Save PDF'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Dealer #${data.dealerCode}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                Spacer(),
                Text(
                  'Effective ${DateFormat('dd MMM yyyy').format(data.effectiveDate)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PriceSection(title: 'MS', product: data.ms),
                    Divider(height: 32),
                    PriceSection(title: 'HSD', product: data.hsd),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
