import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/theme.dart';
import '../core/widgets.dart';
import '../data/models.dart';
import '../data/providers.dart';
import '../l10n/generated/app_localizations.dart';

String statusLabel(AppLocalizations l, BookingStatus s) {
  switch (s) {
    case BookingStatus.quoted:
      return l.statusQuoted;
    case BookingStatus.requested:
      return l.statusRequested;
    case BookingStatus.searching:
      return l.statusSearching;
    case BookingStatus.accepted:
      return l.statusAccepted;
    case BookingStatus.driverArriving:
      return l.statusArriving;
    case BookingStatus.arrived:
      return l.statusArrived;
    case BookingStatus.inProgress:
      return l.statusInProgress;
    case BookingStatus.arrivedPickup:
      return l.statusArrivedPickup;
    case BookingStatus.collected:
      return l.statusCollected;
    case BookingStatus.inTransit:
      return l.statusInTransit;
    case BookingStatus.arrivedDropoff:
      return l.statusArrivedDropoff;
    case BookingStatus.recipientVerified:
      return l.statusRecipientVerified;
    case BookingStatus.completed:
      return l.statusCompleted;
    case BookingStatus.delivered:
      return l.statusDelivered;
    case BookingStatus.paid:
      return l.statusPaid;
    case BookingStatus.cancelled:
      return l.statusCancelled;
    case BookingStatus.expired:
      return l.statusExpired;
    case BookingStatus.failed:
      return l.statusFailed;
    case BookingStatus.returned:
      return l.statusReturned;
    case BookingStatus.unknown:
      return l.statusUnknown;
  }
}

/// Live trip screen: map with the driver moving, status sheet, driver card, actions.
class TrackingScreen extends ConsumerWidget {
  const TrackingScreen({super.key, required this.bookingId});
  final String bookingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final stream = ref.watch(bookingStreamProvider(bookingId));

    return stream.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: BgEmptyState(title: l.errorGeneric, body: e.toString()),
      ),
      data: (booking) => _TrackingBody(booking: booking),
    );
  }
}

class _TrackingBody extends ConsumerStatefulWidget {
  const _TrackingBody({required this.booking});
  final Booking booking;

  @override
  ConsumerState<_TrackingBody> createState() => _TrackingBodyState();
}

class _TrackingBodyState extends ConsumerState<_TrackingBody> {
  bool _navigatedToRating = false;

