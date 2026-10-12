class ReceiptDraft {
  const ReceiptDraft(this.merchant, this.amount, this.date, this.warnings);
  final String? merchant;
  final int? amount;
  final DateTime? date;
  final List<String> warnings;
}

class ReceiptParser {
  static String normalize(String value) {
    var result = value.toLowerCase();
    const groups = [
      'àáạảãâầấậẩẫăằắặẳẵ',
      'èéẹẻẽêềếệểễ',
      'ìíịỉĩ',
      'òóọỏõôồốộổỗơờớợởỡ',
      'ùúụủũưừứựửữ',
      'ỳýỵỷỹ',
      'đ',
    ];
    const replacements = ['a', 'e', 'i', 'o', 'u', 'y', 'd'];
    for (var i = 0; i < groups.length; i++) {
      for (final rune in groups[i].runes) {
        result = result.replaceAll(String.fromCharCode(rune), replacements[i]);
      }
    }
    return result;
  }

  static int? parseAmount(String value) {
    final cleaned = normalize(
      value,
    ).replaceAll(RegExp(r'(vnd|dong|₫|d)$'), '').trim();
    if (!RegExp(r'^(\d{1,3}([., ]\d{3})+|\d+)$').hasMatch(cleaned)) return null;
    final amount = int.tryParse(cleaned.replaceAll(RegExp(r'[., ]'), ''));
    return amount != null && amount > 0 && amount <= 1000000000000
        ? amount
        : null;
  }

  static ReceiptDraft parse(String text) {
    final lines = text
        .split(RegExp(r'[\r\n]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    DateTime? date;
    for (final match in RegExp(
      r'\b(\d{1,2})[/-](\d{1,2})[/-](\d{4})\b',
    ).allMatches(text)) {
      final d = int.parse(match[1]!);
      final m = int.parse(match[2]!);
      final y = int.parse(match[3]!);
      final candidate = DateTime(y, m, d);
      if (y >= 2000 &&
          y <= 2100 &&
          candidate.day == d &&
          candidate.month == m &&
          candidate.year == y) {
        date = candidate;
        break;
      }
    }
    String? merchant;
    for (final line in lines.take(5)) {
      final n = normalize(line);
      if (RegExp(r'[a-z]').hasMatch(n) &&
          !RegExp(
            r'hoa don|invoice|ngay|date|dia chi|address|tel|mst|tax|^\d',
          ).hasMatch(n)) {
        merchant = line;
        break;
      }
    }
    var bestRank = 0;
    final totals = <int>{};
    for (var i = 0; i < lines.length; i++) {
      final n = normalize(lines[i]);
      if (RegExp(
        r'khach|tien thua|tra lai|cash|change|subtotal|tam tinh|thue|vat|giam gia',
      ).hasMatch(n)) {
        continue;
      }
      final rank =
          RegExp(
            r'tong cong|grand total|thanh toan|phai tra|amount due',
          ).hasMatch(n)
          ? 3
          : RegExp(r'total|tong tien').hasMatch(n)
          ? 2
          : 0;
      if (rank == 0) continue;
      int? amount;
      if (!RegExp(r'-\s*\d').hasMatch(n) && !RegExp(r'\d[/-]\d').hasMatch(n)) {
        final match = RegExp(
          r'(\d[\d., ]*)\s*(?:vnd|dong|d|₫)?\s*$',
          caseSensitive: false,
        ).firstMatch(n);
        amount = match == null ? null : parseAmount(match[1]!.trim());
      }
      if (amount == null &&
          i + 1 < lines.length &&
          !RegExp(r'-\s*\d').hasMatch(n)) {
        amount = parseAmount(lines[i + 1]);
      }
      if (amount == null) continue;
      if (rank > bestRank) {
        totals.clear();
        bestRank = rank;
      }
      if (rank == bestRank) totals.add(amount);
    }
    final amount = totals.length == 1 ? totals.single : null;
    return ReceiptDraft(merchant, amount, date, [
      if (merchant == null) 'Chưa nhận dạng được tên cửa hàng.',
      if (date == null) 'Cần chọn ngày trên hóa đơn.',
      if (amount == null)
        totals.length > 1
            ? 'Có nhiều tổng tiền khác nhau; hãy kiểm tra hóa đơn.'
            : 'Chưa xác định được tổng tiền; hãy nhập lại.',
    ]);
  }
}
