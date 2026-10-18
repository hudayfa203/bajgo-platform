import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api.dart';
import 'models.dart';

/// Demo pricing, mirroring the backend defaults.
class DemoPricing {
  DemoPricing._();

  static const int ratePerKmCents = 50;
  static const int minimumFareCents = 100;
  static const int roundingCents = 10;

  /// The demo deducts a flat 10c commission per completed booking so the
  /// driver balance is easy to follow during testing.
  static const int commissionPerBookingCents = 10;

  static int fareCents(int metres) {
    final km = (metres / 100).round() / 10.0;
    final raw = (km * ratePerKmCents).round();
    final rounded = ((raw + roundingCents - 1) ~/ roundingCents) * roundingCents;
    return rounded < minimumFareCents ? minimumFareCents : rounded;
  }
}

/// PLACEHOLDER pickup/drop-off points around Garowe for simulated requests.
const _places = <List<dynamic>>[
  ['Suuqa weyn (Main market)', 8.4091, 48.4823],
  ['Garowe Bus Station', 8.3992, 48.4791],
  ['Puntland State University area', 8.4203, 48.4902],
  ['Garowe General Hospital area', 8.4128, 48.4760],
  ['Isgoyska weyn (Main junction)', 8.4055, 48.4848],
  ['Degmada Waaberi', 8.4150, 48.4700],
  ['Degmada Horseed', 8.3980, 48.4920],
  ['Jidka Bosaso (Bosaso road)', 8.4260, 48.4790],
  ['Garowe Stadium area', 8.4030, 48.4935],
  ['Suuqa Xoolaha (Livestock market)', 8.4210, 48.4755],
];

const _customerNames = [
  'Caasha (demo)',
  'Maxamed (demo)',
  'Hodan (demo)',
  'Yuusuf (demo)',
  'Faadumo (demo)',
];

/// A complete driver-side backend simulated on the device.
///
/// Ride and delivery requests arrive on a timer while the driver is online;
/// accepting one runs the real state machine, and completing it moves money
/// through a simple ledger so earnings and commission are real numbers.
class MockDriverApi implements DriverApi {
  MockDriverApi();

  final _rand = Random(11);
  final _offerCtrl = StreamController<Offer?>.broadcast();
  final _tripCtrl = StreamController<Trip?>.broadcast();
  final _history = <Trip>[];
  final _entries = <WalletEntry>[];
  final _payouts = <Payout>[];
  final _notifications = <DriverNotification>[];

  DriverProfile? _profile;
  Offer? _currentOffer;
  Trip? _active;
  Timer? _offerTimer;
  Timer? _expiryTimer;
  SharedPreferences? _prefs;
  int _seq = 0;
  String? _pendingPhone;

  static const _kProfile = 'drv_profile';
  static const _kHistory = 'drv_history';

  Future<SharedPreferences> get _store async => _prefs ??= await SharedPreferences.getInstance();

  Future<void> restore() async {
    final p = await _store;
    final raw = p.getString(_kProfile);
    if (raw != null) {
      _profile = _profileFromStored(jsonDecode(raw) as Map<String, dynamic>);
    }
    final h = p.getString(_kHistory);
    if (h != null) {
      for (final t in (jsonDecode(h) as List).whereType<Map<String, dynamic>>()) {
        final trip = Trip.fromJson(t);
        _history.add(trip);
        if (trip.status == TripStatus.paid) _postLedger(trip, persist: false);
      }
    }
  }

  DriverProfile? get currentProfile => _profile;

  DriverProfile _profileFromStored(Map<String, dynamic> j) => DriverProfile(
        id: j['id'] as String? ?? 'drv-demo',
        fullName: j['full_name'] as String? ?? '',
        phone: j['phone'] as String? ?? '',
        verification: verificationFromString(j['verification'] as String?),
        availability: Availability.offline,
        vehicle: Vehicle.fromJson((j['vehicle'] ?? const <String, dynamic>{}) as Map<String, dynamic>),
        documents: ((j['documents'] ?? const <dynamic>[]) as List)
            .whereType<Map<String, dynamic>>()
            .map(DriverDocument.fromJson)
            .toList(),
        rating: 4.9,
        ratingCount: 128,
        acceptanceRate: 96,
        totalRides: (j['total_rides'] as num?)?.toInt() ?? 0,
        totalDeliveries: (j['total_deliveries'] as num?)?.toInt() ?? 0,
        commissionPct: 15,
        memberSince: DateTime.tryParse(j['member_since'] as String? ?? '') ?? DateTime(2026, 9, 1),
        payoutMethod: j['payout_method'] as String?,
        payoutAccount: j['payout_account'] as String?,
      );

