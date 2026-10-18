import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';

import '../core/env.dart';
import 'models.dart';

/// Thrown for any API-level failure the UI should show to the person.
class ApiException implements Exception {
  ApiException(this.code, this.message);
  final String code;
  final String message;
  @override
  String toString() => '$code: $message';
}

/// The contract both the live backend client and the on-device demo backend implement.
/// Keeping the UI behind this interface is what lets the demo APK run with no server.
abstract class BajGoApi {
  Future<OtpRequestResult> requestOtp(String phone);
  Future<AuthResult> verifyOtp(String phone, String code);
  Future<AppUser> updateProfile({String? fullName, String? language});
  Future<void> logout();

  Future<List<SavedPlace>> savedPlaces();
  Future<SavedPlace> addSavedPlace(SavedPlace place);
  Future<void> deleteSavedPlace(String id);

  Future<List<Place>> searchPlaces(String query, LatLng near);
  Future<List<NearbyDriver>> nearbyDrivers(LatLng near);

  Future<Quote> quote({
    required ServiceType service,
    required Place pickup,
    required Place dropoff,
    String? deliveryCategory,
    String? packageSize,
    String? promoCode,
  });

  Future<Booking> createBooking({
    required Quote quote,
    required String paymentMethod,
    DeliveryDetails? delivery,
  });

  /// Emits the booking every time anything changes (status, driver position, ETA).
  Stream<Booking> watchBooking(String bookingId);

  Future<Booking> getBooking(String id);
  Future<List<Booking>> bookings({bool activeOnly = false});
  Future<Booking> cancelBooking(String id, String reason);
  Future<Booking> rateBooking(String id, int score, {List<String> tags, String? comment, int tipCents});
  Future<String> shareBooking(String id);
  Future<void> sos(String bookingId, LatLng at);

  Future<List<PaymentMethodInfo>> paymentMethods();
  Future<List<AppNotification>> notifications();

  Future<List<SupportTicket>> tickets();
  Future<SupportTicket> createTicket(String subject, String category, String message);
  Future<SupportTicket> replyTicket(String ticketId, String message);

  void dispose();
}

class OtpRequestResult {
  const OtpRequestResult({required this.resendAfter, this.devCode});
  final int resendAfter;
  final String? devCode;
}

class AuthResult {
  const AuthResult({required this.user, required this.isNew});
  final AppUser user;
  final bool isNew;
}

/// Token storage shared by the live client.
class TokenStore {
  TokenStore(this._storage);
  final FlutterSecureStorage _storage;

  static const _kAccess = 'bg_access';
  static const _kRefresh = 'bg_refresh';

  Future<String?> get access => _storage.read(key: _kAccess);
  Future<String?> get refresh => _storage.read(key: _kRefresh);

  Future<void> save(String access, String refresh) async {
    await _storage.write(key: _kAccess, value: access);
    await _storage.write(key: _kRefresh, value: refresh);
  }

  Future<void> clear() async {
    await _storage.delete(key: _kAccess);
    await _storage.delete(key: _kRefresh);
  }
}

