import 'dart:async';

import 'package:dealer_app/login/login_service.dart';
import 'package:dealer_app/price_letter/price_letter_pdf_service.dart';
import 'package:dealer_app/price_letter/price_letter_service.dart';
import 'package:dealer_app/price_letter/price_seen_storage.dart';
import 'package:dealer_app/price_letter/widgets/price_section.dart';
import 'package:dealer_app/shared/models/app_user_role.dart';
import 'package:dealer_app/shared/utils/dimensions.dart';
import 'package:dealer_app/shared/utils/spacing.dart';
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
    this.initialPriceLetter,
    required this.isHistorical,
  });

  final int dealerCode;
  final SupabaseClient supabase;
  final String? dealerName;
  final AppUserRole role;
  final PriceLetterData? initialPriceLetter;
  final bool isHistorical;

  @override
  State<PriceLetterPage> createState() => _PriceLetterPageState();
}

class _PriceLetterPageState extends State<PriceLetterPage> {
  PriceLetterData? priceLetter;
  String? error;
  String? _bodyError;
  bool loading = true;
  bool generatingPdf = false;
  bool _hasUnseenNotification = false;
  Object? exception;

  Timer? _refreshDebounce;
  Timer? _refreshRetry;

  DateTime? _selectedDate;

  final PriceSeenStorage _priceSeenStorage = PriceSeenStorage();

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

  Future<void> _onNotificationsTap() async {
    final data = priceLetter;
    if (data == null) return;

    final result = await _priceSeenStorage.markAsSeen(
      dealerCode: widget.dealerCode,
      effectiveDate: data.effectiveDate,
      msPrice: data.ms?.sellingPrice,
      hsdPrice: data.hsd?.sellingPrice,
    );

    if (!mounted) return;

    switch (result) {
      case SuccessResult():
        setState(() {
          _hasUnseenNotification = false;
        });

      case FailureResult(message: final message, exception: final exception):
        if (kDebugMode) {
          debugPrint(
            'Failed to mark notification as seen: '
            '$message, exception=$exception',
          );
        }
    }
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

          final unseenResult = await _priceSeenStorage.hasUnseenChange(
            dealerCode: widget.dealerCode,
            effectiveDate: data.effectiveDate,
            msPrice: data.ms?.sellingPrice,
            hsdPrice: data.hsd?.sellingPrice,
          );

          if (!mounted) return;

          switch (unseenResult) {
            case SuccessResult(data: final hasUnseenChange):
              setState(() {
                _hasUnseenNotification = hasUnseenChange;
              });

            case FailureResult(
              message: final message,
              exception: final storageException,
            ):
              if (kDebugMode) {
                debugPrint(
                  'Failed to check price seen state: '
                  '$message, exception=$storageException',
                );
              }

              setState(() {
                _hasUnseenNotification = false;
              });
          }

          setState(() {
            priceLetter = data;
            _selectedDate = data.effectiveDate;
            exception = null;
            error = null;
            loading = false;
          });

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

  void _showPriceLetterDateSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose a date to view its price letter.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: const Text('Choose a date'),
                  trailing: const Icon(Icons.chevron_right),
                  contentPadding: EdgeInsets.zero,
                  onTap: () {
                    Navigator.pop(context);
                    _selectPriceLetterDate();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _selectPriceLetterDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final earliestDate = today.subtract(const Duration(days: 29));

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: priceLetter?.effectiveDate ?? today,
      firstDate: earliestDate,
      lastDate: today,
    );

    if (!mounted || selectedDate == null) return;

    await _loadPriceLetterForDate(selectedDate);
  }

  Future<void> _loadPriceLetterForDate(DateTime selectedDate) async {
    setState(() {
      _selectedDate = selectedDate;
      _bodyError = null;
      loading = true;
    });

    final result = await fetchPriceLetterData(
      supabase: widget.supabase,
      dealerCode: widget.dealerCode,
      effectiveDate: selectedDate,
    );

    if (!mounted) return;

    switch (result) {
      case SuccessResult(data: final data):
        setState(() {
          priceLetter = data;
          _selectedDate = data.effectiveDate;
          _bodyError = null;
          loading = false;
        });

      case FailureResult(message: final message):
        setState(() {
          _bodyError = message;
          loading = false;
        });
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.isHistorical && widget.initialPriceLetter != null) {
      priceLetter = widget.initialPriceLetter;
      _selectedDate = widget.initialPriceLetter!.effectiveDate;
      loading = false;
      return;
    }
    _subscribeToPriceUpdates();
    _loadPriceLetter();
  }

