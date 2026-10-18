import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../core/env.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../data/api.dart';
import '../data/models.dart';
import '../data/providers.dart';
import '../l10n/generated/app_localizations.dart';

/// Ride booking: choose pickup and destination, see the fare, confirm.
class RideBookingScreen extends ConsumerStatefulWidget {
  const RideBookingScreen({super.key});

  @override
  ConsumerState<RideBookingScreen> createState() => _RideBookingScreenState();
}

class _RideBookingScreenState extends ConsumerState<RideBookingScreen> {
  bool _loadingQuote = false;
  bool _confirming = false;
  String? _error;

  Future<void> _getQuote() async {
    setState(() {
      _loadingQuote = true;
      _error = null;
    });
    try {
      await ref.read(bookingDraftProvider.notifier).fetchQuote();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loadingQuote = false);
    }
  }

  Future<void> _confirm() async {
    setState(() => _confirming = true);
    try {
      final booking = await ref.read(bookingDraftProvider.notifier).confirm();
      if (mounted) context.pushReplacement('/track/${booking.id}');
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _confirming = false);
        showBgSnack(context, e.message, error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final draft = ref.watch(bookingDraftProvider);
    return _BookingScaffold(
      title: l.rideTitle,
      draft: draft,
      quoteLoading: _loadingQuote,
      confirming: _confirming,
      error: _error,
      onGetQuote: _getQuote,
      onConfirm: _confirm,
      confirmLabel: l.confirmRide,
    );
  }
}

/// Delivery booking: category, places, package and recipient, then confirm.
class DeliveryBookingScreen extends ConsumerStatefulWidget {
  const DeliveryBookingScreen({super.key});

  @override
  ConsumerState<DeliveryBookingScreen> createState() => _DeliveryBookingScreenState();
}

class _DeliveryBookingScreenState extends ConsumerState<DeliveryBookingScreen> {
  bool _loadingQuote = false;
  bool _confirming = false;
  String? _error;

  Future<void> _openDetails() async {
    final saved = await showModalBottomSheet<DeliveryDetails>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _DeliveryDetailsSheet(),
    );
    if (saved != null) {
      ref.read(bookingDraftProvider.notifier).setDelivery(saved);
    }
  }

  Future<void> _getQuote() async {
    final draft = ref.read(bookingDraftProvider);
    if (draft.delivery == null) {
      await _openDetails();
      if (ref.read(bookingDraftProvider).delivery == null) return;
    }
    setState(() {
      _loadingQuote = true;
      _error = null;
    });
    try {
      await ref.read(bookingDraftProvider.notifier).fetchQuote();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loadingQuote = false);
    }
  }

  Future<void> _confirm() async {
    setState(() => _confirming = true);
    try {
      final booking = await ref.read(bookingDraftProvider.notifier).confirm();
      if (mounted) context.pushReplacement('/track/${booking.id}');
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _confirming = false);
        showBgSnack(context, e.message, error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final draft = ref.watch(bookingDraftProvider);
    return _BookingScaffold(
      title: l.deliveryTitle,
      draft: draft,
      quoteLoading: _loadingQuote,
      confirming: _confirming,
      error: _error,
      onGetQuote: _getQuote,
      onConfirm: _confirm,
      confirmLabel: l.confirmDelivery,
      extra: BgCard(
        onTap: _openDetails,
        child: Row(
          children: [
            const Icon(Icons.inventory_2_outlined, color: BgColors.slate),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.deliveryDetailsTitle,
                      style: Theme.of(context).textTheme.titleMedium),
                  Text(
                    draft.delivery == null
                        ? l.requiredField
                        : '${draft.delivery!.category} · ${draft.delivery!.recipientName ?? ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: BgColors.slate),
          ],
        ),
      ),
    );
  }
}

/// Shared layout for both booking flows: map on top, controls in a sheet.
class _BookingScaffold extends ConsumerWidget {
  const _BookingScaffold({
    required this.title,
    required this.draft,
    required this.quoteLoading,
    required this.confirming,
    required this.onGetQuote,
    required this.onConfirm,
    required this.confirmLabel,
    this.error,
    this.extra,
  });

