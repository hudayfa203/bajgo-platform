import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../core/theme/bg_colors.dart';
import '../core/theme/bg_theme.dart';
import '../core/utils/money.dart';
import '../core/widgets.dart';
import '../data/models.dart';
import '../data/providers.dart';
import '../l10n/generated/app_localizations.dart';
import 'trip_screen.dart' show statusLabel;

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final filter = ref.watch(historyFilterProvider);
    final history = ref.watch(historyProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.historyTitle)),
      body: SafeArea(
        child: Column(
          children: [
            BgDemoBanner(label: l.mockBanner),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  for (final f in [
                    ('all', l.filterAll),
                    ('rides', l.filterRides),
                    ('deliveries', l.filterDeliveries),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(f.$2),
                        selected: filter == f.$1,
                        onSelected: (_) =>
                            ref.read(historyFilterProvider.notifier).state = f.$1,
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => ref.invalidate(historyProvider),
                child: history.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => BgEmptyState(
                    title: l.errorGeneric,
                    icon: Icons.error_outline,
                    action: BgButton(
                      label: l.retry,
                      expand: false,
                      onPressed: () => ref.invalidate(historyProvider),
                    ),
                  ),
                  data: (all) {
                    final list = all.where((t) {
                      if (filter == 'rides') return t.service == ServiceType.ride;
                      if (filter == 'deliveries') return t.service == ServiceType.delivery;
                      return true;
                    }).toList();

                    if (list.isEmpty) {
                      return BgEmptyState(
                        title: l.noHistory,
                        body: l.noHistoryHint,
                        icon: Icons.receipt_long_outlined,
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _TripTile(trip: list[i]),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TripTile extends StatelessWidget {
  const _TripTile({required this.trip});
  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final settled = trip.status == TripStatus.paid;

    return BgCard(
      onTap: () => context.push('/history/trip', extra: trip),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                trip.service == ServiceType.delivery
                    ? Icons.inventory_2_outlined
                    : Icons.person_outline,
                size: 18,
                color: trip.service == ServiceType.delivery ? BgColors.saffron : BgColors.dBlue,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  DateFormat('dd MMM yyyy · HH:mm').format(trip.createdAt),
                  style: BgType.caption,
                ),
              ),
              Text(
                settled ? Money.format(trip.earningsCents) : '—',
                style: BgType.bodyStrong.copyWith(
                  color: settled ? BgColors.success : BgColors.dText2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(trip.dropoff.display, style: BgType.bodyStrong, maxLines: 1),
          Text(trip.pickup.display, style: BgType.caption, maxLines: 1),
          const SizedBox(height: 10),
          BgPill(
            label: statusLabel(trip.status, l),
            colour: switch (trip.status) {
              TripStatus.paid || TripStatus.delivered || TripStatus.completed => BgColors.success,
              TripStatus.cancelled || TripStatus.failed || TripStatus.expired => BgColors.danger,
              _ => BgColors.dSurface2,
            },
            textColour: switch (trip.status) {
              TripStatus.paid ||
              TripStatus.delivered ||
              TripStatus.completed ||
              TripStatus.cancelled ||
              TripStatus.failed ||
              TripStatus.expired =>
                BgColors.white,
              _ => BgColors.dText,
            },
          ),
        ],
      ),
    );
  }
}

/// Read-only receipt for a past trip, with its timeline.
class TripDetailScreen extends StatelessWidget {
  const TripDetailScreen({super.key, required this.trip});
  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(trip.service == ServiceType.delivery ? l.deliveryTitle : l.rideTitle),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SizedBox(
              height: 180,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(BgRadius.card),
                child: BgMap(
                  centre: trip.pickup.location,
                  route: trip.route,
                  pickup: trip.pickup.location,
                  dropoff: trip.dropoff.location,
                  interactive: false,
                ),
              ),
            ),
            const SizedBox(height: 16),
            BgCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BgRouteRows(
                    pickupLabel: l.pickup,
                    pickup: trip.pickup.display,
                    dropoffLabel: l.dropoff,
                    dropoff: trip.dropoff.display,
                  ),
                  const Divider(height: 24),
                  BgKeyValue(l.reference, trip.reference),
                  BgKeyValue(l.distance, l.kmShort((trip.distanceM / 1000).toStringAsFixed(1))),
                  BgKeyValue(l.customer, trip.customerName),
                  if (trip.recipientName != null) BgKeyValue(l.recipient, trip.recipientName!),
                ],
              ),
            ),
            const SizedBox(height: 12),
            BgCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BgSectionTitle(l.earningsBreakdown),
                  BgKeyValue(l.fare, Money.format(trip.fareCents)),
                  if (trip.tipCents > 0) BgKeyValue(l.tip, Money.format(trip.tipCents)),
                  BgKeyValue(l.commission, '-${Money.format(trip.commissionCents)}'),
                  const Divider(height: 20),
                  BgKeyValue(
                    l.yourEarnings,
                    Money.format(trip.earningsCents),
                    strong: true,
                    valueColour: BgColors.success,
                  ),
                ],
              ),
            ),
            if (trip.timeline.isNotEmpty) ...[
              const SizedBox(height: 12),
              BgCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BgSectionTitle(l.timeline),
                    for (final e in trip.timeline)
                      BgKeyValue(
                        statusLabel(e.status, l),
                        DateFormat('HH:mm').format(e.at),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
