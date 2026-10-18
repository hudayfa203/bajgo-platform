import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/env.dart';
import 'api.dart';
import 'demo_api.dart';
import 'models.dart';

/// Created once in main() so the demo backend can be restored before the first frame.
final apiProvider = Provider<BajGoApi>((ref) {
  throw UnimplementedError('apiProvider must be overridden in main()');
});

final prefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('prefsProvider must be overridden in main()');
});

// ─────────────────────────────────────────────────────────── session

class Session {
  const Session({this.user, this.loading = false});
  final AppUser? user;
  final bool loading;

  bool get signedIn => user != null && !user!.needsName;
  bool get needsName => user != null && user!.needsName;
}

class SessionController extends StateNotifier<Session> {
  SessionController(this._api, this._prefs) : super(const Session()) {
    final api = _api;
    if (api is DemoApi && api.currentUser != null) {
      state = Session(user: api.currentUser);
    }
  }

  final BajGoApi _api;
  final SharedPreferences _prefs;

  static const _kOnboarded = 'onboarded';

  bool get onboarded => _prefs.getBool(_kOnboarded) ?? false;
  Future<void> setOnboarded() => _prefs.setBool(_kOnboarded, true);

  Future<OtpRequestResult> requestOtp(String phone) => _api.requestOtp(phone);

  Future<bool> verifyOtp(String phone, String code) async {
    state = const Session(loading: true);
    try {
      final r = await _api.verifyOtp(phone, code);
      state = Session(user: r.user);
      return r.user.needsName;
    } catch (_) {
      state = const Session();
      rethrow;
    }
  }

  Future<void> setName(String name) async {
    final u = await _api.updateProfile(fullName: name);
    state = Session(user: u);
  }

  Future<void> setLanguage(String code) async {
    if (state.user == null) return;
    final u = await _api.updateProfile(language: code);
    state = Session(user: u);
  }

  Future<void> logout() async {
    await _api.logout();
    state = const Session();
  }
}

final sessionProvider = StateNotifierProvider<SessionController, Session>((ref) {
  return SessionController(ref.watch(apiProvider), ref.watch(prefsProvider));
});

// ─────────────────────────────────────────────────────────── preferences

class AppPrefs {
  const AppPrefs({this.locale = 'so', this.themeMode = ThemeMode.system});
  final String locale;
  final ThemeMode themeMode;

  AppPrefs copyWith({String? locale, ThemeMode? themeMode}) =>
      AppPrefs(locale: locale ?? this.locale, themeMode: themeMode ?? this.themeMode);
}

class PrefsController extends StateNotifier<AppPrefs> {
  PrefsController(this._prefs)
      : super(AppPrefs(
          locale: _prefs.getString(_kLocale) ?? 'so',
          themeMode: _modeFrom(_prefs.getString(_kTheme)),
        ));

  final SharedPreferences _prefs;
  static const _kLocale = 'locale';
  static const _kTheme = 'theme_mode';

  static ThemeMode _modeFrom(String? s) => switch (s) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  Future<void> setLocale(String code) async {
    state = state.copyWith(locale: code);
    await _prefs.setString(_kLocale, code);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _prefs.setString(_kTheme, mode.name);
  }
}

final prefsControllerProvider =
    StateNotifierProvider<PrefsController, AppPrefs>((ref) => PrefsController(ref.watch(prefsProvider)));

// ─────────────────────────────────────────────────────────── location

/// Best-known position. Falls back to Garowe centre when permission is denied
/// or the fix is slow, so the map is never blank.
final locationProvider = StateNotifierProvider<LocationController, LatLng>((ref) {
  return LocationController();
});

class LocationController extends StateNotifier<LatLng> {
  LocationController() : super(const LatLng(Env.defaultLat, Env.defaultLng));

  bool _granted = false;
  bool get granted => _granted;

  Future<bool> ensurePermission() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return false;
      var p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
      _granted = p == LocationPermission.always || p == LocationPermission.whileInUse;
      if (_granted) await refresh();
      return _granted;
    } catch (_) {
      return false;
    }
  }

  Future<void> refresh() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 8));
      state = LatLng(pos.latitude, pos.longitude);
    } catch (_) {
      // Keep the previous/default position.
    }
  }
}

// ─────────────────────────────────────────────────────────── data

final savedPlacesProvider = FutureProvider<List<SavedPlace>>(
    (ref) => ref.watch(apiProvider).savedPlaces());

