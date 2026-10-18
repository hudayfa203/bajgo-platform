/// Money helpers. All amounts are integer USD cents (API contract).
class Money {
  Money._();

  /// `150` → `$1.50`, `-250` → `-$2.50`, `100000` → `$1,000.00`.
  static String format(int cents, {bool showSign = false}) {
    final negative = cents < 0;
    final abs = cents.abs();
    final dollars = abs ~/ 100;
    final rem = abs % 100;
    final dollarsStr = _groupThousands(dollars);
    final body = '\$$dollarsStr.${rem.toString().padLeft(2, '0')}';
    if (negative) return '-$body';
    if (showSign && cents > 0) return '+$body';
    return body;
  }

  /// Compact form for tiles: `$12.50` → `$12.50`, `$1,250.00` → `$1,250`.
  static String compact(int cents) {
    if (cents.abs() >= 100000 && cents % 100 == 0) {
      final neg = cents < 0 ? '-' : '';
      return '$neg\$${_groupThousands(cents.abs() ~/ 100)}';
    }
    return format(cents);
  }

  static String _groupThousands(int value) {
    final s = value.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final remaining = s.length - i;
      buf.write(s[i]);
      if (remaining > 1 && remaining % 3 == 1) buf.write(',');
    }
    return buf.toString();
  }

  /// Parses user input such as `12`, `12.5`, `$12.50` into cents.
  /// Returns null when the input is not a valid amount.
  static int? parse(String input) {
    final cleaned = input.replaceAll(r'$', '').replaceAll(',', '').trim();
    if (cleaned.isEmpty) return null;
    final match = RegExp(r'^(\d+)(?:\.(\d{1,2}))?$').firstMatch(cleaned);
    if (match == null) return null;
    final dollars = int.parse(match.group(1)!);
    final fracStr = (match.group(2) ?? '0').padRight(2, '0');
    return dollars * 100 + int.parse(fracStr);
  }
}
