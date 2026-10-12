import 'package:flutter_test/flutter_test.dart';
import 'package:vku_expense_tracker/models/expense.dart';
import 'package:vku_expense_tracker/services/statistics.dart';

Expense item(int day, int amount, String category) => Expense()
  ..date = DateTime(2026, 10, day)
  ..merchant = 'Shop'
  ..amount = amount
  ..category = category;
void main() {
  test('Cộng đúng danh mục', () {
    final result = byCategory([
      item(9, 150000, 'Thực phẩm'),
      item(9, 85000, 'Học tập'),
      item(10, 50000, 'Thực phẩm'),
    ]);
    expect(result['Thực phẩm'], 200000);
    expect(result['Học tập'], 85000);
    expect(result['Du lịch'], 0);
  });
  test('Tuần bắt đầu thứ hai và loại ngày ngoài tuần', () {
    expect(weekStart(DateTime(2026, 10, 9)), DateTime(2026, 10, 5));
    expect(
      byWeek([
        item(4, 999, 'Thực phẩm'),
        item(5, 100, 'Thực phẩm'),
        item(11, 200, 'Học tập'),
        item(12, 999, 'Thực phẩm'),
      ], DateTime(2026, 10, 9)),
      [100, 0, 0, 0, 0, 0, 200],
    );
  });
  test('Dữ liệu rỗng cho bảy ngày bằng không', () {
    expect(byWeek([], DateTime(2026, 10, 9)), List.filled(7, 0));
  });
}
