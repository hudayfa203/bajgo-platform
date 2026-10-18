import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';

import '../core/env.dart';
import 'models.dart';

class ApiException implements Exception {
  ApiException(this.code, this.message);
  final String code;
  final String message;
  @override
  String toString() => '$code: $message';
}

class OtpRequest {
  const OtpRequest({required this.resendAfter, this.devCode});
  final int resendAfter;
  final String? devCode;
}

/// Contract shared by the live client and the on-device simulator.
abstract class DriverApi {
  Future<OtpRequest> requestOtp(String phone);

  /// Returns the profile, or null when this phone has not registered yet.
  Future<DriverProfile?> verifyOtp(String phone, String code);

  Future<DriverProfile> register({
    required String fullName,
    required Vehicle vehicle,
    String? emergencyName,
    String? emergencyPhone,
    String? payoutMethod,
    String? payoutAccount,
  });

  Future<DriverProfile> me();
  Future<DriverProfile> uploadDocument(String type, String filePath);
  Future<DriverProfile> setAvailability(bool online);
  Future<DriverProfile> setServicePreferences({bool? rides, bool? deliveries});
  Future<void> sendLocation(LatLng at, {double? heading, double? speedKmh});

  /// Offers pushed by the dispatcher. Null means the current offer was withdrawn.
  Stream<Offer?> offers();

  Future<Trip> acceptOffer(String offerId);
  Future<void> declineOffer(String offerId, {String? reason});

  /// The trip currently in progress, if any.
  Stream<Trip?> activeTrip();
  Future<Trip> transition(String tripId, TripStatus to, {String? proofPhotoPath});
  Future<Trip> verifyRecipient(String tripId, String code);
  Future<Trip> collectCash(String tripId, int amountCents);
  Future<Trip> failDelivery(String tripId, String reason, {String? note});
  Future<Trip> cancelTrip(String tripId, String reason);
  Future<void> rateCustomer(String tripId, int score, {String? comment});

  Future<Earnings> earnings(String period);
  Future<Wallet> wallet();
  Future<List<Trip>> history();
  Future<List<Payout>> payouts();
  Future<Payout> requestPayout(int amountCents);
  Future<List<DriverNotification>> notifications();

  Future<void> logout();
  void dispose();
}

class TokenStore {
  TokenStore(this._storage);
  final FlutterSecureStorage _storage;

  Future<String?> get access => _storage.read(key: 'bg_drv_access');
  Future<String?> get refresh => _storage.read(key: 'bg_drv_refresh');

  Future<void> save(String a, String r) async {
    await _storage.write(key: 'bg_drv_access', value: a);
    await _storage.write(key: 'bg_drv_refresh', value: r);
  }

  Future<void> clear() async {
    await _storage.delete(key: 'bg_drv_access');
    await _storage.delete(key: 'bg_drv_refresh');
  }
}

