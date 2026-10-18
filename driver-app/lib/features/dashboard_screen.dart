import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/bg_colors.dart';
import '../core/theme/bg_theme.dart';
import '../core/utils/money.dart';
import '../core/widgets.dart';
import '../data/api.dart';
import '../data/models.dart';
import '../data/providers.dart';
import '../l10n/generated/app_localizations.dart';

/// Bottom-navigation shell: Home · Earnings · History · Account.
class DriverShell extends ConsumerWidget {
  const DriverShell({super.key, required this.child, required this.index});
  final Widget child;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);

    // When a trip starts (here or from the dispatcher), go straight to it.
    ref.listen<AsyncValue<Trip?>>(activeTripProvider, (prev, next) {
      final trip = next.value;
      if (trip != null && !tripIsFinished(trip.status)) {
        final loc = GoRouterState.of(context).uri.path;
        if (loc != '/trip') context.push('/trip');
      }
    });

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) {
          const routes = ['/', '/earnings', '/history', '/account'];
          context.go(routes[i.clamp(0, routes.length - 1)]);
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.explore_outlined),
            selectedIcon: const Icon(Icons.explore),
            label: l.navHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.payments_outlined),
            selectedIcon: const Icon(Icons.payments),
            label: l.navEarnings,
          ),
          NavigationDestination(
            icon: const Icon(Icons.receipt_long_outlined),
            selectedIcon: const Icon(Icons.receipt_long),
            label: l.navHistory,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: l.navAccount,
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _toggling = false;

  Future<void> _toggleOnline(bool wantOnline) async {
    final l = AppLocalizations.of(context);
    setState(() => _toggling = true);
    try {
      if (wantOnline) {
        final ok = await ref.read(locationProvider.notifier).ensurePermission();
        if (!ok && mounted) {
          await _askPermission(l);
        }
        await ref.read(locationProvider.notifier).start();
      } else {
        ref.read(locationProvider.notifier).stop();
      }
      await ref.read(sessionProvider.notifier).setOnline(wantOnline);
    } on ApiException catch (e) {
      if (mounted) showBgSnack(context, e.message, error: true);
    } catch (_) {
      if (mounted) showBgSnack(context, l.errorGeneric, error: true);
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  Future<void> _askPermission(AppLocalizations l) => showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l.locationPermissionTitle),
          content: Text(l.locationPermissionBody),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.close)),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                ref.read(locationProvider.notifier).ensurePermission();
              },
              child: Text(l.allowLocation),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final session = ref.watch(sessionProvider);
    final profile = session.profile;
    final online = profile?.availability != Availability.offline;
    final offer = ref.watch(offerProvider).value;
    final trip = ref.watch(activeTripProvider).value;
    final centre = ref.watch(mapCentreProvider);
    final earnings = ref.watch(earningsProvider('today'));

    return Stack(
      children: [
        Positioned.fill(
          child: BgMap(centre: centre, driver: ref.watch(locationProvider).position),
        ),
        Positioned.fill(
          child: SafeArea(
            child: Column(
              children: [
                BgDemoBanner(label: l.mockBanner),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: BgCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          height: 10,
                          width: 10,
                          decoration: BoxDecoration(
                            color: online ? BgColors.success : BgColors.dText2,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(online ? l.onlineLabel : l.offlineLabel, style: BgType.bodyStrong),
                              Text(
                                online
                                    ? l.gpsInterval(LocationController.intervalSeconds)
                                    : l.youAreOffline,
                                style: BgType.caption,
                              ),
                            ],
                          ),
                        ),
                        if (_toggling)
                          const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.4),
                          )
                        else
                          Switch(
                            value: online,
                            onChanged: (profile?.isApproved ?? false) ? _toggleOnline : null,
                          ),
                      ],
                    ),
                  ),
                ),
                if (!(profile?.isApproved ?? false))
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: BgCard(
                      colour: BgColors.danger,
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: BgColors.white, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              l.notApprovedYet,
                              style: BgType.label.copyWith(color: BgColors.white),
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.push('/verification'),
                            child: Text(
                              l.refreshStatus,
                              style: BgType.label.copyWith(color: BgColors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const Spacer(),
                if (trip != null && !tripIsFinished(trip.status))
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: BgCard(
                      onTap: () => context.push('/trip'),
                      border: BgColors.saffron,
                      child: Row(
                        children: [
                          const Icon(Icons.navigation_outlined, color: BgColors.saffron),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(l.activeTrip, style: BgType.bodyStrong),
                                Text(trip.dropoff.display, style: BgType.caption, maxLines: 1),
                              ],
                            ),
                          ),
                          Text(l.resumeTrip, style: BgType.label.copyWith(color: BgColors.saffron)),
                        ],
                      ),
                    ),
                  ),
                Container(
                  decoration: const BoxDecoration(
                    color: BgColors.dSurface,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(BgRadius.sheet)),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.todayEarnings, style: BgType.label),
                      const SizedBox(height: 4),
                      earnings.when(
                        loading: () => Text('—', style: BgType.money),
                        error: (_, __) => Text('—', style: BgType.money),
                        data: (e) => Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(Money.format(e.netCents), style: BgType.money),
                            const SizedBox(width: 10),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                '${l.trips}: ${e.trips} · ${l.deliveries}: ${e.deliveries}',
                                style: BgType.caption,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: BgStatTile(
                              label: l.rating,
                              value: (profile?.rating ?? 5).toStringAsFixed(1),
                              icon: Icons.star_outline,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: BgStatTile(
                              label: l.commission,
                              value: earnings.maybeWhen(
                                data: (e) => Money.format(e.commissionCents),
                                orElse: () => '—',
                              ),
                              icon: Icons.percent,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: BgStatTile(
                              label: l.acceptanceRate,
                              value: '${(profile?.acceptanceRate ?? 100).round()}%',
                              icon: Icons.thumb_up_outlined,
                            ),
                          ),
                        ],
                      ),
                      if (online && offer == null && (trip == null || tripIsFinished(trip.status)))
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Row(
                            children: [
                              const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              const SizedBox(width: 12),
                              Text(l.waitingForRequests, style: BgType.caption),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (offer != null && (trip == null || tripIsFinished(trip.status)))
          Positioned.fill(child: OfferOverlay(offer: offer)),
      ],
    );
  }
}

