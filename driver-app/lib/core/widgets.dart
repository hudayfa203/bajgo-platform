import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:latlong2/latlong.dart';

import '../data/models.dart';
import 'env.dart';
import 'theme/bg_colors.dart';
import 'theme/bg_theme.dart';

enum BgButtonVariant { primary, secondary, danger, ghost, success }

/// 52 dp high, 14 dp radius. Primary is Saffron with Night text — never white
/// on Saffron (DESIGN_SYSTEM.md contrast rules).
class BgButton extends StatelessWidget {
  const BgButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = BgButtonVariant.primary,
    this.icon,
    this.busy = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final BgButtonVariant variant;
  final IconData? icon;
  final bool busy;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (variant) {
      BgButtonVariant.primary => (BgColors.saffron, BgColors.night),
      BgButtonVariant.secondary => (BgColors.dSurface2, BgColors.dText),
      BgButtonVariant.danger => (BgColors.danger, BgColors.white),
      BgButtonVariant.success => (BgColors.success, BgColors.white),
      BgButtonVariant.ghost => (Colors.transparent, BgColors.dText),
    };
    final enabled = onPressed != null && !busy;

    final child = busy
        ? SizedBox(
            height: 20,
            width: 20,
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
                  style: BgType.bodyStrong.copyWith(color: fg),
                ),
              ),
            ],
          );

    final button = Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(BgRadius.button),
        shape: variant == BgButtonVariant.ghost
            ? RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(BgRadius.button),
                side: const BorderSide(color: BgColors.dSurface2),
              )
            : null,
        child: InkWell(
          borderRadius: BorderRadius.circular(BgRadius.button),
          onTap: enabled ? onPressed : null,
          child: Container(
            height: 52,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: child,
          ),
        ),
      ),
    );

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

class BgCard extends StatelessWidget {
  const BgCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.colour,
    this.onTap,
    this.border,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color? colour;
  final VoidCallback? onTap;
  final Color? border;

  @override
  Widget build(BuildContext context) {
    final content = Container(padding: padding, child: child);
    return Material(
      color: colour ?? BgColors.dSurface,
      borderRadius: BorderRadius.circular(BgRadius.card),
      shape: border != null
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(BgRadius.card),
              side: BorderSide(color: border!, width: 1.5),
            )
          : null,
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? content
          : InkWell(onTap: onTap, child: content),
    );
  }
}

class BgPill extends StatelessWidget {
  const BgPill({super.key, required this.label, this.colour, this.textColour, this.icon});

  final String label;
  final Color? colour;
  final Color? textColour;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final bg = colour ?? BgColors.dSurface2;
    final fg = textColour ?? BgColors.dText;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(BgRadius.chip)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 14, color: fg), const SizedBox(width: 6)],
          Text(label, style: BgType.label.copyWith(color: fg, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

/// Service badge: Blue for rides, Saffron for deliveries.
class BgServiceBadge extends StatelessWidget {
  const BgServiceBadge({super.key, required this.service, required this.label});
  final ServiceType service;
  final String label;

  @override
  Widget build(BuildContext context) => BgPill(
        label: label,
        colour: service == ServiceType.delivery ? BgColors.saffron : BgColors.dBlue,
        textColour: service == ServiceType.delivery ? BgColors.night : BgColors.white,
        icon: service == ServiceType.delivery
            ? Icons.inventory_2_outlined
            : Icons.person_outline,
      );
}

class BgSectionTitle extends StatelessWidget {
  const BgSectionTitle(this.title, {super.key, this.trailing});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Expanded(child: Text(title, style: BgType.h3)),
            if (trailing != null) trailing!,
          ],
        ),
      );
}

class BgEmptyState extends StatelessWidget {
  const BgEmptyState({
    super.key,
    required this.title,
    this.body,
    this.icon = Icons.inbox_outlined,
    this.action,
  });

  final String title;
  final String? body;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 72,
                width: 72,
                decoration: const BoxDecoration(
                  color: BgColors.dSurface,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: BgColors.dText2, size: 32),
              ),
              const SizedBox(height: 16),
              Text(title, style: BgType.h3, textAlign: TextAlign.center),
              if (body != null) ...[
                const SizedBox(height: 6),
                Text(body!, style: BgType.caption, textAlign: TextAlign.center),
              ],
              if (action != null) ...[const SizedBox(height: 20), action!],
            ],
          ),
        ),
      );
}

