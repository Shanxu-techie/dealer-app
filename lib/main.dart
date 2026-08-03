import 'package:dealer_app/login/login_page.dart';
import 'package:dealer_app/login/secure_local_storage.dart';
import 'package:dealer_app/services/price_importer_parser.dart';
import 'package:dealer_app/services/price_upsert_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'login/login_service.dart';

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
    authOptions: FlutterAuthClientOptions(localStorage: SecureLocalStorage()),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Supabase.instance.client.auth;

    return MaterialApp(
      home: StreamBuilder<AuthState>(
        stream: auth.onAuthStateChange,
        initialData: AuthState(
          AuthChangeEvent.initialSession,
          auth.currentSession,
        ),
        builder: (context, snapshot) {
          final session = snapshot.data?.session;

          if (session != null) {
            return const DealerHomePage();
          }

          return const LoginPage();
        },
      ),
    );
  }
}

class DealerHomePage extends StatefulWidget {
  const DealerHomePage({super.key});

  @override
  State<DealerHomePage> createState() => _DealerHomePageState();
}

class _DealerHomePageState extends State<DealerHomePage> {
  Map<String, dynamic>? profile;
  String? error;
  bool loading = true;

  Future<void> _testDealerRead() async {
    try {
      final rows = await Supabase.instance.client
          .from('dealer_prices')
          .select()
          .eq('dealer_code', 171736)
          .eq('effective_date', '2026-07-27');

      debugPrint('Returned rows: ${rows.length}');

      for (final row in rows) {
        debugPrint(row.toString());
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> _testImport() async {
    try {
      final bytes = await rootBundle.load('assets/sample_price_letter.xlsx');

      final parser = const PriceImportParser();

      final parseResult = parser.parse(
        bytes.buffer.asUint8List(),
        effectiveDate: DateTime(2026, 7, 27),
      );

      debugPrint('Parsed rows: ${parseResult.rows.length}');
      debugPrint('Parse errors: ${parseResult.errors.length}');

      final summary = await upsertDealerPrices(
        Supabase.instance.client,
        parseResult.rows,
      );

      debugPrint('Total rows: ${summary.totalRows}');
      debugPrint('Successful batches: ${summary.successfulBatches}');
      debugPrint('Failed batches: ${summary.failedBatches}');

      for (final batch in summary.batchResults) {
        debugPrint(
          'Batch ${batch.batchNumber}: success=${batch.success} '
          'rows=${batch.rowCount} '
          'error=${batch.errorMessage}',
        );
      }
    } catch (e, st) {
      debugPrint('IMPORT FAILED');
      debugPrint(e.toString());
      debugPrint(st.toString());
    }
  }

  Future<void> _testDealerWrite() async {
    try {
      await Supabase.instance.client
          .from('dealer_prices')
          .insert({
        'dealer_code': 987654321,
        'effective_date': '2099-01-01',
        'product_name': 'RLS_TEST_ONLY',
        'indent_price': 250,
        'fixed_selling_price': 252,
      });

      debugPrint('WRITE SUCCEEDED - RLS FAILED');
    } catch (e) {
      debugPrint('WRITE BLOCKED');
      debugPrint(e.toString());
    }
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profileData = await LoginService().getCurrentUserProfile();

      if (!mounted) return;

      setState(() {
        profile = profileData;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (error != null) {
      return Scaffold(body: Center(child: Text(error!)));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Dealer Home')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Role: ${profile?['role']}'),
            if (kDebugMode && profile?['role'] == 'dealer') ...[
              ElevatedButton(
                onPressed: _testDealerRead,
                child: const Text('Test Dealer Read'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _testDealerWrite,
                child: const Text('Test Dealer Write'),
              ),
              const SizedBox(height: 16),
            ],
            if (kDebugMode && profile?['role'] == 'publisher') ...[
              ElevatedButton(
                onPressed: _testImport,
                child: const Text('Test Import'),
              ),
              const SizedBox(height: 16),
            ],
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _signOut, child: const Text('Sign Out')),
          ],
        ),
      ),
    );
  }
}
