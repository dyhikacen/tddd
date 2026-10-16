/// Helper lightweight untuk memformat dan mem-parsing mata uang Rupiah
/// tanpa memerlukan library eksternal yang berat.
class CurrencyHelper {
  CurrencyHelper._();

  /// Memformat angka integer ke dalam format Rupiah, contoh: `Rp 150.000` atau `-Rp 50.000`
  static String format(int amount) {
    final isNegative = amount < 0;
    final absString = amount.abs().toString();
    final buffer = StringBuffer();
    final length = absString.length;

    for (int i = 0; i < length; i++) {
      if (i > 0 && (length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(absString[i]);
    }

    final formatted = buffer.toString();
    return isNegative ? '-Rp $formatted' : 'Rp $formatted';
  }

  /// Memformat angka tanpa prefiks "Rp", contoh: `150.000`
  static String formatWithoutPrefix(int amount) {
    final isNegative = amount < 0;
    final absString = amount.abs().toString();
    final buffer = StringBuffer();
    final length = absString.length;

    for (int i = 0; i < length; i++) {
      if (i > 0 && (length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(absString[i]);
    }

    final formatted = buffer.toString();
    return isNegative ? '-$formatted' : formatted;
  }

  /// Mem-parsing input string dari pengguna (misal "150.000", "Rp 150.000", "150000") menjadi int
  static int? parse(String? input) {
    if (input == null || input.trim().isEmpty) return null;
    final cleaned = input
        .replaceAll('Rp', '')
        .replaceAll('rp', '')
        .replaceAll('.', '')
        .replaceAll(',', '')
        .replaceAll(' ', '')
        .trim();
    return int.tryParse(cleaned);
  }
}
