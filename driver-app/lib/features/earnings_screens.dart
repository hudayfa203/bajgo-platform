import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../core/theme/bg_colors.dart';
import '../core/theme/bg_theme.dart';
import '../core/utils/money.dart';
import '../core/widgets.dart';
import '../data/api.dart';
import '../data/models.dart';
import '../data/providers.dart';
import '../l10n/generated/app_localizations.dart';

class EarningsScreen extends ConsumerWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final period = ref.watch(earningsPeriodProvider);
    final earnings = ref.watch(earningsProvider(period));
    final wallet = ref.watch(walletProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.earningsTitle)),
      body: SafeArea(
        child: Column(
          children: [
            BgDemoBanner(label: l.mockBanner),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  for (final p in [
                    ('today', l.periodToday),
                    ('week', l.periodWeek),
                    ('month', l.periodMonth),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(p.$2),
                        selected: period == p.$1,
                        onSelected: (_) =>
                            ref.read(earningsPeriodProvider.notifier).state = p.$1,
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(earningsProvider);
                  ref.invalidate(walletProvider);
                },
                child: earnings.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => BgEmptyState(
                    title: l.errorGeneric,
                    icon: Icons.error_outline,
                    action: BgButton(
                      label: l.retry,
                      expand: false,
                      onPressed: () => ref.invalidate(earningsProvider),
                    ),
                  ),
                  data: (e) => ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      BgCard(
                        colour: BgColors.dSurface2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l.net, style: BgType.label),
                            Text(Money.format(e.netCents), style: BgType.money),
                            const SizedBox(height: 12),
                            BgKeyValue(l.gross, Money.format(e.grossCents)),
                            BgKeyValue(
                              l.commission,
                              '-${Money.format(e.commissionCents)}',
                              valueColour: BgColors.danger,
                            ),
                            BgKeyValue(l.cashReceivedLabel, Money.format(e.cashCents)),
                            BgKeyValue(l.digitalReceivedLabel, Money.format(e.digitalCents)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: BgStatTile(
                              label: l.trips,
                              value: '${e.trips}',
                              icon: Icons.person_outline,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: BgStatTile(
                              label: l.deliveries,
                              value: '${e.deliveries}',
                              icon: Icons.inventory_2_outlined,
                            ),
                          ),
                        ],
                      ),
                      if (e.byDay.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        BgSectionTitle(l.byDay),
                        BgCard(
                          child: BgBarChart(
                            values: e.byDay.map((d) => d.netCents).toList(),
                            labels: e.byDay
                                .map((d) => DateFormat('E').format(d.date).substring(0, 2))
                                .toList(),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      BgSectionTitle(l.availableBalance),
                      wallet.when(
                        loading: () => const BgCard(child: Text('—')),
                        error: (_, __) => BgCard(child: Text(l.errorGeneric)),
                        data: (w) => BgCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(Money.format(w.balanceCents), style: BgType.h1),
                              const SizedBox(height: 10),
                              BgKeyValue(l.outstandingCommission,
                                  Money.format(w.commissionDueCents)),
                              BgKeyValue(l.cashReceivedLabel,
                                  Money.format(w.cashCollectedCents)),
                              const SizedBox(height: 14),
                              BgButton(
                                label: l.requestPayout,
                                icon: Icons.account_balance_wallet_outlined,
                                onPressed: w.balanceCents <= 0
                                    ? null
                                    : () => context.push('/earnings/payout'),
                              ),
                              const SizedBox(height: 8),
                              BgButton(
                                label: l.payoutHistory,
                                variant: BgButtonVariant.ghost,
                                onPressed: () => context.push('/earnings/payouts'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      BgSectionTitle(l.walletEntries),
                      wallet.maybeWhen(
                        data: (w) => w.entries.isEmpty
                            ? BgCard(child: Text(l.noEarningsHint, style: BgType.caption))
                            : BgCard(
                                padding: EdgeInsets.zero,
                                child: Column(
                                  children: [
                                    for (final entry in w.entries.take(25))
                                      ListTile(
                                        dense: true,
                                        title: Text(
                                          switch (entry.kind) {
                                            'fare' => l.fare,
                                            'commission' => l.commission,
                                            'tip' => l.tip,
                                            'payout' => l.requestPayout,
                                            _ => entry.kind,
                                          },
                                          style: BgType.bodyText,
                                        ),
                                        subtitle: Text(
                                          '${entry.reference ?? ''} · '
                                          '${DateFormat('dd MMM HH:mm').format(entry.at)}',
                                          style: BgType.caption,
                                        ),
                                        trailing: Text(
                                          Money.format(entry.amountCents, showSign: true),
                                          style: BgType.bodyStrong.copyWith(
                                            color: entry.amountCents < 0
                                                ? BgColors.danger
                                                : BgColors.success,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                        orElse: () => const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PayoutRequestScreen extends ConsumerStatefulWidget {
  const PayoutRequestScreen({super.key});
  @override
  ConsumerState<PayoutRequestScreen> createState() => _PayoutRequestScreenState();
}

class _PayoutRequestScreenState extends ConsumerState<PayoutRequestScreen> {
  final _amount = TextEditingController();
  bool _busy = false;
  String? _error;

  static const int minimumCents = 500;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _submit(Wallet wallet) async {
    final l = AppLocalizations.of(context);
    final cents = Money.parse(_amount.text);
    if (cents == null || cents < minimumCents) {
      setState(() => _error = l.payoutMin(Money.format(minimumCents)));
      return;
    }
    if (cents > wallet.balanceCents) {
      setState(() => _error = l.insufficientBalance);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(apiProvider).requestPayout(cents);
      ref.invalidate(walletProvider);
      ref.invalidate(payoutsProvider);
      if (!mounted) return;
      showBgSnack(context, l.payoutRequested);
      context.pop();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final wallet = ref.watch(walletProvider);
    final profile = ref.watch(sessionProvider).profile;

    return Scaffold(
      appBar: AppBar(title: Text(l.requestPayout)),
      body: SafeArea(
        child: wallet.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => BgEmptyState(title: l.errorGeneric, icon: Icons.error_outline),
          data: (w) => ListView(
            padding: const EdgeInsets.all(20),
            children: [
              BgCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.availableBalance, style: BgType.label),
                    Text(Money.format(w.balanceCents), style: BgType.money),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _amount,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: l.payoutAmount,
                  prefixText: r'$ ',
                  helperText: l.payoutMin(Money.format(minimumCents)),
                  errorText: _error,
                ),
              ),
              const SizedBox(height: 16),
              BgCard(
                child: BgKeyValue(
                  l.payoutMethod,
                  switch (profile?.payoutMethod) {
                    'evc_plus' => l.payoutEvcPlus,
                    'zaad' => l.payoutZaad,
                    'sahal' => l.payoutSahal,
                    'cash' => l.payoutCash,
                    _ => '—',
                  },
                ),
              ),
              const SizedBox(height: 24),
              BgButton(label: l.requestPayout, busy: _busy, onPressed: () => _submit(w)),
            ],
          ),
        ),
      ),
    );
  }
}

class PayoutHistoryScreen extends ConsumerWidget {
  const PayoutHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final payouts = ref.watch(payoutsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.payoutHistory)),
      body: SafeArea(
        child: payouts.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => BgEmptyState(title: l.errorGeneric, icon: Icons.error_outline),
          data: (list) => list.isEmpty
              ? BgEmptyState(
                  title: l.noPayouts,
                  icon: Icons.account_balance_wallet_outlined,
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final p = list[i];
                    return BgCard(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(Money.format(p.amountCents), style: BgType.bodyStrong),
                                Text(
                                  DateFormat('dd MMM yyyy · HH:mm').format(p.requestedAt),
                                  style: BgType.caption,
                                ),
                              ],
                            ),
                          ),
                          BgPill(
                            label: switch (p.status) {
                              'approved' => l.payoutStatusApproved,
                              'paid' => l.payoutStatusPaid,
                              'rejected' => l.payoutStatusRejected,
                              'failed' => l.payoutStatusFailed,
                              _ => l.payoutStatusRequested,
                            },
                            colour: switch (p.status) {
                              'paid' => BgColors.success,
                              'rejected' || 'failed' => BgColors.danger,
                              _ => BgColors.dSurface2,
                            },
                            textColour: p.status == 'paid' || p.status == 'rejected'
                                ? BgColors.white
                                : BgColors.dText,
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
