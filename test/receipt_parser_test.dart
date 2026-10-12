import 'package:flutter_test/flutter_test.dart';
import 'package:vku_expense_tracker/services/receipt_parser.dart';

void main() {
  test('Chọn tổng cộng, bỏ tiền khách đưa và tiền thừa', () {
    final r = ReceiptParser.parse(
      'MINH AN MARKET\nNgày: 09/10/2026\nTỔNG CỘNG: 150.000 VND\nTiền khách đưa: 200.000 VND\nTiền thừa: 50.000 VND',
    );
    expect(r.amount, 150000);
    expect(r.date, DateTime(2026, 10, 9));
    expect(r.merchant, 'MINH AN MARKET');
  });
  test('Các định dạng tiền nguyên VND', () {
    for (final s in ['150,000 VND', '150.000đ', '150 000 ₫', '150000']) {
      expect(ReceiptParser.parseAmount(s), 150000);
    }
  });
  test('Tổng tiền trên dòng kế tiếp', () {
    expect(ReceiptParser.parse('SHOP\nTONG CONG\n85.000 VND').amount, 85000);
  });
  test('Ngày không tồn tại cần nhập lại', () {
    expect(ReceiptParser.parse('SHOP\n31/02/2026\nTOTAL 1000').date, isNull);
  });
  test('Không tự chọn giá hàng làm tổng tiền', () {
    expect(
      ReceiptParser.parse('SHOP\nSua 60.000 VND\nBanh 40.000 VND').amount,
      isNull,
    );
  });
  test('Hai tổng tiền cùng mức ưu tiên cần kiểm tra', () {
    expect(ReceiptParser.parse('SHOP\nTOTAL 1000\nTOTAL 2000').amount, isNull);
  });
  test('Ưu tiên grand total, bỏ subtotal', () {
    expect(
      ReceiptParser.parse(
        'SHOP\nSubtotal 300000\nTotal 200000\nGrand total 150000',
      ).amount,
      150000,
    );
  });
  test('Từ chối âm, số lẻ và dấu phân nhóm sai', () {
    for (final s in ['-150000', '0', '15.50', '150.00', '1000000000001']) {
      expect(ReceiptParser.parseAmount(s), isNull);
    }
  });
  test('Tổng âm không được chuyển thành dương', () {
    expect(ReceiptParser.parse('SHOP\nTOTAL -150000').amount, isNull);
  });
  test('Chấp nhận ngày nhuận đúng', () {
    expect(
      ReceiptParser.parse('SHOP\n29/02/2024\nTOTAL 5000').date,
      DateTime(2024, 2, 29),
    );
  });
}
