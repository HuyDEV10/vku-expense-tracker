import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vku_expense_tracker/widgets/charts.dart';

void main() {
  test('Vùng chạm donut không nhận tâm hoặc ngoài vòng', () {
    expect(
      donutHit(const Offset(130, 20), const Size(260, 260), [
        100,
        100,
        0,
        0,
        0,
      ]),
      0,
    );
    expect(
      donutHit(const Offset(130, 130), const Size(260, 260), [
        100,
        100,
        0,
        0,
        0,
      ]),
      isNull,
    );
    expect(
      donutHit(Offset.zero, const Size(260, 260), [100, 100, 0, 0, 0]),
      isNull,
    );
    expect(
      donutHit(const Offset(130, 20), const Size(260, 260), [0, 0, 0, 0, 0]),
      isNull,
    );
  });
  testWidgets('Donut rỗng và chọn danh mục không lỗi', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: DonutChart(amounts: {'Thực phẩm': 150000, 'Học tập': 85000}),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Học tập'));
    await tester.pump();
    expect(find.text('85.000 đ'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });
  testWidgets('Biểu đồ cột hiển thị số tiền ngày được chọn', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 350,
            child: WeeklyChart(values: [100, 200, 0, 0, 0, 0, 0]),
          ),
        ),
      ),
    );
    final rect = tester.getRect(find.byType(CustomPaint).last);
    await tester.tapAt(
      Offset(rect.left + 12 + (rect.width - 24) / 7 * 1.5, rect.top + 100),
    );
    await tester.pump();
    expect(find.text('T3: 200 đ'), findsOneWidget);
  });
}
