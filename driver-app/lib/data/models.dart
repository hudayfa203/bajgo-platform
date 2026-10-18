import 'package:latlong2/latlong.dart';

enum ServiceType { ride, delivery }

ServiceType serviceFromString(String s) =>
    s == 'delivery' ? ServiceType.delivery : ServiceType.ride;
String serviceToString(ServiceType s) => s == ServiceType.delivery ? 'delivery' : 'ride';

enum VerificationStatus { pending, underReview, approved, rejected, suspended }

VerificationStatus verificationFromString(String? s) => switch (s) {
      'under_review' => VerificationStatus.underReview,
      'approved' => VerificationStatus.approved,
      'rejected' => VerificationStatus.rejected,
      'suspended' => VerificationStatus.suspended,
      _ => VerificationStatus.pending,
    };

enum Availability { offline, online, onTrip }

enum DocStatus { missing, pending, approved, rejected, expired }

DocStatus docStatusFromString(String? s) => switch (s) {
      'approved' => DocStatus.approved,
      'rejected' => DocStatus.rejected,
      'expired' => DocStatus.expired,
      'pending' => DocStatus.pending,
      _ => DocStatus.missing,
    };

/// Booking lifecycle as the driver sees it (docs/ARCHITECTURE.md §4).
enum TripStatus {
  searching,
  accepted,
  driverArriving,
  arrived,
  inProgress,
  arrivedPickup,
  collected,
  inTransit,
  arrivedDropoff,
  recipientVerified,
  completed,
  delivered,
  paid,
  cancelled,
  expired,
  failed,
  returned,
}

const Map<String, TripStatus> _wire = {
  'searching': TripStatus.searching,
  'accepted': TripStatus.accepted,
  'driver_arriving': TripStatus.driverArriving,
  'arrived': TripStatus.arrived,
  'in_progress': TripStatus.inProgress,
  'arrived_pickup': TripStatus.arrivedPickup,
  'collected': TripStatus.collected,
  'in_transit': TripStatus.inTransit,
  'arrived_dropoff': TripStatus.arrivedDropoff,
  'recipient_verified': TripStatus.recipientVerified,
  'completed': TripStatus.completed,
  'delivered': TripStatus.delivered,
  'paid': TripStatus.paid,
  'cancelled_by_customer': TripStatus.cancelled,
  'cancelled_by_driver': TripStatus.cancelled,
  'cancelled_by_admin': TripStatus.cancelled,
  'expired': TripStatus.expired,
  'failed': TripStatus.failed,
  'returned': TripStatus.returned,
};

TripStatus tripStatusFromString(String? s) => _wire[s ?? ''] ?? TripStatus.searching;

String tripStatusToString(TripStatus s) {
  for (final e in _wire.entries) {
    if (e.value == s) return e.key;
  }
  return 'searching';
}

bool tripIsFinished(TripStatus s) =>
    s == TripStatus.completed ||
    s == TripStatus.delivered ||
    s == TripStatus.paid ||
    s == TripStatus.cancelled ||
    s == TripStatus.expired ||
    s == TripStatus.failed ||
    s == TripStatus.returned;

class Vehicle {
  const Vehicle({
    this.fleetCode = '',
    this.plateNumber = '',
    this.makeModel = 'Bajaj RE',
    this.colour,
    this.year,
  });

  final String fleetCode;
  final String plateNumber;
  final String makeModel;
  final String? colour;
  final int? year;

  static Vehicle fromJson(Map<String, dynamic> j) => Vehicle(
        fleetCode: j['fleet_code'] as String? ?? '',
        plateNumber: j['plate_number'] as String? ?? '',
        makeModel: j['make_model'] as String? ?? 'Bajaj RE',
        colour: j['colour'] as String?,
        year: (j['year'] as num?)?.toInt(),
      );

  Map<String, dynamic> toJson() => {
        'fleet_code': fleetCode,
        'plate_number': plateNumber,
        'make_model': makeModel,
        'colour': colour,
        'year': year,
      };
}

