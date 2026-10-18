import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';
import '../core/widgets.dart';
import '../data/models.dart';
import '../data/providers.dart';
import '../l10n/generated/app_localizations.dart';
import 'tracking_screens.dart';

/// Trip history with Active / History tabs.
class TripsScreen extends ConsumerWidget {
  const TripsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final all = ref.watch(bookingHistoryProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.trips),
          bottom: TabBar(tabs: [Tab(text: l.active), Tab(text: l.history)]),
        ),
        body: all.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => BgEmptyState(title: l.errorGeneric, body: '$e'),
          data: (bookings) {
            final active = bookings.where((b) => isActive(b.status)).toList();
            final past = bookings.where((b) => !isActive(b.status)).toList();
            return TabBarView(
              children: [
                _TripList(
                  bookings: active,
                  emptyTitle: l.noActiveTrips,
                  emptyBody: l.noActiveTripsBody,
                ),
                _TripList(
                  bookings: past,
                  emptyTitle: l.noHistory,
                  emptyBody: l.noHistoryBody,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TripList extends ConsumerWidget {
  const _TripList({required this.bookings, required this.emptyTitle, required this.emptyBody});

  final List<Booking> bookings;
  final String emptyTitle;
  final String emptyBody;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    if (bookings.isEmpty) {
      return BgEmptyState(title: emptyTitle, body: emptyBody);
    }
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(bookingHistoryProvider);
        await ref.read(bookingHistoryProvider.future);
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(BgSpace.md),
        itemCount: bookings.length,
        separatorBuilder: (_, __) => const SizedBox(height: BgSpace.sm),
        itemBuilder: (context, i) {
          final b = bookings[i];
          final t = Theme.of(context);
          return BgCard(
            onTap: () => context.push(
              isActive(b.status) ? '/track/${b.id}' : '/booking/${b.id}',
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      b.service == ServiceType.ride
                          ? Icons.airline_seat_recline_normal
                          : Icons.inventory_2_outlined,
                      size: 18,
                      color: BgColors.blue,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      b.service == ServiceType.ride ? l.serviceRide : l.serviceDelivery,
                      style: t.textTheme.titleMedium,
                    ),
                    const Spacer(),
                    BgStatusPill(status: b.status, label: statusLabel(l, b.status)),
                  ],
                ),
                const SizedBox(height: BgSpace.sm),
                BgPlaceRows(
                  pickupLabel: b.pickup.display,
                  dropoffLabel: b.dropoff.display,
                ),
                const Divider(height: BgSpace.lg),
                Row(
                  children: [
                    Text(b.reference, style: t.textTheme.labelSmall),
                    const Spacer(),
                    Text(formatMoney(b.payableCents), style: t.textTheme.titleMedium),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Detail view for a finished booking, with its timeline.
class BookingDetailScreen extends ConsumerWidget {
  const BookingDetailScreen({super.key, required this.bookingId});
  final String bookingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l.bookingDetails)),
      body: FutureBuilder<Booking>(
        future: ref.read(apiProvider).getBooking(bookingId),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final b = snap.data!;
          return ListView(
            padding: const EdgeInsets.all(BgSpace.md),
            children: [
              SizedBox(
                height: 190,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(BgSpace.rCard),
                  child: BgMap(
                    centre: b.pickup.location,
                    pickup: b.pickup.location,
                    dropoff: b.dropoff.location,
                    route: b.polyline,
                    interactive: false,
                  ),
                ),
              ),
              const SizedBox(height: BgSpace.md),
              BgCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(b.reference, style: t.textTheme.titleMedium),
                        const Spacer(),
                        BgStatusPill(status: b.status, label: statusLabel(l, b.status)),
                      ],
                    ),
                    const SizedBox(height: BgSpace.sm),
                    BgPlaceRows(
                      pickupHint: l.pickup,
                      dropoffHint: l.dropoff,
                      pickupLabel: b.pickup.display,
                      dropoffLabel: b.dropoff.display,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: BgSpace.md),
              BgCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.timeline, style: t.textTheme.titleMedium),
                    const SizedBox(height: BgSpace.sm),
                    for (final e in b.timeline)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                  color: BgColors.blue, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Text(statusLabel(l, e.status), style: t.textTheme.bodyLarge)),
                            Text(
                              e.at.toLocal().toString().substring(11, 16),
                              style: t.textTheme.labelSmall,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: BgSpace.md),
              BgButton(
                label: l.viewReceipt,
                variant: BgButtonVariant.secondary,
                onPressed: () => context.push('/receipt/${b.id}'),
              ),
              const SizedBox(height: BgSpace.sm),
              BgButton(
                label: l.reportProblem,
                variant: BgButtonVariant.ghost,
                onPressed: () => context.push('/support'),
              ),
            ],
          );
        },
      ),
    );
  }
}
