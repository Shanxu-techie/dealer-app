import 'dart:async';

import 'package:dealer_app/login/login_page.dart';
import 'package:dealer_app/login/role_router.dart';
import 'package:dealer_app/login/secure_local_storage.dart';
import 'package:dealer_app/notifications/notification_service.dart';
import 'package:dealer_app/shared/utils/theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

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

  final notificationService = NotificationService();
  await notificationService.initialize();

  runApp(MyApp(notificationService: notificationService));
}

class MyApp extends StatefulWidget {
  const MyApp({required this.notificationService, super.key});

  final NotificationService notificationService;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final StreamSubscription<AuthState> _authSubscription;

  @override
  void initState() {
    super.initState();

    final auth = Supabase.instance.client.auth;

    _authSubscription = auth.onAuthStateChange.listen((authState) {
      if (authState.event == AuthChangeEvent.signedIn ||
          authState.event == AuthChangeEvent.initialSession) {
        if (authState.session != null) {
          widget.notificationService.registerCurrentToken();
        }
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Supabase.instance.client.auth;

    return MaterialApp(
      theme: AppThemes.lightTheme,
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<AuthState>(
        stream: auth.onAuthStateChange,
        initialData: AuthState(
          AuthChangeEvent.initialSession,
          auth.currentSession,
        ),
        builder: (context, snapshot) {
          if (kDebugMode) {
            debugPrint(
              'Auth event: ${snapshot.data?.event}, '
              'session: ${snapshot.data?.session != null}',
            );
          }

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
