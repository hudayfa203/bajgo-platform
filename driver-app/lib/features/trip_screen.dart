import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/theme/bg_colors.dart';
import '../core/theme/bg_theme.dart';
import '../core/utils/money.dart';
import '../core/widgets.dart';
import '../data/api.dart';
import '../data/models.dart';
import '../data/providers.dart';
import '../l10n/generated/app_localizations.dart';

String statusHeadline(Trip t, AppLocalizations l) => switch (t.status) {
      TripStatus.accepted => l.stateNavigatingToPickup,
      TripStatus.driverArriving => l.stateNavigatingToPickup,
      TripStatus.arrived => l.stateArrived,
      TripStatus.inProgress => l.stateInProgress,
      TripStatus.arrivedPickup => l.stateArrived,
      TripStatus.collected => l.stateCollected,
      TripStatus.inTransit => l.stateInTransit,
      TripStatus.arrivedDropoff => l.stateArrivedDropoff,
      TripStatus.recipientVerified => l.stateRecipientVerified,
      TripStatus.completed => l.stateCompleted,
      TripStatus.delivered => l.stateDelivered,
      TripStatus.paid => l.statePaid,
      TripStatus.cancelled => l.statusCancelled,
      TripStatus.failed => l.statusFailed,
      TripStatus.returned => l.statusReturned,
      TripStatus.expired => l.statusExpired,
      TripStatus.searching => l.statusSearching,
    };

String statusLabel(TripStatus s, AppLocalizations l) => switch (s) {
      TripStatus.searching => l.statusSearching,
      TripStatus.accepted => l.statusAccepted,
      TripStatus.driverArriving => l.statusDriverArriving,
      TripStatus.arrived => l.statusArrived,
      TripStatus.inProgress => l.statusInProgress,
      TripStatus.arrivedPickup => l.statusArrivedPickup,
      TripStatus.collected => l.statusCollected,
      TripStatus.inTransit => l.statusInTransit,
      TripStatus.arrivedDropoff => l.statusArrivedDropoff,
      TripStatus.recipientVerified => l.statusRecipientVerified,
      TripStatus.completed => l.statusCompleted,
      TripStatus.delivered => l.statusDelivered,
      TripStatus.paid => l.statusPaid,
      TripStatus.cancelled => l.statusCancelled,
      TripStatus.expired => l.statusExpired,
      TripStatus.failed => l.statusFailed,
      TripStatus.returned => l.statusReturned,
    };

class TripScreen extends ConsumerStatefulWidget {
  const TripScreen({super.key});
  @override
  ConsumerState<TripScreen> createState() => _TripScreenState();
}

