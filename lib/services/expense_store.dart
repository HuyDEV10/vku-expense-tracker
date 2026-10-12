import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:isar_community/isar.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/expense.dart';

Uint8List thumbnail(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    throw const FormatException('Không đọc được ảnh hóa đơn.');
  }
  var image = img.bakeOrientation(decoded);
  if (image.width > 1200) image = img.copyResize(image, width: 1200);
  return Uint8List.fromList(img.encodeJpg(image, quality: 85));
}

class ExpenseStore extends ChangeNotifier {
  ExpenseStore._(this.database, this.directory);
  final Isar database;
  final Directory directory;
  List<Expense> items = [];
  static Future<ExpenseStore> open({
    Directory? directory,
    String name = 'expenses',
  }) async {
    final root = directory ?? await getApplicationDocumentsDirectory();
    await root.create(recursive: true);
    final db = await Isar.open(
      [ExpenseSchema],
      directory: root.path,
      name: name,
    );
    final store = ExpenseStore._(db, root);
    await store.reload();
    final used = store.items.map((e) => e.imagePath).toSet();
    final images = Directory(p.join(root.path, 'receipts'));
    if (await images.exists()) {
      await for (final file in images.list()) {
        if (file is File && !used.contains(file.path)) {
          try {
            await file.delete();
          } on FileSystemException {
            /* Thử lại khi mở ứng dụng. */
          }
        }
      }
    }
    return store;
  }

  Future<void> reload() async {
    items = await database.expenses.where().findAll();
    items.sort(
      (a, b) => b.date.compareTo(a.date) != 0
          ? b.date.compareTo(a.date)
          : b.id.compareTo(a.id),
    );
    notifyListeners();
  }

  Future<void> save(Expense expense, {String? sourceImage}) async {
    if (expense.merchant.trim().isEmpty ||
        expense.amount <= 0 ||
        expense.amount > 1000000000000 ||
        !categories.contains(expense.category)) {
      throw ArgumentError('Thông tin khoản chi không hợp lệ.');
    }
    final previous = await database.expenses.get(expense.id);
    final originalPath = expense.imagePath;
    String? newPath;
    if (sourceImage != null) {
      final folder = Directory(p.join(directory.path, 'receipts'));
      await folder.create(recursive: true);
      newPath = p.join(
        folder.path,
        '${DateTime.now().microsecondsSinceEpoch}.jpg',
      );
      final bytes = await compute(
        thumbnail,
        await File(sourceImage).readAsBytes(),
      );
      await File(newPath).writeAsBytes(bytes, flush: true);
      expense.imagePath = newPath;
    }
    expense.merchant = expense.merchant.trim();
    try {
      await database.writeTxn(() async {
        await database.expenses.put(expense);
      });
    } catch (_) {
      await _removeImage(newPath);
      expense.imagePath = originalPath;
      rethrow;
    }
    await reload();
    if (previous?.imagePath != expense.imagePath) {
      await _removeImage(previous?.imagePath);
    }
  }

  Future<void> delete(int id) async {
    final old = await database.expenses.get(id);
    await database.writeTxn(() async {
      await database.expenses.delete(id);
    });
    await reload();
    await _removeImage(old?.imagePath);
  }

  Future<void> _removeImage(String? path) async {
    if (path == null || !p.isWithin(p.join(directory.path, 'receipts'), path)) {
      return;
    }
    try {
      if (await File(path).exists()) await File(path).delete();
    } on FileSystemException {
      /* Dọn ảnh chưa dùng ở lần mở tiếp theo. */
    }
  }

  Future<void> close() async {
    await database.close();
    dispose();
  }
}
