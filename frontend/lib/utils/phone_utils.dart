/// Ramène un numéro saisi au format +221XXXXXXXXX
/// (mêmes règles que le backend : espaces, points et tirets ignorés).
String normalizePhone(String input) {
  final p = input.replaceAll(RegExp(r'[^\d+]'), '');

  if (p.startsWith('+')) return '+${p.substring(1).replaceAll('+', '')}';
  if (p.startsWith('00221')) return '+${p.substring(2)}';
  if (RegExp(r'^221\d{9}$').hasMatch(p)) return '+$p';
  if (RegExp(r'^\d{9}$').hasMatch(p)) return '+221$p';
  return p;
}

bool isValidPhone(String input) =>
    RegExp(r'^\+221\d{9}$').hasMatch(normalizePhone(input));
