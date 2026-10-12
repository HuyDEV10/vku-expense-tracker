import 'package:isar_community/isar.dart';
part 'expense.g.dart';

const categories = ['Thực phẩm', 'Học tập', 'Du lịch', 'Thiết bị', 'Giải trí'];

@collection
class Expense {
  Id id = Isar.autoIncrement;
  @Index()
  late DateTime date;
  late String merchant;
  late int amount;
  late String category;
  String note = '';
  String rawText = '';
  String? imagePath;
  int? ocrMilliseconds;
  DateTime createdAt = DateTime.now();
}
