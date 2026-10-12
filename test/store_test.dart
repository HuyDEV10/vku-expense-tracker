import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:vku_expense_tracker/models/expense.dart';
import 'package:vku_expense_tracker/services/expense_store.dart';

void main() {
  setUpAll(() async {
    final config =
        jsonDecode(await File('.dart_tool/package_config.json').readAsString())
            as Map<String, dynamic>;
    final packages = config['packages'] as List;
    final package =
        packages.firstWhere((e) => e['name'] == 'isar_community_flutter_libs')
            as Map<String, dynamic>;
    final uri = Uri.parse(package['rootUri'] as String);
    final root = uri.isAbsolute
        ? uri
        : File('.dart_tool/package_config.json').absolute.uri.resolveUri(uri);
    final prefix = root.toString().endsWith('/') ? root : Uri.parse('$root/');
    final file = Platform.isWindows
        ? 'windows/libisar.dll'
        : Platform.isMacOS
        ? 'macos/libisar.dylib'
        : 'linux/libisar.so';
    await Isar.initializeIsarCore(
      libraries: {Abi.current(): prefix.resolve(file).toFilePath()},
    );
  });
  test('Isar lưu, mở lại, sửa, xóa và dọn ảnh', () async {
    final root = await Directory.systemTemp.createTemp('lab3_store_');
    ExpenseStore? store;
    try {
      store = await ExpenseStore.open(directory: root, name: 'test');
      final e = Expense()
        ..merchant = 'Shop'
        ..amount = 150000
        ..date = DateTime(2026, 10, 9)
        ..category = 'Thực phẩm';
      await store.save(e, sourceImage: 'assets/receipts/food.png');
      final id = e.id;
      final path = e.imagePath!;
      expect(await File(path).exists(), isTrue);
      await store.close();
      store = null;
      store = await ExpenseStore.open(directory: root, name: 'test');
      expect(store.items.single.amount, 150000);
      expect(store.items.single.id, id);
      final changed = store.items.single..amount = 180000;
      await store.save(changed);
      expect(store.items.single.amount, 180000);
      await store.delete(id);
      expect(store.items, isEmpty);
      expect(await File(path).exists(), isFalse);
    } finally {
      await store?.close();
      await root.delete(recursive: true);
    }
  });
  test('Không ghi số tiền âm vào Isar', () async {
    final root = await Directory.systemTemp.createTemp('lab3_invalid_');
    final store = await ExpenseStore.open(directory: root, name: 'invalid');
    try {
      final e = Expense()
        ..merchant = 'Shop'
        ..date = DateTime.now()
        ..amount = -100
        ..category = 'Thực phẩm';
      await expectLater(store.save(e), throwsArgumentError);
      expect(store.items, isEmpty);
    } finally {
      await store.close();
      await root.delete(recursive: true);
    }
  });
}
