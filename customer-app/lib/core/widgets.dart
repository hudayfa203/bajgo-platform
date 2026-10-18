import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:latlong2/latlong.dart';

import '../data/models.dart';
import 'env.dart';
import 'theme.dart';

/// Primary action button. Height 52, full width by default, loading state built in.
class BgButton extends StatelessWidget {
  const BgButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = BgButtonVariant.primary,
    this.icon,
    this.loading = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final BgButtonVariant variant;
  final IconData? icon;
  final bool loading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    late final Color bg;
    late final Color fg;
    Color? border;
    switch (variant) {
      case BgButtonVariant.primary:
        bg = BgColors.blue;
        fg = BgColors.white;
      case BgButtonVariant.secondary:
        bg = Colors.transparent;
        fg = dark ? BgColors.dText : BgColors.night;
        border = dark ? BgColors.dSurface2 : BgColors.night;
      case BgButtonVariant.saffron:
        bg = BgColors.saffron;
        fg = BgColors.night;
      case BgButtonVariant.danger:
        bg = BgColors.danger;
        fg = BgColors.white;
      case BgButtonVariant.ghost:
        bg = dark ? BgColors.dSurface2 : BgColors.cloud;
        fg = dark ? BgColors.dText : BgColors.night;
    }

    final child = loading
        ? SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: fg),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[Icon(icon, size: 20, color: fg), const SizedBox(width: 8)],
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontFamily: BgTheme.body, fontSize: 16, fontWeight: FontWeight.w700, color: fg),
                ),
              ),
            ],
          );

    return SizedBox(
      width: expand ? double.infinity : null,
      height: 52,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(BgSpace.rButton),
        child: InkWell(
          onTap: loading ? null : onPressed,
          borderRadius: BorderRadius.circular(BgSpace.rButton),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(BgSpace.rButton),
              border: border != null ? Border.all(color: border, width: 1.6) : null,
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Opacity(opacity: onPressed == null && !loading ? 0.45 : 1, child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum BgButtonVariant { primary, secondary, saffron, danger, ghost }

/// Card surface with the standard border and radius.
class BgCard extends StatelessWidget {
  const BgCard({super.key, required this.child, this.padding, this.onTap, this.color});

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final content = Padding(
      padding: padding ?? const EdgeInsets.all(BgSpace.md),
      child: child,
    );
    return Material(
      color: color ?? t.colorScheme.surface,
      borderRadius: BorderRadius.circular(BgSpace.rCard),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(BgSpace.rCard),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(BgSpace.rCard),
            border: Border.all(color: t.dividerColor),
          ),
          child: content,
        ),
      ),
    );
  }
}

/// Status chip with a colour-coded dot, used across tracking and history.
class BgStatusPill extends StatelessWidget {
  const BgStatusPill({super.key, required this.status, required this.label});

  final BookingStatus status;
  final String label;

  Color get _color {
    switch (status) {
      case BookingStatus.searching:
      case BookingStatus.requested:
        return BgColors.saffron;
      case BookingStatus.completed:
      case BookingStatus.delivered:
      case BookingStatus.paid:
        return BgColors.success;
      case BookingStatus.cancelled:
      case BookingStatus.expired:
      case BookingStatus.failed:
      case BookingStatus.returned:
        return BgColors.danger;
      default:
        return BgColors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: dark ? BgColors.dSurface2 : BgColors.cloud,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: _color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}

/// Map with BajGo styling. Handles markers, the route line and the driver pin.
class BgMap extends StatelessWidget {
  const BgMap({
    super.key,
    required this.centre,
    this.zoom = Env.defaultZoom,
    this.controller,
    this.pickup,
    this.dropoff,
    this.driver,
    this.nearby = const <LatLng>[],
    this.route = const <LatLng>[],
    this.onTap,
    this.interactive = true,
  });

  final LatLng centre;
  final double zoom;
  final MapController? controller;
  final LatLng? pickup;
  final LatLng? dropoff;
  final LatLng? driver;
  final List<LatLng> nearby;
  final List<LatLng> route;
  final void Function(LatLng)? onTap;
  final bool interactive;

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: controller,
      options: MapOptions(
        initialCenter: centre,
        initialZoom: zoom,
        interactionOptions: InteractionOptions(
          flags: interactive ? InteractiveFlag.all & ~InteractiveFlag.rotate : InteractiveFlag.none,
        ),
        onTap: onTap == null ? null : (tapPos, point) => onTap!(point),
      ),
      children: [
        TileLayer(
          urlTemplate: Env.tileUrl,
          userAgentPackageName: 'com.bajgo.customer',
          maxZoom: 19,
        ),
        if (route.length > 1)
          PolylineLayer(
            polylines: [
              Polyline(points: route, color: BgColors.blue, strokeWidth: 5),
            ],
          ),
        MarkerLayer(
          markers: [
            for (final n in nearby)
              Marker(
                point: n,
                width: 30,
                height: 30,
                child: const _SymbolMarker(size: 30),
              ),
            if (pickup != null)
              Marker(
                point: pickup!,
                width: 26,
                height: 26,
                child: const _Dot(color: BgColors.saffron),
              ),
            if (dropoff != null)
              Marker(
                point: dropoff!,
                width: 22,
                height: 22,
                child: const _Square(color: BgColors.blue),
              ),
            if (driver != null)
              Marker(
                point: driver!,
                width: 44,
                height: 44,
                child: const _SymbolMarker(size: 44, elevated: true),
              ),
          ],
        ),
        const _Attribution(),
      ],
    );
  }
}

