import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../services/expense_store.dart';
import '../services/ocr_service.dart';
import '../services/statistics.dart';
import '../widgets/charts.dart';
import 'camera_screen.dart';
import 'review_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.store});
  final ExpenseStore store;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ocr = OcrService();
  int tab = 0;
  bool busy = false;
  String? category;
  DateTimeRange? range;
  String search = '';
  DateTime week = weekStart(DateTime.now());
  @override
  void dispose() {
    unawaited(ocr.close());
    super.dispose();
  }

  List<Expense> get filtered => widget.store.items
      .where(
        (e) =>
            (category == null || e.category == category) &&
            (range == null ||
                (!dayOnly(e.date).isBefore(dayOnly(range!.start)) &&
                    !dayOnly(e.date).isAfter(dayOnly(range!.end)))) &&
            (e.merchant.toLowerCase().contains(search.toLowerCase()) ||
                e.note.toLowerCase().contains(search.toLowerCase())),
      )
      .toList();
  Future<void> edit({
    Expense? expense,
    String? image,
    OcrResult? result,
  }) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ReviewScreen(
          store: widget.store,
          existing: expense,
          image: image,
          ocr: result,
        ),
      ),
    );
  }

  Future<void> add() async {
    final source = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Chụp hóa đơn'),
              onTap: () => Navigator.pop(context, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Chọn ảnh hóa đơn'),
              onTap: () => Navigator.pop(context, 'gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Nhập thủ công'),
              onTap: () => Navigator.pop(context, 'manual'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || source == null) return;
    if (source == 'manual') {
      await edit();
      return;
    }
    try {
      final path = source == 'camera'
          ? await Navigator.push<String>(
              context,
              MaterialPageRoute(builder: (_) => const CameraScreen()),
            )
          : (await ImagePicker().pickImage(source: ImageSource.gallery))?.path;
      if (!mounted || path == null) return;
      final crop = await ImageCropper().cropImage(
        sourcePath: path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Cắt và xoay hóa đơn',
            toolbarColor: const Color(0xff26705d),
            toolbarWidgetColor: Colors.white,
            lockAspectRatio: false,
          ),
        ],
      );
      if (!mounted || crop == null) return;
      setState(() => busy = true);
      final result = await ocr.recognize(crop.path);
      if (!mounted) return;
      setState(() => busy = false);
      await edit(image: crop.path, result: result);
    } catch (e) {
      if (mounted) {
        setState(() => busy = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Không xử lý được ảnh: $e')));
      }
    }
  }

  Future<void> detail(Expense expense) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                expense.merchant,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(
                '${currency(expense.amount)} · ${DateFormat('dd/MM/yyyy').format(expense.date)}',
              ),
              Text(expense.category),
              if (expense.note.isNotEmpty) Text(expense.note),
              if (expense.imagePath != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Image.file(
                    File(expense.imagePath!),
                    height: 250,
                    errorBuilder: (_, _, _) =>
                        const Text('Ảnh không còn tồn tại.'),
                  ),
                ),
              if (expense.ocrMilliseconds != null)
                Text('OCR: ${expense.ocrMilliseconds} ms'),
              if (expense.rawText.isNotEmpty)
                ExpansionTile(
                  title: const Text('Văn bản nhận dạng'),
                  children: [SelectableText(expense.rawText)],
                ),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      unawaited(edit(expense: expense));
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Sửa'),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: sheetContext,
                        builder: (dialogContext) => AlertDialog(
                          title: const Text('Xóa khoản chi?'),
                          content: const Text(
                            'Khoản chi và ảnh hóa đơn sẽ bị xóa.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(dialogContext, false),
                              child: const Text('Hủy'),
                            ),
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(dialogContext, true),
                              child: const Text('Xóa'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        try {
                          await widget.store.delete(expense.id);
                          if (sheetContext.mounted) Navigator.pop(sheetContext);
                        } catch (e) {
                          if (sheetContext.mounted) {
                            ScaffoldMessenger.of(sheetContext).showSnackBar(
                              SnackBar(content: Text('Không xóa được: $e')),
                            );
                          }
                        }
                      }
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Xóa'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.store,
    builder: (context, _) {
      final data = filtered;
      return Scaffold(
        appBar: AppBar(
          title: const Text('Sổ chi tiêu VKU'),
          actions: [
            IconButton(
              tooltip: 'Thông tin ứng dụng',
              onPressed: () => showAboutDialog(
                context: context,
                applicationName: 'Sổ chi tiêu VKU',
                applicationVersion: '1.0.0',
                children: [
                  const Text(
                    'Lab 3 · Nguyễn Đăng Đức Huy · 23IT101.\nOCR và dữ liệu được xử lý trên thiết bị. Không cần máy chủ.',
                  ),
                ],
              ),
              icon: const Icon(Icons.info_outline),
            ),
          ],
        ),
        body: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Tìm cửa hàng hoặc ghi chú',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (v) => setState(() => search = v),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Tất cả'),
                      selected: category == null,
                      onSelected: (_) => setState(() => category = null),
                    ),
                    for (final c in categories)
                      ChoiceChip(
                        label: Text(c),
                        selected: category == c,
                        onSelected: (_) =>
                            setState(() => category = category == c ? null : c),
                      ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () async {
                          final picked = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100, 12, 31),
                            initialDateRange: range,
                          );
                          if (picked != null && mounted) {
                            setState(() => range = picked);
                          }
                        },
                        icon: const Icon(Icons.date_range),
                        label: Text(
                          range == null
                              ? 'Lọc theo ngày'
                              : '${DateFormat('dd/MM').format(range!.start)} – ${DateFormat('dd/MM').format(range!.end)}',
                        ),
                      ),
                    ),
                    if (range != null)
                      IconButton(
                        tooltip: 'Bỏ lọc ngày',
                        onPressed: () => setState(() => range = null),
                        icon: const Icon(Icons.close),
                      ),
                  ],
                ),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${data.length} khoản chi'),
                        Text(
                          currency(
                            data.fold<int>(0, (sum, e) => sum + e.amount),
                          ),
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                if (tab == 0) ...[
                  if (data.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'Chưa có khoản chi. Nhấn Thêm để nhập hoặc chọn hóa đơn.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  for (final e in data)
                    Card(
                      child: ListTile(
                        leading: e.imagePath == null
                            ? const Icon(Icons.receipt_long)
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.file(
                                  File(e.imagePath!),
                                  width: 48,
                                  height: 56,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) =>
                                      const Icon(Icons.receipt_long),
                                ),
                              ),
                        title: Text(e.merchant),
                        subtitle: Text(
                          '${e.category} · ${DateFormat('dd/MM/yyyy').format(e.date)}',
                        ),
                        trailing: Text(currency(e.amount)),
                        onTap: () => detail(e),
                      ),
                    ),
                ],
                if (tab == 1) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Chi theo danh mục',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  DonutChart(amounts: byCategory(data)),
                  const Divider(),
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Tuần trước',
                        onPressed: () => setState(
                          () => week = week.subtract(const Duration(days: 7)),
                        ),
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Expanded(
                        child: Text(
                          'Tuần ${DateFormat('dd/MM/yyyy').format(week)}',
                          textAlign: TextAlign.center,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Tuần sau',
                        onPressed: () => setState(
                          () => week = week.add(const Duration(days: 7)),
                        ),
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                  WeeklyChart(values: byWeek(data, week)),
                ],
              ],
            ),
            if (busy)
              const Positioned.fill(
                child: ColoredBox(
                  color: Colors.black45,
                  child: Center(
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 12),
                            Text('Đang nhận dạng hóa đơn…'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: busy ? null : add,
          icon: const Icon(Icons.add),
          label: const Text('Thêm'),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: tab,
          onDestinationSelected: (v) => setState(() => tab = v),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              label: 'Khoản chi',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart),
              label: 'Thống kê',
            ),
          ],
        ),
      );
    },
  );
}