  @override
  void dispose() {
    _refreshDebounce?.cancel();
    _refreshRetry?.cancel();
    if (!widget.isHistorical) {
      widget.supabase.removeChannel(_priceLetterChannel);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        appBar: AppSharedBar(
          title: 'Price Letter',
          role: widget.role,
          hasUnseenNotification: widget.isHistorical
              ? false
              : _hasUnseenNotification,
          notificationMsPrice: priceLetter?.ms?.sellingPrice,
          notificationHsdPrice: priceLetter?.hsd?.sellingPrice,
          notificationEffectiveDate: priceLetter?.effectiveDate,
          onNotificationsTap: widget.isHistorical ? null : _onNotificationsTap,
          onProfileTap: null,
          onLogoutTap: () async {
            await LoginService().signOutAndReturnToLogin(context);
          },
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (error != null) {
      final noPriceData = exception is PriceLetterUnavailableException;

      return Scaffold(
        appBar: AppSharedBar(
          title: 'Price Letter',
          role: widget.role,
          hasUnseenNotification: widget.isHistorical
              ? false
              : _hasUnseenNotification,
          notificationMsPrice: priceLetter?.ms?.sellingPrice,
          notificationHsdPrice: priceLetter?.hsd?.sellingPrice,
          notificationEffectiveDate: priceLetter?.effectiveDate,
          onNotificationsTap: widget.isHistorical ? null : _onNotificationsTap,
          onProfileTap: null,
          onLogoutTap: () async {
            await LoginService().signOutAndReturnToLogin(context);
          },
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(Dimensions.paddingMedium),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  noPriceData
                      ? 'No price letter is available for this dealer yet.'
                      : error!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),

                if (!noPriceData) ...[
                  Spacing.mediumY,
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
        ),
      );
    }
    final data = priceLetter!;
    final displayDate = _selectedDate ?? data.effectiveDate;
    return Scaffold(
      appBar: AppSharedBar(
        title: 'Price Letter',
        role: widget.role,
        hasUnseenNotification: widget.isHistorical
            ? false
            : _hasUnseenNotification,
        notificationMsPrice: priceLetter?.ms?.sellingPrice,
        notificationHsdPrice: priceLetter?.hsd?.sellingPrice,
        notificationEffectiveDate: priceLetter?.effectiveDate,
        onNotificationsTap: widget.isHistorical ? null : _onNotificationsTap,
        onProfileTap: null,
        onLogoutTap: () async {
          await LoginService().signOutAndReturnToLogin(context);
        },
      ),
      bottomNavigationBar: _bodyError != null
          ? null
          : SafeArea(
              minimum: const EdgeInsets.all(Dimensions.paddingMedium),
              child: FilledButton.icon(
                onPressed: generatingPdf ? null : _generatePdf,
                icon: generatingPdf
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.picture_as_pdf),
                label: Text(generatingPdf ? 'Generating PDF...' : 'Save PDF'),
              ),
            ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Dimensions.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.dealerName?.trim().isNotEmpty == true) ...[
              Text(
                widget.dealerName!,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Spacing.smallY,
            ],
            Row(
              children: [
                Text(
                  'Code# ${data.dealerCode}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const Spacer(),
                InkWell(
                  onTap: _showPriceLetterDateSheet,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Effective ${DateFormat('dd MMM yyyy').format(displayDate)}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.secondary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.keyboard_arrow_down,
                          size: 18,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Spacing.largeY,
            const Divider(),
            Spacing.largeY,
            _bodyError == null
                ? Card(
                    child: Padding(
                      padding: const EdgeInsets.all(Dimensions.paddingMedium),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          PriceSection(title: 'MS', product: data.ms),
                          const Divider(height: 32),
                          PriceSection(title: 'HSD', product: data.hsd),
                        ],
                      ),
                    ),
                  )
                : Center(
                    child: Padding(
                      padding: const EdgeInsets.all(Dimensions.paddingLarge),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          Spacing.mediumY,
                          Text(
                            _bodyError!,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
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