  Future<void> _persist() async {
    final p = await _store;
    final pr = _profile;
    if (pr != null) {
      await p.setString(
          _kProfile,
          jsonEncode({
            'id': pr.id,
            'full_name': pr.fullName,
            'phone': pr.phone,
            'verification': switch (pr.verification) {
              VerificationStatus.approved => 'approved',
              VerificationStatus.underReview => 'under_review',
              VerificationStatus.rejected => 'rejected',
              VerificationStatus.suspended => 'suspended',
              VerificationStatus.pending => 'pending',
            },
            'vehicle': pr.vehicle.toJson(),
            'total_rides': pr.totalRides,
            'total_deliveries': pr.totalDeliveries,
            'member_since': pr.memberSince?.toIso8601String(),
            'payout_method': pr.payoutMethod,
            'payout_account': pr.payoutAccount,
          }));
    }
    await p.setString(_kHistory, jsonEncode(_history.map((t) => t.toJson()).toList()));
  }

  String _id(String prefix) => '$prefix-${DateTime.now().millisecondsSinceEpoch}-${_seq++}';

  // ───────────────────────────────────────────── auth
  @override
  Future<OtpRequest> requestOtp(String phone) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    _pendingPhone = phone;
    return const OtpRequest(resendAfter: 30, devCode: '123456');
  }

  @override
  Future<DriverProfile?> verifyOtp(String phone, String code) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (code != '123456') throw ApiException('INVALID_OTP', 'Incorrect code');
    if (_profile != null && _profile!.phone == phone) return _profile;
    _pendingPhone = phone;
    // Demo mode signs in to a ready, already-approved driver so the dashboard
    // and the trip workflow can be tested immediately. On the real backend
    // verifyOtp returns null for an unknown phone and the app then runs the
    // five-step registration, which an administrator must approve.
    _profile = demoDriver(phone);
    _notify('Welcome to BajGo', 'Demo driver account ready — you can go online.');
    await _persist();
    return _profile;
  }

  /// The pre-approved account a demo build signs in to.
  static DriverProfile demoDriver(String phone) => DriverProfile(
        id: 'drv-demo',
        fullName: 'Darawal Tijaabo',
        phone: phone,
        verification: VerificationStatus.approved,
        vehicle: const Vehicle(
          fleetCode: 'BG-1042',
          plateNumber: 'PL 4210',
          makeModel: 'Bajaj RE',
          colour: 'Blue',
          year: 2023,
        ),
        documents: const [
          DriverDocument(type: 'national_id', status: DocStatus.approved),
          DriverDocument(type: 'driving_licence', status: DocStatus.approved),
          DriverDocument(type: 'vehicle_registration', status: DocStatus.approved),
          DriverDocument(type: 'insurance', status: DocStatus.approved),
        ],
        rating: 4.9,
        ratingCount: 128,
        acceptanceRate: 96,
        memberSince: null,
        payoutMethod: 'evc_plus',
        payoutAccount: '90 000 0103',
      );

  @override
  Future<DriverProfile> register({
    required String fullName,
    required Vehicle vehicle,
    String? emergencyName,
    String? emergencyPhone,
    String? payoutMethod,
    String? payoutAccount,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    _profile = DriverProfile(
      id: _id('drv'),
      fullName: fullName,
      phone: _pendingPhone ?? '',
      // The demo approves instantly so the whole workflow can be tested;
      // on a real backend this stays `pending` until an admin approves.
      verification: VerificationStatus.approved,
      vehicle: Vehicle(
        fleetCode: 'BG-${(1000 + _rand.nextInt(8999))}',
        plateNumber: vehicle.plateNumber,
        makeModel: vehicle.makeModel,
        colour: vehicle.colour,
        year: vehicle.year,
      ),
      documents: const [
        DriverDocument(type: 'national_id', status: DocStatus.approved),
        DriverDocument(type: 'driving_licence', status: DocStatus.approved),
        DriverDocument(type: 'vehicle_registration', status: DocStatus.approved),
      ],
      rating: 5.0,
      memberSince: DateTime.now(),
      payoutMethod: payoutMethod,
      payoutAccount: payoutAccount,
      emergencyName: emergencyName,
      emergencyPhone: emergencyPhone,
    );
    _notify('Welcome to BajGo', 'Your demo driver account is ready.');
    await _persist();
    return _profile!;
  }

  @override
  Future<DriverProfile> me() async {
    final p = _profile;
    if (p == null) throw ApiException('NOT_REGISTERED', 'Register first');
    return p;
  }

  @override
  Future<DriverProfile> uploadDocument(String type, String filePath) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final p = await me();
    final docs = [...p.documents.where((d) => d.type != type),
      DriverDocument(type: type, status: DocStatus.approved)];
    _profile = p.copyWith(documents: docs);
    await _persist();
    return _profile!;
  }

  // ───────────────────────────────────────────── availability & location
  @override
  Future<DriverProfile> setAvailability(bool online) async {
    final p = await me();
    if (online && !p.isApproved) {
      throw ApiException('NOT_APPROVED', 'Your account is not approved yet');
    }
    _profile = p.copyWith(availability: online ? Availability.online : Availability.offline);
    if (online) {
      _scheduleNextOffer(first: true);
    } else {
      _offerTimer?.cancel();
      _withdrawOffer();
    }
    return _profile!;
  }

  @override
  Future<DriverProfile> setServicePreferences({bool? rides, bool? deliveries}) async {
    final p = await me();
    _profile = p.copyWith(acceptsRides: rides, acceptsDeliveries: deliveries);
    return _profile!;
  }

  @override
  Future<void> sendLocation(LatLng at, {double? heading, double? speedKmh}) async {
    // Nothing to send in demo mode; the dashboard reads the device position directly.
  }

  // ───────────────────────────────────────────── offers
  void _scheduleNextOffer({bool first = false}) {
    _offerTimer?.cancel();
    final wait = first ? 8 : 25 + _rand.nextInt(25);
    _offerTimer = Timer(Duration(seconds: wait), _emitOffer);
  }

  void _emitOffer() {
    final p = _profile;
    if (p == null || p.availability != Availability.online || _active != null) {
      _scheduleNextOffer();
      return;
    }
    final wantsRide = p.acceptsRides;
    final wantsDelivery = p.acceptsDeliveries;
    if (!wantsRide && !wantsDelivery) {
      _scheduleNextOffer();
      return;
    }
    final isDelivery = wantsDelivery && (!wantsRide || _rand.nextInt(10) < 4);

    final a = _places[_rand.nextInt(_places.length)];
    var b = _places[_rand.nextInt(_places.length)];
    while (b[0] == a[0]) {
      b = _places[_rand.nextInt(_places.length)];
    }
    final pickup = TripPlace(
        location: LatLng(a[1] as double, a[2] as double), address: a[0] as String);
    final dropoff = TripPlace(
        location: LatLng(b[1] as double, b[2] as double), address: b[0] as String);
    const dist = Distance();
    final metres =
        (dist.as(LengthUnit.Meter, pickup.location, dropoff.location) * 1.3).round();
    final fare = DemoPricing.fareCents(metres);

    final offer = Offer(
      id: _id('ofr'),
      bookingId: _id('bkg'),
      service: isDelivery ? ServiceType.delivery : ServiceType.ride,
      pickup: pickup,
      dropoff: dropoff,
      distanceM: metres,
      etaToPickupS: 120 + _rand.nextInt(240),
      fareCents: fare,
      commissionCents: DemoPricing.commissionPerBookingCents,
      expiresAt: DateTime.now().add(const Duration(seconds: 20)),
      deliveryCategory: isDelivery ? 'parcel' : null,
    );
    _currentOffer = offer;
    _offerCtrl.add(offer);

    _expiryTimer?.cancel();
    _expiryTimer = Timer(const Duration(seconds: 20), () {
      if (_currentOffer?.id == offer.id) {
        _withdrawOffer();
        _scheduleNextOffer();
      }
    });
  }

  void _withdrawOffer() {
    _currentOffer = null;
    _expiryTimer?.cancel();
    _offerCtrl.add(null);
  }

  @override
  Stream<Offer?> offers() => _offerCtrl.stream;

  @override
  Future<Trip> acceptOffer(String offerId) async {
    final o = _currentOffer;
    if (o == null || o.id != offerId || o.expired) {
      throw ApiException('OFFER_TAKEN', 'This request is no longer available');
    }
    final isDelivery = o.service == ServiceType.delivery;
    final trip = Trip(
      id: o.bookingId,
      reference: 'BJ${DateTime.now().toIso8601String().substring(2, 10).replaceAll('-', '')}'
          '-${1000 + _history.length + 1}',
      service: o.service,
      status: TripStatus.accepted,
      pickup: o.pickup,
      dropoff: o.dropoff,
      fareCents: o.fareCents,
      commissionCents: o.commissionCents,
      createdAt: DateTime.now(),
      customerName: _customerNames[_rand.nextInt(_customerNames.length)],
      customerPhone: '+252 90 000 0001',
      distanceM: o.distanceM,
      route: _route(o.pickup.location, o.dropoff.location),
      paymentMethod: 'cash',
      deliveryCategory: o.deliveryCategory,
      recipientName: isDelivery ? 'Khadra (demo)' : null,
      recipientPhone: isDelivery ? '+252 90 000 0003' : null,
      packageDescription: isDelivery ? 'Small parcel (demo)' : null,
      recipientOtp: isDelivery ? (1000 + _rand.nextInt(9000)).toString() : null,
      timeline: [TripEvent(status: TripStatus.accepted, at: DateTime.now())],
    );
    _active = trip;
    _withdrawOffer();
    _profile = _profile?.copyWith(availability: Availability.onTrip);
    _tripCtrl.add(trip);
    return trip;
  }

  @override
  Future<void> declineOffer(String offerId, {String? reason}) async {
    if (_currentOffer?.id == offerId) {
      _withdrawOffer();
      _scheduleNextOffer();
    }
  }

  List<LatLng> _route(LatLng a, LatLng b) {
    final pts = <LatLng>[];
    const steps = 20;
    final bend = 0.1 * (_rand.nextBool() ? 1 : -1);
    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      final off = sin(t * pi) * bend * 0.01;
      pts.add(LatLng(
        a.latitude + (b.latitude - a.latitude) * t + off,
        a.longitude + (b.longitude - a.longitude) * t - off,
      ));
    }
    return pts;
  }

  // ───────────────────────────────────────────── trip lifecycle
  @override
  Stream<Trip?> activeTrip() => _tripCtrl.stream;

  Trip _requireActive(String id) {
    final t = _active;
    if (t == null || t.id != id) throw ApiException('NOT_FOUND', 'No active trip');
    return t;
  }

  /// Which transitions the driver may make from here. Mirrors the server's
  /// state machine so the demo cannot reach a state the backend would reject.
  static List<TripStatus> allowedNext(Trip t) {
    final delivery = t.service == ServiceType.delivery;
    return switch (t.status) {
      TripStatus.accepted => [TripStatus.driverArriving],
      TripStatus.driverArriving => [delivery ? TripStatus.arrivedPickup : TripStatus.arrived],
      TripStatus.arrived => [TripStatus.inProgress],
      TripStatus.inProgress => [TripStatus.completed],
      TripStatus.arrivedPickup => [TripStatus.collected],
      TripStatus.collected => [TripStatus.inTransit],
      TripStatus.inTransit => [TripStatus.arrivedDropoff],
      TripStatus.arrivedDropoff => [TripStatus.recipientVerified],
      TripStatus.recipientVerified => [TripStatus.delivered],
      _ => const <TripStatus>[],
    };
  }

  @override
  Future<Trip> transition(String tripId, TripStatus to, {String? proofPhotoPath}) async {
    final t = _requireActive(tripId);
    if (!allowedNext(t).contains(to)) {
      throw ApiException('INVALID_TRANSITION', 'Cannot move from ${t.status.name} to ${to.name}');
    }
    t.status = to;
    t.timeline = [...t.timeline, TripEvent(status: to, at: DateTime.now())];
    _tripCtrl.add(t);
    return t;
  }

  @override
  Future<Trip> verifyRecipient(String tripId, String code) async {
    final t = _requireActive(tripId);
    if (code.trim() != t.recipientOtp) {
      throw ApiException('OTP_WRONG', 'That code does not match');
    }
    return transition(tripId, TripStatus.recipientVerified);
  }

  @override
  Future<Trip> collectCash(String tripId, int amountCents) async {
    final t = _requireActive(tripId);
    t.status = TripStatus.paid;
    t.timeline = [...t.timeline, TripEvent(status: TripStatus.paid, at: DateTime.now())];
    _finish(t);
    return t;
  }

  @override
  Future<Trip> failDelivery(String tripId, String reason, {String? note}) async {
    final t = _requireActive(tripId);
    t.status = TripStatus.failed;
    t.timeline = [...t.timeline, TripEvent(status: TripStatus.failed, at: DateTime.now())];
    _finish(t, earn: false);
    return t;
  }

  @override
  Future<Trip> cancelTrip(String tripId, String reason) async {
    final t = _requireActive(tripId);
    t.status = TripStatus.cancelled;
    t.timeline = [...t.timeline, TripEvent(status: TripStatus.cancelled, at: DateTime.now())];
    _finish(t, earn: false);
    return t;
  }

  @override
  Future<void> rateCustomer(String tripId, int score, {String? comment}) async {}

  void _finish(Trip t, {bool earn = true}) {
    _history.insert(0, t);
    if (earn) {
      _postLedger(t);
      final p = _profile;
      if (p != null) {
        _profile = DriverProfile(
          id: p.id,
          fullName: p.fullName,
          phone: p.phone,
          verification: p.verification,
          availability: Availability.online,
          vehicle: p.vehicle,
          documents: p.documents,
          rating: p.rating,
          ratingCount: p.ratingCount,
          acceptanceRate: p.acceptanceRate,
          totalRides: p.totalRides + (t.service == ServiceType.ride ? 1 : 0),
          totalDeliveries: p.totalDeliveries + (t.service == ServiceType.delivery ? 1 : 0),
          acceptsRides: p.acceptsRides,
          acceptsDeliveries: p.acceptsDeliveries,
          commissionPct: p.commissionPct,
          memberSince: p.memberSince,
          payoutMethod: p.payoutMethod,
          payoutAccount: p.payoutAccount,
          emergencyName: p.emergencyName,
          emergencyPhone: p.emergencyPhone,
        );
      }
      _notify('Trip completed',
          'You earned ${_money(t.earningsCents)} (commission ${_money(t.commissionCents)}).');
    } else {
      _profile = _profile?.copyWith(availability: Availability.online);
    }
    _active = null;
    _tripCtrl.add(null);
    unawaited(_persist());
    _scheduleNextOffer();
  }

  /// Two entries per completed trip: the fare earned and the commission owed.
  void _postLedger(Trip t, {bool persist = true}) {
    _entries.insert(
      0,
      WalletEntry(
        id: _id('led'),
        kind: 'fare',
        amountCents: t.fareCents + t.tipCents,
        at: DateTime.now(),
        reference: t.reference,
      ),
    );
    _entries.insert(
      0,
      WalletEntry(
        id: _id('led'),
        kind: 'commission',
        amountCents: -t.commissionCents,
        at: DateTime.now(),
        reference: t.reference,
      ),
    );
  }

  static String _money(int cents) =>
      '\$${cents ~/ 100}.${(cents % 100).toString().padLeft(2, '0')}';

  void _notify(String title, String body) {
    _notifications.insert(
      0,
      DriverNotification(id: _id('ntf'), title: title, body: body, at: DateTime.now()),
    );
  }

  // ───────────────────────────────────────────── money
  List<Trip> _inPeriod(String period) {
    final now = DateTime.now();
    final from = switch (period) {
      'week' => now.subtract(Duration(days: now.weekday - 1)),
      'month' => DateTime(now.year, now.month),
      _ => DateTime(now.year, now.month, now.day),
    };
    return _history
        .where((t) => t.status == TripStatus.paid && t.createdAt.isAfter(from))
        .toList();
  }

  @override
  Future<Earnings> earnings(String period) async {
    final trips = _inPeriod(period);
    final gross = trips.fold<int>(0, (s, t) => s + t.fareCents + t.tipCents);
    final commission = trips.fold<int>(0, (s, t) => s + t.commissionCents);
    final cash = trips
        .where((t) => t.paymentMethod == 'cash')
        .fold<int>(0, (s, t) => s + t.fareCents + t.tipCents);

    final byDay = <DayEarnings>[];
    for (var i = 6; i >= 0; i--) {
      final day = DateTime.now().subtract(Duration(days: i));
      final dayTrips = _history.where((t) =>
          t.status == TripStatus.paid &&
          t.createdAt.year == day.year &&
          t.createdAt.month == day.month &&
          t.createdAt.day == day.day);
      byDay.add(DayEarnings(
        date: day,
        netCents: dayTrips.fold<int>(0, (s, t) => s + t.earningsCents),
        trips: dayTrips.length,
      ));
    }

    return Earnings(
      grossCents: gross,
      commissionCents: commission,
      cashCents: cash,
      digitalCents: gross - cash,
      trips: trips.where((t) => t.service == ServiceType.ride).length,
      deliveries: trips.where((t) => t.service == ServiceType.delivery).length,
      byDay: byDay,
    );
  }

  @override
  Future<Wallet> wallet() async {
    final balance = _entries.fold<int>(0, (s, e) => s + e.amountCents) -
        _payouts
            .where((p) => p.status == 'paid' || p.status == 'approved' || p.status == 'requested')
            .fold<int>(0, (s, p) => s + p.amountCents);
    final commissionDue =
        _entries.where((e) => e.kind == 'commission').fold<int>(0, (s, e) => s + e.amountCents).abs();
    final cash = _history
        .where((t) => t.status == TripStatus.paid && t.paymentMethod == 'cash')
        .fold<int>(0, (s, t) => s + t.fareCents + t.tipCents);
    return Wallet(
      balanceCents: balance,
      commissionDueCents: commissionDue,
      cashCollectedCents: cash,
      paidOutCents: _payouts.where((p) => p.status == 'paid').fold<int>(0, (s, p) => s + p.amountCents),
      entries: List.unmodifiable(_entries),
    );
  }

  @override
  Future<List<Trip>> history() async => List.unmodifiable(_history);

  @override
  Future<List<Payout>> payouts() async => List.unmodifiable(_payouts);

  @override
  Future<Payout> requestPayout(int amountCents) async {
    final w = await wallet();
    if (amountCents > w.balanceCents) {
      throw ApiException('INSUFFICIENT_BALANCE', 'Not enough balance');
    }
    final p = Payout(
      id: _id('pay'),
      amountCents: amountCents,
      status: 'requested',
      requestedAt: DateTime.now(),
      method: _profile?.payoutMethod,
    );
    _payouts.insert(0, p);
    _notify('Payout requested', '${_money(amountCents)} is awaiting approval.');
    return p;
  }

  @override
  Future<List<DriverNotification>> notifications() async => List.unmodifiable(_notifications);

  @override
  Future<void> logout() async {
    _offerTimer?.cancel();
    _expiryTimer?.cancel();
    final p = await _store;
    await p.remove(_kProfile);
    _profile = null;
  }

  @override
  void dispose() {
    _offerTimer?.cancel();
    _expiryTimer?.cancel();
    _offerCtrl.close();
    _tripCtrl.close();
  }
}
