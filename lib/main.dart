import 'package:dealer_app/login/login_page.dart';
import 'package:dealer_app/login/role_router.dart';
import 'package:dealer_app/login/secure_local_storage.dart';
import 'package:flutter/material.dart';
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
          debugPrint(
            'Auth event: ${snapshot.data?.event}, '
            'session: ${snapshot.data?.session != null}',
          );
          final session = snapshot.data?.session;
          if (session != null) {
            return const RoleRouter();
          }
          return const LoginPage();
        },
      ),
    );
  }
}