  final String title;
  final BookingDraft draft;
  final bool quoteLoading;
  final bool confirming;
  final String? error;
  final VoidCallback onGetQuote;
  final VoidCallback onConfirm;
  final String confirmLabel;
  final Widget? extra;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context);
    final quote = draft.quote;
    final centre = draft.pickup?.location ?? ref.watch(locationProvider);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: BgMap(
                    centre: centre,
                    pickup: draft.pickup?.location,
                    dropoff: draft.dropoff?.location,
                    route: quote?.polyline ?? const <LatLng>[],
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: t.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(BgSpace.rSheet)),
              border: Border.all(color: t.dividerColor),
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(BgSpace.md, 0, BgSpace.md, BgSpace.md),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const BgGrabber(),
                    BgPlaceRows(
                      pickupHint: l.pickup,
                      dropoffHint: l.dropoff,
                      pickupLabel: draft.pickup?.display ?? '',
                      dropoffLabel: draft.dropoff?.display ?? '',
                      onTapPickup: () => _pick(context, ref, isPickup: true),
                      onTapDropoff: () => _pick(context, ref, isPickup: false),
                    ),
                    if (extra != null) ...[const SizedBox(height: BgSpace.md), extra!],
                    const SizedBox(height: BgSpace.md),
                    if (quote != null) _QuoteCard(quote: quote, draft: draft),
                    if (error != null) ...[
                      const SizedBox(height: BgSpace.sm),
                      Text(error!,
                          style: t.textTheme.bodyMedium?.copyWith(color: BgColors.danger)),
                    ],
                    const SizedBox(height: BgSpace.md),
                    if (quote == null)
                      BgButton(
                        label: l.gettingQuote,
                        loading: quoteLoading,
                        onPressed: draft.ready ? onGetQuote : null,
                      )
                    else
                      BgButton(
                        label: '$confirmLabel · ${formatMoney(quote.fareCents)}',
                        loading: confirming,
                        onPressed: onConfirm,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pick(BuildContext context, WidgetRef ref, {required bool isPickup}) async {
    final picked = await context.push<Place>('/pick', extra: isPickup);
    if (picked == null) return;
    final n = ref.read(bookingDraftProvider.notifier);
    if (isPickup) {
      n.setPickup(picked);
    } else {
      n.setDropoff(picked);
    }
  }
}

