import 'package:bajgo_driver/core/theme/bg_theme.dart';
import 'package:bajgo_driver/data/api.dart';
import 'package:bajgo_driver/data/mock_api.dart';
import 'package:bajgo_driver/data/providers.dart';
import 'package:bajgo_driver/features/auth_screens.dart';
import 'package:bajgo_driver/l10n/generated/app_localizations.dart';
import 'package:bajgo_driver/l10n/material_so.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Samsung Galaxy S24 Ultra: 1440x3120 physical at 3.5x.
const Size s24Ultra = Size(411.4, 891.4);
const Size smallPhone = Size(320, 568);
const Size tablet = Size(834, 1112);

Future<Widget> _host(Widget screen, {required Locale locale, double textScale = 1.0}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final prefs = await SharedPreferences.getInstance();
  final DriverApi api = MockDriverApi();

  return ProviderScope(
    overrides: [
      apiProvider.overrideWithValue(api),
      prefsProvider.overrideWithValue(prefs),
    ],
    child: MaterialApp(
      locale: locale,
      theme: buildDriverTheme(),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        ...bajgoLocalizationsDelegates,
      ],
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: screen,
    ),
  );
}

Future<void> _pumpAt(WidgetTester tester, Widget app, Size size) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(app);
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  // Somali is not a locale flutter_localizations ships. Without the fallback
  // delegates no MaterialLocalizations resolves, every TextField throws, and a
  // release build paints a grey RenderErrorBox over the login form.
  group('Driver login layout renders without errors', () {
    for (final locale in [const Locale('so'), const Locale('en')]) {
      for (final entry in {
        'Galaxy S24 Ultra': s24Ultra,
        'small phone': smallPhone,
        'tablet': tablet,
      }.entries) {
        testWidgets('phone screen · ${locale.languageCode} · ${entry.key}', (tester) async {
          await _pumpAt(tester, await _host(const PhoneScreen(), locale: locale), entry.value);

          expect(tester.takeException(), isNull);
          expect(find.byType(TextField), findsOneWidget);
          expect(find.byType(ErrorWidget), findsNothing);
        });

        testWidgets('OTP screen · ${locale.languageCode} · ${entry.key}', (tester) async {
          await _pumpAt(tester, await _host(const OtpScreen(), locale: locale), entry.value);

          expect(tester.takeException(), isNull);
          expect(find.byType(TextField), findsOneWidget);
          expect(find.byType(ErrorWidget), findsNothing);
        });
      }
    }

    testWidgets('phone screen survives 1.5x text scaling', (tester) async {
      await _pumpAt(
        tester,
        await _host(const PhoneScreen(), locale: const Locale('so'), textScale: 1.5),
        s24Ultra,
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(ErrorWidget), findsNothing);
    });

    testWidgets('the driver can type a number', (tester) async {
      await _pumpAt(tester, await _host(const PhoneScreen(), locale: const Locale('so')), s24Ultra);

      await tester.enterText(find.byType(TextField), '905000103');
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('905000103'), findsOneWidget);
    });
  });

  group('Demo driver account', () {
    test('verifying the demo code signs in to an approved driver', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final api = MockDriverApi();
      await api.requestOtp('+252905000103');

      final profile = await api.verifyOtp('+252905000103', '123456');

      expect(profile, isNotNull);
      expect(profile!.isApproved, isTrue,
          reason: 'a demo driver must reach the dashboard without admin approval');
      expect(profile.vehicle.plateNumber, isNotEmpty);
      api.dispose();
    });

    test('a wrong code is rejected', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final api = MockDriverApi();
      await expectLater(
        api.verifyOtp('+252905000103', '000000'),
        throwsA(isA<ApiException>()),
      );
      api.dispose();
    });
  });
}