class DriverDocument {
  const DriverDocument({required this.type, required this.status, this.expiresAt});

  final String type;
  final DocStatus status;
  final DateTime? expiresAt;

  bool get expiringSoon =>
      expiresAt != null && expiresAt!.difference(DateTime.now()).inDays <= 30;

  static DriverDocument fromJson(Map<String, dynamic> j) => DriverDocument(
        type: j['type'] as String,
        status: docStatusFromString(j['status'] as String?),
        expiresAt: j['expires_at'] != null ? DateTime.tryParse(j['expires_at'] as String) : null,
      );
}

class DriverProfile {
  const DriverProfile({
    required this.id,
    required this.fullName,
    required this.phone,
    this.verification = VerificationStatus.pending,
    this.verificationReason,
    this.availability = Availability.offline,
    this.vehicle = const Vehicle(),
    this.documents = const <DriverDocument>[],
    this.rating = 5.0,
    this.ratingCount = 0,
    this.acceptanceRate = 100,
    this.totalRides = 0,
    this.totalDeliveries = 0,
    this.acceptsRides = true,
    this.acceptsDeliveries = true,
    this.commissionPct = 15,
    this.memberSince,
    this.payoutMethod,
    this.payoutAccount,
    this.emergencyName,
    this.emergencyPhone,
  });

  final String id;
  final String fullName;
  final String phone;
  final VerificationStatus verification;
  final String? verificationReason;
  final Availability availability;
  final Vehicle vehicle;
  final List<DriverDocument> documents;
  final double rating;
  final int ratingCount;
  final double acceptanceRate;
  final int totalRides;
  final int totalDeliveries;
  final bool acceptsRides;
  final bool acceptsDeliveries;
  final double commissionPct;
  final DateTime? memberSince;
  final String? payoutMethod;
  final String? payoutAccount;
  final String? emergencyName;
  final String? emergencyPhone;

  bool get isApproved => verification == VerificationStatus.approved;

  DriverProfile copyWith({
    VerificationStatus? verification,
    Availability? availability,
    Vehicle? vehicle,
    List<DriverDocument>? documents,
    bool? acceptsRides,
    bool? acceptsDeliveries,
    String? fullName,
  }) =>
      DriverProfile(
        id: id,
        fullName: fullName ?? this.fullName,
        phone: phone,
        verification: verification ?? this.verification,
        verificationReason: verificationReason,
        availability: availability ?? this.availability,
        vehicle: vehicle ?? this.vehicle,
        documents: documents ?? this.documents,
        rating: rating,
        ratingCount: ratingCount,
        acceptanceRate: acceptanceRate,
        totalRides: totalRides,
        totalDeliveries: totalDeliveries,
        acceptsRides: acceptsRides ?? this.acceptsRides,
        acceptsDeliveries: acceptsDeliveries ?? this.acceptsDeliveries,
        commissionPct: commissionPct,
        memberSince: memberSince,
        payoutMethod: payoutMethod,
        payoutAccount: payoutAccount,
        emergencyName: emergencyName,
        emergencyPhone: emergencyPhone,
      );

  static DriverProfile fromJson(Map<String, dynamic> j) {
    final p = (j['driver_profile'] ?? j) as Map<String, dynamic>;
    return DriverProfile(
      id: j['id'] as String? ?? '',
      fullName: j['full_name'] as String? ?? '',
      phone: (j['phone'] ?? j['phone_e164'] ?? '') as String,
      verification: verificationFromString(p['verification'] as String?),
      verificationReason: p['verification_notes'] as String?,
      availability: switch (p['availability'] as String?) {
        'online' => Availability.online,
        'on_trip' => Availability.onTrip,
        _ => Availability.offline,
      },
      vehicle: p['vehicle'] != null
          ? Vehicle.fromJson(p['vehicle'] as Map<String, dynamic>)
          : const Vehicle(),
      documents: ((p['documents'] ?? const <dynamic>[]) as List)
          .whereType<Map<String, dynamic>>()
          .map(DriverDocument.fromJson)
          .toList(),
      rating: ((p['rating_avg'] ?? 5) as num).toDouble(),
      ratingCount: (p['rating_count'] as num?)?.toInt() ?? 0,
      acceptanceRate: ((p['acceptance_rate'] ?? 100) as num).toDouble(),
      totalRides: (p['total_rides'] as num?)?.toInt() ?? 0,
      totalDeliveries: (p['total_deliveries'] as num?)?.toInt() ?? 0,
      acceptsRides: p['accepts_rides'] as bool? ?? true,
      acceptsDeliveries: p['accepts_deliveries'] as bool? ?? true,
      commissionPct: ((p['commission_pct'] ?? 15) as num).toDouble(),
      memberSince: DateTime.tryParse(j['created_at'] as String? ?? ''),
      payoutMethod: p['payout_method'] as String?,
      payoutAccount: p['payout_account'] as String?,
      emergencyName: p['emergency_contact_name'] as String?,
      emergencyPhone: p['emergency_contact_phone'] as String?,
    );
  }
}