/// Live backend client. Used when the app is built with DEMO=false and an API_BASE_URL.
class HttpApi implements BajGoApi {
  HttpApi({required TokenStore tokens, Dio? dio})
      : _tokens = tokens,
        _dio = dio ?? Dio(BaseOptions(baseUrl: Env.apiBaseUrl, connectTimeout: const Duration(seconds: 15), receiveTimeout: const Duration(seconds: 20))) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _tokens.access;
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
        options.headers['Accept-Language'] = _language;
        final m = options.method.toUpperCase();
        if (m == 'POST' || m == 'PATCH' || m == 'PUT') {
          options.headers.putIfAbsent('Idempotency-Key', () => const Uuid().v4());
        }
        handler.next(options);
      },
      onError: (e, handler) async {
        if (e.response?.statusCode == 401) {
          final refreshed = await _refresh();
          if (refreshed) {
            try {
              final clone = await _dio.fetch<dynamic>(e.requestOptions);
              return handler.resolve(clone);
            } catch (_) {/* fall through to the original error */}
          }
        }
        handler.next(e);
      },
    ));
  }

  final Dio _dio;
  final TokenStore _tokens;
  String _language = 'so';

  set language(String v) => _language = v;

  Future<bool> _refresh() async {
    final r = await _tokens.refresh;
    if (r == null) return false;
    try {
      final res = await Dio(BaseOptions(baseUrl: Env.apiBaseUrl))
          .post<Map<String, dynamic>>('/auth/refresh', data: {'refresh_token': r});
      final d = res.data!;
      await _tokens.save(d['access_token'] as String, d['refresh_token'] as String);
      return true;
    } catch (_) {
      await _tokens.clear();
      return false;
    }
  }

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

  Future<Map<String, dynamic>> _get(String path, {Map<String, dynamic>? query}) async {
    try {
      final r = await _dio.get<Map<String, dynamic>>(path, queryParameters: query);
      return r.data ?? <String, dynamic>{};
    } catch (e) {
      _fail(e);
    }
  }

  Future<Map<String, dynamic>> _post(String path, {Object? data}) async {
    try {
      final r = await _dio.post<Map<String, dynamic>>(path, data: data);
      return r.data ?? <String, dynamic>{};
    } catch (e) {
      _fail(e);
    }
  }

  @override
  Future<OtpRequestResult> requestOtp(String phone) async {
    final d = await _post('/auth/otp/request',
        data: {'phone': phone, 'purpose': 'login', 'role': 'customer'});
    return OtpRequestResult(
      resendAfter: (d['resend_after'] as num?)?.toInt() ?? 45,
      devCode: d['dev_code'] as String?,
    );
  }

  @override
  Future<AuthResult> verifyOtp(String phone, String code) async {
    final d = await _post('/auth/otp/verify', data: {
      'phone': phone,
      'code': code,
      'device': {'platform': 'android', 'app_version': Env.appVersion},
    });
    await _tokens.save(d['access_token'] as String, d['refresh_token'] as String);
    return AuthResult(
      user: AppUser.fromJson(d['user'] as Map<String, dynamic>),
      isNew: d['is_new'] as bool? ?? false,
    );
  }

  @override
  Future<AppUser> updateProfile({String? fullName, String? language}) async {
    final d = await _dio.patch<Map<String, dynamic>>('/me', data: {
      if (fullName != null) 'full_name': fullName,
      if (language != null) 'language': language,
    });
    return AppUser.fromJson(d.data!);
  }

  @override
  Future<void> logout() async {
    try {
      await _post('/auth/logout', data: {'all_devices': false});
    } catch (_) {/* best effort */}
    await _tokens.clear();
  }

  @override
  Future<List<SavedPlace>> savedPlaces() async {
    final d = await _get('/me/places');
    return ((d['data'] ?? const <dynamic>[]) as List)
        .whereType<Map<String, dynamic>>()
        .map(SavedPlace.fromJson)
        .toList();
  }

  @override
  Future<SavedPlace> addSavedPlace(SavedPlace place) async =>
      SavedPlace.fromJson(await _post('/me/places', data: place.toJson()));

  @override
  Future<void> deleteSavedPlace(String id) async {
    await _dio.delete<dynamic>('/me/places/$id');
  }

  @override
  Future<List<Place>> searchPlaces(String query, LatLng near) async {
    final d = await _get('/geo/search',
        query: {'q': query, 'near': '${near.latitude},${near.longitude}'});
    return ((d['data'] ?? const <dynamic>[]) as List)
        .whereType<Map<String, dynamic>>()
        .map(Place.fromJson)
        .toList();
  }

  @override
  Future<List<NearbyDriver>> nearbyDrivers(LatLng near) async {
    final d = await _get('/geo/nearby-drivers',
        query: {'lat': near.latitude, 'lng': near.longitude});
    return ((d['data'] ?? const <dynamic>[]) as List)
        .whereType<Map<String, dynamic>>()
        .map((e) => NearbyDriver(
              location: LatLng(
                ((e['location']?['lat'] ?? 0) as num).toDouble(),
                ((e['location']?['lng'] ?? 0) as num).toDouble(),
              ),
              heading: ((e['heading'] ?? 0) as num).toDouble(),
            ))
        .toList();
  }

  @override
  Future<Quote> quote({
    required ServiceType service,
    required Place pickup,
    required Place dropoff,
    String? deliveryCategory,
    String? packageSize,
    String? promoCode,
  }) async {
    final d = await _post('/quotes', data: {
      'service': serviceToString(service),
      'pickup': pickup.toJson(),
      'dropoff': dropoff.toJson(),
      if (deliveryCategory != null)
        'delivery': {'category': deliveryCategory, 'package_size': packageSize ?? 'small'},
      if (promoCode != null && promoCode.isNotEmpty) 'promo_code': promoCode,
    });
    return Quote.fromJson(d);
  }

  @override
  Future<Booking> createBooking({
    required Quote quote,
    required String paymentMethod,
    DeliveryDetails? delivery,
  }) async {
    final d = await _post('/bookings', data: {
      'quote_id': quote.id,
      'payment_method': paymentMethod,
      if (delivery != null) 'delivery': delivery.toJson(),
    });
    return Booking.fromJson(d);
  }

  @override
  Stream<Booking> watchBooking(String bookingId) async* {
    // Polling keeps the live client simple and works on unstable networks;
    // the socket channel is an optimisation layered on top in a later stage.
    while (true) {
      await Future<void>.delayed(const Duration(seconds: 3));
      try {
        final b = await getBooking(bookingId);
        yield b;
        if (isTerminal(b.status)) return;
      } catch (_) {/* keep polling through transient failures */}
    }
  }

  @override
  Future<Booking> getBooking(String id) async => Booking.fromJson(await _get('/bookings/$id'));

  @override
  Future<List<Booking>> bookings({bool activeOnly = false}) async {
    final d = await _get('/bookings', query: {'status': activeOnly ? 'active' : 'history'});
    return ((d['data'] ?? const <dynamic>[]) as List)
        .whereType<Map<String, dynamic>>()
        .map(Booking.fromJson)
        .toList();
  }

  @override
  Future<Booking> cancelBooking(String id, String reason) async =>
      Booking.fromJson(await _post('/bookings/$id/cancel', data: {'reason': reason}));

  @override
  Future<Booking> rateBooking(String id, int score,
      {List<String> tags = const <String>[], String? comment, int tipCents = 0}) async {
    return Booking.fromJson(await _post('/bookings/$id/rate', data: {
      'score': score,
      'tags': tags,
      if (comment != null) 'comment': comment,
      'tip_cents': tipCents,
    }));
  }

  @override
  Future<String> shareBooking(String id) async {
    final d = await _post('/bookings/$id/share');
    return d['url'] as String? ?? '';
  }

  @override
  Future<void> sos(String bookingId, LatLng at) async {
    await _post('/bookings/$bookingId/sos', data: {
      'location': {'lat': at.latitude, 'lng': at.longitude}
    });
  }

  @override
  Future<List<PaymentMethodInfo>> paymentMethods() async {
    final d = await _get('/payments/methods');
    return ((d['data'] ?? const <dynamic>[]) as List)
        .whereType<Map<String, dynamic>>()
        .map(PaymentMethodInfo.fromJson)
        .toList();
  }

  @override
  Future<List<AppNotification>> notifications() async {
    final d = await _get('/me/notifications');
    return ((d['data'] ?? const <dynamic>[]) as List)
        .whereType<Map<String, dynamic>>()
        .map((e) => AppNotification(
              id: e['id'] as String,
              title: e['title'] as String? ?? 'BajGo',
              body: e['body'] as String? ?? '',
              createdAt: DateTime.tryParse(e['created_at'] as String? ?? '') ?? DateTime.now(),
              read: e['read_at'] != null,
            ))
        .toList();
  }

  @override
  Future<List<SupportTicket>> tickets() async {
    final d = await _get('/support/tickets');
    return ((d['data'] ?? const <dynamic>[]) as List)
        .whereType<Map<String, dynamic>>()
        .map((e) => SupportTicket(
              id: e['id'] as String,
              reference: e['reference'] as String? ?? '',
              subject: e['subject'] as String? ?? '',
              category: e['category'] as String? ?? 'other',
              status: e['status'] as String? ?? 'open',
              createdAt: DateTime.tryParse(e['created_at'] as String? ?? '') ?? DateTime.now(),
            ))
        .toList();
  }

  @override
  Future<SupportTicket> createTicket(String subject, String category, String message) async {
    final d = await _post('/support/tickets',
        data: {'subject': subject, 'category': category, 'message': message});
    return SupportTicket(
      id: d['id'] as String,
      reference: d['reference'] as String? ?? '',
      subject: subject,
      category: category,
      status: 'open',
      createdAt: DateTime.now(),
      messages: [TicketMessage(body: message, mine: true, at: DateTime.now())],
    );
  }

  @override
  Future<SupportTicket> replyTicket(String ticketId, String message) async {
    await _post('/support/tickets/$ticketId/messages', data: {'body': message});
    final list = await tickets();
    return list.firstWhere((t) => t.id == ticketId);
  }

  @override
  void dispose() => _dio.close(force: true);
}
