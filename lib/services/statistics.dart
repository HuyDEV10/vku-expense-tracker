import '../models/expense.dart';

DateTime dayOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);
DateTime weekStart(DateTime value) =>
    dayOnly(value).subtract(Duration(days: value.weekday - 1));
Map<String, int> byCategory(Iterable<Expense> items) {
  final result = {for (final category in categories) category: 0};
  for (final expense in items) {
    result.update(
      expense.category,
      (value) => value + expense.amount,
      ifAbsent: () => expense.amount,
    );
  }
  return result;
}

List<int> byWeek(Iterable<Expense> items, DateTime week) {
  final start = weekStart(week);
  final result = List.filled(7, 0);
  for (final expense in items) {
    final date = dayOnly(expense.date);
    for (var i = 0; i < 7; i++) {
      if (date == DateTime(start.year, start.month, start.day + i)) {
        result[i] += expense.amount;
      }
    }
  }
  return result;
}
