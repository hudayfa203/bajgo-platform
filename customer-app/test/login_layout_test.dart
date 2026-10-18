import 'package:bajgo_customer/core/theme.dart';
import 'package:bajgo_customer/data/api.dart';
import 'package:bajgo_customer/data/demo_api.dart';
import 'package:bajgo_customer/data/providers.dart';
import 'package:bajgo_customer/features/auth_screens.dart';
import 'package:bajgo_customer/l10n/generated/app_localizations.dart';
import 'package:bajgo_customer/l10n/material_so.dart';
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
  final BajGoApi api = DemoApi();

  return ProviderScope(
    overrides: [
      apiProvider.overrideWithValue(api),
      prefsProvider.overrideWithValue(prefs),
    ],
    child: MaterialApp(
      locale: locale,
      theme: BgTheme.light(),
      darkTheme: BgTheme.dark(),
      themeMode: ThemeMode.dark,
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
  // delegates no MaterialLocalizations resolves, every TextField throws, and
  // a release build paints a grey RenderErrorBox over the login form. These
  // tests fail if that regresses.
  group('Login layout renders without errors', () {
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
          // The +252 prefix and the field are one widget, so the prefix cannot
          // drift away from the input.
          expect(find.text('+252 '), findsOneWidget);
          expect(find.byType(ErrorWidget), findsNothing);
        });

        testWidgets('OTP screen · ${locale.languageCode} · ${entry.key}', (tester) async {
          await _pumpAt(
            tester,
            await _host(
              const OtpScreen(phone: '+252900000001', resendAfter: 30, devCode: '123456'),
              locale: locale,
            ),
            entry.value,
          );

          expect(tester.takeException(), isNull);
          expect(find.byType(TextField), findsOneWidget);
          expect(find.byType(ErrorWidget), findsNothing);
        });

        testWidgets('name screen · ${locale.languageCode} · ${entry.key}', (tester) async {
          await _pumpAt(tester, await _host(const NameScreen(), locale: locale), entry.value);

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

    testWidgets('phone field accepts typing and the field stays visible', (tester) async {
      await _pumpAt(tester, await _host(const PhoneScreen(), locale: const Locale('so')), s24Ultra);

      await tester.enterText(find.byType(TextField), '905000103');
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('905000103'), findsOneWidget);

      // The field must be on screen, not pushed out by anything.
      final box = tester.getRect(find.byType(TextField));
      expect(box.top, greaterThanOrEqualTo(0));
      expect(box.width, greaterThan(100));
      expect(box.height, lessThan(200));
    });

    testWidgets('the OTP field is a single field, not six boxes that can overflow',
        (tester) async {
      await _pumpAt(
        tester,
        await _host(
          const OtpScreen(phone: '+252900000001', devCode: '123456'),
          locale: const Locale('so'),
        ),
        smallPhone,
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(TextField), findsOneWidget);
      final box = tester.getRect(find.byType(TextField));
      expect(box.width, lessThanOrEqualTo(smallPhone.width));
    });
  });
}
