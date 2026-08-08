import 'dart:async';

import 'package:dealer_app/login/login_service.dart';
import 'package:dealer_app/price_letter/price_letter_pdf_service.dart';
import 'package:dealer_app/price_letter/price_letter_service.dart';
import 'package:dealer_app/price_letter/widgets/price_section.dart';
import 'package:dealer_app/shared/models/app_user_role.dart';
import 'package:dealer_app/shared/widgets/app_shared_bar.dart';
import 'package:flutter/foundation.dart';
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
    required this.role,
    this.dealerName,
  });

  final int dealerCode;
  final SupabaseClient supabase;
  final String? dealerName;
  final AppUserRole role;

  @override
  State<PriceLetterPage> createState() => _PriceLetterPageState();
}

class _PriceLetterPageState extends State<PriceLetterPage> {
  PriceLetterData? priceLetter;
  String? error;
  bool loading = true;
  bool generatingPdf = false;
  Object? exception;

  Timer? _refreshDebounce;
  Timer? _refreshRetry;

  late final RealtimeChannel _priceLetterChannel;

  bool _hasConnectedOnce = false;
  bool _isRefreshing = false;

  int _refreshRetryAttempts = 0;
  static const int _maxRefreshRetryAttempts = 5;

  void _subscribeToPriceUpdates() {
    _priceLetterChannel = widget.supabase
        .channel('dealer-price-${widget.dealerCode}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'dealer_prices',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'dealer_code',
            value: widget.dealerCode,
          ),
          callback: (_) {
            if (kDebugMode) {
              debugPrint('Realtime event received');
            }

            _refreshDebounce?.cancel();

            _refreshDebounce = Timer(const Duration(milliseconds: 300), () {
              if (kDebugMode) {
                debugPrint('Refreshing price letter');
              }
              if (mounted) {
                _loadPriceLetter(showUpdateBanner: true);
              }
            });
          },
        )
        .subscribe((status, [error]) {
          if (kDebugMode) {
            debugPrint(
              'status=$status hasConnected=$_hasConnectedOnce mounted=$mounted',
            );
          }

          if (status == RealtimeSubscribeStatus.subscribed) {
            if (kDebugMode) {
              debugPrint("ENTERED SUBSCRIBED");
            }

            if (_hasConnectedOnce) {
              if (kDebugMode) {
                debugPrint("RECONNECTED");
              }
              _loadPriceLetter(showUpdateBanner: true);
            } else {
              if (kDebugMode) {
                debugPrint("FIRST CONNECT");
              }
              _hasConnectedOnce = true;
            }
          }
        });
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _scheduleRefreshRetry() {
    if (_refreshRetryAttempts >= _maxRefreshRetryAttempts) {
      return;
    }

    _refreshRetry?.cancel();
    _refreshRetryAttempts++;

    _refreshRetry = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;

      _loadPriceLetter(showUpdateBanner: true);
    });
  }

  bool _priceLetterChanged(PriceLetterData? previous, PriceLetterData next) {
    if (previous == null) return false;

    return previous.effectiveDate != next.effectiveDate ||
        _productChanged(previous.ms, next.ms) ||
        _productChanged(previous.hsd, next.hsd);
  }

  bool _productChanged(ProductPriceData? previous, ProductPriceData? next) {
    if (previous == null && next == null) return false;
    if (previous == null || next == null) return true;

    return previous.indentPrice != next.indentPrice ||
        previous.sellingPrice != next.sellingPrice;
  }

  @override
  void initState() {
    super.initState();
    _subscribeToPriceUpdates();
    _loadPriceLetter();
  }

  Future<void> _loadPriceLetter({bool showUpdateBanner = false}) async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    try {
      if (kDebugMode) {
        debugPrint('Loading latest price letter...');
      }
      final result = await fetchCurrentPriceLetterData(
        supabase: widget.supabase,
        dealerCode: widget.dealerCode,
      );
      if (!mounted) return;
      switch (result) {
        case SuccessResult(data: final data):
          if (kDebugMode) {
            debugPrint('Fetched effective date: ${data.effectiveDate}');
          }
          _refreshRetry?.cancel();
          _refreshRetryAttempts = 0;
          if (kDebugMode) {
            debugPrint(
              'Fetched effectiveDate=${data.effectiveDate}, '
              'MS=${data.ms?.sellingPrice}, '
              'HSD=${data.hsd?.sellingPrice}',
            );
          }

          final previousPriceLetter = priceLetter;

          if (kDebugMode) {
            debugPrint(
              'Previous effectiveDate=${previousPriceLetter?.effectiveDate}, '
              'MS=${previousPriceLetter?.ms?.sellingPrice}, '
              'HSD=${previousPriceLetter?.hsd?.sellingPrice}',
            );
          }

          final hasChanged = _priceLetterChanged(previousPriceLetter, data);

          if (kDebugMode) {
            debugPrint('hasChanged = $hasChanged');
          }
          setState(() {
            priceLetter = data;
            exception = null;
            error = null;
            loading = false;
          });
          if (showUpdateBanner && hasChanged) {
            final messenger = ScaffoldMessenger.of(context);

            messenger.hideCurrentSnackBar();

            messenger.showSnackBar(
              const SnackBar(content: Text('Price updated')),
            );
          }

        case FailureResult(message: final message, exception: final exception):
          if (showUpdateBanner) {
            _showErrorSnackBar(
              'Couldn\'t refresh the latest prices. Showing the last available data.',
            );

            _scheduleRefreshRetry();
            return;
          }

          setState(() {
            this.exception = exception;
            error = message;
            loading = false;
          });
      }
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> _generatePdf() async {
    if (priceLetter == null) return;

    setState(() => generatingPdf = true);

    try {
      final pdfBytes = await generatePriceLetterPdf(
        priceLetter!,
      ).timeout(const Duration(seconds: 30));
      await Printing.layoutPdf(
        onLayout: (_) async => pdfBytes,
      ).timeout(const Duration(seconds: 30));
    } on TimeoutException {
      _showErrorSnackBar('PDF request timed out. Please try again.');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('PDF generation failed: $e');
      }
      _showErrorSnackBar('Failed to generate PDF. Please try again.');
    } finally {
      if (mounted) {
        setState(() => generatingPdf = false);
      }
    }
  }

  @override
  void dispose() {
    _refreshDebounce?.cancel();
    _refreshRetry?.cancel();
    widget.supabase.removeChannel(_priceLetterChannel);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (error != null) {
      final noPriceData = exception is PriceLetterUnavailableException;

      return Scaffold(
        appBar: AppSharedBar(
          title: widget.dealerName ?? 'Price Letter',
          role: widget.role,
          hasUnseenNotification: false,
          onProfileTap: null,
          onLogoutTap: () async {
            await LoginService().signOut();
          },
        ),
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
      appBar: AppSharedBar(
        title: widget.dealerName ?? 'Price Letter',
        role: widget.role,
        hasUnseenNotification: false,
        onProfileTap: null,
        onLogoutTap: () async {
          await LoginService().signOut();
        },
      ),
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