/// Shown on every screen of a demo build so nobody mistakes it for live data.
class BgDemoBanner extends StatelessWidget {
  const BgDemoBanner({super.key, required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    if (!Env.useMock) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      color: BgColors.saffron,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      child: Row(
        children: [
          const Icon(Icons.science_outlined, size: 15, color: BgColors.night),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: BgType.caption.copyWith(
                color: BgColors.night,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BgLogo extends StatelessWidget {
  const BgLogo({super.key, this.height = 36, this.symbolOnly = false});
  final double height;
  final bool symbolOnly;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
        symbolOnly
            ? 'assets/brand/BajGo_Symbol_White.svg'
            : 'assets/brand/BajGo_Logo_Horizontal_White.svg',
        height: height,
      );
}

/// Map with OSM tiles, an optional route, and pickup / drop-off / driver pins.
class BgMap extends StatelessWidget {
  const BgMap({
    super.key,
    required this.centre,
    this.zoom = 14,
    this.route = const <LatLng>[],
    this.pickup,
    this.dropoff,
    this.driver,
    this.controller,
    this.interactive = true,
  });

  final LatLng centre;
  final double zoom;
  final List<LatLng> route;
  final LatLng? pickup;
  final LatLng? dropoff;
  final LatLng? driver;
  final MapController? controller;
  final bool interactive;

  @override
  Widget build(BuildContext context) => FlutterMap(
        mapController: controller,
        options: MapOptions(
          initialCenter: centre,
          initialZoom: zoom,
          interactionOptions: InteractionOptions(
            flags: interactive ? InteractiveFlag.all : InteractiveFlag.none,
          ),
          backgroundColor: BgColors.dBg,
        ),
        children: [
          TileLayer(
            urlTemplate: Env.tileUrl,
            userAgentPackageName: Env.userAgentPackage,
            tileProvider: NetworkTileProvider(),
          ),
          if (route.length > 1)
            PolylineLayer(
              polylines: [
                Polyline(points: route, strokeWidth: 5, color: BgColors.dBlue),
              ],
            ),
          MarkerLayer(
            markers: [
              if (pickup != null)
                Marker(
                  point: pickup!,
                  width: 26,
                  height: 26,
                  child: const _Dot(colour: BgColors.saffron),
                ),
              if (dropoff != null)
                Marker(
                  point: dropoff!,
                  width: 26,
                  height: 26,
                  child: const _Dot(colour: BgColors.dBlue),
                ),
              if (driver != null)
                Marker(
                  point: driver!,
                  width: 44,
                  height: 44,
                  child: Container(
                    decoration: BoxDecoration(
                      color: BgColors.saffron,
                      shape: BoxShape.circle,
                      border: Border.all(color: BgColors.night, width: 2),
                    ),
                    padding: const EdgeInsets.all(7),
                    child: SvgPicture.asset('assets/brand/BajGo_Symbol_Black.svg'),
                  ),
                ),
            ],
          ),
        ],
      );
}

class _Dot extends StatelessWidget {
  const _Dot({required this.colour});
  final Color colour;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: BgColors.white,
          shape: BoxShape.circle,
          border: Border.all(color: colour, width: 4),
        ),
      );
}

/// Pickup → drop-off, the pattern used on offers, trips and receipts.
class BgRouteRows extends StatelessWidget {
  const BgRouteRows({
    super.key,
    required this.pickupLabel,
    required this.pickup,
    required this.dropoffLabel,
    required this.dropoff,
  });

  final String pickupLabel;
  final String pickup;
  final String dropoffLabel;
  final String dropoff;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          _row(BgColors.saffron, pickupLabel, pickup),
          Padding(
            padding: const EdgeInsets.only(left: 5),
            child: Row(
              children: [
                Container(width: 2, height: 18, color: BgColors.dSurface2),
              ],
            ),
          ),
          _row(BgColors.dBlue, dropoffLabel, dropoff),
        ],
      );

  Widget _row(Color colour, String label, String value) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 5),
            height: 12,
            width: 12,
            decoration: BoxDecoration(color: colour, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: BgType.caption),
                Text(value, style: BgType.bodyStrong, maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      );
}

/// Label / value row used across earnings, receipts and account screens.
class BgKeyValue extends StatelessWidget {
  const BgKeyValue(this.label, this.value, {super.key, this.strong = false, this.valueColour});
  final String label;
  final String value;
  final bool strong;
  final Color? valueColour;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text(label, style: BgType.bodyText.copyWith(color: BgColors.dText2))),
            const SizedBox(width: 12),
            Text(
              value,
              style: (strong ? BgType.bodyStrong : BgType.bodyText)
                  .copyWith(color: valueColour ?? BgColors.dText),
            ),
          ],
        ),
      );
}

class BgStatTile extends StatelessWidget {
  const BgStatTile({super.key, required this.label, required this.value, this.icon});
  final String label;
  final String value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => BgCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: BgColors.dText2),
              const SizedBox(height: 8),
            ],
            Text(value, style: BgType.h2),
            const SizedBox(height: 2),
            Text(label, style: BgType.caption),
          ],
        ),
      );
}

void showBgSnack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: BgType.bodyText.copyWith(color: error ? BgColors.white : BgColors.dText),
        ),
        backgroundColor: error ? BgColors.danger : BgColors.dSurface2,
      ),
    );
}

/// A simple bar chart for the earnings screen; no chart package needed.
class BgBarChart extends StatelessWidget {
  const BgBarChart({super.key, required this.values, required this.labels});
  final List<int> values;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final max = values.isEmpty ? 1 : values.reduce((a, b) => a > b ? a : b);
    final safeMax = max == 0 ? 1 : max;
    return SizedBox(
      height: 132,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < values.length; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      height: (values[i] / safeMax) * 96 + 2,
                      decoration: BoxDecoration(
                        color: values[i] == 0 ? BgColors.dSurface2 : BgColors.saffron,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      i < labels.length ? labels[i] : '',
                      style: BgType.caption,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
