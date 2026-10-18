import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/env.dart';
import '../core/theme/bg_colors.dart';
import '../core/theme/bg_theme.dart';
import '../core/utils/phone.dart';
import '../core/widgets.dart';
import '../data/api.dart';
import '../data/providers.dart';
import '../l10n/generated/app_localizations.dart';

class PhoneScreen extends ConsumerStatefulWidget {
  const PhoneScreen({super.key});
  @override
  ConsumerState<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends ConsumerState<PhoneScreen> {
  final _ctrl = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l = AppLocalizations.of(context);
    final e164 = SomaliPhone.normalize(_ctrl.text);
    if (e164 == null) {
      setState(() => _error = l.phoneInvalid);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final req = await ref.read(sessionProvider.notifier).requestOtp(e164);
      if (!mounted) return;
      context.go('/otp', extra: req);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = l.errorNetwork);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            BgDemoBanner(label: l.mockBanner),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    const Align(alignment: Alignment.centerLeft, child: BgLogo(height: 40)),
                    const SizedBox(height: 40),
                    Text(l.phoneTitle, style: BgType.display),
                    const SizedBox(height: 8),
                    Text(l.phoneSubtitle, style: BgType.bodyText.copyWith(color: BgColors.dText2)),
                    const SizedBox(height: 28),
                    TextField(
                      controller: _ctrl,
                      keyboardType: TextInputType.phone,
                      style: BgType.bodyStrong,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
                        LengthLimitingTextInputFormatter(18),
                      ],
                      decoration: InputDecoration(
                        labelText: l.phoneLabel,
                        prefixText: '${SomaliPhone.countryCode} ',
                        prefixStyle: BgType.bodyStrong.copyWith(color: BgColors.dText2),
                        hintText: '90 000 0000',
                        errorText: _error,
                      ),
                      onSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: 24),
                    BgButton(
                      label: l.sendCode,
                      busy: _busy,
                      onPressed: _submit,
                      icon: Icons.arrow_forward,
                    ),
                    if (Env.useMock) ...[
                      const SizedBox(height: 24),
                      BgCard(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.science_outlined,
                                size: 18, color: BgColors.dText2),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '90 000 0103\n${l.devCodeHint(Env.demoOtp)}',
                                style: BgType.caption,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
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

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key, this.request});
  final OtpRequest? request;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _ctrl = TextEditingController();
  Timer? _timer;
  int _left = 0;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startCountdown(widget.request?.resendAfter ?? 30);
  }

  void _startCountdown(int seconds) {
    _timer?.cancel();
    setState(() => _left = seconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _left = _left - 1);
      if (_left <= 0) t.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final l = AppLocalizations.of(context);
    if (_ctrl.text.trim().length < 4) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final registered = await ref.read(sessionProvider.notifier).verifyOtp(_ctrl.text.trim());
      if (!mounted) return;
      context.go(registered ? '/' : '/register');
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.code == 'INVALID_OTP' ? l.otpInvalid : e.message);
    } catch (_) {
      if (mounted) setState(() => _error = l.errorNetwork);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend() async {
    final phone = ref.read(sessionProvider).phone;
    if (phone == null) return;
    try {
      final r = await ref.read(sessionProvider.notifier).requestOtp(phone);
      _startCountdown(r.resendAfter);
    } catch (_) {
      if (mounted) showBgSnack(context, AppLocalizations.of(context).errorNetwork, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final phone = ref.watch(sessionProvider).phone ?? '';
    final devCode = widget.request?.devCode;

    return Scaffold(
      appBar: AppBar(leading: BackButton(onPressed: () => context.go('/phone'))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.otpTitle, style: BgType.display),
              const SizedBox(height: 8),
              Text(
                l.otpSubtitle(SomaliPhone.format(phone)),
                style: BgType.bodyText.copyWith(color: BgColors.dText2),
              ),
              if (devCode != null) ...[
                const SizedBox(height: 16),
                BgPill(
                  label: l.devCodeHint(devCode),
                  colour: BgColors.saffron,
                  textColour: BgColors.night,
                  icon: Icons.vpn_key_outlined,
                ),
              ],
              const SizedBox(height: 28),
              TextField(
                controller: _ctrl,
                keyboardType: TextInputType.number,
                autofocus: true,
                textAlign: TextAlign.center,
                maxLength: 6,
                style: BgType.h1.copyWith(letterSpacing: 10),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(counterText: '', errorText: _error),
                onChanged: (v) {
                  if (v.length == 6) _verify();
                },
              ),
              const SizedBox(height: 20),
              BgButton(label: l.verify, busy: _busy, onPressed: _verify),
              const SizedBox(height: 12),
              Center(
                child: _left > 0
                    ? Text(l.otpResendIn(_left), style: BgType.caption)
                    : TextButton(
                        onPressed: _resend,
                        child: Text(
                          l.otpResend,
                          style: BgType.label.copyWith(color: BgColors.saffron),
                        ),
                      ),
              ),
              const SizedBox(height: 24),
              Center(child: Text(l.envBadge(Env.appEnv), style: BgType.caption)),
            ],
          ),
        ),
      ),
    );
  }
}
