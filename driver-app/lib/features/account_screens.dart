import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/env.dart';
import '../core/theme/bg_colors.dart';
import '../core/theme/bg_theme.dart';
import '../core/utils/phone.dart';
import '../core/widgets.dart';
import '../data/models.dart';
import '../data/providers.dart';
import '../l10n/generated/app_localizations.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final session = ref.watch(sessionProvider);
    final p = session.profile;
    final locale = ref.watch(localeProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.accountTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            BgDemoBanner(label: l.mockBanner),
            BgCard(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: BgColors.saffron,
                    child: Text(
                      (p?.fullName.isNotEmpty ?? false)
                          ? p!.fullName.substring(0, 1).toUpperCase()
                          : 'B',
                      style: BgType.h2.copyWith(color: BgColors.night),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p?.fullName ?? '—', style: BgType.h3),
                        Text(SomaliPhone.format(p?.phone ?? ''), style: BgType.caption),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.star, size: 14, color: BgColors.saffron),
                            const SizedBox(width: 4),
                            Text(
                              '${(p?.rating ?? 5).toStringAsFixed(1)} (${p?.ratingCount ?? 0})',
                              style: BgType.caption,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            BgCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BgSectionTitle(l.vehicle),
                  BgKeyValue(l.fleetCode, p?.vehicle.fleetCode ?? '—'),
                  BgKeyValue(l.plate, p?.vehicle.plateNumber ?? '—'),
                  BgKeyValue(l.makeModel, p?.vehicle.makeModel ?? '—'),
                  if (p?.vehicle.colour != null) BgKeyValue(l.colour, p!.vehicle.colour!),
                ],
              ),
            ),
            const SizedBox(height: 12),
            BgCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BgSectionTitle(l.trips),
                  BgKeyValue(l.trips, '${p?.totalRides ?? 0}'),
                  BgKeyValue(l.deliveries, '${p?.totalDeliveries ?? 0}'),
                  BgKeyValue(l.acceptanceRate, '${(p?.acceptanceRate ?? 100).round()}%'),
                  if (p?.memberSince != null)
                    BgKeyValue(
                      l.memberSince(DateFormat('MMM yyyy').format(p!.memberSince!)),
                      '',
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            BgCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text(l.acceptsRides, style: BgType.bodyText),
                    value: p?.acceptsRides ?? true,
                    onChanged: (v) =>
                        ref.read(sessionProvider.notifier).setServices(rides: v),
                  ),
                  SwitchListTile(
                    title: Text(l.acceptsDeliveries, style: BgType.bodyText),
                    value: p?.acceptsDeliveries ?? true,
                    onChanged: (v) =>
                        ref.read(sessionProvider.notifier).setServices(deliveries: v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            BgCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: Text(l.documents, style: BgType.bodyText),
                    trailing: const Icon(Icons.chevron_right, color: BgColors.dText2),
                    onTap: () => context.push('/account/documents'),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.notifications_outlined),
                    title: Text(l.notifications, style: BgType.bodyText),
                    trailing: const Icon(Icons.chevron_right, color: BgColors.dText2),
                    onTap: () => context.push('/account/notifications'),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.translate),
                    title: Text(l.language, style: BgType.bodyText),
                    trailing: Text(
                      locale.languageCode == 'en' ? l.languageEnglish : l.languageSomali,
                      style: BgType.label,
                    ),
                    onTap: () => _languageSheet(context, ref, l),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.support_agent_outlined),
                    title: Text(l.support, style: BgType.bodyText),
                    trailing: const Icon(Icons.chevron_right, color: BgColors.dText2),
                    onTap: () => context.push('/account/support'),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.verified_user_outlined),
                    title: Text(l.verificationTitle, style: BgType.bodyText),
                    trailing: const Icon(Icons.chevron_right, color: BgColors.dText2),
                    onTap: () => context.push('/verification'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            BgButton(
              label: l.logout,
              variant: BgButtonVariant.ghost,
              icon: Icons.logout,
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(l.logout),
                    content: Text(l.logoutConfirm),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(l.cancel),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(l.logout),
                      ),
                    ],
                  ),
                );
                if (ok ?? false) {
                  await ref.read(sessionProvider.notifier).logout();
                  if (context.mounted) context.go('/phone');
                }
              },
            ),
            const SizedBox(height: 16),
            Center(child: Text(l.version(Env.appVersion), style: BgType.caption)),
            Center(child: Text(l.envBadge(Env.appEnv), style: BgType.caption)),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _languageSheet(BuildContext context, WidgetRef ref, AppLocalizations l) =>
      showModalBottomSheet<void>(
        context: context,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(l.languageSomali),
                onTap: () {
                  ref.read(localeProvider.notifier).set('so');
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                title: Text(l.languageEnglish),
                onTap: () {
                  ref.read(localeProvider.notifier).set('en');
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      );
}

class DocumentsScreen extends ConsumerStatefulWidget {
  const DocumentsScreen({super.key});
  @override
  ConsumerState<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends ConsumerState<DocumentsScreen> {
  String? _uploading;

  static const _types = [
    'national_id',
    'driving_licence',
    'vehicle_registration',
    'insurance',
  ];

  String _label(String type, AppLocalizations l) => switch (type) {
        'national_id' => l.docNationalId,
        'driving_licence' => l.docDrivingLicence,
        'vehicle_registration' => l.docVehicleRegistration,
        'insurance' => l.docInsurance,
        _ => type,
      };

  Future<void> _upload(String type) async {
    final l = AppLocalizations.of(context);
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (file == null) return;
      setState(() => _uploading = type);
      await ref.read(sessionProvider.notifier).uploadDocument(type, file.path);
      if (mounted) showBgSnack(context, l.saved);
    } catch (_) {
      if (mounted) showBgSnack(context, l.errorGeneric, error: true);
    } finally {
      if (mounted) setState(() => _uploading = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final docs = ref.watch(sessionProvider).profile?.documents ?? const <DriverDocument>[];

    return Scaffold(
      appBar: AppBar(title: Text(l.documents)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(l.docsRequiredHint, style: BgType.caption),
            const SizedBox(height: 16),
            for (final type in _types) ...[
              _row(type, docs, l),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(String type, List<DriverDocument> docs, AppLocalizations l) {
    final matches = docs.where((d) => d.type == type).toList();
    final doc = matches.isEmpty ? null : matches.first;
    final status = doc?.status ?? DocStatus.missing;
    final (label, colour) = switch (status) {
      DocStatus.approved => (l.docStatusApproved, BgColors.success),
      DocStatus.rejected => (l.docStatusRejected, BgColors.danger),
      DocStatus.expired => (l.docStatusExpired, BgColors.danger),
      DocStatus.pending => (l.docStatusPending, BgColors.saffron),
      DocStatus.missing => (l.docStatusMissing, BgColors.dText2),
    };

    return BgCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_label(type, l), style: BgType.bodyStrong),
                const SizedBox(height: 4),
                Row(
                  children: [
                    BgPill(
                      label: label,
                      colour: colour,
                      textColour: status == DocStatus.missing ? BgColors.dText : BgColors.night,
                    ),
                    if (doc?.expiresAt != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        l.docExpires(DateFormat('dd MMM yyyy').format(doc!.expiresAt!)),
                        style: BgType.caption,
                      ),
                    ],
                  ],
                ),
                if (doc?.expiringSoon ?? false) ...[
                  const SizedBox(height: 4),
                  Text(
                    l.docExpiringSoon,
                    style: BgType.caption.copyWith(color: BgColors.saffron),
                  ),
                ],
              ],
            ),
          ),
          if (_uploading == type)
            const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
          else
            TextButton(
              onPressed: () => _upload(type),
              child: Text(
                status == DocStatus.missing ? l.docUpload : l.docReupload,
                style: BgType.label.copyWith(color: BgColors.saffron),
              ),
            ),
        ],
      ),
    );
  }
}

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final items = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.notifications)),
      body: SafeArea(
        child: items.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => BgEmptyState(title: l.errorGeneric, icon: Icons.error_outline),
          data: (list) => list.isEmpty
              ? BgEmptyState(title: l.noNotifications, icon: Icons.notifications_none)
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final n = list[i];
                    return BgCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(n.title, style: BgType.bodyStrong),
                          const SizedBox(height: 4),
                          Text(n.body, style: BgType.bodyText),
                          const SizedBox(height: 6),
                          Text(
                            DateFormat('dd MMM · HH:mm').format(n.at),
                            style: BgType.caption,
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l.support)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            BgCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BgSectionTitle(l.supportPhone),
                  Text(Env.supportPhone, style: BgType.h3),
                  const SizedBox(height: 14),
                  BgButton(
                    label: l.callSupport,
                    icon: Icons.phone,
                    onPressed: () async {
                      final uri = Uri.parse('tel:${Env.supportPhone.replaceAll(' ', '')}');
                      try {
                        await launchUrl(uri);
                      } catch (_) {/* no dialler */}
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            BgCard(
              onTap: () async {
                try {
                  await launchUrl(
                    Uri.parse(Env.handbookUrl),
                    mode: LaunchMode.externalApplication,
                  );
                } catch (_) {/* no browser */}
              },
              child: Row(
                children: [
                  const Icon(Icons.menu_book_outlined, color: BgColors.dBlue),
                  const SizedBox(width: 14),
                  Expanded(child: Text(l.handbook, style: BgType.bodyStrong)),
                  const Icon(Icons.open_in_new, size: 18, color: BgColors.dText2),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (Env.useMock)
              BgCard(
                colour: BgColors.dSurface2,
                child: Text(
                  'Demo build: in-app support tickets need the BajGo backend. '
                  'Use the support phone above in the meantime.',
                  style: BgType.caption,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
