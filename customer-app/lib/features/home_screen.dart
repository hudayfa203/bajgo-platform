import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../core/theme.dart';
import '../core/widgets.dart';
import '../data/models.dart';
import '../data/providers.dart';
import '../l10n/generated/app_localizations.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _map = MapController();
  bool _askedPermission = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initLocation());
  }

  Future<void> _initLocation() async {
    if (_askedPermission) return;
    _askedPermission = true;
    final ok = await ref.read(locationProvider.notifier).ensurePermission();
    if (ok && mounted) {
      final here = ref.read(locationProvider);
      _map.move(here, 15);
      ref.invalidate(nearbyDriversProvider);
    }
  }

  void _startBooking(ServiceType service) {
    ref.read(bookingDraftProvider.notifier).start(service);
    context.push(service == ServiceType.ride ? '/book/ride' : '/book/delivery');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context);
    final here = ref.watch(locationProvider);
    final nearby = ref.watch(nearbyDriversProvider);
    final active = ref.watch(activeBookingsProvider);
    final session = ref.watch(sessionProvider);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: BgMap(
              centre: here,
              controller: _map,
              nearby: nearby.maybeWhen(
                data: (list) => list.map((d) => d.location).toList(),
                orElse: () => const <LatLng>[],
              ),
            ),
          ),
          // Top bar
          SafeArea(
            child: Column(
              children: [
                BgDemoBanner(message: l.mockModeBanner),
                Padding(
                  padding: const EdgeInsets.all(BgSpace.md),
                  child: Row(
                    children: [
                      _RoundIcon(
                        child: SvgPicture.asset('assets/brand/BajGo_Symbol_FullColour.svg', height: 22),
                        onTap: () {},
                      ),
                      const Spacer(),
                      nearby.maybeWhen(
                        data: (list) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: t.colorScheme.surface,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: t.dividerColor),
                          ),
                          child: Text(l.nearbyCount(list.length), style: t.textTheme.labelMedium),
                        ),
                        orElse: () => const SizedBox.shrink(),
                      ),
                      const Spacer(),
                      _RoundIcon(
                        child: const Icon(Icons.notifications_none, size: 22),
                        onTap: () => context.push('/notifications'),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(right: BgSpace.md, bottom: BgSpace.sm),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _RoundIcon(
                      child: const Icon(Icons.my_location, size: 22),
                      onTap: () async {
                        await ref.read(locationProvider.notifier).refresh();
                        if (mounted) _map.move(ref.read(locationProvider), 15);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Bottom sheet
          DraggableScrollableSheet(
            initialChildSize: 0.46,
            minChildSize: 0.30,
            maxChildSize: 0.88,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: t.colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(BgSpace.rSheet)),
                  border: Border.all(color: t.dividerColor),
                ),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(BgSpace.md, 0, BgSpace.md, BgSpace.lg),
                  children: [
                    const BgGrabber(),
                    Text(
                      session.user?.fullName != null
                          ? l.greeting(session.user!.fullName!)
                          : l.greetingNoName,
                      style: t.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: BgSpace.md),

                    active.maybeWhen(
                      data: (list) => list.isEmpty
                          ? const SizedBox.shrink()
                          : Padding(
                              padding: const EdgeInsets.only(bottom: BgSpace.md),
                              child: BgCard(
                                color: BgColors.blue,
                                onTap: () => context.push('/track/${list.first.id}'),
                                child: Row(
                                  children: [
                                    const Icon(Icons.local_taxi, color: BgColors.white),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(l.activeTripBanner,
                                              style: t.textTheme.titleMedium
                                                  ?.copyWith(color: BgColors.white)),
                                          Text(list.first.reference,
                                              style: t.textTheme.labelSmall
                                                  ?.copyWith(color: BgColors.sky)),
                                        ],
                                      ),
                                    ),
                                    Text(l.viewTrip,
                                        style: t.textTheme.labelLarge
                                            ?.copyWith(color: BgColors.saffron)),
                                  ],
                                ),
                              ),
                            ),
                      orElse: () => const SizedBox.shrink(),
                    ),

                    // Where to?
                    BgCard(
                      onTap: () {
                        ref.read(bookingDraftProvider.notifier).start(ServiceType.ride);
                        context.push('/book/ride');
                      },
                      child: Row(
                        children: [
                          const Icon(Icons.search, color: BgColors.slate),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(l.whereTo, style: t.textTheme.titleMedium),
                                Text(l.searchHint, style: t.textTheme.labelSmall),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: BgSpace.md),

                    // Two service cards
                    Row(
                      children: [
                        Expanded(
                          child: _ServiceCard(
                            title: l.rideTitle,
                            body: l.rideDesc,
                            colour: BgColors.blue,
                            icon: Icons.airline_seat_recline_normal,
                            onTap: () => _startBooking(ServiceType.ride),
                          ),
                        ),
                        const SizedBox(width: BgSpace.md),
                        Expanded(
                          child: _ServiceCard(
                            title: l.deliveryTitle,
                            body: l.deliveryDesc,
                            colour: BgColors.saffron,
                            foreground: BgColors.night,
                            icon: Icons.inventory_2_outlined,
                            onTap: () => _startBooking(ServiceType.delivery),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: BgSpace.lg),

                    // Saved places
                    BgSectionTitle(l.recentPlaces),
                    ref.watch(savedPlacesProvider).maybeWhen(
                          data: (places) {
                            if (places.isEmpty) {
                              return Text(l.noSavedPlacesBody, style: t.textTheme.bodyMedium);
                            }
                            return Column(
                              children: [
                                for (final p in places.take(4))
                                  ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: Icon(
                                      p.kind == 'home'
                                          ? Icons.home_outlined
                                          : p.kind == 'work'
                                              ? Icons.work_outline
                                              : Icons.place_outlined,
                                      color: BgColors.slate,
                                    ),
                                    title: Text(p.label, style: t.textTheme.titleMedium),
                                    subtitle: Text(p.place.display,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: t.textTheme.labelSmall),
                                    onTap: () {
                                      final n = ref.read(bookingDraftProvider.notifier);
                                      n.start(ServiceType.ride);
                                      n.setDropoff(p.place);
                                      context.push('/book/ride');
                                    },
                                  ),
                              ],
                            );
                          },
                          orElse: () => const SizedBox.shrink(),
                        ),
                    const SizedBox(height: BgSpace.sm),
                    Center(
                      child: Text(l.fareNote,
                          textAlign: TextAlign.center, style: t.textTheme.labelSmall),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (i) {
          switch (i) {
            case 1:
              context.push('/trips');
            case 2:
              context.push('/wallet');
            case 3:
              context.push('/account');
          }
        },
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home), label: l.navHome),
          NavigationDestination(icon: const Icon(Icons.receipt_long_outlined), label: l.navTrips),
          NavigationDestination(icon: const Icon(Icons.account_balance_wallet_outlined), label: l.navWallet),
          NavigationDestination(icon: const Icon(Icons.person_outline), label: l.navAccount),
        ],
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Material(
      color: t.colorScheme.surface,
      shape: CircleBorder(side: BorderSide(color: t.dividerColor)),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(width: 44, height: 44, child: Center(child: child)),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.title,
    required this.body,
    required this.colour,
    required this.icon,
    required this.onTap,
    this.foreground = BgColors.white,
  });

  final String title;
  final String body;
  final Color colour;
  final Color foreground;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colour,
      borderRadius: BorderRadius.circular(BgSpace.rCard),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(BgSpace.rCard),
        child: Padding(
          padding: const EdgeInsets.all(BgSpace.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: foreground, size: 28),
              const SizedBox(height: BgSpace.md),
              Text(title,
                  style: TextStyle(
                      fontFamily: BgTheme.display,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: foreground)),
              const SizedBox(height: 4),
              Text(body,
                  maxLines: 3,
                  style: TextStyle(
                      fontFamily: BgTheme.body,
                      fontSize: 12,
                      height: 1.35,
                      color: foreground.withAlpha(217))),
            ],
          ),
        ),
      ),
    );
  }
}
