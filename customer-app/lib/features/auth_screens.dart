import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../core/env.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../data/api.dart';
import '../data/providers.dart';
import '../l10n/generated/app_localizations.dart';

/// Three-slide introduction shown once on first launch.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await ref.read(sessionProvider.notifier).setOnboarded();
    if (mounted) context.go('/phone');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final slides = [
      (l.onboarding1Title, l.onboarding1Body),
      (l.onboarding2Title, l.onboarding2Body),
      (l.onboarding3Title, l.onboarding3Body),
    ];
    return Scaffold(
      backgroundColor: BgColors.blue,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(BgSpace.md),
              child: Row(
                children: [
                  SvgPicture.asset('assets/brand/BajGo_Logo_Horizontal_White.svg', height: 28),
                  const Spacer(),
                  TextButton(
                    onPressed: _finish,
                    child: Text(l.skip,
                        style: const TextStyle(color: BgColors.white, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: BgSpace.lg),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SvgPicture.asset('assets/brand/BajGo_Symbol_White.svg', height: 120),
                      const SizedBox(height: BgSpace.xl),
                      Text(slides[i].$1,
                          style: const TextStyle(
                              fontFamily: BgTheme.display,
                              fontSize: 32,
                              height: 1.15,
                              fontWeight: FontWeight.w800,
                              color: BgColors.white)),
                      const SizedBox(height: BgSpace.md),
                      Text(slides[i].$2,
                          style: const TextStyle(
                              fontFamily: BgTheme.body,
                              fontSize: 17,
                              height: 1.5,
                              color: BgColors.sky)),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(BgSpace.lg),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      slides.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: i == _page ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == _page ? BgColors.saffron : const Color(0x66FFFFFF),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: BgSpace.lg),
                  BgButton(
                    label: _page == slides.length - 1 ? l.getStarted : l.next,
                    variant: BgButtonVariant.saffron,
                    onPressed: () {
                      if (_page == slides.length - 1) {
                        _finish();
                      } else {
                        _controller.nextPage(
                            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Phone number entry. The +252 prefix is fixed; the person types 9 local digits.
class PhoneScreen extends ConsumerStatefulWidget {
  const PhoneScreen({super.key});

  @override
  ConsumerState<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends ConsumerState<PhoneScreen> {
  final _controller = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _digits => _controller.text.replaceAll(RegExp(r'\D'), '');
  bool get _valid => _digits.length >= 7 && _digits.length <= 9;

  Future<void> _submit() async {
    final l = AppLocalizations.of(context);
    if (!_valid) {
      setState(() => _error = l.phoneInvalid);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final phone = '${Env.countryCode}$_digits';
    try {
      final res = await ref.read(sessionProvider.notifier).requestOtp(phone);
      if (!mounted) return;
      context.push('/otp', extra: {'phone': phone, 'resend': res.resendAfter, 'dev': res.devCode});
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
    final t = Theme.of(context);
    return Scaffold(
      body: Column(
        children: [
          BgDemoBanner(message: l.mockModeBanner),
          Expanded(
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(BgSpace.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: BgSpace.lg),
                    SvgPicture.asset(
                      t.brightness == Brightness.dark
                          ? 'assets/brand/BajGo_Logo_Horizontal_White.svg'
                          : 'assets/brand/BajGo_Logo_Horizontal_FullColour.svg',
                      height: 34,
                    ),
                    const SizedBox(height: BgSpace.xl),
                    Text(l.phoneTitle, style: t.textTheme.headlineLarge),
                    const SizedBox(height: BgSpace.sm),
                    Text(l.phoneHelp, style: t.textTheme.bodyMedium),
                    const SizedBox(height: BgSpace.lg),
                    Row(
                      children: [
                        Container(
                          height: 56,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: t.colorScheme.surface,
                            borderRadius: BorderRadius.circular(BgSpace.rInput),
                            border: Border.all(color: t.dividerColor),
                          ),
                          child: Center(
                            child: Text(Env.countryCode, style: t.textTheme.titleMedium),
                          ),
                        ),
                        const SizedBox(width: BgSpace.sm),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            keyboardType: TextInputType.phone,
                            style: t.textTheme.titleLarge,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(9),
                            ],
                            decoration: InputDecoration(hintText: l.phoneHint),
                            onChanged: (_) => setState(() => _error = null),
                            onSubmitted: (_) => _submit(),
                          ),
                        ),
                      ],
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: BgSpace.sm),
                      Text(_error!, style: t.textTheme.bodyMedium?.copyWith(color: BgColors.danger)),
                    ],
                    const SizedBox(height: BgSpace.lg),
                    BgButton(label: l.continueLabel, loading: _busy, onPressed: _valid ? _submit : null),
                    const SizedBox(height: BgSpace.md),
                    Text(l.termsNotice, style: t.textTheme.labelSmall),
                    if (Env.demo) ...[
                      const SizedBox(height: BgSpace.lg),
                      BgCard(
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, size: 18, color: BgColors.slate),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text('${l.demoAccount}: 90 000 0001  ·  ${l.otpDevCode(Env.demoOtp)}',
                                  style: t.textTheme.labelMedium),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Six-box OTP entry with a resend countdown.
class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key, required this.phone, this.resendAfter = 45, this.devCode});

  final String phone;
  final int resendAfter;
  final String? devCode;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  Timer? _timer;
  int _seconds = 0;
  bool _busy = false;
  String? _error;

  static const _length = 6;

  @override
  void initState() {
    super.initState();
    _startCountdown(widget.resendAfter);
    if (widget.devCode != null) _controller.text = widget.devCode!;
  }

  void _startCountdown(int from) {
    _timer?.cancel();
    setState(() => _seconds = from);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_seconds <= 1) {
        t.cancel();
        setState(() => _seconds = 0);
      } else {
        setState(() => _seconds--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final l = AppLocalizations.of(context);
    if (_controller.text.length < _length) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final needsName =
          await ref.read(sessionProvider.notifier).verifyOtp(widget.phone, _controller.text);
      if (!mounted) return;
      context.go(needsName ? '/name' : '/home');
    } on ApiException {
      if (mounted) setState(() => _error = l.otpInvalid);
    } catch (_) {
      if (mounted) setState(() => _error = l.errorNetwork);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend() async {
    final res = await ref.read(sessionProvider.notifier).requestOtp(widget.phone);
    if (!mounted) return;
    _startCountdown(res.resendAfter);
    showBgSnack(context, AppLocalizations.of(context).otpSent(widget.phone));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(leading: BackButton(onPressed: () => context.pop())),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(BgSpace.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.otpTitle, style: t.textTheme.headlineLarge),
              const SizedBox(height: BgSpace.sm),
              Text(l.otpSent(widget.phone), style: t.textTheme.bodyMedium),
              const SizedBox(height: BgSpace.xl),
              // A single hidden field drives six visible boxes: reliable with
              // every keyboard and with SMS autofill.
              Stack(
                children: [
                  Opacity(
                    opacity: 0,
                    child: TextField(
                      controller: _controller,
                      focusNode: _focus,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      maxLength: _length,
                      decoration: const InputDecoration(
                        counterText: '',
                        border: InputBorder.none,
                      ),
                      autofillHints: const [AutofillHints.oneTimeCode],
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (v) {
                        setState(() => _error = null);
                        if (v.length == _length) _verify();
                      },
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _focus.requestFocus(),
                    // Flexible boxes: six fixed 48 px boxes plus padding do not
                    // fit on a 360 dp screen, which overflowed the row.
                    child: Row(
                      children: List.generate(_length, (i) {
                        final filled = i < _controller.text.length;
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: i == _length - 1 ? 0 : BgSpace.sm,
                            ),
                            child: Container(
                              height: 60,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: t.colorScheme.surface,
                                borderRadius: BorderRadius.circular(BgSpace.rInput),
                                border: Border.all(
                                  color: filled ? BgColors.blue : t.dividerColor,
                                  width: filled ? 2 : 1,
                                ),
                              ),
                              child: Text(
                                filled ? _controller.text[i] : '',
                                style: t.textTheme.headlineMedium,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: BgSpace.md),
                Text(_error!, style: t.textTheme.bodyMedium?.copyWith(color: BgColors.danger)),
              ],
              const SizedBox(height: BgSpace.lg),
              BgButton(
                label: l.confirm,
                loading: _busy,
                onPressed: _controller.text.length == _length ? _verify : null,
              ),
              const SizedBox(height: BgSpace.md),
              Center(
                child: _seconds > 0
                    ? Text(l.otpResendIn(_seconds), style: t.textTheme.labelMedium)
                    : TextButton(onPressed: _resend, child: Text(l.otpResend)),
              ),
              if (widget.devCode != null)
                Center(
                  child: Text(l.otpDevCode(widget.devCode!),
                      style: t.textTheme.labelMedium?.copyWith(color: BgColors.blue)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Name capture — only shown the first time a phone number signs in.
class NameScreen extends ConsumerStatefulWidget {
  const NameScreen({super.key});

  @override
  ConsumerState<NameScreen> createState() => _NameScreenState();
}

class _NameScreenState extends ConsumerState<NameScreen> {
  final _controller = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _valid => _controller.text.trim().length >= 2;

  Future<void> _submit() async {
    if (!_valid) return;
    setState(() => _busy = true);
    try {
      await ref.read(sessionProvider.notifier).setName(_controller.text.trim());
      if (mounted) context.go('/home');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(BgSpace.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: BgSpace.xl),
              Text(l.nameTitle, style: t.textTheme.headlineLarge),
              const SizedBox(height: BgSpace.sm),
              Text(l.nameHelp, style: t.textTheme.bodyMedium),
              const SizedBox(height: BgSpace.lg),
              TextField(
                controller: _controller,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(hintText: l.nameHint),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: BgSpace.lg),
              BgButton(label: l.continueLabel, loading: _busy, onPressed: _valid ? _submit : null),
            ],
          ),
        ),
      ),
    );
  }
}
