import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/env.dart';
import 'core/router.dart';
import 'core/theme/bg_theme.dart';
import 'data/api.dart';
import 'data/mock_api.dart';
import 'data/providers.dart';
import 'l10n/generated/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  final prefs = await SharedPreferences.getInstance();

  // A demo build runs entirely on the device: no server, nothing real.
  final DriverApi api;
  if (Env.useMock) {
    final mock = MockDriverApi();
    await mock.restore();
    api = mock;
  } else {
    api = HttpDriverApi(tokens: TokenStore(const FlutterSecureStorage()));
  }

  runApp(ProviderScope(
    overrides: [
      apiProvider.overrideWithValue(api),
      prefsProvider.overrideWithValue(prefs),
    ],
    child: const BajGoDriverApp(),
  ));
}

class BajGoDriverApp extends ConsumerWidget {
  const BajGoDriverApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'BajGo Driver',
      debugShowCheckedModeBanner: false,
      theme: buildDriverTheme(),
      darkTheme: buildDriverTheme(),
      themeMode: ThemeMode.dark,
      routerConfig: router,
      locale: locale,
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
