import 'package:latlong2/latlong.dart';

/// All money is integer USD cents, matching the API contract (docs/API.md).
String formatMoney(int cents) {
  final sign = cents < 0 ? '-' : '';
  final v = cents.abs();
  return '$sign\$${(v ~/ 100)}.${(v % 100).toString().padLeft(2, '0')}';
}

String formatKm(int metres) => (metres / 1000).toStringAsFixed(1);

int minutesFromSeconds(int seconds) => (seconds / 60).ceil().clamp(1, 999);

enum ServiceType { ride, delivery }

ServiceType serviceFromString(String s) =>
    s == 'delivery' ? ServiceType.delivery : ServiceType.ride;

String serviceToString(ServiceType s) => s == ServiceType.delivery ? 'delivery' : 'ride';

enum BookingStatus {
  quoted,
  requested,
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
  unknown,
}

const Map<String, BookingStatus> _statusWire = {
  'quoted': BookingStatus.quoted,
  'requested': BookingStatus.requested,
  'searching': BookingStatus.searching,
  'accepted': BookingStatus.accepted,
  'driver_arriving': BookingStatus.driverArriving,
  'arrived': BookingStatus.arrived,
  'in_progress': BookingStatus.inProgress,
  'arrived_pickup': BookingStatus.arrivedPickup,
  'collected': BookingStatus.collected,
  'in_transit': BookingStatus.inTransit,
  'arrived_dropoff': BookingStatus.arrivedDropoff,
  'recipient_verified': BookingStatus.recipientVerified,
  'completed': BookingStatus.completed,
  'delivered': BookingStatus.delivered,
  'paid': BookingStatus.paid,
  'cancelled_by_customer': BookingStatus.cancelled,
  'cancelled_by_driver': BookingStatus.cancelled,
  'cancelled_by_admin': BookingStatus.cancelled,
  'expired': BookingStatus.expired,
  'failed': BookingStatus.failed,
  'returned': BookingStatus.returned,
};

BookingStatus statusFromString(String? s) =>
    _statusWire[s ?? ''] ?? BookingStatus.unknown;

String statusToString(BookingStatus s) {
  for (final e in _statusWire.entries) {
    if (e.value == s) return e.key;
  }
  return 'unknown';
}

/// Statuses where the trip is over and nothing more will happen.
bool isTerminal(BookingStatus s) =>
    s == BookingStatus.paid ||
    s == BookingStatus.completed ||
    s == BookingStatus.delivered ||
    s == BookingStatus.cancelled ||
    s == BookingStatus.expired ||
    s == BookingStatus.failed ||
    s == BookingStatus.returned;

bool isActive(BookingStatus s) => !isTerminal(s) && s != BookingStatus.quoted;

class Place {
  const Place({required this.location, this.address, this.landmark, this.label});

  final LatLng location;
  final String? address;
  final String? landmark;
  final String? label;

  String get display => (label ?? address ?? landmark ?? '')
      .trim()
      .isEmpty
      ? '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}'
      : (label ?? address ?? landmark)!;

  Map<String, dynamic> toJson() => {
        'location': {'lat': location.latitude, 'lng': location.longitude},
        if (address != null) 'address': address,
        if (landmark != null) 'landmark': landmark,
      };

  static Place fromJson(Map<String, dynamic> j) {
    final loc = (j['location'] ?? j) as Map<String, dynamic>;
    return Place(
      location: LatLng((loc['lat'] as num).toDouble(), (loc['lng'] as num).toDouble()),
      address: j['address'] as String?,
      landmark: j['landmark'] as String?,
      label: j['label'] as String?,
    );
  }
}

class SavedPlace {
  const SavedPlace({
    required this.id,
    required this.label,
    required this.kind,
    required this.place,
  });

  final String id;
  final String label;
  final String kind; // home | work | custom | recent
  final Place place;

  static SavedPlace fromJson(Map<String, dynamic> j) => SavedPlace(
        id: j['id'] as String,
        label: j['label'] as String? ?? '',
        kind: j['kind'] as String? ?? 'custom',
        place: Place.fromJson(j),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'kind': kind,
        ...place.toJson(),
      };
}

class AppUser {
  const AppUser({
    required this.id,
    required this.phone,
    this.fullName,
    this.language = 'so',
    this.avatarUrl,
  });

  final String id;
  final String phone;
  final String? fullName;
  final String language;
  final String? avatarUrl;

  bool get needsName => (fullName ?? '').trim().isEmpty;

  AppUser copyWith({String? fullName, String? language}) => AppUser(
        id: id,
        phone: phone,
        fullName: fullName ?? this.fullName,
        language: language ?? this.language,
        avatarUrl: avatarUrl,
      );