  @override
  void didUpdateWidget(covariant _TrackingBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    _maybeFinish();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeFinish());
  }

  /// When the trip finishes, move straight to rating — the person should never
  /// be left staring at a finished map.
  void _maybeFinish() {
    final b = widget.booking;
    final done = b.status == BookingStatus.completed || b.status == BookingStatus.delivered;
    if (done && !_navigatedToRating && mounted) {
      _navigatedToRating = true;
      context.pushReplacement('/rate/${b.id}');
    }
  }

  Future<void> _cancel() async {
    final l = AppLocalizations.of(context);
    final reason = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BgGrabber(),
            Padding(
              padding: const EdgeInsets.all(BgSpace.md),
              child: Text(l.cancelReasonTitle, style: Theme.of(context).textTheme.titleLarge),
            ),
            for (final r in [l.reasonChangedMind, l.reasonTooLong, l.reasonWrongPlace, l.reasonOther])
              ListTile(title: Text(r), onTap: () => Navigator.of(context).pop(r)),
            const SizedBox(height: BgSpace.sm),
          ],
        ),
      ),
    );
    if (reason == null) return;
    await ref.read(apiProvider).cancelBooking(widget.booking.id, reason);
    ref.invalidate(activeBookingsProvider);
    ref.invalidate(bookingHistoryProvider);
    if (mounted) context.go('/home');
  }

  Future<void> _sos() async {
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l.sosConfirmTitle),
        content: Text(l.sosConfirmBody),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: BgColors.danger),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.sos),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(apiProvider).sos(widget.booking.id, widget.booking.pickup.location);
    if (mounted) showBgSnack(context, l.sosSent);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context);
    final b = widget.booking;
    final searching = b.status == BookingStatus.searching;
    final cancellable = b.status == BookingStatus.searching ||
        b.status == BookingStatus.accepted ||
        b.status == BookingStatus.driverArriving ||
        b.status == BookingStatus.arrived ||
        b.status == BookingStatus.arrivedPickup;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: BgMap(
              centre: b.driverLocation ?? b.pickup.location,
              pickup: b.pickup.location,
              dropoff: b.dropoff.location,
              driver: b.driverLocation,
              route: b.polyline,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                BgDemoBanner(message: l.mockModeBanner),
                Padding(
                  padding: const EdgeInsets.all(BgSpace.md),
                  child: Row(
                    children: [
                      Material(
                        color: t.colorScheme.surface,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => context.go('/home'),
                          child: const SizedBox(
                              width: 44, height: 44, child: Icon(Icons.close, size: 22)),
                        ),
                      ),
                      const Spacer(),
                      if (b.status != BookingStatus.searching)
                        Material(
                          color: BgColors.danger,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: _sos,
                            child: const SizedBox(
                              width: 44,
                              height: 44,
                              child: Icon(Icons.sos, size: 20, color: BgColors.white),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: t.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(BgSpace.rSheet)),
                border: Border.all(color: t.dividerColor),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(BgSpace.md, 0, BgSpace.md, BgSpace.md),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const BgGrabber(),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              searching ? l.searchingTitle : statusLabel(l, b.status),
                              style: t.textTheme.headlineMedium,
                            ),
                          ),
                          BgStatusPill(status: b.status, label: statusLabel(l, b.status)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (searching)
                        Text(l.searchingBody, style: t.textTheme.bodyMedium)
                      else if (b.etaSeconds != null && b.status != BookingStatus.inProgress)
                        Text(l.etaMinutes(minutesFromSeconds(b.etaSeconds!)),
                            style: t.textTheme.bodyMedium),
                      const SizedBox(height: BgSpace.md),

                      if (searching)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: BgSpace.md),
                            child: _SearchingPulse(),
                          ),
                        ),

                      if (b.driver != null) ...[
                        _DriverCardView(driver: b.driver!),
                        const SizedBox(height: BgSpace.md),
                      ],

                      if (b.service == ServiceType.delivery &&
                          b.delivery?.recipientOtp != null &&
                          !isTerminal(b.status)) ...[
                        BgCard(
                          color: BgColors.saffron,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l.recipientOtpTitle,
                                  style: t.textTheme.labelMedium?.copyWith(color: BgColors.night)),
                              const SizedBox(height: 4),
                              Text(b.delivery!.recipientOtp!,
                                  style: t.textTheme.displayLarge?.copyWith(
                                      color: BgColors.night, letterSpacing: 8)),
                              Text(l.recipientOtpBody,
                                  style: t.textTheme.labelSmall?.copyWith(color: BgColors.night)),
                            ],
                          ),
                        ),
                        const SizedBox(height: BgSpace.md),
                      ],

                      BgPlaceRows(
                        pickupHint: l.pickup,
                        dropoffHint: l.dropoff,
                        pickupLabel: b.pickup.display,
                        dropoffLabel: b.dropoff.display,
                      ),
                      const SizedBox(height: BgSpace.sm),
                      Row(
                        children: [
                          Text(formatMoney(b.payableCents), style: t.textTheme.titleLarge),
                          const SizedBox(width: 8),
                          Text('· ${l.kilometres(formatKm(b.distanceM))}',
                              style: t.textTheme.labelMedium),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () async {
                              final url = await ref.read(apiProvider).shareBooking(b.id);
                              await Share.share(l.shareTripText(url));
                            },
                            icon: const Icon(Icons.ios_share, size: 18),
                            label: Text(l.shareTrip),
                          ),
                        ],
                      ),
                      if (cancellable) ...[
                        const SizedBox(height: BgSpace.sm),
                        BgButton(
                          label: l.cancelRequest,
                          variant: BgButtonVariant.ghost,
                          onPressed: _cancel,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchingPulse extends StatefulWidget {
  const _SearchingPulse();

  @override
  State<_SearchingPulse> createState() => _SearchingPulseState();
}

class _SearchingPulseState extends State<_SearchingPulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final v = _c.value;
        return SizedBox(
          width: 90,
          height: 90,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 40 + 50 * v,
                height: 40 + 50 * v,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: BgColors.saffron.withOpacity((1 - v) * 0.45),
                ),
              ),
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: BgColors.blue),
                child: const Icon(Icons.local_taxi, color: BgColors.white, size: 22),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DriverCardView extends StatelessWidget {
  const _DriverCardView({required this.driver});
  final DriverCard driver;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context);
    return BgCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: BgColors.blue,
            child: Text(
              initialOf(driver.fullName),
              style: const TextStyle(color: BgColors.white, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(driver.fullName, style: t.textTheme.titleMedium),
                Row(
                  children: [
                    const Icon(Icons.star, size: 14, color: BgColors.saffron),
                    const SizedBox(width: 4),
                    Text(driver.rating.toStringAsFixed(1), style: t.textTheme.labelMedium),
                    const SizedBox(width: 8),
                    Text('${driver.fleetCode} · ${driver.plate}', style: t.textTheme.labelSmall),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: l.call,
            icon: const Icon(Icons.phone, color: BgColors.blue),
            onPressed: driver.phone == null
                ? null
                : () => launchUrl(Uri.parse('tel:${driver.phone}')),
          ),
        ],
      ),
    );
  }
}

/// Rating + optional tip, shown as soon as the trip completes.
class RatingScreen extends ConsumerStatefulWidget {
  const RatingScreen({super.key, required this.bookingId});
  final String bookingId;

