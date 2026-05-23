abstract final class CurrencyFormatter {
  static String clp(num amount) {
    final int roundedAmount = amount.round();
    final String sign = roundedAmount < 0 ? '-' : '';
    final String digits = roundedAmount.abs().toString();
    final String grouped = digits.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
    return '$sign\$ $grouped';
  }

  static String clpSemantics(num amount) {
    final int roundedAmount = amount.round();
    final String sign = roundedAmount < 0 ? 'menos ' : '';
    final String digits = roundedAmount.abs().toString();
    final String grouped = digits.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
    return '$sign$grouped pesos chilenos';
  }
}