final nearbyDriversProvider = FutureProvider<List<NearbyDriver>>((ref) {
  final here = ref.watch(locationProvider);
  return ref.watch(apiProvider).nearbyDrivers(here);
});

final paymentMethodsProvider =
    FutureProvider<List<PaymentMethodInfo>>((ref) => ref.watch(apiProvider).paymentMethods());

final bookingHistoryProvider =
    FutureProvider<List<Booking>>((ref) => ref.watch(apiProvider).bookings());

final activeBookingsProvider =
    FutureProvider<List<Booking>>((ref) => ref.watch(apiProvider).bookings(activeOnly: true));

final notificationsProvider =
    FutureProvider<List<AppNotification>>((ref) => ref.watch(apiProvider).notifications());

final ticketsProvider =
    FutureProvider<List<SupportTicket>>((ref) => ref.watch(apiProvider).tickets());

/// Live stream of one booking, used by the tracking screen.
final bookingStreamProvider =
    StreamProvider.autoDispose.family<Booking, String>((ref, id) {
  return ref.watch(apiProvider).watchBooking(id);
});

// ─────────────────────────────────────────────────────────── booking draft

/// What the person is currently building, shared across the booking screens.
class BookingDraft {
  const BookingDraft({
    this.service = ServiceType.ride,
    this.pickup,
    this.dropoff,
    this.quote,
    this.delivery,
    this.paymentMethod = 'cash',
    this.promoCode,
  });

  final ServiceType service;
  final Place? pickup;
  final Place? dropoff;
  final Quote? quote;
  final DeliveryDetails? delivery;
  final String paymentMethod;
  final String? promoCode;

  bool get ready => pickup != null && dropoff != null;

  BookingDraft copyWith({
    ServiceType? service,
    Place? pickup,
    Place? dropoff,
    Quote? quote,
    DeliveryDetails? delivery,
    String? paymentMethod,
    String? promoCode,
    bool clearQuote = false,
  }) {
    return BookingDraft(
      service: service ?? this.service,
      pickup: pickup ?? this.pickup,
      dropoff: dropoff ?? this.dropoff,
      quote: clearQuote ? null : (quote ?? this.quote),
      delivery: delivery ?? this.delivery,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      promoCode: promoCode ?? this.promoCode,
    );
  }
}

class BookingDraftController extends StateNotifier<BookingDraft> {
  BookingDraftController(this._api, this._ref) : super(const BookingDraft());

  final BajGoApi _api;
  final Ref _ref;

  void start(ServiceType service) {
    final here = _ref.read(locationProvider);
    state = BookingDraft(
      service: service,
      pickup: Place(location: here, label: null),
    );
  }

  void setPickup(Place p) => state = state.copyWith(pickup: p, clearQuote: true);
  void setDropoff(Place p) => state = state.copyWith(dropoff: p, clearQuote: true);
  void setDelivery(DeliveryDetails d) => state = state.copyWith(delivery: d, clearQuote: true);
  void setPaymentMethod(String m) => state = state.copyWith(paymentMethod: m);
  void setPromo(String? code) => state = state.copyWith(promoCode: code, clearQuote: true);
  void reset() => state = const BookingDraft();

  Future<Quote> fetchQuote() async {
    final s = state;
    if (s.pickup == null || s.dropoff == null) {
      throw ApiException('INCOMPLETE', 'Pickup and drop-off are required');
    }
    final q = await _api.quote(
      service: s.service,
      pickup: s.pickup!,
      dropoff: s.dropoff!,
      deliveryCategory: s.delivery?.category,
      packageSize: s.delivery?.size,
      promoCode: s.promoCode,
    );
    state = s.copyWith(quote: q);
    return q;
  }

  Future<Booking> confirm() async {
    final s = state;
    final q = s.quote;
    if (q == null) throw ApiException('NO_QUOTE', 'Get a fare first');
    final booking = await _api.createBooking(
      quote: q,
      paymentMethod: s.paymentMethod,
      delivery: s.delivery,
    );
    _ref.invalidate(activeBookingsProvider);
    _ref.invalidate(bookingHistoryProvider);
    return booking;
  }
}

final bookingDraftProvider =
    StateNotifierProvider<BookingDraftController, BookingDraft>((ref) {
  return BookingDraftController(ref.watch(apiProvider), ref);
});
