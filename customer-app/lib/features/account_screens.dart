import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/env.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../data/models.dart';
import '../data/providers.dart';
import '../l10n/generated/app_localizations.dart';

/// Payment methods, payment history and promo codes.
class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context);
    final methods = ref.watch(paymentMethodsProvider);
    final history = ref.watch(bookingHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.wallet)),
      body: ListView(
        padding: const EdgeInsets.all(BgSpace.md),
        children: [
          BgSectionTitle(l.paymentMethods),
          methods.maybeWhen(
            data: (list) => BgCard(
              child: Column(
                children: [
                  for (final m in list)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        m.method == 'cash' ? Icons.payments_outlined : Icons.smartphone,
                        color: BgColors.slate,
                      ),
                      title: Text(m.labelEn, style: t.textTheme.titleMedium),
                      subtitle: Text(m.labelSo, style: t.textTheme.labelSmall),
                      trailing: m.live
                          ? const Icon(Icons.check_circle, color: BgColors.success, size: 20)
                          : Text(l.comingSoon, style: t.textTheme.labelSmall),
                    ),
                ],
              ),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
          const SizedBox(height: BgSpace.lg),
          BgSectionTitle(l.paymentHistory),
          history.maybeWhen(
            data: (list) {
              final paid = list.where((b) => isTerminal(b.status) && b.payableCents > 0).toList();
              if (paid.isEmpty) {
                return BgCard(
                  child: Column(
                    children: [
                      Text(l.noPayments, style: t.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(l.noPaymentsBody,
                          textAlign: TextAlign.center, style: t.textTheme.bodyMedium),
                    ],
                  ),
                );
              }
              return BgCard(
                child: Column(
                  children: [
                    for (final b in paid.take(20))
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(b.reference, style: t.textTheme.titleMedium),
                        subtitle: Text(
                          '${b.service == ServiceType.ride ? l.serviceRide : l.serviceDelivery} · ${b.paymentMethod}',
                          style: t.textTheme.labelSmall,
                        ),
                        trailing: Text(formatMoney(b.payableCents), style: t.textTheme.titleMedium),
                        onTap: () => context.push('/receipt/${b.id}'),
                      ),
                  ],
                ),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
          const SizedBox(height: BgSpace.lg),
          BgSectionTitle(l.promoCodes),
          BgCard(
            child: Row(
              children: [
                const Icon(Icons.local_offer_outlined, color: BgColors.saffron),
                const SizedBox(width: 12),
                Expanded(child: Text(l.promoHint, style: t.textTheme.bodyMedium)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Profile, language, theme, saved places, support and account actions.
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context);
    final session = ref.watch(sessionProvider);
    final prefs = ref.watch(prefsControllerProvider);
    final user = session.user;

    return Scaffold(
      appBar: AppBar(title: Text(l.account)),
      body: ListView(
        padding: const EdgeInsets.all(BgSpace.md),
        children: [
          BgCard(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: BgColors.blue,
                  child: Text(
                    initialOf(user?.fullName),
                    style: const TextStyle(
                        color: BgColors.white, fontWeight: FontWeight.w700, fontSize: 20),
                  ),
                ),
                const SizedBox(width: BgSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.fullName ?? '—', style: t.textTheme.titleLarge),
                      Text(user?.phone ?? '', style: t.textTheme.labelMedium),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: BgSpace.lg),

          BgSectionTitle(l.language),
          BgCard(
            child: Column(
              children: [
                RadioListTile<String>(
                  contentPadding: EdgeInsets.zero,
                  value: 'so',
                  groupValue: prefs.locale,
                  title: Text(l.somali, style: t.textTheme.titleMedium),
                  onChanged: (v) {
                    ref.read(prefsControllerProvider.notifier).setLocale('so');
                    ref.read(sessionProvider.notifier).setLanguage('so');
                  },
                ),
                RadioListTile<String>(
                  contentPadding: EdgeInsets.zero,
                  value: 'en',
                  groupValue: prefs.locale,
                  title: Text(l.english, style: t.textTheme.titleMedium),
                  onChanged: (v) {
                    ref.read(prefsControllerProvider.notifier).setLocale('en');
                    ref.read(sessionProvider.notifier).setLanguage('en');
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: BgSpace.lg),

          BgSectionTitle(l.appearance),
          BgCard(
            child: Column(
              children: [
                for (final e in {
                  ThemeMode.system: l.themeSystem,
                  ThemeMode.light: l.themeLight,
                  ThemeMode.dark: l.themeDark,
                }.entries)
                  RadioListTile<ThemeMode>(
                    contentPadding: EdgeInsets.zero,
                    value: e.key,
                    groupValue: prefs.themeMode,
                    title: Text(e.value, style: t.textTheme.titleMedium),
                    onChanged: (v) =>
                        ref.read(prefsControllerProvider.notifier).setThemeMode(v ?? ThemeMode.system),
                  ),
              ],
            ),
          ),
          const SizedBox(height: BgSpace.lg),

          BgCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _tile(context, Icons.place_outlined, l.savedPlaces, () => context.push('/places')),
                _tile(context, Icons.notifications_none, l.notifications,
                    () => context.push('/notifications')),
                _tile(context, Icons.support_agent, l.support, () => context.push('/support')),
                _tile(context, Icons.call, l.callSupport, () {
                  launchUrl(Uri.parse('mailto:${Env.supportEmail}'));
                }),
                _tile(context, Icons.privacy_tip_outlined, l.privacy,
                    () => launchUrl(Uri.parse('${Env.website}/so/privacy'),
                        mode: LaunchMode.externalApplication)),
                _tile(context, Icons.description_outlined, l.terms,
                    () => launchUrl(Uri.parse('${Env.website}/so/terms'),
                        mode: LaunchMode.externalApplication)),
              ],
            ),
          ),
          const SizedBox(height: BgSpace.lg),

          BgButton(
            label: l.logout,
            variant: BgButtonVariant.ghost,
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text(l.logout),
                  content: Text(l.logoutConfirm),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.of(context).pop(false), child: Text(l.cancel)),
                    FilledButton(
                        onPressed: () => Navigator.of(context).pop(true), child: Text(l.logout)),
                  ],
                ),
              );
              if (ok != true) return;
              await ref.read(sessionProvider.notifier).logout();
              if (context.mounted) context.go('/phone');
            },
          ),
          const SizedBox(height: BgSpace.md),
          Center(child: Text(l.version(Env.appVersion), style: t.textTheme.labelSmall)),
          const SizedBox(height: BgSpace.lg),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: BgColors.slate),
      title: Text(label, style: Theme.of(context).textTheme.titleMedium),
      trailing: const Icon(Icons.chevron_right, color: BgColors.slate),
      onTap: onTap,
    );
  }
}

/// Saved places: add Home / Work / custom addresses.
class SavedPlacesScreen extends ConsumerWidget {
  const SavedPlacesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context);
    final places = ref.watch(savedPlacesProvider);

    Future<void> add(String kind, String label) async {
      final picked = await context.push<Place>('/pick', extra: false);
      if (picked == null) return;
      await ref.read(apiProvider).addSavedPlace(
            SavedPlace(id: '', label: label, kind: kind, place: picked),
          );
      ref.invalidate(savedPlacesProvider);
    }

    return Scaffold(
      appBar: AppBar(title: Text(l.savedPlaces)),
      body: places.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => BgEmptyState(title: l.errorGeneric, body: '$e'),
        data: (list) => ListView(
          padding: const EdgeInsets.all(BgSpace.md),
          children: [
            BgCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.home_outlined, color: BgColors.blue),
                    title: Text(l.addHome, style: t.textTheme.titleMedium),
                    onTap: () => add('home', l.savedHome),
                  ),
                  ListTile(
                    leading: const Icon(Icons.work_outline, color: BgColors.blue),
                    title: Text(l.addWork, style: t.textTheme.titleMedium),
                    onTap: () => add('work', l.savedWork),
                  ),
                  ListTile(
                    leading: const Icon(Icons.add_location_alt_outlined, color: BgColors.blue),
                    title: Text(l.addPlace, style: t.textTheme.titleMedium),
                    onTap: () => add('custom', l.placeCustom),
                  ),
                ],
              ),
            ),
            const SizedBox(height: BgSpace.lg),
            if (list.isEmpty)
              BgEmptyState(title: l.noSavedPlaces, body: l.noSavedPlacesBody)
            else
              for (final p in list)
                Padding(
                  padding: const EdgeInsets.only(bottom: BgSpace.sm),
                  child: BgCard(
                    child: Row(
                      children: [
                        Icon(
                          p.kind == 'home'
                              ? Icons.home_outlined
                              : p.kind == 'work'
                                  ? Icons.work_outline
                                  : Icons.place_outlined,
                          color: BgColors.slate,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.label, style: t.textTheme.titleMedium),
                              Text(p.place.display,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: t.textTheme.labelSmall),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: BgColors.danger),
                          onPressed: () async {
                            await ref.read(apiProvider).deleteSavedPlace(p.id);
                            ref.invalidate(savedPlacesProvider);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context);
    final items = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.notifications)),
      body: items.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => BgEmptyState(title: l.errorGeneric, body: '$e'),
        data: (list) => list.isEmpty
            ? BgEmptyState(title: l.noNotifications, body: l.noNotificationsBody)
            : RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(notificationsProvider);
                  await ref.read(notificationsProvider.future);
                },
                child: ListView.separated(
                  padding: const EdgeInsets.all(BgSpace.md),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: BgSpace.sm),
                  itemBuilder: (context, i) {
                    final n = list[i];
                    return BgCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(n.title, style: t.textTheme.titleMedium),
                          const SizedBox(height: 2),
                          Text(n.body, style: t.textTheme.bodyMedium),
                          const SizedBox(height: 6),
                          Text(n.createdAt.toLocal().toString().substring(0, 16),
                              style: t.textTheme.labelSmall),
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

/// Support tickets list + new ticket.
class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key});

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  Future<void> _newTicket() async {
    final l = AppLocalizations.of(context);
    final subject = TextEditingController();
    final message = TextEditingController();
    var category = 'other';

    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: StatefulBuilder(
          builder: (ctx, setSheet) => Padding(
            padding: const EdgeInsets.all(BgSpace.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const BgGrabber(),
                Text(l.newTicket, style: Theme.of(ctx).textTheme.headlineMedium),
                const SizedBox(height: BgSpace.md),
                TextField(
                  controller: subject,
                  decoration: InputDecoration(labelText: l.ticketSubject),
                ),
                const SizedBox(height: BgSpace.sm),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final e in {
                      'ride': l.ticketCatRide,
                      'delivery': l.ticketCatDelivery,
                      'payment': l.ticketCatPayment,
                      'lost_item': l.ticketCatLostItem,
                      'account': l.ticketCatAccount,
                      'other': l.ticketCatOther,
                    }.entries)
                      ChoiceChip(
                        label: Text(e.value),
                        selected: category == e.key,
                        onSelected: (_) => setSheet(() => category = e.key),
                      ),
                  ],
                ),
                const SizedBox(height: BgSpace.sm),
                TextField(
                  controller: message,
                  maxLines: 4,
                  decoration: InputDecoration(labelText: l.ticketMessage),
                ),
                const SizedBox(height: BgSpace.md),
                BgButton(
                  label: l.send,
                  onPressed: () async {
                    if (subject.text.trim().isEmpty || message.text.trim().isEmpty) return;
                    await ref
                        .read(apiProvider)
                        .createTicket(subject.text.trim(), category, message.text.trim());
                    if (ctx.mounted) Navigator.of(ctx).pop(true);
                  },
                ),
                const SizedBox(height: BgSpace.md),
              ],
            ),
          ),
        ),
      ),
    );

    subject.dispose();
    message.dispose();
    if (created == true) ref.invalidate(ticketsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context);
    final tickets = ref.watch(ticketsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.support)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _newTicket,
        backgroundColor: BgColors.blue,
        foregroundColor: BgColors.white,
        icon: const Icon(Icons.add),
        label: Text(l.newTicket),
      ),
      body: tickets.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => BgEmptyState(title: l.errorGeneric, body: '$e'),
        data: (list) => list.isEmpty
            ? BgEmptyState(title: l.noTickets, body: l.noTicketsBody)
            : ListView.separated(
                padding: const EdgeInsets.all(BgSpace.md),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: BgSpace.sm),
                itemBuilder: (context, i) {
                  final tk = list[i];
                  return BgCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text(tk.subject, style: t.textTheme.titleMedium)),
                            Text(tk.reference, style: t.textTheme.labelSmall),
                          ],
                        ),
                        const SizedBox(height: BgSpace.sm),
                        for (final m in tk.messages)
                          Align(
                            alignment: m.mine ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: m.mine ? BgColors.blue : t.dividerColor,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                m.body,
                                style: t.textTheme.bodyMedium?.copyWith(
                                    color: m.mine ? BgColors.white : null),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
