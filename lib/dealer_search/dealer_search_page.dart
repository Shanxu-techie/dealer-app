import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../shared/models/result.dart';
import 'dealer_search_service.dart';
import 'dealer_summary.dart';

class DealerSearchPage extends StatefulWidget {
  final DealerSearchService service;

  const DealerSearchPage({super.key, required this.service});

  @override
  State<DealerSearchPage> createState() => _DealerSearchPageState();
}

class _DealerSearchPageState extends State<DealerSearchPage> {
  late final DealerSearchService _service;
  List<DealerSummary> _dealers = [];
  List<DealerSummary> _filteredDealers = [];
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  String? _errorMessage;

  Future<void> _loadDealers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final result = await _service.getDealers();

    if (!mounted) return;

    switch (result) {
      case SuccessResult(data: final dealers):
        setState(() {
          _dealers = dealers;
          _filteredDealers = _service.filterDealers(
            dealers,
            _searchController.text.trim(),
          );
          _isLoading = false;
        });

      case FailureResult(
        message: final message,
        exception: final exception,
        stackTrace: final stackTrace,
      ):
        debugPrint('DealerSearchPage: $message');
        debugPrint('Exception: $exception');
        debugPrint('StackTrace: $stackTrace');

        setState(() {
          _errorMessage = message;
          _dealers = [];
          _filteredDealers = [];
          _isLoading = false;
        });
    }
  }

  void _onSearchChanged(String query) {
    final trimmedQuery = query.trim();

    final filtered = _service.filterDealers(_dealers, trimmedQuery);

    setState(() {
      _filteredDealers = filtered;
    });
  }

  @override
  void initState() {
    super.initState();
    _service = widget.service;
    _loadDealers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dealer Search')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                hintText: 'Search by dealer code...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: _buildDealerList()),
        ],
      ),
    );
  }

  Widget _buildDealerList() {
    final List<DealerSummary> items = _filteredDealers;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Unable to load dealers. Check your connection and try again.',
              textAlign: TextAlign.center,
            ),
            if (kDebugMode) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
            const SizedBox(height: 12),
            FilledButton(onPressed: _loadDealers, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (items.isEmpty) {
      return const Center(child: Text('No dealers found'));
    }

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final dealer = items[index];
        return ListTile(
          title: Text(dealer.name),
          subtitle: Text('Code: ${dealer.dealerCode}'),
        );
      },
    );
  }
}
