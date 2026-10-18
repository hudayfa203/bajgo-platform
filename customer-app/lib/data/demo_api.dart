import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/env.dart';
import 'api.dart';
import 'models.dart';

/// Fare rules mirroring the backend pricing engine defaults (docs/ARCHITECTURE.md §6).
/// Kept here only so the DEMO build can run with no server; the live app always
/// uses the fare the API quotes.
class DemoPricing {
  const DemoPricing._();

  static const int ratePerKmCents = 50;
  static const int minimumFareCents = 100;
  static const int baseFeeCents = 0;
  static const int roundingCents = 10;

  /// Flat commission used by the demo so the driver balance is easy to follow.
  static const int commissionPerBookingCents = 10;

  static int fareCents(int distanceMetres, {int extrasCents = 0, int discountCents = 0}) {
    final km = (distanceMetres / 100).round() / 10.0;
    final raw = baseFeeCents + (km * ratePerKmCents).round() + extrasCents;
    final rounded = ((raw + roundingCents - 1) ~/ roundingCents) * roundingCents;
    final withMinimum = rounded < minimumFareCents ? minimumFareCents : rounded;
    final net = withMinimum - discountCents;
    return net < 0 ? 0 : net;
  }
}

/// Landmarks used for destination search in the demo.
/// PLACEHOLDER DATA — generic names only, to be replaced with a real local gazetteer.
const List<Map<String, dynamic>> _demoLandmarks = [
  {'name': 'Suuqa weyn (Main market)', 'lat': 8.4091, 'lng': 48.4823},
  {'name': 'Garowe Bus Station', 'lat': 8.3992, 'lng': 48.4791},
  {'name': 'Puntland State University area', 'lat': 8.4203, 'lng': 48.4902},
  {'name': 'Garowe General Hospital area', 'lat': 8.4128, 'lng': 48.4760},
  {'name': 'Garowe Airport road', 'lat': 8.3845, 'lng': 48.5062},
  {'name': 'Isgoyska weyn (Main junction)', 'lat': 8.4055, 'lng': 48.4848},
  {'name': 'Xarunta Maamulka (Administration area)', 'lat': 8.4112, 'lng': 48.4885},
  {'name': 'Masaajidka weyn (Grand mosque area)', 'lat': 8.4068, 'lng': 48.4812},
  {'name': 'Jidka Bosaso (Bosaso road)', 'lat': 8.4260, 'lng': 48.4790},
  {'name': 'Jidka Galkacyo (Galkacyo road)', 'lat': 8.3900, 'lng': 48.4870},
  {'name': 'Degmada Waaberi', 'lat': 8.4150, 'lng': 48.4700},
  {'name': 'Degmada Horseed', 'lat': 8.3980, 'lng': 48.4920},
  {'name': 'Suuqa Xoolaha (Livestock market)', 'lat': 8.4210, 'lng': 48.4755},
  {'name': 'Garowe Stadium area', 'lat': 8.4030, 'lng': 48.4935},
  {'name': 'Xarunta Caafimaadka (Health centre)', 'lat': 8.4175, 'lng': 48.4840},
];

/// A complete BajGo backend simulated on the device.
///
/// It runs the real booking lifecycle on timers: a driver is found, accepts,
/// drives to the pickup, starts the trip, drives the route and completes it —
/// so the whole flow can be tested on a phone with no server and no SIM.
class DemoApi implements BajGoApi {
  DemoApi();

  final _rand = Random(7);
  final _bookings = <String, Booking>{};
  final _controllers = <String, StreamController<Booking>>{};
  final _timers = <String, List<Timer>>{};
  final _tickets = <SupportTicket>[];
  final _notifications = <AppNotification>[];
  var _savedPlaces = <SavedPlace>[];

  AppUser? _user;
  String? _pendingPhone;
  SharedPreferences? _prefs;
  int _seq = 0;

  static const _kUser = 'demo_user';
  static const _kBookings = 'demo_bookings';
  static const _kPlaces = 'demo_places';

  Future<SharedPreferences> get _store async => _prefs ??= await SharedPreferences.getInstance();

