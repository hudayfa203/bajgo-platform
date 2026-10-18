import 'package:bajgo_driver/core/utils/money.dart';
import 'package:bajgo_driver/core/utils/phone.dart';
import 'package:bajgo_driver/data/mock_api.dart';
import 'package:bajgo_driver/data/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

Trip _trip(ServiceType service, TripStatus status) => Trip(
      id: 't1',
      reference: 'BJ260101-1001',
      service: service,
      status: status,
      pickup: const TripPlace(location: LatLng(8.4091, 48.4823), address: 'Suuqa weyn'),
      dropoff: const TripPlace(location: LatLng(8.4203, 48.4902), address: 'PSU'),
      fareCents: 150,
      commissionCents: 10,
      createdAt: DateTime(2026, 10, 18, 9),
    );

void main() {
  group('Fare engine — BajGo default pricing (\$1 per 2 km)', () {
    const expected = <int, int>{
      1000: 100, // 1 km  → $1.00 (minimum applies)
      2000: 100, // 2 km  → $1.00
      3000: 150, // 3 km  → $1.50
      4000: 200, // 4 km  → $2.00
      6000: 300, // 6 km  → $3.00
      10000: 500, // 10 km → $5.00
    };

    expected.forEach((metres, cents) {
      test('${metres ~/ 1000} km costs ${Money.format(cents)}', () {
        expect(DemoPricing.fareCents(metres), cents);
      });
    });

    test('never falls below the minimum fare', () {
      for (final m in [0, 100, 900, 1999]) {
        expect(DemoPricing.fareCents(m), greaterThanOrEqualTo(DemoPricing.minimumFareCents));
      }
    });

    test('rounds up to the nearest 10 cents', () {
      expect(DemoPricing.fareCents(3330) % 10, 0);
      expect(DemoPricing.fareCents(7777) % 10, 0);
    });

    test('commission in the demo is a flat 10 cents per completed booking', () {
      expect(DemoPricing.commissionPerBookingCents, 10);
    });

    test('driver earnings are the fare less commission', () {
      final t = _trip(ServiceType.ride, TripStatus.paid);
      expect(t.earningsCents, 140);
      t.tipCents = 50;
      expect(t.earningsCents, 190);
    });
  });

  group('Trip state machine', () {
    test('a ride runs accepted → arriving → arrived → in progress → completed', () {
      var status = TripStatus.accepted;
      final seen = <TripStatus>[status];
      for (var i = 0; i < 10; i++) {
        final next = nextStatusFor(_trip(ServiceType.ride, status));
        if (next == null) break;
        status = next;
        seen.add(status);
      }
      expect(seen, [
        TripStatus.accepted,
        TripStatus.driverArriving,
        TripStatus.arrived,
        TripStatus.inProgress,
        TripStatus.completed,
      ]);
    });

    test('a delivery runs through collection, transit and the drop-off point', () {
      var status = TripStatus.accepted;
      final seen = <TripStatus>[status];
      for (var i = 0; i < 10; i++) {
        final next = nextStatusFor(_trip(ServiceType.delivery, status));
        if (next == null) break;
        status = next;
        seen.add(status);
      }
      expect(seen, [
        TripStatus.accepted,
        TripStatus.driverArriving,
        TripStatus.arrivedPickup,
        TripStatus.collected,
        TripStatus.inTransit,
        TripStatus.arrivedDropoff,
      ]);
    });

    test('the drop-off point stops for the recipient code', () {
      expect(nextStatusFor(_trip(ServiceType.delivery, TripStatus.arrivedDropoff)), isNull);
      expect(
        nextStatusFor(_trip(ServiceType.delivery, TripStatus.recipientVerified)),
        TripStatus.delivered,
      );
    });

    test('finished trips offer no further transition', () {
      for (final s in [
        TripStatus.paid,
        TripStatus.cancelled,
        TripStatus.failed,
        TripStatus.returned,
        TripStatus.expired,
      ]) {
        expect(nextStatusFor(_trip(ServiceType.ride, s)), isNull, reason: '$s');
        expect(tripIsFinished(s), isTrue, reason: '$s');
      }
    });

    test('wire values map both ways', () {
      expect(tripStatusFromString('in_progress'), TripStatus.inProgress);
      expect(tripStatusFromString('recipient_verified'), TripStatus.recipientVerified);
      expect(tripStatusFromString('cancelled_by_driver'), TripStatus.cancelled);
      expect(tripStatusToString(TripStatus.arrivedDropoff), 'arrived_dropoff');
    });
  });

  group('Offer countdown', () {
    Offer offer(DateTime expires) => Offer(
          id: 'o1',
          bookingId: 'b1',
          service: ServiceType.ride,
          pickup: const TripPlace(location: LatLng(8.4091, 48.4823)),
          dropoff: const TripPlace(location: LatLng(8.4203, 48.4902)),
          distanceM: 3000,
          etaToPickupS: 180,
          fareCents: 150,
          commissionCents: 10,
          expiresAt: expires,
        );

    test('earnings exclude the commission', () {
      expect(offer(DateTime.now()).earningsCents, 140);
    });

    test('an elapsed offer is expired', () {
      expect(offer(DateTime.now().subtract(const Duration(seconds: 1))).expired, isTrue);
    });

    test('a fresh offer has seconds left', () {
      expect(offer(DateTime.now().add(const Duration(seconds: 20))).secondsLeft, greaterThan(15));
    });
  });

  group('Money', () {
    test('formats cents as USD', () {
      expect(Money.format(0), r'$0.00');
      expect(Money.format(10), r'$0.10');
      expect(Money.format(150), r'$1.50');
      expect(Money.format(123456), r'$1,234.56');
      expect(Money.format(-250), r'-$2.50');
      expect(Money.format(150, showSign: true), r'+$1.50');
    });

    test('parses typed amounts', () {
      expect(Money.parse('12'), 1200);
      expect(Money.parse('12.5'), 1250);
      expect(Money.parse(r'$12.50'), 1250);
      expect(Money.parse('abc'), isNull);
    });
  });

  group('Somali phone numbers', () {
    test('normalizes the usual input shapes', () {
      for (final input in ['0905000103', '905000103', '+252905000103', '252 90 500 0103']) {
        expect(SomaliPhone.normalize(input), '+252905000103', reason: input);
      }
    });

    test('rejects what is not a mobile number', () {
      expect(SomaliPhone.normalize('123'), isNull);
      expect(SomaliPhone.normalize(''), isNull);
    });

    test('formats and masks for display', () {
      expect(SomaliPhone.format('+252905000103'), '+252 90 500 0103');
      expect(SomaliPhone.masked('+252905000103'), '+252 90 *** *103');
    });
  });
}