class _TripScreenState extends ConsumerState<TripScreen> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } on ApiException catch (e) {
      if (mounted) showBgSnack(context, e.message, error: true);
    } catch (_) {
      if (mounted) showBgSnack(context, AppLocalizations.of(context).errorGeneric, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _navigateTo(TripPlace place) async {
    final uri = Uri.parse(
        'geo:${place.location.latitude},${place.location.longitude}?q='
        '${place.location.latitude},${place.location.longitude}');
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        final web = Uri.parse('https://www.openstreetmap.org/?mlat='
            '${place.location.latitude}&mlon=${place.location.longitude}#map=17/'
            '${place.location.latitude}/${place.location.longitude}');
        await launchUrl(web, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      if (mounted) showBgSnack(context, AppLocalizations.of(context).errorGeneric, error: true);
    }
  }

  Future<void> _call(String? phone) async {
    if (phone == null) return;
    try {
      await launchUrl(Uri.parse('tel:${phone.replaceAll(' ', '')}'));
    } catch (_) {/* no dialler on this device */}
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final trip = ref.watch(activeTripProvider).value;

    if (trip == null) {
      return Scaffold(
        appBar: AppBar(leading: BackButton(onPressed: () => context.go('/'))),
        body: BgEmptyState(
          title: l.noHistory,
          body: l.noHistoryHint,
          icon: Icons.navigation_outlined,
        ),
      );
    }

    final isDelivery = trip.service == ServiceType.delivery;
    final target = switch (trip.status) {
      TripStatus.accepted ||
      TripStatus.driverArriving ||
      TripStatus.arrived ||
      TripStatus.arrivedPickup =>
        trip.pickup,
      _ => trip.dropoff,
    };

    return Scaffold(
      body: Column(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.34,
            child: Stack(
              children: [
                Positioned.fill(
                  child: BgMap(
                    centre: target.location,
                    zoom: 15,
                    route: trip.route,
                    pickup: trip.pickup.location,
                    dropoff: trip.dropoff.location,
                    driver: ref.watch(locationProvider).position,
                  ),
                ),
                SafeArea(
                  child: Row(
                    children: [
                      IconButton.filled(
                        style: IconButton.styleFrom(backgroundColor: BgColors.dSurface),
                        icon: const Icon(Icons.arrow_back, color: BgColors.dText),
                        onPressed: () => context.go('/'),
                      ),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: BgServiceBadge(
                          service: trip.service,
                          label: isDelivery ? l.serviceBadgeDelivery : l.serviceBadgeRide,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: BgColors.dBg,
                borderRadius: BorderRadius.vertical(top: Radius.circular(BgRadius.sheet)),
              ),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(statusHeadline(trip, l), style: BgType.h2)),
                      Text(Money.format(trip.earningsCents), style: BgType.h3),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('${l.reference}: ${trip.reference}', style: BgType.caption),
                  const SizedBox(height: 16),
                  BgCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: BgColors.dSurface2,
                              child: Text(
                                trip.customerName.isEmpty
                                    ? 'B'
                                    : trip.customerName.substring(0, 1).toUpperCase(),
                                style: BgType.bodyStrong,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isDelivery &&
                                            (trip.status == TripStatus.inTransit ||
                                                trip.status == TripStatus.arrivedDropoff ||
                                                trip.status == TripStatus.recipientVerified)
                                        ? (trip.recipientName ?? l.recipient)
                                        : trip.customerName,
                                    style: BgType.bodyStrong,
                                  ),
                                  Text(
                                    isDelivery ? l.sender : l.customer,
                                    style: BgType.caption,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.phone),
                              tooltip: l.callCustomer,
                              onPressed: () => _call(trip.customerPhone),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        BgRouteRows(
                          pickupLabel: l.pickup,
                          pickup: trip.pickup.display,
                          dropoffLabel: l.dropoff,
                          dropoff: trip.dropoff.display,
                        ),
                        const SizedBox(height: 16),
                        BgButton(
                          label: l.navigate,
                          icon: Icons.navigation_outlined,
                          variant: BgButtonVariant.secondary,
                          onPressed: () => _navigateTo(target),
                        ),
                      ],
                    ),
                  ),
                  if (isDelivery) ...[
                    const SizedBox(height: 12),
                    BgCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          BgSectionTitle(l.packageLabel),
                          if (trip.packageDescription != null)
                            BgKeyValue(l.packageLabel, trip.packageDescription!),
                          if (trip.recipientName != null)
                            BgKeyValue(l.recipient, trip.recipientName!),
                          if (trip.recipientPhone != null)
                            BgKeyValue(l.phone, trip.recipientPhone!),
                          if (trip.instructions != null)
                            BgKeyValue(l.instructions, trip.instructions!),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  BgCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        BgKeyValue(l.fare, Money.format(trip.fareCents)),
                        BgKeyValue(l.commission, '-${Money.format(trip.commissionCents)}'),
                        if (trip.tipCents > 0) BgKeyValue(l.tip, Money.format(trip.tipCents)),
                        const Divider(height: 20),
                        BgKeyValue(
                          l.yourEarnings,
                          Money.format(trip.earningsCents),
                          strong: true,
                          valueColour: BgColors.success,
                        ),
                        BgKeyValue(
                          l.paymentMethodLabel,
                          switch (trip.paymentMethod) {
                            'evc_plus' => l.paymentEvcPlus,
                            'zaad' => l.paymentZaad,
                            'sahal' => l.paymentSahal,
                            'sandbox' => l.paymentSandbox,
                            'cash' => l.paymentCash,
                            _ => l.paymentOther,
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _primaryAction(trip, l),
                  const SizedBox(height: 10),
                  if (isDelivery &&
                      (trip.status == TripStatus.inTransit ||
                          trip.status == TripStatus.arrivedDropoff))
                    BgButton(
                      label: l.cantDeliver,
                      variant: BgButtonVariant.ghost,
                      onPressed: _busy ? null : () => _failSheet(trip, l),
                    ),
                  if (trip.status == TripStatus.accepted ||
                      trip.status == TripStatus.driverArriving ||
                      trip.status == TripStatus.arrived ||
                      trip.status == TripStatus.arrivedPickup)
                    BgButton(
                      label: l.cancelTrip,
                      variant: BgButtonVariant.ghost,
                      onPressed: _busy ? null : () => _cancelSheet(trip, l),
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _primaryAction(Trip trip, AppLocalizations l) {
    final api = ref.read(apiProvider);
    final delivery = trip.service == ServiceType.delivery;

    // Steps with their own flow.
    if (trip.status == TripStatus.arrivedDropoff) {
      return BgButton(
        label: l.actionEnterOtp,
        icon: Icons.pin_outlined,
        onPressed: _busy ? null : () => _otpSheet(trip, l),
      );
    }
    if (trip.status == TripStatus.completed || trip.status == TripStatus.delivered) {
      return trip.paymentMethod == 'cash'
          ? BgButton(
              label: l.actionCollectCash,
              icon: Icons.payments_outlined,
              onPressed: _busy ? null : () => _cashSheet(trip, l),
            )
          : BgButton(label: l.actionAwaitPayment, onPressed: null, busy: true);
    }
    if (trip.status == TripStatus.paid) {
      return BgButton(
        label: l.actionRateCustomer,
        icon: Icons.star_outline,
        onPressed: _busy ? null : () => _rateSheet(trip, l),
      );
    }

    final next = nextStatusFor(trip);
    if (next == null) {
      return BgButton(
        label: l.actionDone,
        variant: BgButtonVariant.secondary,
        onPressed: () => context.go('/'),
      );
    }

    final label = switch (next) {
      TripStatus.driverArriving => l.navigate,
      TripStatus.arrived || TripStatus.arrivedPickup => l.actionArrived,
      TripStatus.inProgress => l.actionStartRide,
      TripStatus.completed => l.actionCompleteRide,
      TripStatus.collected => l.actionPackageCollected,
      TripStatus.inTransit => l.actionInTransit,
      TripStatus.delivered => l.actionDelivered,
      _ => l.continueLabel,
    };

    return BgButton(
      label: label,
      busy: _busy,
      variant: next == TripStatus.completed || next == TripStatus.delivered
          ? BgButtonVariant.success
          : BgButtonVariant.primary,
      onPressed: () => _run(() async {
        await api.transition(trip.id, next);
        if (delivery && next == TripStatus.collected && mounted) {
          showBgSnack(context, l.stateCollected);
        }
      }),
    );
  }

  Future<void> _cashSheet(Trip trip, AppLocalizations l) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (ctx) => Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l.cashAmountTitle, style: BgType.h3),
              const SizedBox(height: 16),
              Center(child: Text(Money.format(trip.fareCents), style: BgType.money)),
              const SizedBox(height: 20),
              BgButton(
                label: l.cashReceived(Money.format(trip.fareCents)),
                icon: Icons.check,
                variant: BgButtonVariant.success,
                onPressed: () {
                  Navigator.pop(ctx);
                  _run(() async {
                    final paid = await ref.read(apiProvider).collectCash(trip.id, trip.fareCents);
                    ref.invalidate(earningsProvider);
                    ref.invalidate(walletProvider);
                    ref.invalidate(historyProvider);
                    if (mounted) context.go('/trip/complete', extra: paid);
                  });
                },
              ),
              const SizedBox(height: 8),
              BgButton(
                label: l.cancel,
                variant: BgButtonVariant.ghost,
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
        ),
      );

  Future<void> _otpSheet(Trip trip, AppLocalizations l) {
    final ctrl = TextEditingController();
    String? error;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l.recipientOtpTitle, style: BgType.h3),
              const SizedBox(height: 6),
              Text(l.recipientOtpHint, style: BgType.caption),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                autofocus: true,
                maxLength: 4,
                textAlign: TextAlign.center,
                style: BgType.h1.copyWith(letterSpacing: 10),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(counterText: '', errorText: error),
              ),
              const SizedBox(height: 12),
              BgButton(
                label: l.confirm,
                onPressed: () async {
                  try {
                    await ref.read(apiProvider).verifyRecipient(trip.id, ctrl.text.trim());
                    if (ctx.mounted) Navigator.pop(ctx);
                  } on ApiException {
                    setSheet(() => error = l.otpWrong);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _failSheet(Trip trip, AppLocalizations l) {
    final reasons = {
      'unreachable': l.failReasonUnreachable,
      'refused': l.failReasonRefused,
      'wrong_address': l.failReasonWrongAddress,
      'other': l.failReasonOther,
    };
    return showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l.cantDeliver, style: BgType.h3),
            ),
            for (final r in reasons.entries)
              ListTile(
                title: Text(r.value),
                onTap: () {
                  Navigator.pop(ctx);
                  _run(() async {
                    await ref.read(apiProvider).failDelivery(trip.id, r.key);
                    if (mounted) {
                      await showDialog<void>(
                        context: context,
                        builder: (d) => AlertDialog(
                          title: Text(l.returnToSenderTitle),
                          content: Text(l.returnToSenderBody),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(d), child: Text(l.ok)),
                          ],
                        ),
                      );
                      if (mounted) context.go('/');
                    }
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _cancelSheet(Trip trip, AppLocalizations l) => showModalBottomSheet<void>(
        context: context,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(l.cancelReason, style: BgType.h3),
              ),
              for (final r in ['customer_no_show', 'vehicle_problem', 'other'])
                ListTile(
                  title: Text(switch (r) {
                    'customer_no_show' => l.failReasonUnreachable,
                    'vehicle_problem' => l.failReasonOther,
                    _ => l.failReasonOther,
                  }),
                  onTap: () {
                    Navigator.pop(ctx);
                    _run(() async {
                      await ref.read(apiProvider).cancelTrip(trip.id, r);
                      if (mounted) context.go('/');
                    });
                  },
                ),
            ],
          ),
        ),
      );

  Future<void> _rateSheet(Trip trip, AppLocalizations l) {
    var score = 5;
    final comment = TextEditingController();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l.rateTitle, style: BgType.h3),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 1; i <= 5; i++)
                    IconButton(
                      icon: Icon(
                        i <= score ? Icons.star : Icons.star_border,
                        color: BgColors.saffron,
                        size: 34,
                      ),
                      onPressed: () => setSheet(() => score = i),
                    ),
                ],
              ),
              TextField(
                controller: comment,
                decoration: InputDecoration(labelText: l.rateComment),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              BgButton(
                label: l.submitRating,
                onPressed: () {
                  Navigator.pop(ctx);
                  _run(() async {
                    await ref.read(apiProvider).rateCustomer(
                          trip.id,
                          score,
                          comment: comment.text.trim().isEmpty ? null : comment.text.trim(),
                        );
                    ref.invalidate(earningsProvider);
                    ref.invalidate(historyProvider);
                    ref.invalidate(walletProvider);
                    if (mounted) context.go('/');
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shown once payment is in hand: receipt, earnings breakdown and a rating.
class TripCompleteScreen extends ConsumerStatefulWidget {
  const TripCompleteScreen({super.key, required this.trip});
  final Trip trip;

  @override
  ConsumerState<TripCompleteScreen> createState() => _TripCompleteScreenState();
}

class _TripCompleteScreenState extends ConsumerState<TripCompleteScreen> {
  int _score = 5;
  final _comment = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    setState(() => _busy = true);
    try {
      await ref.read(apiProvider).rateCustomer(
            widget.trip.id,
            _score,
            comment: _comment.text.trim().isEmpty ? null : _comment.text.trim(),
          );
    } catch (_) {
      // Rating is best-effort; the trip is already settled.
    }
    ref.invalidate(earningsProvider);
    ref.invalidate(walletProvider);
    ref.invalidate(historyProvider);
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = widget.trip;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 20),
            Center(
              child: Container(
                height: 88,
                width: 88,
                decoration: const BoxDecoration(color: BgColors.success, shape: BoxShape.circle),
                child: const Icon(Icons.check, size: 44, color: BgColors.white),
              ),
            ),
            const SizedBox(height: 18),
            Center(child: Text(l.paymentReceived, style: BgType.h2)),
            const SizedBox(height: 4),
            Center(child: Text('${l.reference}: ${t.reference}', style: BgType.caption)),
            const SizedBox(height: 24),
            BgCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BgSectionTitle(l.earningsBreakdown),
                  BgKeyValue(l.fare, Money.format(t.fareCents)),
                  if (t.tipCents > 0) BgKeyValue(l.tip, Money.format(t.tipCents)),
                  BgKeyValue(l.commission, '-${Money.format(t.commissionCents)}'),
                  const Divider(height: 20),
                  BgKeyValue(
                    l.yourEarnings,
                    Money.format(t.earningsCents),
                    strong: true,
                    valueColour: BgColors.success,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            BgCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BgRouteRows(
                    pickupLabel: l.pickup,
                    pickup: t.pickup.display,
                    dropoffLabel: l.dropoff,
                    dropoff: t.dropoff.display,
                  ),
                  const SizedBox(height: 12),
                  BgKeyValue(l.distance, l.kmShort((t.distanceM / 1000).toStringAsFixed(1))),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(l.rateTitle, style: BgType.h3),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 1; i <= 5; i++)
                  IconButton(
                    icon: Icon(
                      i <= _score ? Icons.star : Icons.star_border,
                      color: BgColors.saffron,
                      size: 34,
                    ),
                    onPressed: () => setState(() => _score = i),
                  ),
              ],
            ),
            TextField(
              controller: _comment,
              decoration: InputDecoration(labelText: l.rateComment),
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            BgButton(label: l.actionDone, busy: _busy, onPressed: _finish),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
