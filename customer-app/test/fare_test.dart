import 'package:bajgo_customer/data/demo_api.dart';
import 'package:bajgo_customer/data/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group(r'Fare engine — BajGo default pricing ($1 per 2 km)', () {
    // The table published in the brief and on the pricing page.
    const expected = <int, int>{
      1000: 100, // 1 km  → $1.00 (minimum applies)
      2000: 100, // 2 km  → $1.00
      3000: 150, // 3 km  → $1.50
      4000: 200, // 4 km  → $2.00
      6000: 300, // 6 km  → $3.00
      10000: 500, // 10 km → $5.00
    };

    expected.forEach((metres, cents) {
      test('${metres ~/ 1000} km costs ${formatMoney(cents)}', () {
        expect(DemoPricing.fareCents(metres), cents);
      });
    });

    test(r'never falls below the $1.00 minimum', () {
      for (final m in [0, 50, 100, 400, 900, 1999]) {
        expect(DemoPricing.fareCents(m), greaterThanOrEqualTo(100));
      }
    });

    test('rounds up to the nearest 10 cents', () {
      // 3.33 km → 166.5 → 170
      expect(DemoPricing.fareCents(3330) % 10, 0);
      expect(DemoPricing.fareCents(7777) % 10, 0);
    });

    test('package size extras are added before the minimum', () {
      final small = DemoPricing.fareCents(6000);
      final large = DemoPricing.fareCents(6000, extrasCents: 100);
      expect(large - small, 100);
    });

    test('a promotion reduces the fare but never below zero', () {
      expect(DemoPricing.fareCents(6000, discountCents: 50), 250);
      expect(DemoPricing.fareCents(1000, discountCents: 10000), 0);
    });

    test('commission in the demo is a flat 10 cents per completed booking', () {
      expect(DemoPricing.commissionPerBookingCents, 10);
    });
  });

  group('Money formatting', () {
    test('renders whole and part dollars', () {
      expect(formatMoney(0), r'$0.00');
      expect(formatMoney(5), r'$0.05');
      expect(formatMoney(100), r'$1.00');
      expect(formatMoney(150), r'$1.50');
      expect(formatMoney(123456), r'$1234.56');
    });

    test('handles negative amounts', () {
      expect(formatMoney(-250), r'-$2.50');
    });
  });

  group('Distance and duration helpers', () {
    test('kilometres are shown to one decimal', () {
      expect(formatKm(1000), '1.0');
      expect(formatKm(3330), '3.3');
    });

    test('duration rounds up to whole minutes, minimum one', () {
      expect(minutesFromSeconds(10), 1);
      expect(minutesFromSeconds(61), 2);
      expect(minutesFromSeconds(600), 10);
    });

    test('road distance is longer than the straight line', () {
      const a = LatLng(8.4064, 48.4847);
      const b = LatLng(8.4203, 48.4902);
      const straight = Distance();
      final road = DemoApi.roadMetres(a, b);
      expect(road, greaterThan(straight.as(LengthUnit.Meter, a, b).round()));
    });
  });

  group('Booking status mapping', () {
    test('wire values map to enum values', () {
      expect(statusFromString('searching'), BookingStatus.searching);
      expect(statusFromString('in_progress'), BookingStatus.inProgress);
      expect(statusFromString('recipient_verified'), BookingStatus.recipientVerified);
      expect(statusFromString('cancelled_by_driver'), BookingStatus.cancelled);
      expect(statusFromString('nonsense'), BookingStatus.unknown);
    });

    test('terminal and active states are mutually exclusive', () {
      for (final s in BookingStatus.values) {
        if (s == BookingStatus.quoted || s == BookingStatus.unknown) continue;
        expect(isTerminal(s) != isActive(s), isTrue, reason: '$s');
      }
    });

    test('a completed trip is terminal, an accepted one is active', () {
      expect(isTerminal(BookingStatus.delivered), isTrue);
      expect(isActive(BookingStatus.accepted), isTrue);
      expect(isActive(BookingStatus.searching), isTrue);
    });
  });

  group('Name initial', () {
    test('falls back for empty input', () {
      expect(initialOf(null), 'B');
      expect(initialOf('   '), 'B');
    });

    test('uppercases the first letter', () {
      expect(initialOf('cabdi'), 'C');
      expect(initialOf('Hudayfi Mohamed'), 'H');
    });
  });
}