class TripPlace {
  const TripPlace({required this.location, this.address, this.landmark});
  final LatLng location;
  final String? address;
  final String? landmark;

  String get display => (address ?? landmark ?? '').trim().isEmpty
      ? '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}'
      : (address ?? landmark)!;

  static TripPlace fromJson(Map<String, dynamic> j) {
    final loc = (j['location'] ?? j) as Map<String, dynamic>;
    return TripPlace(
      location: LatLng((loc['lat'] as num).toDouble(), (loc['lng'] as num).toDouble()),
      address: j['address'] as String?,
      landmark: j['landmark'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'location': {'lat': location.latitude, 'lng': location.longitude},
        'address': address,
        'landmark': landmark,
      };
}

/// A dispatch offer the driver can accept or decline before it times out.
class Offer {
  const Offer({
    required this.id,
    required this.bookingId,
    required this.service,
    required this.pickup,
    required this.dropoff,
    required this.distanceM,
    required this.etaToPickupS,
    required this.fareCents,
    required this.commissionCents,
    required this.expiresAt,
    this.deliveryCategory,
  });

  final String id;
  final String bookingId;
  final ServiceType service;
  final TripPlace pickup;
  final TripPlace dropoff;
  final int distanceM;
  final int etaToPickupS;
  final int fareCents;
  final int commissionCents;
  final DateTime expiresAt;
  final String? deliveryCategory;

  int get earningsCents => fareCents - commissionCents;
  int get secondsLeft => expiresAt.difference(DateTime.now()).inSeconds.clamp(0, 999);
  bool get expired => secondsLeft <= 0;

  static Offer fromJson(Map<String, dynamic> j) {
    final b = (j['booking'] ?? j) as Map<String, dynamic>;
    return Offer(
      id: j['id'] as String,
      bookingId: b['id'] as String? ?? '',
      service: serviceFromString(b['service'] as String? ?? 'ride'),
      pickup: TripPlace.fromJson(b['pickup'] as Map<String, dynamic>),
      dropoff: TripPlace.fromJson(b['dropoff'] as Map<String, dynamic>),
      distanceM: (j['distance_m'] as num?)?.toInt() ?? 0,
      etaToPickupS: (j['eta_seconds'] as num?)?.toInt() ?? 0,
      fareCents: (b['quoted_fare_cents'] as num?)?.toInt() ?? 0,
      commissionCents: (b['commission_cents'] as num?)?.toInt() ?? 0,
      expiresAt: DateTime.tryParse(j['expires_at'] as String? ?? '') ??
          DateTime.now().add(const Duration(seconds: 20)),
      deliveryCategory: (b['delivery'] as Map<String, dynamic>?)?['category'] as String?,
    );
  }
}

class Trip {
  Trip({
    required this.id,
    required this.reference,
    required this.service,
    required this.status,
    required this.pickup,
    required this.dropoff,
    required this.fareCents,
    required this.commissionCents,
    required this.createdAt,
    this.customerName = '',
    this.customerPhone,
    this.distanceM = 0,
    this.route = const <LatLng>[],
    this.paymentMethod = 'cash',
    this.deliveryCategory,
    this.recipientName,
    this.recipientPhone,
    this.packageDescription,
    this.instructions,
    this.recipientOtp,
    this.tipCents = 0,
    this.timeline = const <TripEvent>[],
  });

  final String id;
  final String reference;
  final ServiceType service;
  TripStatus status;
  final TripPlace pickup;
  final TripPlace dropoff;
  final int fareCents;
  final int commissionCents;
  final DateTime createdAt;
  final String customerName;
  final String? customerPhone;
  final int distanceM;
  final List<LatLng> route;
  final String paymentMethod;
  final String? deliveryCategory;
  final String? recipientName;
  final String? recipientPhone;
  final String? packageDescription;
  final String? instructions;
  final String? recipientOtp;
  int tipCents;
  List<TripEvent> timeline;

  int get earningsCents => fareCents - commissionCents + tipCents;

  static Trip fromJson(Map<String, dynamic> j) {
    final d = (j['delivery'] ?? const <String, dynamic>{}) as Map<String, dynamic>;
    final c = (j['customer'] ?? const <String, dynamic>{}) as Map<String, dynamic>;
    final r = (j['route'] ?? const <String, dynamic>{}) as Map<String, dynamic>;
    return Trip(
      id: j['id'] as String,
      reference: j['reference'] as String? ?? '',
      service: serviceFromString(j['service'] as String? ?? 'ride'),
      status: tripStatusFromString(j['status'] as String?),
      pickup: TripPlace.fromJson(j['pickup'] as Map<String, dynamic>),
      dropoff: TripPlace.fromJson(j['dropoff'] as Map<String, dynamic>),
      fareCents: (j['quoted_fare_cents'] as num?)?.toInt() ?? 0,
      commissionCents: (j['commission_cents'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(j['created_at'] as String? ?? '') ?? DateTime.now(),
      customerName: c['full_name'] as String? ?? '',
      customerPhone: c['phone'] as String?,
      distanceM: (r['distance_m'] as num?)?.toInt() ?? 0,
      route: ((r['polyline'] ?? const <dynamic>[]) as List)
          .whereType<Map>()
          .map((p) => LatLng(((p['lat'] ?? 0) as num).toDouble(), ((p['lng'] ?? 0) as num).toDouble()))
          .toList(),
      paymentMethod: j['payment_method'] as String? ?? 'cash',
      deliveryCategory: d['category'] as String?,
      recipientName: d['recipient_name'] as String?,
      recipientPhone: d['recipient_phone'] as String?,
      packageDescription: d['package_description'] as String?,
      instructions: d['instructions'] as String?,
      recipientOtp: d['recipient_otp'] as String?,
      tipCents: (j['tip_cents'] as num?)?.toInt() ?? 0,
      timeline: ((j['timeline'] ?? const <dynamic>[]) as List)
          .whereType<Map<String, dynamic>>()
          .map(TripEvent.fromJson)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'reference': reference,
        'service': serviceToString(service),
        'status': tripStatusToString(status),
        'pickup': pickup.toJson(),
        'dropoff': dropoff.toJson(),
        'quoted_fare_cents': fareCents,
        'commission_cents': commissionCents,
        'created_at': createdAt.toIso8601String(),
        'customer': {'full_name': customerName, 'phone': customerPhone},
        'route': {
          'distance_m': distanceM,
          'polyline': route.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList(),
        },
        'payment_method': paymentMethod,
        'tip_cents': tipCents,
        'delivery': service == ServiceType.delivery
            ? {
                'category': deliveryCategory,
                'recipient_name': recipientName,
                'recipient_phone': recipientPhone,
                'package_description': packageDescription,
                'instructions': instructions,
                'recipient_otp': recipientOtp,
              }
            : null,
        'timeline': timeline.map((e) => e.toJson()).toList(),
      };
}

class TripEvent {
  const TripEvent({required this.status, required this.at});
  final TripStatus status;
  final DateTime at;

  static TripEvent fromJson(Map<String, dynamic> j) => TripEvent(
        status: tripStatusFromString(j['status'] as String?),
        at: DateTime.tryParse(j['at'] as String? ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() =>
      {'status': tripStatusToString(status), 'at': at.toIso8601String()};
}

class Earnings {
  const Earnings({
    this.grossCents = 0,
    this.commissionCents = 0,
    this.cashCents = 0,
    this.digitalCents = 0,
    this.trips = 0,
    this.deliveries = 0,
    this.byDay = const <DayEarnings>[],
  });

  final int grossCents;
  final int commissionCents;
  final int cashCents;
  final int digitalCents;
  final int trips;
  final int deliveries;
  final List<DayEarnings> byDay;

  int get netCents => grossCents - commissionCents;

  static Earnings fromJson(Map<String, dynamic> j) => Earnings(
        grossCents: (j['gross_cents'] as num?)?.toInt() ?? 0,
        commissionCents: (j['commission_cents'] as num?)?.toInt() ?? 0,
        cashCents: (j['cash_cents'] as num?)?.toInt() ?? 0,
        digitalCents: (j['digital_cents'] as num?)?.toInt() ?? 0,
        trips: (j['trips'] as num?)?.toInt() ?? 0,
        deliveries: (j['deliveries'] as num?)?.toInt() ?? 0,
        byDay: ((j['by_day'] ?? const <dynamic>[]) as List)
            .whereType<Map<String, dynamic>>()
            .map(DayEarnings.fromJson)
            .toList(),
      );
}

class DayEarnings {
  const DayEarnings({required this.date, required this.netCents, this.trips = 0});
  final DateTime date;
  final int netCents;
  final int trips;

  static DayEarnings fromJson(Map<String, dynamic> j) => DayEarnings(
        date: DateTime.tryParse(j['date'] as String? ?? '') ?? DateTime.now(),
        netCents: (j['net_cents'] as num?)?.toInt() ?? 0,
        trips: (j['trips'] as num?)?.toInt() ?? 0,
      );
}

class WalletEntry {
  const WalletEntry({
    required this.id,
    required this.kind,
    required this.amountCents,
    required this.at,
    this.reference,
  });

  final String id;
  final String kind; // fare | commission | tip | payout | adjustment
  final int amountCents;
  final DateTime at;
  final String? reference;
}

class Payout {
  const Payout({
    required this.id,
    required this.amountCents,
    required this.status,
    required this.requestedAt,
    this.method,
  });

  final String id;
  final int amountCents;
  final String status; // requested | approved | paid | rejected | failed
  final DateTime requestedAt;
  final String? method;
}

class Wallet {
  const Wallet({
    this.balanceCents = 0,
    this.commissionDueCents = 0,
    this.cashCollectedCents = 0,
    this.paidOutCents = 0,
    this.entries = const <WalletEntry>[],
  });

  final int balanceCents;
  final int commissionDueCents;
  final int cashCollectedCents;
  final int paidOutCents;
  final List<WalletEntry> entries;
}

class DriverNotification {
  const DriverNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.at,
  });
  final String id;
  final String title;
  final String body;
  final DateTime at;
}

/// The next status the driver may move a trip to, or null when the step needs
/// its own flow (cash collection, recipient code, rating) or the trip is over.
/// Mirrors the server state machine in docs/ARCHITECTURE.md §4, so the app can
/// never offer a transition the backend would reject.
TripStatus? nextStatusFor(Trip t) {
  final delivery = t.service == ServiceType.delivery;
  return switch (t.status) {
    TripStatus.accepted => TripStatus.driverArriving,
    TripStatus.driverArriving => delivery ? TripStatus.arrivedPickup : TripStatus.arrived,
    TripStatus.arrived => TripStatus.inProgress,
    TripStatus.inProgress => TripStatus.completed,
    TripStatus.arrivedPickup => TripStatus.collected,
    TripStatus.collected => TripStatus.inTransit,
    TripStatus.inTransit => TripStatus.arrivedDropoff,
    TripStatus.recipientVerified => TripStatus.delivered,
    _ => null,
  };
}