  /// Restores the previous demo session so history survives an app restart.
  Future<void> restore() async {
    final p = await _store;
    final u = p.getString(_kUser);
    if (u != null) {
      _user = AppUser.fromJson(jsonDecode(u) as Map<String, dynamic>);
    }
    final b = p.getString(_kBookings);
    if (b != null) {
      for (final raw in (jsonDecode(b) as List).whereType<Map<String, dynamic>>()) {
        final booking = Booking.fromJson(raw);
        // Anything left mid-flight from a previous run is closed out, not resumed.
        if (isActive(booking.status)) booking.status = BookingStatus.expired;
        _bookings[booking.id] = booking;
      }
    }
    final pl = p.getString(_kPlaces);
    if (pl != null) {
      _savedPlaces = (jsonDecode(pl) as List)
          .whereType<Map<String, dynamic>>()
          .map(SavedPlace.fromJson)
          .toList();
    }
  }

  AppUser? get currentUser => _user;

  Future<void> _persist() async {
    final p = await _store;
    if (_user != null) await p.setString(_kUser, jsonEncode(_user!.toJson()));
    await p.setString(
        _kBookings, jsonEncode(_bookings.values.map((b) => b.toJson()).toList()));
    await p.setString(_kPlaces, jsonEncode(_savedPlaces.map((e) => e.toJson()).toList()));
  }

  String _id(String prefix) => '$prefix-${DateTime.now().millisecondsSinceEpoch}-${_seq++}';