/// Full-screen offer with a 20-second countdown ring.
class OfferOverlay extends ConsumerStatefulWidget {
  const OfferOverlay({super.key, required this.offer});
  final Offer offer;

  @override
  ConsumerState<OfferOverlay> createState() => _OfferOverlayState();
}

class _OfferOverlayState extends ConsumerState<OfferOverlay> {
  Timer? _tick;
  int _left = 20;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _left = widget.offer.secondsLeft;
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _left = widget.offer.secondsLeft);
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _accept() async {
    final l = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      await ref.read(apiProvider).acceptOffer(widget.offer.id);
      ref.read(sessionProvider.notifier).markAvailability(Availability.onTrip);
      if (mounted) context.push('/trip');
    } on ApiException catch (e) {
      if (mounted) {
        showBgSnack(context, e.code == 'OFFER_TAKEN' ? l.offerTaken : e.message, error: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _decline() async {
    await ref.read(apiProvider).declineOffer(widget.offer.id);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final o = widget.offer;
    final isDelivery = o.service == ServiceType.delivery;

    return Container(
      color: BgColors.night.withOpacity(0.92),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 92,
                width: 92,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      height: 92,
                      width: 92,
                      child: CircularProgressIndicator(
                        value: (_left / 20).clamp(0, 1),
                        strokeWidth: 7,
                        color: _left <= 5 ? BgColors.danger : BgColors.saffron,
                      ),
                    ),
                    Text('$_left', style: BgType.h1),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(l.newRequest, style: BgType.h2),
              const SizedBox(height: 12),
              BgServiceBadge(
                service: o.service,
                label: isDelivery ? l.serviceBadgeDelivery : l.serviceBadgeRide,
              ),
              const SizedBox(height: 20),
              BgCard(
                child: Column(
                  children: [
                    Text(Money.format(o.earningsCents), style: BgType.money),
                    Text(l.estimatedEarnings, style: BgType.caption),
                    const SizedBox(height: 16),
                    BgRouteRows(
                      pickupLabel: l.pickup,
                      pickup: o.pickup.display,
                      dropoffLabel: l.dropoff,
                      dropoff: o.dropoff.display,
                    ),
                    const Divider(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Text(l.distance, style: BgType.caption),
                              Text(
                                l.kmShort((o.distanceM / 1000).toStringAsFixed(1)),
                                style: BgType.bodyStrong,
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text(l.etaToPickup, style: BgType.caption),
                              Text(
                                l.minutesShort((o.etaToPickupS / 60).ceil()),
                                style: BgType.bodyStrong,
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text(l.fare, style: BgType.caption),
                              Text(Money.format(o.fareCents), style: BgType.bodyStrong),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              BgButton(
                label: l.accept,
                busy: _busy,
                icon: Icons.check,
                onPressed: _left > 0 ? _accept : null,
              ),
              const SizedBox(height: 10),
              BgButton(
                label: l.decline,
                variant: BgButtonVariant.ghost,
                onPressed: _busy ? null : _decline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