/// Live backend client (used when the app is built with DEMO=false).
class HttpDriverApi implements DriverApi {
  HttpDriverApi({required TokenStore tokens, Dio? dio})
      : _tokens = tokens,
        _dio = dio ??
            Dio(BaseOptions(
              baseUrl: Env.apiBaseUrl,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 20),
            )) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _tokens.access;
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
        final m = options.method.toUpperCase();
        if (m == 'POST' || m == 'PATCH') {
          options.headers.putIfAbsent('Idempotency-Key', () => const Uuid().v4());
        }
        handler.next(options);
      },
    ));
  }

  final Dio _dio;
  final TokenStore _tokens;

  Never _fail(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['error'] is Map) {
        final err = data['error'] as Map;
        throw ApiException(err['code'] as String? ?? 'ERROR', err['message'] as String? ?? '');
      }
      throw ApiException('NETWORK', e.message ?? 'Network error');
    }
    throw ApiException('UNKNOWN', e.toString());
  }

  Future<Map<String, dynamic>> _get(String p, {Map<String, dynamic>? q}) async {
    try {
      final r = await _dio.get<Map<String, dynamic>>(p, queryParameters: q);
      return r.data ?? <String, dynamic>{};
    } catch (e) {
      _fail(e);
    }
  }

  Future<Map<String, dynamic>> _post(String p, {Object? data}) async {
    try {
      final r = await _dio.post<Map<String, dynamic>>(p, data: data);
      return r.data ?? <String, dynamic>{};
    } catch (e) {
      _fail(e);
    }
  }

  @override
  Future<OtpRequest> requestOtp(String phone) async {
    final d = await _post('/auth/otp/request',
        data: {'phone': phone, 'purpose': 'login', 'role': 'driver'});
    return OtpRequest(
      resendAfter: (d['resend_after'] as num?)?.toInt() ?? 45,
      devCode: d['dev_code'] as String?,
    );
  }

  @override
  Future<DriverProfile?> verifyOtp(String phone, String code) async {
    final d = await _post('/auth/otp/verify', data: {
      'phone': phone,
      'code': code,
      'device': {'platform': 'android', 'app_version': Env.appVersion},
    });
    await _tokens.save(d['access_token'] as String, d['refresh_token'] as String);
    if (d['is_new'] as bool? ?? false) return null;
    return me();
  }

  @override
  Future<DriverProfile> register({
    required String fullName,
    required Vehicle vehicle,
    String? emergencyName,
    String? emergencyPhone,
    String? payoutMethod,
    String? payoutAccount,
  }) async {
    await _post('/driver/register', data: {
      'full_name': fullName,
      'vehicle': vehicle.toJson(),
      'emergency_contact': {'name': emergencyName, 'phone': emergencyPhone},
      'payout': {'method': payoutMethod, 'account': payoutAccount},
    });
    return me();
  }

  @override
  Future<DriverProfile> me() async => DriverProfile.fromJson(await _get('/driver/me'));

  @override
  Future<DriverProfile> uploadDocument(String type, String filePath) async {
    try {
      final form = FormData.fromMap({
        'type': type,
        'file': await MultipartFile.fromFile(filePath),
      });
      await _dio.post<dynamic>('/driver/documents', data: form);
      return me();
    } catch (e) {
      _fail(e);
    }
  }

  @override
  Future<DriverProfile> setAvailability(bool online) async {
    await _post('/driver/availability', data: {'online': online});
    return me();
  }

  @override
  Future<DriverProfile> setServicePreferences({bool? rides, bool? deliveries}) async {
    await _dio.patch<dynamic>('/driver/me', data: {
      if (rides != null) 'accepts_rides': rides,
      if (deliveries != null) 'accepts_deliveries': deliveries,
    });
    return me();
  }

  @override
  Future<void> sendLocation(LatLng at, {double? heading, double? speedKmh}) async {
    try {
      await _dio.post<dynamic>('/driver/location', data: {
        'lat': at.latitude,
        'lng': at.longitude,
        'heading': heading,
        'speed_kmh': speedKmh,
        'recorded_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (_) {
      // Location updates are best-effort; the queue retries on the next tick.
    }
  }

  @override
  Stream<Offer?> offers() async* {
    while (true) {
      await Future<void>.delayed(const Duration(seconds: 4));
      try {
        final d = await _get('/driver/offers');
        final list = (d['data'] ?? const <dynamic>[]) as List;
        yield list.isEmpty
            ? null
            : Offer.fromJson(list.first as Map<String, dynamic>);
      } catch (_) {
        yield null;
      }
    }
  }

  @override
  Future<Trip> acceptOffer(String offerId) async =>
      Trip.fromJson(await _post('/driver/offers/$offerId/accept'));

  @override
  Future<void> declineOffer(String offerId, {String? reason}) async {
    await _post('/driver/offers/$offerId/reject', data: {'reason': reason});
  }

  @override
  Stream<Trip?> activeTrip() async* {
    while (true) {
      await Future<void>.delayed(const Duration(seconds: 3));
      try {
        final d = await _get('/driver/bookings', q: {'status': 'active'});
        final list = (d['data'] ?? const <dynamic>[]) as List;
        yield list.isEmpty ? null : Trip.fromJson(list.first as Map<String, dynamic>);
      } catch (_) {
        yield null;
      }
    }
  }

  @override
  Future<Trip> transition(String tripId, TripStatus to, {String? proofPhotoPath}) async =>
      Trip.fromJson(await _post('/driver/bookings/$tripId/transition',
          data: {'to': tripStatusToString(to), 'proof_photo_url': proofPhotoPath}));

  @override
  Future<Trip> verifyRecipient(String tripId, String code) async =>
      Trip.fromJson(await _post('/driver/bookings/$tripId/verify-recipient', data: {'code': code}));

  @override
  Future<Trip> collectCash(String tripId, int amountCents) async => Trip.fromJson(
      await _post('/driver/bookings/$tripId/collect-cash', data: {'amount_cents': amountCents}));

  @override
  Future<Trip> failDelivery(String tripId, String reason, {String? note}) async => Trip.fromJson(
      await _post('/driver/bookings/$tripId/fail', data: {'reason': reason, 'note': note}));

  @override
  Future<Trip> cancelTrip(String tripId, String reason) async =>
      Trip.fromJson(await _post('/driver/bookings/$tripId/cancel', data: {'reason': reason}));

  @override
  Future<void> rateCustomer(String tripId, int score, {String? comment}) async {
    await _post('/driver/bookings/$tripId/rate', data: {'score': score, 'comment': comment});
  }

  @override
  Future<Earnings> earnings(String period) async =>
      Earnings.fromJson(await _get('/driver/earnings', q: {'period': period}));

  @override
  Future<Wallet> wallet() async {
    final d = await _get('/driver/wallet');
    return Wallet(
      balanceCents: (d['balance_cents'] as num?)?.toInt() ?? 0,
      commissionDueCents: (d['commission_due_cents'] as num?)?.toInt() ?? 0,
      cashCollectedCents: (d['cash_collected_cents'] as num?)?.toInt() ?? 0,
      paidOutCents: (d['paid_out_cents'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  Future<List<Trip>> history() async {
    final d = await _get('/driver/bookings', q: {'status': 'history'});
    return ((d['data'] ?? const <dynamic>[]) as List)
        .whereType<Map<String, dynamic>>()
        .map(Trip.fromJson)
        .toList();
  }

  @override
  Future<List<Payout>> payouts() async {
    final d = await _get('/driver/payouts');
    return ((d['data'] ?? const <dynamic>[]) as List)
        .whereType<Map<String, dynamic>>()
        .map((e) => Payout(
              id: e['id'] as String,
              amountCents: (e['amount_cents'] as num?)?.toInt() ?? 0,
              status: e['status'] as String? ?? 'requested',
              requestedAt: DateTime.tryParse(e['requested_at'] as String? ?? '') ?? DateTime.now(),
              method: e['method'] as String?,
            ))
        .toList();
  }

  @override
  Future<Payout> requestPayout(int amountCents) async {
    final d = await _post('/driver/payouts', data: {'amount_cents': amountCents});
    return Payout(
      id: d['id'] as String? ?? '',
      amountCents: amountCents,
      status: d['status'] as String? ?? 'requested',
      requestedAt: DateTime.now(),
    );
  }

  @override
  Future<List<DriverNotification>> notifications() async {
    final d = await _get('/me/notifications');
    return ((d['data'] ?? const <dynamic>[]) as List)
        .whereType<Map<String, dynamic>>()
        .map((e) => DriverNotification(
              id: e['id'] as String,
              title: e['title'] as String? ?? 'BajGo',
              body: e['body'] as String? ?? '',
              at: DateTime.tryParse(e['created_at'] as String? ?? '') ?? DateTime.now(),
            ))
        .toList();
  }

  @override
  Future<void> logout() async {
    try {
      await _post('/auth/logout');
    } catch (_) {/* best effort */}
    await _tokens.clear();
  }

  @override
  void dispose() => _dio.close(force: true);
}
