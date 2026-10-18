import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../core/theme/bg_colors.dart';
import '../core/theme/bg_theme.dart';
import '../core/utils/phone.dart';
import '../core/widgets.dart';
import '../data/api.dart';
import '../data/models.dart';
import '../data/providers.dart';
import '../l10n/generated/app_localizations.dart';

/// Five-step registration: about you · your Bajaaj · documents · emergency
/// contact · payout. Nothing is sent until the last step.
class RegistrationScreen extends ConsumerStatefulWidget {
  const RegistrationScreen({super.key});
  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  static const _total = 5;
  int _step = 0;
  bool _busy = false;

  final _name = TextEditingController();
  final _plate = TextEditingController();
  final _model = TextEditingController(text: 'Bajaj RE');
  final _colour = TextEditingController();
  final _year = TextEditingController();
  final _emName = TextEditingController();
  final _emPhone = TextEditingController();
  final _payoutAccount = TextEditingController();
  String _payoutMethod = 'evc_plus';
  final _docs = <String, String>{}; // type → local file path
  String? _photoPath;

  @override
  void dispose() {
    for (final c in [_name, _plate, _model, _colour, _year, _emName, _emPhone, _payoutAccount]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _canContinue => switch (_step) {
        0 => _name.text.trim().length >= 3,
        1 => _plate.text.trim().isNotEmpty,
        2 => true, // documents can be added later; status shows as missing
        3 => true,
        _ => true,
      };

  Future<void> _pick(String docType) async {
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (file == null) return;
      setState(() {
        if (docType == 'photo') {
          _photoPath = file.path;
        } else {
          _docs[docType] = file.path;
        }
      });
    } catch (_) {
      if (mounted) {
        showBgSnack(context, AppLocalizations.of(context).errorGeneric, error: true);
      }
    }
  }

  Future<void> _submit() async {
    final l = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      final session = ref.read(sessionProvider.notifier);
      await session.register(
        fullName: _name.text.trim(),
        vehicle: Vehicle(
          plateNumber: _plate.text.trim().toUpperCase(),
          makeModel: _model.text.trim().isEmpty ? 'Bajaj RE' : _model.text.trim(),
          colour: _colour.text.trim().isEmpty ? null : _colour.text.trim(),
          year: int.tryParse(_year.text.trim()),
        ),
        emergencyName: _emName.text.trim().isEmpty ? null : _emName.text.trim(),
        emergencyPhone: SomaliPhone.normalize(_emPhone.text),
        payoutMethod: _payoutMethod,
        payoutAccount: _payoutAccount.text.trim().isEmpty ? null : _payoutAccount.text.trim(),
      );
      for (final entry in _docs.entries) {
        await session.uploadDocument(entry.key, entry.value);
      }
      if (!mounted) return;
      context.go('/');
    } on ApiException catch (e) {
      if (mounted) showBgSnack(context, e.message, error: true);
    } catch (_) {
      if (mounted) showBgSnack(context, l.errorGeneric, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final titles = [
      l.regStepPersonal,
      l.regStepVehicle,
      l.regStepDocuments,
      l.regStepEmergency,
      l.regStepPayout,
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(l.regTitle),
        leading: _step == 0
            ? null
            : BackButton(onPressed: () => setState(() => _step = _step - 1)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            BgDemoBanner(label: l.mockBanner),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(titles[_step], style: BgType.h2)),
                      Text(l.regStepOf(_step + 1, _total), style: BgType.caption),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: (_step + 1) / _total,
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: switch (_step) {
                  0 => _personal(l),
                  1 => _vehicle(l),
                  2 => _documents(l),
                  3 => _emergency(l),
                  _ => _payout(l),
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: BgButton(
                label: _step == _total - 1 ? l.submitRegistration : l.next,
                busy: _busy,
                onPressed: _canContinue
                    ? () {
                        if (_step == _total - 1) {
                          _submit();
                        } else {
                          setState(() => _step = _step + 1);
                        }
                      }
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _personal(AppLocalizations l) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: GestureDetector(
              onTap: () => _pick('photo'),
              child: Container(
                height: 104,
                width: 104,
                decoration: const BoxDecoration(
                  color: BgColors.dSurface,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _photoPath == null ? Icons.add_a_photo_outlined : Icons.check_circle_outline,
                  color: _photoPath == null ? BgColors.dText2 : BgColors.success,
                  size: 32,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              _photoPath == null ? l.addPhoto : l.retakePhoto,
              style: BgType.caption,
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(labelText: l.fullName),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          BgCard(
            child: BgKeyValue(l.phone, SomaliPhone.format(ref.read(sessionProvider).phone ?? '')),
          ),
        ],
      );

  Widget _vehicle(AppLocalizations l) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _plate,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(labelText: l.plateNumber),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _model,
            decoration: InputDecoration(labelText: l.makeModel),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _colour,
                  decoration: InputDecoration(labelText: l.colour),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _year,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: l.year),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          BgSectionTitle(l.vehiclePhotos),
          Row(
            children: [
              Expanded(child: _photoSlot(l.photoFront, 'vehicle_front')),
              const SizedBox(width: 10),
              Expanded(child: _photoSlot(l.photoSide, 'vehicle_side')),
              const SizedBox(width: 10),
              Expanded(child: _photoSlot(l.photoRear, 'vehicle_rear')),
            ],
          ),
        ],
      );

  Widget _photoSlot(String label, String type) => BgCard(
        onTap: () => _pick(type),
        padding: const EdgeInsets.symmetric(vertical: 18),
        border: _docs.containsKey(type) ? BgColors.success : null,
        child: Column(
          children: [
            Icon(
              _docs.containsKey(type) ? Icons.check : Icons.photo_camera_outlined,
              color: _docs.containsKey(type) ? BgColors.success : BgColors.dText2,
            ),
            const SizedBox(height: 6),
            Text(label, style: BgType.caption, textAlign: TextAlign.center),
          ],
        ),
      );

  Widget _documents(AppLocalizations l) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.docsRequiredHint, style: BgType.bodyText.copyWith(color: BgColors.dText2)),
          const SizedBox(height: 20),
          _docRow(l.docNationalId, 'national_id', l),
          _docRow(l.docDrivingLicence, 'driving_licence', l),
          _docRow(l.docVehicleRegistration, 'vehicle_registration', l),
          _docRow(l.docInsurance, 'insurance', l),
        ],
      );

  Widget _docRow(String label, String type, AppLocalizations l) {
    final has = _docs.containsKey(type);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: BgCard(
        onTap: () => _pick(type),
        child: Row(
          children: [
            Icon(
              has ? Icons.verified_outlined : Icons.description_outlined,
              color: has ? BgColors.success : BgColors.dText2,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: BgType.bodyStrong),
                  Text(has ? l.docStatusPending : l.docStatusMissing, style: BgType.caption),
                ],
              ),
            ),
            Text(
              has ? l.docReupload : l.docUpload,
              style: BgType.label.copyWith(color: BgColors.saffron),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emergency(AppLocalizations l) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _emName,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(labelText: l.emergencyName),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _emPhone,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: l.emergencyPhone,
              prefixText: '${SomaliPhone.countryCode} ',
            ),
          ),
        ],
      );

  Widget _payout(AppLocalizations l) {
    final methods = {
      'evc_plus': l.payoutEvcPlus,
      'zaad': l.payoutZaad,
      'sahal': l.payoutSahal,
      'cash': l.payoutCash,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BgSectionTitle(l.payoutMethod),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: methods.entries
              .map((e) => ChoiceChip(
                    label: Text(e.value),
                    selected: _payoutMethod == e.key,
                    onSelected: (_) => setState(() => _payoutMethod = e.key),
                  ))
              .toList(),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _payoutAccount,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(labelText: l.payoutAccount),
        ),
      ],
    );
  }
}

