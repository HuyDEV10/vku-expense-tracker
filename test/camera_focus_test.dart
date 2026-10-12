import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vku_expense_tracker/screens/camera_screen.dart';

void main() {
  test('Điểm chạm dùng tọa độ preview khi có khoảng trống trên dưới', () {
    const bounds = Size(300, 600);
    expect(
      cameraFocusPoint(const Offset(150, 100), bounds, .75),
      const Offset(.5, 0),
    );
    expect(
      cameraFocusPoint(const Offset(150, 300), bounds, .75),
      const Offset(.5, .5),
    );
    expect(cameraFocusPoint(const Offset(150, 50), bounds, .75), isNull);
  });
  test('Điểm chạm dùng tọa độ preview khi có khoảng trống hai bên', () {
    const bounds = Size(600, 400);
    expect(
      cameraFocusPoint(const Offset(150, 200), bounds, .75),
      const Offset(0, .5),
    );
    expect(
      cameraFocusPoint(const Offset(300, 200), bounds, .75),
      const Offset(.5, .5),
    );
    expect(cameraFocusPoint(const Offset(50, 200), bounds, .75), isNull);
  });
  test('Không gửi tọa độ khi preview chưa có kích thước hợp lệ', () {
    expect(cameraFocusPoint(Offset.zero, Size.zero, .75), isNull);
    expect(cameraFocusPoint(Offset.zero, const Size(300, 400), 0), isNull);
    expect(
      cameraFocusPoint(Offset.zero, const Size(300, 400), double.nan),
      isNull,
    );
  });
}