  // ─────────────────────────────────────────────────────────── auth
  @override
  Future<OtpRequestResult> requestOtp(String phone) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _pendingPhone = phone;
    return const OtpRequestResult(resendAfter: 30, devCode: Env.demoOtp);
  }

  @override
  Future<AuthResult> verifyOtp(String phone, String code) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (code != Env.demoOtp) {
      throw ApiException('INVALID_OTP', 'Incorrect code');
    }
    final existing = _user;
    if (existing != null && existing.phone == phone) {
      return AuthResult(user: existing, isNew: existing.needsName);
    }
    _user = AppUser(id: _id('usr'), phone: _pendingPhone ?? phone, fullName: null);
    await _persist();
    return AuthResult(user: _user!, isNew: true);
  }

  @override
  Future<AppUser> updateProfile({String? fullName, String? language}) async {
    _user = (_user ?? AppUser(id: _id('usr'), phone: _pendingPhone ?? ''))
        .copyWith(fullName: fullName, language: language);
    await _persist();
    return _user!;
  }

  @override
  Future<void> logout() async {
    final p = await _store;
    await p.remove(_kUser);
    _user = null;
  }

  // ─────────────────────────────────────────────────────────── places
  @override
  Future<List<SavedPlace>> savedPlaces() async => List.unmodifiable(_savedPlaces);

  @override
  Future<SavedPlace> addSavedPlace(SavedPlace place) async {
    final saved = SavedPlace(
        id: _id('plc'), label: place.label, kind: place.kind, place: place.place);
    _savedPlaces = [..._savedPlaces.where((p) => !(p.kind == saved.kind && saved.kind != 'custom')), saved];
    await _persist();
    return saved;
  }

  @override
  Future<void> deleteSavedPlace(String id) async {
    _savedPlaces = _savedPlaces.where((p) => p.id != id).toList();
    await _persist();
  }

  @override
  Future<List<Place>> searchPlaces(String query, LatLng near) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final q = query.trim().toLowerCase();
    final all = _demoLandmarks
        .map((m) => Place(
              location: LatLng(m['lat'] as double, m['lng'] as double),
              address: m['name'] as String,
            ))
        .toList();
    if (q.isEmpty) return all.take(8).toList();
    return all.where((p) => (p.address ?? '').toLowerCase().contains(q)).toList();
  }

  @override
  Future<List<NearbyDriver>> nearbyDrivers(LatLng near) async {
    return List.generate(6, (i) {
      final a = (i / 6) * 2 * pi + _rand.nextDouble();
      final r = 0.004 + _rand.nextDouble() * 0.012;
      return NearbyDriver(
        location: LatLng(near.latitude + r * sin(a), near.longitude + r * cos(a)),
        heading: _rand.nextDouble() * 360,
      );
    });
  }

  // ─────────────────────────────────────────────────────────── quote
  static const _distance = Distance();

  /// Straight-line distance inflated by a road factor, which is how the backend's
  /// Haversine fallback provider behaves when no routing service is configured.
  static int roadMetres(LatLng a, LatLng b) =>
      (_distance.as(LengthUnit.Meter, a, b) * 1.30).round();

  List<LatLng> _route(LatLng a, LatLng b) {
    // A gently bent path so the map reads like a street route rather than a ruler line.
    final pts = <LatLng>[];
    const steps = 24;
    final bend = 0.12 * (_rand.nextBool() ? 1 : -1);
    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      final lat = a.latitude + (b.latitude - a.latitude) * t;
      final lng = a.longitude + (b.longitude - a.longitude) * t;
      final off = sin(t * pi) * bend * 0.01;
      pts.add(LatLng(lat + off, lng - off));
    }
    return pts;
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
    await Future<void>.delayed(const Duration(milliseconds: 650));
    final metres = roadMetres(pickup.location, dropoff.location);
    final extras = packageSize == 'large' ? 100 : (packageSize == 'medium' ? 50 : 0);
    final discount = (promoCode ?? '').trim().toUpperCase() == 'BAJGO' ? 50 : 0;
    final fare = DemoPricing.fareCents(metres, extrasCents: extras, discountCents: discount);
    final distanceCents = ((metres / 100).round() / 10.0 * DemoPricing.ratePerKmCents).round();
    return Quote(
      id: _id('qte'),
      service: service,
      pickup: pickup,
      dropoff: dropoff,
      distanceM: metres,
      durationS: (metres / 1000 * 180).round().clamp(120, 5400),
      fareCents: fare,
      breakdown: FareBreakdown(
        distanceCents: distanceCents,
        extrasCents: extras,
        discountCents: discount,
        minimumApplied: distanceCents + extras < DemoPricing.minimumFareCents,
      ),
      polyline: _route(pickup.location, dropoff.location),
      expiresAt: DateTime.now().add(const Duration(minutes: 10)),
    );
  }

  // ─────────────────────────────────────────────────────────── bookings
  @override
  Future<Booking> createBooking({
    required Quote quote,
    required String paymentMethod,
    DeliveryDetails? delivery,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final id = _id('bkg');
    final ref = 'BJ${DateTime.now().toIso8601String().substring(2, 10).replaceAll('-', '')}'
        '-${(1000 + _bookings.length + 1)}';
    final booking = Booking(
      id: id,
      reference: ref,
      service: quote.service,
      status: BookingStatus.searching,
      pickup: quote.pickup,
      dropoff: quote.dropoff,
      quotedFareCents: quote.fareCents,
      createdAt: DateTime.now(),
      distanceM: quote.distanceM,
      durationS: quote.durationS,
      polyline: quote.polyline,
      paymentMethod: paymentMethod,
      delivery: delivery?.copyWith(
          recipientOtp: (1000 + _rand.nextInt(9000)).toString()),
      discountCents: quote.breakdown.discountCents,
      breakdown: quote.breakdown,
      timeline: [TimelineEntry(status: BookingStatus.searching, at: DateTime.now())],
      shareUrl: '${Env.website}/t/demo-$ref',
    );
    _bookings[id] = booking;
    await _persist();
    _startSimulation(booking);
    return booking;
  }

  void _emit(Booking b) {
    _controllers[b.id]?.add(b);
    unawaited(_persist());
  }

  void _advance(Booking b, BookingStatus to) {
    if (isTerminal(b.status)) return;
    b.status = to;
    b.timeline = [...b.timeline, TimelineEntry(status: to, at: DateTime.now())];
    _emit(b);
  }

  void _schedule(Booking b, Duration after, void Function() action) {
    final t = Timer(after, () {
      if (isTerminal(b.status) && b.status != BookingStatus.completed) return;
      action();
    });
    _timers.putIfAbsent(b.id, () => <Timer>[]).add(t);
  }

  /// Drives the booking through its full lifecycle, moving the driver along the
  /// route between status changes.
  void _startSimulation(Booking b) {
    final isDelivery = b.service == ServiceType.delivery;

    // Driver starts a short distance away from the pickup.
    final start = LatLng(
      b.pickup.location.latitude + (_rand.nextDouble() - 0.5) * 0.016,
      b.pickup.location.longitude + (_rand.nextDouble() - 0.5) * 0.016,
    );
    b.driverLocation = start;

    _schedule(b, const Duration(seconds: 5), () {
      b.driver = DriverCard(
        id: 'drv-demo-1',
        fullName: 'Cabdi (demo driver)',
        rating: 4.9,
        fleetCode: 'BG-0142',
        plate: 'PL 0142',
        vehicleColour: 'BajGo Blue',
        phone: '+252 90 000 0002',
      );
      b.etaSeconds = 240;
      _advance(b, BookingStatus.accepted);
      _notify('Driver found', 'BG-0142 is on the way.');
      _animate(b, start, b.pickup.location, const Duration(seconds: 14), onDone: () {
        _advance(b, isDelivery ? BookingStatus.arrivedPickup : BookingStatus.arrived);
        _notify('Driver arrived', 'Your Bajaaj is at the pickup point.');

        _schedule(b, const Duration(seconds: 6), () {
          _advance(b, isDelivery ? BookingStatus.collected : BookingStatus.inProgress);
          if (isDelivery) _advance(b, BookingStatus.inTransit);

          _animate(b, b.pickup.location, b.dropoff.location, const Duration(seconds: 22),
              onDone: () {
            if (isDelivery) {
              _advance(b, BookingStatus.arrivedDropoff);
              _schedule(b, const Duration(seconds: 4), () {
                _advance(b, BookingStatus.recipientVerified);
                _schedule(b, const Duration(seconds: 2), () => _complete(b));
              });
            } else {
              _complete(b);
            }
          });
        });
      });
    });

    // Progress the ETA countdown every second while the driver is coming.
    final eta = Timer.periodic(const Duration(seconds: 1), (t) {
      if (isTerminal(b.status) || b.status == BookingStatus.inProgress) {
        t.cancel();
        return;
      }
      if (b.etaSeconds != null && b.etaSeconds! > 20) {
        b.etaSeconds = b.etaSeconds! - 12;
        _emit(b);
      }
    });
    _timers.putIfAbsent(b.id, () => <Timer>[]).add(eta);
  }

  void _complete(Booking b) {
    b.finalFareCents = b.quotedFareCents;
    b.etaSeconds = null;
    _advance(b, b.service == ServiceType.delivery ? BookingStatus.delivered : BookingStatus.completed);
    _notify(
      b.service == ServiceType.delivery ? 'Delivered' : 'Trip completed',
      '${formatMoney(b.payableCents)} — ${b.paymentMethod == 'cash' ? 'pay the driver in cash' : 'payment recorded'}.',
    );
    _cancelTimers(b.id, keepStream: true);
  }

  /// Moves the driver marker smoothly from a to b over [total].
  void _animate(Booking b, LatLng from, LatLng to, Duration total, {required void Function() onDone}) {
    const tick = Duration(milliseconds: 900);
    final steps = (total.inMilliseconds / tick.inMilliseconds).round().clamp(4, 200);
    var i = 0;
    final t = Timer.periodic(tick, (timer) {
      if (isTerminal(b.status)) {
        timer.cancel();
        return;
      }
      i++;
      final f = (i / steps).clamp(0.0, 1.0);
      b.driverLocation = LatLng(
        from.latitude + (to.latitude - from.latitude) * f,
        from.longitude + (to.longitude - from.longitude) * f,
      );
      _emit(b);
      if (i >= steps) {
        timer.cancel();
        onDone();
      }
    });
    _timers.putIfAbsent(b.id, () => <Timer>[]).add(t);
  }

  void _cancelTimers(String bookingId, {bool keepStream = false}) {
    for (final t in _timers[bookingId] ?? const <Timer>[]) {
      t.cancel();
    }
    _timers.remove(bookingId);
    if (!keepStream) {
      _controllers[bookingId]?.close();
      _controllers.remove(bookingId);
    }
  }

  void _notify(String title, String body) {
    _notifications.insert(
      0,
      AppNotification(
        id: _id('ntf'),
        title: title,
        body: body,
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Stream<Booking> watchBooking(String bookingId) {
    final c = _controllers.putIfAbsent(
        bookingId, () => StreamController<Booking>.broadcast());
    final b = _bookings[bookingId];
    if (b != null) scheduleMicrotask(() => c.add(b));
    return c.stream;
  }

  @override
  Future<Booking> getBooking(String id) async {
    final b = _bookings[id];
    if (b == null) throw ApiException('NOT_FOUND', 'Booking not found');
    return b;
  }

  @override
  Future<List<Booking>> bookings({bool activeOnly = false}) async {
    final list = _bookings.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return activeOnly ? list.where((b) => isActive(b.status)).toList() : list;
  }

  @override
  Future<Booking> cancelBooking(String id, String reason) async {
    final b = await getBooking(id);
    _cancelTimers(id, keepStream: true);
    _advance(b, BookingStatus.cancelled);
    return b;
  }

  @override
  Future<Booking> rateBooking(String id, int score,
      {List<String> tags = const <String>[], String? comment, int tipCents = 0}) async {
    final b = await getBooking(id);
    b.customerRating = score;
    b.tipCents = tipCents;
    b.status = BookingStatus.paid;
    b.timeline = [...b.timeline, TimelineEntry(status: BookingStatus.paid, at: DateTime.now())];
    _emit(b);
    _cancelTimers(id);
    return b;
  }

  @override
  Future<String> shareBooking(String id) async => (await getBooking(id)).shareUrl ?? Env.website;

  @override
  Future<void> sos(String bookingId, LatLng at) async {
    _notify('Emergency alert sent', 'BajGo support has been notified of your location.');
  }

  // ─────────────────────────────────────────────────────────── misc
  @override
  Future<List<PaymentMethodInfo>> paymentMethods() async => const [
        PaymentMethodInfo(method: 'cash', live: true, labelSo: 'Lacag cadaan', labelEn: 'Cash'),
        PaymentMethodInfo(method: 'evc_plus', live: false, labelSo: 'EVC Plus', labelEn: 'EVC Plus'),
        PaymentMethodInfo(method: 'zaad', live: false, labelSo: 'ZAAD', labelEn: 'ZAAD'),
        PaymentMethodInfo(method: 'sahal', live: false, labelSo: 'Sahal', labelEn: 'Sahal'),
      ];

  @override
  Future<List<AppNotification>> notifications() async => List.unmodifiable(_notifications);

  @override
  Future<List<SupportTicket>> tickets() async => List.unmodifiable(_tickets);

  @override
  Future<SupportTicket> createTicket(String subject, String category, String message) async {
    final t = SupportTicket(
      id: _id('tkt'),
      reference: 'T${100000 + _tickets.length + 1}',
      subject: subject,
      category: category,
      status: 'open',
      createdAt: DateTime.now(),
      messages: [TicketMessage(body: message, mine: true, at: DateTime.now())],
    );
    _tickets.insert(0, t);
    // A support reply arrives shortly so the thread is not a dead end in the demo.
    Timer(const Duration(seconds: 6), () {
      t.messages = [
        ...t.messages,
        TicketMessage(
          body: 'Thank you for contacting BajGo. Our team will reply shortly. (demo reply)',
          mine: false,
          at: DateTime.now(),
        ),
      ];
      t.status = 'in_progress';
    });
    return t;
  }

  @override
  Future<SupportTicket> replyTicket(String ticketId, String message) async {
    final t = _tickets.firstWhere((e) => e.id == ticketId);
    t.messages = [...t.messages, TicketMessage(body: message, mine: true, at: DateTime.now())];
    return t;
  }

  @override
  void dispose() {
    for (final id in _timers.keys.toList()) {
      _cancelTimers(id);
    }
  }
}
