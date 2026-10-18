import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/env.dart';
import 'core/router.dart';
import 'core/theme.dart';
import 'data/api.dart';
import 'data/demo_api.dart';
import 'data/providers.dart';
import 'l10n/generated/app_localizations.dart';

const bool _demoDiagnostics = Env.demo;

/// In a release build Flutter paints a plain grey box wherever a widget throws,
/// which tells a tester nothing. In demo builds show the actual error instead.
void _installDemoErrorWidget() {
  if (!_demoDiagnostics) return;
  ErrorWidget.builder = (FlutterErrorDetails details) => Material(
        color: const Color(0xFFD93A3F),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Demo build — widget error',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    details.exceptionAsString(),
                    style: const TextStyle(color: Colors.white, fontSize: 11, height: 1.35),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _installDemoErrorWidget();

  final prefs = await SharedPreferences.getInstance();

  // DEMO builds run against the on-device simulated backend so the app can be
  // installed and tested with no server. Live builds talk to the real API.
  final BajGoApi api;
  if (Env.demo) {
    final demo = DemoApi();
    await demo.restore();
    api = demo;
  } else {
    api = HttpApi(tokens: TokenStore(const FlutterSecureStorage()));
  }

  runApp(
    ProviderScope(
      overrides: [
        apiProvider.overrideWithValue(api),
        prefsProvider.overrideWithValue(prefs),
      ],
      child: const BajGoApp(),
    ),
  );
}

class BajGoApp extends ConsumerWidget {
  const BajGoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final prefs = ref.watch(prefsControllerProvider);

    return MaterialApp.router(
      title: 'BajGo',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: BgTheme.light(),
      darkTheme: BgTheme.dark(),
      themeMode: prefs.themeMode,
      locale: Locale(prefs.locale),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
