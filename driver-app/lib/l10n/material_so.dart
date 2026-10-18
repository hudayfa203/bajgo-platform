import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Somali ('so') is not one of the locales flutter_localizations ships.
///
/// Without this, `Localizations` resolves no [MaterialLocalizations] for a
/// Somali locale: GlobalMaterialLocalizations reports it unsupported and
/// DefaultMaterialLocalizations only supports English. Every widget that looks
/// one up — a TextField above all — then throws, and a release build paints
/// Flutter's grey RenderErrorBox over it. That is what covered the login form.
///
/// These delegates claim Somali and serve the English strings, so widget
/// chrome (the text-selection menu, tooltips, date pickers) is in English
/// while the app's own copy stays Somali through AppLocalizations.
class SoMaterialLocalizationsDelegate extends LocalizationsDelegate<MaterialLocalizations> {
  const SoMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'so';

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      GlobalMaterialLocalizations.delegate.load(const Locale('en'));

  @override
  bool shouldReload(SoMaterialLocalizationsDelegate old) => false;
}

class SoCupertinoLocalizationsDelegate extends LocalizationsDelegate<CupertinoLocalizations> {
  const SoCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'so';

  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      GlobalCupertinoLocalizations.delegate.load(const Locale('en'));

  @override
  bool shouldReload(SoCupertinoLocalizationsDelegate old) => false;
}

class SoWidgetsLocalizationsDelegate extends LocalizationsDelegate<WidgetsLocalizations> {
  const SoWidgetsLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'so';

  @override
  Future<WidgetsLocalizations> load(Locale locale) =>
      GlobalWidgetsLocalizations.delegate.load(const Locale('en'));

  @override
  bool shouldReload(SoWidgetsLocalizationsDelegate old) => false;
}

/// The full delegate list every BajGo app uses.
const List<LocalizationsDelegate<dynamic>> bajgoLocalizationsDelegates =
    <LocalizationsDelegate<dynamic>>[
  SoMaterialLocalizationsDelegate(),
  SoCupertinoLocalizationsDelegate(),
  SoWidgetsLocalizationsDelegate(),
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];
