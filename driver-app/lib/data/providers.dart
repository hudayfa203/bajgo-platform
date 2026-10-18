import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/env.dart';
import 'api.dart';
import 'models.dart';

/// Both are overridden in `main()` once the real instances exist.
final apiProvider = Provider<DriverApi>((ref) => throw UnimplementedError());
final prefsProvider = Provider<SharedPreferences>((ref) => throw UnimplementedError());

// ─────────────────────────────────────────────────────────── session

class SessionState {
  const SessionState({
    this.profile,
    this.phone,
    this.signedIn = false,
    this.busy = false,
  });

  /// Null while signed in but not yet registered → the registration wizard.
  final DriverProfile? profile;
  final String? phone;
  final bool signedIn;
  final bool busy;

  bool get needsRegistration => signedIn && profile == null;
  bool get approved => profile?.isApproved ?? false;

  SessionState copyWith({
    DriverProfile? profile,
    String? phone,
    bool? signedIn,
    bool? busy,
    bool clearProfile = false,
  }) =>
      SessionState(
        profile: clearProfile ? null : (profile ?? this.profile),
        phone: phone ?? this.phone,
        signedIn: signedIn ?? this.signedIn,
        busy: busy ?? this.busy,
      );
}

class SessionController extends StateNotifier<SessionState> {
  SessionController(this._api, this._prefs) : super(const SessionState()) {
    _bootstrap();
  }

  final DriverApi _api;
  final SharedPreferences _prefs;

  static const _kSignedIn = 'drv_signed_in';
  static const _kPhone = 'drv_phone';

  Future<void> _bootstrap() async {
    if (!(_prefs.getBool(_kSignedIn) ?? false)) return;
    final phone = _prefs.getString(_kPhone);
    state = state.copyWith(signedIn: true, phone: phone, busy: true);
    try {
      final me = await _api.me();
      state = state.copyWith(profile: me, busy: false);
    } on ApiException {
      state = state.copyWith(busy: false); // registered? no → wizard
    } catch (_) {
      state = state.copyWith(busy: false);
    }
  }

  Future<OtpRequest> requestOtp(String phone) {
    state = state.copyWith(phone: phone);
    return _api.requestOtp(phone);
  }

  /// Returns true when the driver already has a profile.
  Future<bool> verifyOtp(String code) async {
    final phone = state.phone;
    if (phone == null) throw ApiException('NO_PHONE', 'Enter your number first');
    state = state.copyWith(busy: true);
    try {
      final profile = await _api.verifyOtp(phone, code);
      await _prefs.setBool(_kSignedIn, true);
      await _prefs.setString(_kPhone, phone);
      state = SessionState(profile: profile, phone: phone, signedIn: true);
      return profile != null;
    } finally {
      if (state.busy) state = state.copyWith(busy: false);
    }
  }

  Future<void> register({
    required String fullName,
    required Vehicle vehicle,
    String? emergencyName,
    String? emergencyPhone,
    String? payoutMethod,
    String? payoutAccount,
  }) async {
    state = state.copyWith(busy: true);
    try {
      final p = await _api.register(
        fullName: fullName,
        vehicle: vehicle,
        emergencyName: emergencyName,
        emergencyPhone: emergencyPhone,
        payoutMethod: payoutMethod,
        payoutAccount: payoutAccount,
      );
      state = state.copyWith(profile: p, busy: false);
    } catch (_) {
      state = state.copyWith(busy: false);
      rethrow;
    }
  }

  Future<void> refresh() async {
    try {
      state = state.copyWith(profile: await _api.me());
    } catch (_) {
      // keep the current profile
    }
  }

  Future<void> uploadDocument(String type, String path) async {
    state = state.copyWith(profile: await _api.uploadDocument(type, path));
  }

  Future<void> setOnline(bool online) async {
    state = state.copyWith(profile: await _api.setAvailability(online));
  }

  Future<void> setServices({bool? rides, bool? deliveries}) async {
    state = state.copyWith(
        profile: await _api.setServicePreferences(rides: rides, deliveries: deliveries));
  }

  /// Keeps the dashboard honest while a trip is running.
  void markAvailability(Availability a) {
    final p = state.profile;
    if (p != null) state = state.copyWith(profile: p.copyWith(availability: a));
  }