class _QuoteCard extends ConsumerWidget {
  const _QuoteCard({required this.quote, required this.draft});
  final Quote quote;
  final BookingDraft draft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context);
    final methods = ref.watch(paymentMethodsProvider);

    return BgCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.fare, style: t.textTheme.labelMedium),
                    Text(formatMoney(quote.fareCents), style: t.textTheme.displayLarge),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(l.kilometres(formatKm(quote.distanceM)), style: t.textTheme.titleMedium),
                  Text(l.minutes(minutesFromSeconds(quote.durationS)),
                      style: t.textTheme.labelMedium),
                ],
              ),
            ],
          ),
          if (quote.breakdown.discountCents > 0) ...[
            const SizedBox(height: 4),
            Text('${l.discount}: −${formatMoney(quote.breakdown.discountCents)}',
                style: t.textTheme.labelMedium?.copyWith(color: BgColors.success)),
          ],
          const SizedBox(height: BgSpace.sm),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? BgColors.dSurface2
                  : BgColors.cloud,
              borderRadius: BorderRadius.circular(BgSpace.rInput),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_outlined, size: 16, color: BgColors.success),
                const SizedBox(width: 8),
                Expanded(child: Text(l.fareNote, style: t.textTheme.labelSmall)),
              ],
            ),
          ),
          const SizedBox(height: BgSpace.md),
          Text(l.paymentMethod, style: t.textTheme.labelMedium),
          const SizedBox(height: 6),
          methods.maybeWhen(
            data: (list) => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final m in list)
                  ChoiceChip(
                    selected: draft.paymentMethod == m.method,
                    onSelected: m.live
                        ? (_) => ref.read(bookingDraftProvider.notifier).setPaymentMethod(m.method)
                        : null,
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(m.labelEn),
                        if (!m.live) ...[
                          const SizedBox(width: 6),
                          Text(l.comingSoon, style: t.textTheme.labelSmall),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

/// Destination picker: search the landmark list, or drop a pin on the map.
class PlacePickerScreen extends ConsumerStatefulWidget {
  const PlacePickerScreen({super.key, required this.isPickup});
  final bool isPickup;

  @override
  ConsumerState<PlacePickerScreen> createState() => _PlacePickerScreenState();
}

class _PlacePickerScreenState extends ConsumerState<PlacePickerScreen> {
  final _search = TextEditingController();
  final _map = MapController();
  Timer? _debounce;
  List<Place> _results = const [];
  bool _mapMode = false;
  LatLng? _pin;
  final _landmark = TextEditingController();

  @override
  void initState() {
    super.initState();
    _runSearch('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _landmark.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 280), () => _runSearch(v));
  }

  Future<void> _runSearch(String q) async {
    final here = ref.read(locationProvider);
    final r = await ref.read(apiProvider).searchPlaces(q, here);
    if (mounted) setState(() => _results = r);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context);
    final here = ref.watch(locationProvider);

    if (_mapMode) {
      final pin = _pin ?? here;
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.isPickup ? l.setPickup : l.setDropoff),
          leading: BackButton(onPressed: () => setState(() => _mapMode = false)),
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: BgMap(
                centre: pin,
                controller: _map,
                onTap: (p) => setState(() => _pin = p),
                pickup: widget.isPickup ? pin : null,
                dropoff: widget.isPickup ? null : pin,
              ),
            ),
            IgnorePointer(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 28),
                  child: Icon(Icons.place, size: 44, color: widget.isPickup ? BgColors.saffron : BgColors.blue),
                ),
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.all(BgSpace.md),
                child: BgCard(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Text(l.movePin, style: t.textTheme.labelMedium),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(BgSpace.md),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: _landmark,
                        decoration: InputDecoration(hintText: l.landmarkHint),
                      ),
                      const SizedBox(height: BgSpace.sm),
                      BgButton(
                        label: l.confirm,
                        onPressed: () => context.pop(Place(
                          location: pin,
                          landmark: _landmark.text.trim().isEmpty ? null : _landmark.text.trim(),
                          address: _landmark.text.trim().isEmpty ? null : _landmark.text.trim(),
                        )),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.isPickup ? l.setPickup : l.setDropoff)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(BgSpace.md),
            child: TextField(
              controller: _search,
              autofocus: true,
              onChanged: _onChanged,
              decoration: InputDecoration(
                hintText: l.searchHint,
                prefixIcon: const Icon(Icons.search),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.my_location, color: BgColors.blue),
            title: Text(l.yourLocation, style: t.textTheme.titleMedium),
            onTap: () => context.pop(Place(location: here, label: l.yourLocation)),
          ),
          ListTile(
            leading: const Icon(Icons.map_outlined, color: BgColors.blue),
            title: Text(l.chooseOnMap, style: t.textTheme.titleMedium),
            onTap: () => setState(() => _mapMode = true),
          ),
          const Divider(height: 1),
          Expanded(
            child: _results.isEmpty
                ? BgEmptyState(title: l.noResults, body: l.searchHint)
                : ListView.separated(
                    itemCount: _results.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final p = _results[i];
                      return ListTile(
                        leading: const Icon(Icons.place_outlined, color: BgColors.slate),
                        title: Text(p.display, style: t.textTheme.titleMedium),
                        onTap: () => context.pop(p),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Delivery details form shown as a sheet before quoting.
class _DeliveryDetailsSheet extends ConsumerStatefulWidget {
  const _DeliveryDetailsSheet();

  @override
  ConsumerState<_DeliveryDetailsSheet> createState() => _DeliveryDetailsSheetState();
}

class _DeliveryDetailsSheetState extends ConsumerState<_DeliveryDetailsSheet> {
  final _formKey = GlobalKey<FormState>();
  final _recipientName = TextEditingController();
  final _recipientPhone = TextEditingController();
  final _description = TextEditingController();
  final _instructions = TextEditingController();

  String _category = 'parcel';
  String _size = 'small';

  @override
  void dispose() {
    _recipientName.dispose();
    _recipientPhone.dispose();
    _description.dispose();
    _instructions.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context);
    final session = ref.watch(sessionProvider);

    final categories = <String, String>{
      'food': l.catFood,
      'shopping': l.catShopping,
      'parcel': l.catParcel,
      'document': l.catDocument,
      'pharmacy': l.catPharmacy,
      'other': l.catOther,
    };
    final sizes = <String, String>{
      'small': '${l.sizeSmall} · ${l.upToKg('5')}',
      'medium': '${l.sizeMedium} · ${l.upToKg('15')}',
      'large': '${l.sizeLarge} · ${l.upToKg('30')}',
    };

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, controller) => Form(
          key: _formKey,
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(BgSpace.md, 0, BgSpace.md, BgSpace.lg),
            children: [
              const BgGrabber(),
              Text(l.deliveryDetailsTitle, style: t.textTheme.headlineMedium),
              const SizedBox(height: BgSpace.md),

              Text(l.deliveryCategory, style: t.textTheme.labelMedium),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final e in categories.entries)
                    ChoiceChip(
                      label: Text(e.value),
                      selected: _category == e.key,
                      onSelected: (_) => setState(() => _category = e.key),
                    ),
                ],
              ),
              const SizedBox(height: BgSpace.md),

              Text(l.recipientDetails, style: t.textTheme.titleMedium),
              const SizedBox(height: 6),
              TextFormField(
                controller: _recipientName,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(labelText: l.recipientName),
                validator: (v) => (v ?? '').trim().isEmpty ? l.requiredField : null,
              ),
              const SizedBox(height: BgSpace.sm),
              TextFormField(
                controller: _recipientPhone,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(9)],
                decoration: InputDecoration(
                  labelText: l.recipientPhone,
                  prefixText: '${Env.countryCode} ',
                ),
                validator: (v) => (v ?? '').trim().length < 7 ? l.requiredField : null,
              ),
              const SizedBox(height: BgSpace.md),

              Text(l.packageSize, style: t.textTheme.labelMedium),
              const SizedBox(height: 6),
              Column(
                children: [
                  for (final e in sizes.entries)
                    RadioListTile<String>(
                      contentPadding: EdgeInsets.zero,
                      value: e.key,
                      groupValue: _size,
                      onChanged: (v) => setState(() => _size = v ?? 'small'),
                      title: Text(e.value, style: t.textTheme.titleMedium),
                    ),
                ],
              ),
              const SizedBox(height: BgSpace.sm),
              TextFormField(
                controller: _description,
                decoration: InputDecoration(labelText: l.packageDescription),
                validator: (v) => (v ?? '').trim().isEmpty ? l.requiredField : null,
              ),
              const SizedBox(height: BgSpace.sm),
              TextFormField(
                controller: _instructions,
                maxLines: 2,
                decoration: InputDecoration(labelText: '${l.instructions} (${l.optional})'),
              ),
              const SizedBox(height: BgSpace.md),

              BgCard(
                color: Theme.of(context).brightness == Brightness.dark
                    ? BgColors.dSurface2
                    : BgColors.sand,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, size: 18, color: BgColors.danger),
                        const SizedBox(width: 8),
                        Text(l.prohibitedTitle, style: t.textTheme.titleMedium),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(l.prohibitedBody, style: t.textTheme.labelSmall),
                  ],
                ),
              ),
              const SizedBox(height: BgSpace.md),
              BgButton(
                label: l.save,
                onPressed: () {
                  if (!(_formKey.currentState?.validate() ?? false)) return;
                  Navigator.of(context).pop(DeliveryDetails(
                    category: _category,
                    senderName: session.user?.fullName,
                    senderPhone: session.user?.phone,
                    recipientName: _recipientName.text.trim(),
                    recipientPhone: '${Env.countryCode}${_recipientPhone.text.trim()}',
                    description: _description.text.trim(),
                    size: _size,
                    instructions:
                        _instructions.text.trim().isEmpty ? null : _instructions.text.trim(),
                  ));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
