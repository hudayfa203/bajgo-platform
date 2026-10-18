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

/// A centred, width-capped page body. Everything in the auth flow uses it so
/// the layout is correct on a narrow Samsung phone and on a tablet alike.
class _AuthBody extends StatelessWidget {
  const _AuthBody({required this.children, this.banner});
  final List<Widget> children;
  final Widget? banner;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          if (banner != null) banner!,
          Expanded(
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(BgSpace.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: children,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The brand lockup, in the variant that is readable on the current background.
class _AuthLogo extends StatelessWidget {
  const _AuthLogo({this.height = 34});
  final double height;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: SvgPicture.asset(
          Theme.of(context).brightness == Brightness.dark
              ? 'assets/brand/BajGo_Logo_Horizontal_White.svg'
              : 'assets/brand/BajGo_Logo_Horizontal_FullColour.svg',
          height: height,
        ),
      );
}

/// Phone number entry. The +252 prefix is part of the field decoration rather
/// than a separate box, so there is no row that can overflow a narrow screen.
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
    FocusScope.of(context).unfocus();
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

    return _AuthBody(
      banner: BgDemoBanner(message: l.mockModeBanner),
      children: [
        const SizedBox(height: BgSpace.lg),
        const _AuthLogo(),
        const SizedBox(height: BgSpace.xl),
        Text(l.phoneTitle, style: t.textTheme.headlineLarge),
        const SizedBox(height: BgSpace.sm),
        Text(l.phoneHelp, style: t.textTheme.bodyMedium),
        const SizedBox(height: BgSpace.lg),
        TextField(
          controller: _controller,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.done,
          style: t.textTheme.titleLarge,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(9),
          ],
          decoration: InputDecoration(
            prefixText: '${Env.countryCode} ',
            prefixStyle: t.textTheme.titleLarge?.copyWith(color: t.colorScheme.primary),
            hintText: l.phoneHint,
            errorText: _error,
          ),
          onChanged: (_) => setState(() => _error = null),
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: BgSpace.lg),
        BgButton(label: l.continueLabel, loading: _busy, onPressed: _valid ? _submit : null),
        const SizedBox(height: BgSpace.md),
        Text(l.termsNotice, style: t.textTheme.labelSmall, textAlign: TextAlign.center),
        if (Env.demo) ...[
          const SizedBox(height: BgSpace.lg),
          BgCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.science_outlined, size: 18, color: BgColors.slate),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${l.demoAccount}: 90 000 0001\n${l.otpDevCode(Env.demoOtp)}',
                    style: t.textTheme.labelMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: BgSpace.lg),
      ],
    );
  }
}

/// OTP entry: one real text field, styled large and spaced. A single field is
/// what every keyboard and SMS autofill expects, and it cannot overflow.
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
    super.dispose();
  }

  Future<void> _verify() async {
    final l = AppLocalizations.of(context);
    if (_controller.text.length < _length || _busy) return;
    FocusScope.of(context).unfocus();
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
    try {
      final res = await ref.read(sessionProvider.notifier).requestOtp(widget.phone);
      if (!mounted) return;
      _startCountdown(res.resendAfter);
      showBgSnack(context, AppLocalizations.of(context).otpSent(widget.phone));
    } catch (_) {
      if (mounted) showBgSnack(context, AppLocalizations.of(context).errorNetwork);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context);
    final ready = _controller.text.length == _length;

    return _AuthBody(
      banner: BgDemoBanner(message: l.mockModeBanner),
      children: [
        const SizedBox(height: BgSpace.md),
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.canPop() ? context.pop() : context.go('/phone'),
          ),
        ),
        Text(l.otpTitle, style: t.textTheme.headlineLarge),
        const SizedBox(height: BgSpace.sm),
        Text(l.otpSent(widget.phone), style: t.textTheme.bodyMedium),
        const SizedBox(height: BgSpace.xl),
        TextField(
          controller: _controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: _length,
          autofillHints: const [AutofillHints.oneTimeCode],
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: t.textTheme.displayLarge?.copyWith(letterSpacing: 12),
          decoration: InputDecoration(
            counterText: '',
            hintText: '······',
            errorText: _error,
            contentPadding: const EdgeInsets.symmetric(vertical: 18),
          ),
          onChanged: (v) {
            setState(() => _error = null);
            if (v.length == _length) _verify();
          },
        ),
        const SizedBox(height: BgSpace.lg),
        BgButton(label: l.confirm, loading: _busy, onPressed: ready ? _verify : null),
        const SizedBox(height: BgSpace.md),
        Center(
          child: _seconds > 0
              ? Text(l.otpResendIn(_seconds), style: t.textTheme.labelMedium)
              : TextButton(onPressed: _resend, child: Text(l.otpResend)),
        ),
        if (widget.devCode != null)
          Center(
            child: Text(
              l.otpDevCode(widget.devCode!),
              style: t.textTheme.labelMedium?.copyWith(color: t.colorScheme.primary),
            ),
          ),
        const SizedBox(height: BgSpace.lg),
      ],
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

    return _AuthBody(
      banner: BgDemoBanner(message: l.mockModeBanner),
      children: [
        const SizedBox(height: BgSpace.xl),
        const _AuthLogo(),
        const SizedBox(height: BgSpace.xl),
        Text(l.nameTitle, style: t.textTheme.headlineLarge),
        const SizedBox(height: BgSpace.sm),
        Text(l.nameHelp, style: t.textTheme.bodyMedium),
        const SizedBox(height: BgSpace.lg),
        TextField(
          controller: _controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          style: t.textTheme.titleLarge,
          decoration: InputDecoration(hintText: l.nameHint),
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: BgSpace.lg),
        BgButton(label: l.continueLabel, loading: _busy, onPressed: _valid ? _submit : null),
        const SizedBox(height: BgSpace.lg),
      ],
    );
  }
}