class _Attribution extends StatelessWidget {
  const _Attribution();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomLeft,
      child: Container(
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        color: const Color(0xAAFFFFFF),
        child: const Text(
          '© OpenStreetMap contributors',
          style: TextStyle(fontSize: 9, color: BgColors.night, fontFamily: BgTheme.body),
        ),
      ),
    );
  }
}

class _SymbolMarker extends StatelessWidget {
  const _SymbolMarker({required this.size, this.elevated = false});
  final double size;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: elevated ? BgColors.blue : BgColors.white,
        shape: BoxShape.circle,
        border: Border.all(color: elevated ? BgColors.white : BgColors.blue, width: 2),
      ),
      padding: EdgeInsets.all(size * 0.16),
      child: SvgPicture.asset(
        elevated
            ? 'assets/brand/BajGo_Symbol_White.svg'
            : 'assets/brand/BajGo_Symbol_FullColour.svg',
        fit: BoxFit.contain,
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: BgColors.white, width: 3),
        ),
      );
}

class _Square extends StatelessWidget {
  const _Square({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: BgColors.white, width: 3),
        ),
      );
}

/// Pickup → drop-off rows with the saffron origin dot and blue destination square.
class BgPlaceRows extends StatelessWidget {
  const BgPlaceRows({
    super.key,
    required this.pickupLabel,
    required this.dropoffLabel,
    this.pickupHint,
    this.dropoffHint,
    this.onTapPickup,
    this.onTapDropoff,
  });

  final String pickupLabel;
  final String dropoffLabel;
  final String? pickupHint;
  final String? dropoffHint;
  final VoidCallback? onTapPickup;
  final VoidCallback? onTapDropoff;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    Widget row(String label, String? hint, Widget marker, VoidCallback? onTap) {
      final empty = label.trim().isEmpty;
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(BgSpace.rInput),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Row(
            children: [
              SizedBox(width: 24, child: Center(child: marker)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hint != null)
                      Text(hint, style: t.textTheme.labelSmall),
                    Text(
                      empty ? '—' : label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.textTheme.titleMedium?.copyWith(
                        color: empty ? t.textTheme.bodyMedium?.color : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        row(pickupLabel, pickupHint,
            Container(width: 12, height: 12, decoration: const BoxDecoration(color: BgColors.saffron, shape: BoxShape.circle)),
            onTapPickup),
        Padding(
          padding: const EdgeInsets.only(left: 15),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(width: 2, height: 16, color: t.dividerColor),
          ),
        ),
        row(dropoffLabel, dropoffHint,
            Container(width: 12, height: 12, decoration: BoxDecoration(color: BgColors.blue, borderRadius: BorderRadius.circular(3))),
            onTapDropoff),
      ],
    );
  }
}

/// Empty state built around the brand symbol.
class BgEmptyState extends StatelessWidget {
  const BgEmptyState({super.key, required this.title, required this.body, this.action});

  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(BgSpace.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Opacity(
              opacity: 0.25,
              child: SvgPicture.asset('assets/brand/BajGo_Symbol_FullColour.svg', height: 72),
            ),
            const SizedBox(height: BgSpace.lg),
            Text(title, textAlign: TextAlign.center, style: t.textTheme.titleLarge),
            const SizedBox(height: BgSpace.sm),
            Text(body, textAlign: TextAlign.center, style: t.textTheme.bodyMedium),
            if (action != null) ...[const SizedBox(height: BgSpace.lg), action!],
          ],
        ),
      ),
    );
  }
}

/// Persistent strip shown in demo builds so a test APK is never mistaken for production.
class BgDemoBanner extends StatelessWidget {
  const BgDemoBanner({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    if (!Env.demo) return const SizedBox.shrink();
    return Material(
      color: BgColors.saffron,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              const Icon(Icons.science_outlined, size: 16, color: BgColors.night),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                      fontFamily: BgTheme.body,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: BgColors.night),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Grabber handle for bottom sheets.
class BgGrabber extends StatelessWidget {
  const BgGrabber({super.key});

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          width: 36,
          height: 4,
          margin: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).dividerColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );
}

/// Small labelled section heading.
class BgSectionTitle extends StatelessWidget {
  const BgSectionTitle(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: BgSpace.sm),
        child: Row(
          children: [
            Expanded(child: Text(text, style: Theme.of(context).textTheme.titleMedium)),
            if (trailing != null) trailing!,
          ],
        ),
      );
}

void showBgSnack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: error ? BgColors.danger : BgColors.night,
    ));
}