  @override
  ConsumerState<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends ConsumerState<RatingScreen> {
  int _score = 5;
  int _tip = 0;
  final _tags = <String>{};
  final _comment = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    try {
      await ref.read(apiProvider).rateBooking(
            widget.bookingId,
            _score,
            tags: _tags.toList(),
            comment: _comment.text.trim().isEmpty ? null : _comment.text.trim(),
            tipCents: _tip,
          );
      ref.invalidate(bookingHistoryProvider);
      ref.invalidate(activeBookingsProvider);
      if (mounted) {
        showBgSnack(context, AppLocalizations.of(context).thanksRating);
        context.go('/receipt/${widget.bookingId}');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context);
    final tags = {
      'polite': l.tagPolite,
      'safe': l.tagSafe,
      'clean': l.tagClean,
      'on_time': l.tagOnTime,
      'helpful': l.tagHelpful,
    };

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [TextButton(onPressed: () => context.go('/home'), child: Text(l.skip))],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(BgSpace.lg),
          children: [
            Text(l.rateTitle, style: t.textTheme.headlineLarge),
            const SizedBox(height: BgSpace.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final filled = i < _score;
                return IconButton(
                  iconSize: 44,
                  onPressed: () => setState(() => _score = i + 1),
                  icon: Icon(
                    filled ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: filled ? BgColors.saffron : BgColors.mist,
                  ),
                );
              }),
            ),
            const SizedBox(height: BgSpace.md),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (final e in tags.entries)
                  FilterChip(
                    label: Text(e.value),
                    selected: _tags.contains(e.key),
                    onSelected: (v) => setState(() {
                      if (v) {
                        _tags.add(e.key);
                      } else {
                        _tags.remove(e.key);
                      }
                    }),
                  ),
              ],
            ),
            const SizedBox(height: BgSpace.lg),
            Text(l.tip, style: t.textTheme.titleMedium),
            const SizedBox(height: BgSpace.sm),
            Row(
              children: [
                for (final c in [0, 25, 50, 100])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(c == 0 ? l.noTip : formatMoney(c)),
                      selected: _tip == c,
                      onSelected: (_) => setState(() => _tip = c),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: BgSpace.lg),
            TextField(
              controller: _comment,
              maxLines: 3,
              decoration: InputDecoration(hintText: l.commentHint),
            ),
            const SizedBox(height: BgSpace.lg),
            BgButton(label: l.submitRating, loading: _busy, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}

/// Receipt for a finished booking.
class ReceiptScreen extends ConsumerWidget {
  const ReceiptScreen({super.key, required this.bookingId});
  final String bookingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l.receipt)),
      body: FutureBuilder<Booking>(
        future: ref.read(apiProvider).getBooking(bookingId),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final b = snap.data!;
          final fare = b.finalFareCents ?? b.quotedFareCents;
          return ListView(
            padding: const EdgeInsets.all(BgSpace.lg),
            children: [
              Center(
                child: Column(
                  children: [
                    const Icon(Icons.check_circle, size: 56, color: BgColors.success),
                    const SizedBox(height: BgSpace.sm),
                    Text(formatMoney(b.payableCents), style: t.textTheme.displayLarge),
                    Text(b.reference, style: t.textTheme.labelMedium),
                  ],
                ),
              ),
              const SizedBox(height: BgSpace.lg),
              BgCard(
                child: Column(
                  children: [
                    _row(
                      context,
                      b.service == ServiceType.ride ? l.serviceRide : l.serviceDelivery,
                      b.createdAt.toLocal().toString().substring(0, 16),
                    ),
                    const Divider(),
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
                  children: [
                    _row(context, l.distance, l.kilometres(formatKm(b.distanceM))),
                    _row(context, l.fare, formatMoney(fare)),
                    if (b.discountCents > 0)
                      _row(context, l.discount, '−${formatMoney(b.discountCents)}'),
                    if (b.tipCents > 0) _row(context, l.tipLabel, formatMoney(b.tipCents)),
                    const Divider(),
                    _row(context, l.total, formatMoney(b.payableCents), bold: true),
                    _row(context, l.paidWith, b.paymentMethod),
                  ],
                ),
              ),
              const SizedBox(height: BgSpace.lg),
              BgButton(
                label: l.shareReceipt,
                variant: BgButtonVariant.secondary,
                icon: Icons.ios_share,
                onPressed: () => Share.share(
                  l.receiptShareText(
                    b.reference,
                    formatMoney(b.payableCents),
                    b.service == ServiceType.ride ? l.serviceRide : l.serviceDelivery,
                    b.pickup.display,
                    b.dropoff.display,
                    '',
                  ),
                ),
              ),
              const SizedBox(height: BgSpace.sm),
              BgButton(label: l.done, onPressed: () => context.go('/home')),
            ],
          );
        },
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value, {bool bold = false}) {
    final t = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: t.textTheme.bodyMedium)),
          Text(value,
              style: bold ? t.textTheme.titleLarge : t.textTheme.titleMedium),
        ],
      ),
    );
  }
}
