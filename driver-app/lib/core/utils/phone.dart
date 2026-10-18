/// Somali phone number helpers. The platform identifies drivers by phone in
/// E.164 form: `+252` followed by the 9-digit national number (e.g.
/// `+252905000103`). Leading `0`, spaces, dashes and a `00252` / `252` prefix
/// are tolerated on input.
class SomaliPhone {
  SomaliPhone._();

  static const String countryCode = '+252';

  /// Returns the E.164 number or null when the input is not a valid Somali
  /// mobile number.
  static String? normalize(String input) {
    var digits = input.replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.startsWith('+')) digits = digits.substring(1);
    if (digits.startsWith('00252')) {
      digits = digits.substring(5);
    } else if (digits.startsWith('252')) {
      digits = digits.substring(3);
    }
    if (digits.startsWith('0')) digits = digits.substring(1);
    // Somali mobile numbers: 9 digits, first digit 6, 7 or 9 (e.g. 90 679 8858).
    // Accept 8-digit legacy numbers too.
    if (!RegExp(r'^[679]\d{7,8}$').hasMatch(digits)) return null;
    return '$countryCode$digits';
  }

  static bool isValid(String input) => normalize(input) != null;

  /// `+252905000103` → `+252 90 500 0103`.
  static String format(String e164) {
    final normalized = normalize(e164) ?? e164;
    if (!normalized.startsWith(countryCode)) return e164;
    final national = normalized.substring(countryCode.length);
    if (national.length == 9) {
      return '$countryCode ${national.substring(0, 2)} '
          '${national.substring(2, 5)} ${national.substring(5)}';
    }
    if (national.length == 8) {
      return '$countryCode ${national.substring(0, 2)} '
          '${national.substring(2, 5)} ${national.substring(5)}';
    }
    return normalized;
  }

  /// Masks for display on shared screens: `+252 90 *** *103`.
  static String masked(String e164) {
    final normalized = normalize(e164);
    if (normalized == null) return e164;
    final national = normalized.substring(countryCode.length);
    final tail = national.substring(national.length - 3);
    return '$countryCode ${national.substring(0, 2)} *** *$tail';
  }
}