  static AppUser fromJson(Map<String, dynamic> j) => AppUser(
        id: j['id'] as String,
        phone: (j['phone'] ?? j['phone_e164'] ?? '') as String,
        fullName: j['full_name'] as String?,
        language: j['language'] as String? ?? 'so',
        avatarUrl: j['avatar_url'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'phone': phone,
        'full_name': fullName,
        'language': language,
        'avatar_url': avatarUrl,
      };
}

class DriverCard {
  const DriverCard({
    required this.id,
    required this.fullName,
    required this.rating,
    required this.fleetCode,
    required this.plate,
    this.vehicleColour,
    this.phone,
    this.avatarUrl,
  });

  final String id;
  final String fullName;
  final double rating;
  final String fleetCode;
  final String plate;
  final String? vehicleColour;
  final String? phone;
  final String? avatarUrl;

  static DriverCard fromJson(Map<String, dynamic> j) {
    final v = (j['vehicle'] ?? const <String, dynamic>{}) as Map<String, dynamic>;
    return DriverCard(
      id: j['id'] as String? ?? '',
      fullName: j['full_name'] as String? ?? '',
      rating: ((j['rating'] ?? j['rating_avg'] ?? 5) as num).toDouble(),
      fleetCode: v['fleet_code'] as String? ?? '',
      plate: v['plate_number'] as String? ?? '',
      vehicleColour: v['colour'] as String?,
      phone: j['phone'] as String?,
      avatarUrl: j['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'full_name': fullName,
        'rating': rating,
        'phone': phone,
        'avatar_url': avatarUrl,
        'vehicle': {'fleet_code': fleetCode, 'plate_number': plate, 'colour': vehicleColour},
      };
}

class FareBreakdown {
  const FareBreakdown({
    this.baseCents = 0,
    this.distanceCents = 0,
    this.waitingCents = 0,
    this.extrasCents = 0,
    this.discountCents = 0,
    this.multiplier = 1.0,
    this.minimumApplied = false,
  });

  final int baseCents;
  final int distanceCents;
  final int waitingCents;
  final int extrasCents;
  final int discountCents;
  final double multiplier;
  final bool minimumApplied;

  static FareBreakdown fromJson(Map<String, dynamic> j) => FareBreakdown(
        baseCents: (j['base'] as num?)?.toInt() ?? 0,
        distanceCents: (j['distance'] as num?)?.toInt() ?? 0,
        waitingCents: (j['waiting'] as num?)?.toInt() ?? 0,
        extrasCents: (j['extras'] as num?)?.toInt() ?? 0,
        discountCents: (j['discount'] as num?)?.toInt() ?? 0,
        multiplier: ((j['multiplier'] ?? 1) as num).toDouble(),
        minimumApplied: j['minimum_applied'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'base': baseCents,
        'distance': distanceCents,
        'waiting': waitingCents,
        'extras': extrasCents,
        'discount': discountCents,
        'multiplier': multiplier,
        'minimum_applied': minimumApplied,
      };
}

class Quote {
  const Quote({
    required this.id,
    required this.service,
    required this.pickup,
    required this.dropoff,
    required this.distanceM,
    required this.durationS,
    required this.fareCents,
    required this.breakdown,
    this.polyline = const <LatLng>[],
    this.pricingVersion = 1,
    this.expiresAt,
  });

  final String id;
  final ServiceType service;
  final Place pickup;
  final Place dropoff;
  final int distanceM;
  final int durationS;
  final int fareCents;
  final FareBreakdown breakdown;
  final List<LatLng> polyline;
  final int pricingVersion;
  final DateTime? expiresAt;

  bool get expired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  static Quote fromJson(Map<String, dynamic> j) => Quote(
        id: (j['quote_id'] ?? j['id']) as String,
        service: serviceFromString(j['service'] as String? ?? 'ride'),
        pickup: Place.fromJson(j['pickup'] as Map<String, dynamic>),
        dropoff: Place.fromJson(j['dropoff'] as Map<String, dynamic>),
        distanceM: (j['distance_m'] as num?)?.toInt() ?? 0,
        durationS: (j['duration_s'] as num?)?.toInt() ?? 0,
        fareCents: (j['fare_cents'] as num?)?.toInt() ?? 0,
        breakdown: FareBreakdown.fromJson(
            (j['breakdown'] ?? const <String, dynamic>{}) as Map<String, dynamic>),
        polyline: decodePolylinePoints(j['polyline']),
        pricingVersion:
            ((j['pricing_version'] as Map<String, dynamic>?)?['version'] as num?)?.toInt() ?? 1,
        expiresAt: j['expires_at'] != null ? DateTime.tryParse(j['expires_at'] as String) : null,
      );
}

/// The API may send a polyline either as an encoded string or as a list of points.
/// The demo backend uses the list form; both are handled.
List<LatLng> decodePolylinePoints(dynamic raw) {
  if (raw is List) {
    return raw
        .whereType<Map>()
        .map((p) => LatLng(
              ((p['lat'] ?? 0) as num).toDouble(),
              ((p['lng'] ?? 0) as num).toDouble(),
            ))
        .toList();
  }
  return const <LatLng>[];
}

class DeliveryDetails {
  const DeliveryDetails({
    required this.category,
    this.senderName,
    this.senderPhone,
    this.recipientName,
    this.recipientPhone,
    this.description,
    this.size = 'small',
    this.weightKg,
    this.instructions,
    this.photoPath,
    this.proofPhotoUrl,
    this.recipientOtp,
  });

  final String category; // food | shopping | parcel | document | pharmacy | other
  final String? senderName;
  final String? senderPhone;
  final String? recipientName;
  final String? recipientPhone;
  final String? description;
  final String size; // small | medium | large
  final double? weightKg;
  final String? instructions;
  final String? photoPath;
  final String? proofPhotoUrl;
  final String? recipientOtp;

  Map<String, dynamic> toJson() => {
        'category': category,
        'sender_name': senderName,
        'sender_phone': senderPhone,
        'recipient_name': recipientName,
        'recipient_phone': recipientPhone,
        'package_description': description,
        'package_size': size,
        'package_weight_kg': weightKg,
        'instructions': instructions,
        'proof_photo_url': proofPhotoUrl,
        'recipient_otp': recipientOtp,
      };

  static DeliveryDetails fromJson(Map<String, dynamic> j) => DeliveryDetails(
        category: j['category'] as String? ?? 'parcel',
        senderName: j['sender_name'] as String?,
        senderPhone: j['sender_phone'] as String?,
        recipientName: j['recipient_name'] as String?,
        recipientPhone: j['recipient_phone'] as String?,
        description: j['package_description'] as String?,
        size: j['package_size'] as String? ?? 'small',
        weightKg: (j['package_weight_kg'] as num?)?.toDouble(),
        instructions: j['instructions'] as String?,
        proofPhotoUrl: j['proof_photo_url'] as String?,
        recipientOtp: j['recipient_otp'] as String?,
      );

  DeliveryDetails copyWith({String? proofPhotoUrl, String? recipientOtp}) => DeliveryDetails(
        category: category,
        senderName: senderName,
        senderPhone: senderPhone,
        recipientName: recipientName,
        recipientPhone: recipientPhone,
        description: description,
        size: size,
        weightKg: weightKg,
        instructions: instructions,
        photoPath: photoPath,
        proofPhotoUrl: proofPhotoUrl ?? this.proofPhotoUrl,
        recipientOtp: recipientOtp ?? this.recipientOtp,
      );
}

class TimelineEntry {
  const TimelineEntry({required this.status, required this.at});
  final BookingStatus status;
  final DateTime at;

  static TimelineEntry fromJson(Map<String, dynamic> j) => TimelineEntry(
        status: statusFromString(j['status'] as String?),
        at: DateTime.tryParse(j['at'] as String? ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() =>
      {'status': statusToString(status), 'at': at.toIso8601String()};
}

class Booking {
  Booking({
    required this.id,
    required this.reference,
    required this.service,
    required this.status,
    required this.pickup,
    required this.dropoff,
    required this.quotedFareCents,
    required this.createdAt,
    this.driver,
    this.driverLocation,
    this.etaSeconds,
    this.distanceM = 0,
    this.durationS = 0,
    this.polyline = const <LatLng>[],
    this.finalFareCents,
    this.tipCents = 0,
    this.discountCents = 0,
    this.paymentMethod = 'cash',
    this.delivery,
    this.timeline = const <TimelineEntry>[],
    this.shareUrl,
    this.customerRating,
    this.breakdown = const FareBreakdown(),
  });

  final String id;
  final String reference;
  final ServiceType service;
  BookingStatus status;
  final Place pickup;
  final Place dropoff;
  final int quotedFareCents;
  final DateTime createdAt;
  DriverCard? driver;
  LatLng? driverLocation;
  int? etaSeconds;
  final int distanceM;
  final int durationS;
  final List<LatLng> polyline;
  int? finalFareCents;
  int tipCents;
  final int discountCents;
  final String paymentMethod;
  DeliveryDetails? delivery;
  List<TimelineEntry> timeline;
  final String? shareUrl;
  int? customerRating;
  final FareBreakdown breakdown;

  int get payableCents => (finalFareCents ?? quotedFareCents) + tipCents;

  static Booking fromJson(Map<String, dynamic> j) {
    final route = (j['route'] ?? const <String, dynamic>{}) as Map<String, dynamic>;
    return Booking(
      id: j['id'] as String,
      reference: j['reference'] as String? ?? '',
      service: serviceFromString(j['service'] as String? ?? 'ride'),
      status: statusFromString(j['status'] as String?),
      pickup: Place.fromJson(j['pickup'] as Map<String, dynamic>),
      dropoff: Place.fromJson(j['dropoff'] as Map<String, dynamic>),
      quotedFareCents: (j['quoted_fare_cents'] as num?)?.toInt() ?? 0,
      finalFareCents: (j['final_fare_cents'] as num?)?.toInt(),
      tipCents: (j['tip_cents'] as num?)?.toInt() ?? 0,
      discountCents: (j['discount_cents'] as num?)?.toInt() ?? 0,
      paymentMethod: j['payment_method'] as String? ?? 'cash',
      createdAt: DateTime.tryParse(j['created_at'] as String? ?? '') ?? DateTime.now(),
      driver: j['driver'] != null ? DriverCard.fromJson(j['driver'] as Map<String, dynamic>) : null,
      driverLocation: j['driver_location'] != null
          ? LatLng(
              ((j['driver_location']['lat'] ?? 0) as num).toDouble(),
              ((j['driver_location']['lng'] ?? 0) as num).toDouble(),
            )
          : null,
      etaSeconds: (j['eta_s'] as num?)?.toInt(),
      distanceM: (route['distance_m'] as num?)?.toInt() ?? 0,
      durationS: (route['duration_s'] as num?)?.toInt() ?? 0,
      polyline: decodePolylinePoints(route['polyline']),
      delivery: j['delivery'] != null
          ? DeliveryDetails.fromJson(j['delivery'] as Map<String, dynamic>)
          : null,
      timeline: ((j['timeline'] ?? const <dynamic>[]) as List)
          .whereType<Map<String, dynamic>>()
          .map(TimelineEntry.fromJson)
          .toList(),
      shareUrl: j['share_url'] as String?,
      customerRating: (j['customer_rating'] as num?)?.toInt(),
      breakdown:
          FareBreakdown.fromJson((j['breakdown'] ?? const <String, dynamic>{}) as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'reference': reference,
        'service': serviceToString(service),
        'status': statusToString(status),
        'pickup': pickup.toJson(),
        'dropoff': dropoff.toJson(),
        'quoted_fare_cents': quotedFareCents,
        'final_fare_cents': finalFareCents,
        'tip_cents': tipCents,
        'discount_cents': discountCents,
        'payment_method': paymentMethod,
        'created_at': createdAt.toIso8601String(),
        'driver': driver?.toJson(),
        'eta_s': etaSeconds,
        'route': {
          'distance_m': distanceM,
          'duration_s': durationS,
          'polyline': polyline.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList(),
        },
        'delivery': delivery?.toJson(),
        'timeline': timeline.map((t) => t.toJson()).toList(),
        'share_url': shareUrl,
        'customer_rating': customerRating,
        'breakdown': breakdown.toJson(),
      };
}

class PaymentMethodInfo {
  const PaymentMethodInfo({
    required this.method,
    required this.live,
    required this.labelSo,
    required this.labelEn,
  });

  final String method;
  final bool live;
  final String labelSo;
  final String labelEn;

  static PaymentMethodInfo fromJson(Map<String, dynamic> j) => PaymentMethodInfo(
        method: j['method'] as String,
        live: j['live'] as bool? ?? false,
        labelSo: j['label_so'] as String? ?? j['method'] as String,
        labelEn: j['label_en'] as String? ?? j['method'] as String,
      );
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.read = false,
  });

  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool read;
}

class SupportTicket {
  SupportTicket({
    required this.id,
    required this.reference,
    required this.subject,
    required this.category,
    required this.status,
    required this.createdAt,
    this.messages = const <TicketMessage>[],
  });

  final String id;
  final String reference;
  final String subject;
  final String category;
  String status;
  final DateTime createdAt;
  List<TicketMessage> messages;
}

class TicketMessage {
  const TicketMessage({required this.body, required this.mine, required this.at});
  final String body;
  final bool mine;
  final DateTime at;
}

class NearbyDriver {
  const NearbyDriver({required this.location, this.heading = 0});
  final LatLng location;
  final double heading;
}