/// Shown while the account is pending, under review, rejected or suspended.
class VerificationScreen extends ConsumerWidget {
  const VerificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final profile = ref.watch(sessionProvider).profile;
    final status = profile?.verification ?? VerificationStatus.pending;

    final (icon, colour, body) = switch (status) {
      VerificationStatus.underReview =>
        (Icons.hourglass_top_outlined, BgColors.saffron, l.verificationUnderReview),
      VerificationStatus.rejected =>
        (Icons.cancel_outlined, BgColors.danger, l.verificationRejected),
      VerificationStatus.suspended =>
        (Icons.block_outlined, BgColors.danger, l.verificationSuspended),
      _ => (Icons.schedule_outlined, BgColors.dBlue, l.verificationPending),
    };

    final statusLabel = switch (status) {
      VerificationStatus.underReview => l.statusUnderReview,
      VerificationStatus.approved => l.statusApproved,
      VerificationStatus.rejected => l.statusRejected,
      VerificationStatus.suspended => l.statusSuspended,
      VerificationStatus.pending => l.statusPending,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(l.verificationTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l.refreshStatus,
            onPressed: () => ref.read(sessionProvider.notifier).refresh(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            BgDemoBanner(label: l.mockBanner),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    Center(
                      child: Container(
                        height: 96,
                        width: 96,
                        decoration: BoxDecoration(
                          color: colour.withAlpha(36),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, size: 40, color: colour),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(child: BgPill(label: statusLabel, colour: colour, textColour: BgColors.night)),
                    const SizedBox(height: 16),
                    Text(body, style: BgType.bodyText, textAlign: TextAlign.center),
                    if (profile?.verificationReason != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        l.verificationReason(profile!.verificationReason!),
                        style: BgType.caption,
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 28),
                    BgCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          BgSectionTitle(l.documents),
                          for (final d in profile?.documents ?? const <DriverDocument>[])
                            BgKeyValue(
                              _docLabel(d.type, l),
                              switch (d.status) {
                                DocStatus.approved => l.docStatusApproved,
                                DocStatus.rejected => l.docStatusRejected,
                                DocStatus.expired => l.docStatusExpired,
                                DocStatus.pending => l.docStatusPending,
                                DocStatus.missing => l.docStatusMissing,
                              },
                              valueColour: d.status == DocStatus.approved
                                  ? BgColors.success
                                  : d.status == DocStatus.rejected
                                      ? BgColors.danger
                                      : null,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (status == VerificationStatus.rejected)
                      BgButton(
                        label: l.reuploadDocuments,
                        onPressed: () => context.push('/account/documents'),
                      ),
                    const SizedBox(height: 12),
                    BgButton(
                      label: l.contactSupport,
                      variant: BgButtonVariant.ghost,
                      onPressed: () => context.push('/account/support'),
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

  static String _docLabel(String type, AppLocalizations l) => switch (type) {
        'national_id' => l.docNationalId,
        'driving_licence' => l.docDrivingLicence,
        'vehicle_registration' => l.docVehicleRegistration,
        'insurance' => l.docInsurance,
        _ => type,
      };
}