  Future<void> logout() async {
    await _api.logout();
    await _prefs.remove(_kSignedIn);
    await _prefs.remove(_kPhone);
    state = const SessionState();
  }
}

final sessionProvider = StateNotifierProvider<SessionController, SessionState>(
  (ref) => SessionController(ref.watch(apiProvider), ref.watch(prefsProvider)),
);

// ─────────────────────────────────────────────────────────── locale

class LocaleController extends StateNotifier<Locale> {
  LocaleController(this._prefs) : super(Locale(_prefs.getString(_k) ?? 'so'));

  final SharedPreferences _prefs;
  static const _k = 'drv_locale';

  Future<void> set(String code) async {
    await _prefs.setString(_k, code);
    state = Locale(code);
  }
}

final localeProvider = StateNotifierProvider<LocaleController, Locale>(
  (ref) => LocaleController(ref.watch(prefsProvider)),
);

// ─────────────────────────────────────────────────────────── dispatch

/// The offer currently on screen; null when there is none.
final offerProvider = StreamProvider<Offer?>((ref) => ref.watch(apiProvider).offers());

/// The trip in progress; null when free.
final activeTripProvider = StreamProvider<Trip?>((ref) => ref.watch(apiProvider).activeTrip());

// ─────────────────────────────────────────────────────────── money & lists

final earningsProvider = FutureProvider.family<Earnings, String>(
  (ref, period) => ref.watch(apiProvider).earnings(period),
);

final walletProvider = FutureProvider<Wallet>((ref) => ref.watch(apiProvider).wallet());

final historyProvider = FutureProvider<List<Trip>>((ref) => ref.watch(apiProvider).history());

final payoutsProvider = FutureProvider<List<Payout>>((ref) => ref.watch(apiProvider).payouts());

final notificationsProvider =
    FutureProvider<List<DriverNotification>>((ref) => ref.watch(apiProvider).notifications());

/// History filter on the trips screen: all | rides | deliveries.
final historyFilterProvider = StateProvider<String>((ref) => 'all');

/// Selected period on the earnings screen.
final earningsPeriodProvider = StateProvider<String>((ref) => 'today');

// ─────────────────────────────────────────────────────────── location

class LocationState {
  const LocationState({this.position, this.denied = false, this.serviceOff = false});
  final LatLng? position;
  final bool denied;
  final bool serviceOff;
}

/// Device position, pushed to the API every [_intervalSeconds] while online.
///
/// Uses the foreground location stream only: no background service is bundled,
/// so tracking runs while the app is in the foreground. Continuous background
/// tracking is a follow-up that needs a foreground-service implementation.
class LocationController extends StateNotifier<LocationState> {
  LocationController(this._api) : super(const LocationState());

  final DriverApi _api;
  StreamSubscription<Position>? _sub;
  Timer? _ticker;
  static const int intervalSeconds = 10;

  Future<bool> ensurePermission() async {
    if (kIsWeb) return false;
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        state = LocationState(position: state.position, serviceOff: true);
        return false;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      final ok = perm == LocationPermission.always || perm == LocationPermission.whileInUse;
      state = LocationState(position: state.position, denied: !ok);
      return ok;
    } catch (_) {
      return false;
    }
  }

  Future<void> start() async {
    if (_sub != null) return;
    if (!await ensurePermission()) return;
    _sub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((p) {
      state = LocationState(position: LatLng(p.latitude, p.longitude));
    }, onError: (_) {});

    _ticker = Timer.periodic(const Duration(seconds: intervalSeconds), (_) {
      final at = state.position;
      if (at != null) _api.sendLocation(at);
    });
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
    _ticker?.cancel();
    _ticker = null;
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}

final locationProvider = StateNotifierProvider<LocationController, LocationState>(
  (ref) => LocationController(ref.watch(apiProvider)),
);

/// Convenience for the map: the driver's position, or the Garowe centre.
final mapCentreProvider = Provider<LatLng>((ref) =>
    ref.watch(locationProvider).position ?? const LatLng(8.4064, 48.4847));

/// True when this build talks to the on-device simulator rather than a server.
final isDemoProvider = Provider<bool>((ref) => Env.useMock);
