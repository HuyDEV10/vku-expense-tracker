import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../services/expense_store.dart';
import '../services/ocr_service.dart';
import '../services/receipt_parser.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({
    super.key,
    required this.store,
    this.existing,
    this.image,
    this.ocr,
  });
  final ExpenseStore store;
  final Expense? existing;
  final String? image;
  final OcrResult? ocr;
  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final form = GlobalKey<FormState>();
  late TextEditingController merchant, amount, note;
  late ReceiptDraft? draft;
  DateTime? date;
  late String category;
  bool saving = false;
  @override
  void initState() {
    super.initState();
    draft = widget.ocr == null ? null : ReceiptParser.parse(widget.ocr!.text);
    merchant = TextEditingController(
      text: widget.existing?.merchant ?? draft?.merchant ?? '',
    );
    amount = TextEditingController(
      text: (widget.existing?.amount ?? draft?.amount)?.toString() ?? '',
    );
    note = TextEditingController(text: widget.existing?.note ?? '');
    category = widget.existing?.category ?? categories.first;
    date =
        widget.existing?.date ??
        (widget.ocr == null ? DateTime.now() : draft?.date);
  }

  @override
  void dispose() {
    merchant.dispose();
    amount.dispose();
    note.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (saving) return;
    if (!form.currentState!.validate()) return;
    if (date == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hãy chọn ngày trên hóa đơn.')),
      );
      return;
    }
    setState(() => saving = true);
    final expense = Expense()
      ..merchant = merchant.text
      ..amount = ReceiptParser.parseAmount(amount.text)!
      ..date = date!
      ..category = category
      ..note = note.text.trim()
      ..rawText = widget.ocr?.text ?? widget.existing?.rawText ?? ''
      ..ocrMilliseconds =
          widget.ocr?.milliseconds ?? widget.existing?.ocrMilliseconds
      ..imagePath = widget.existing?.imagePath;
    if (widget.existing != null) {
      expense.id = widget.existing!.id;
      expense.createdAt = widget.existing!.createdAt;
    }
    try {
      await widget.store.save(expense, sourceImage: widget.image);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Không lưu được: $e')));
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final image = widget.image ?? widget.existing?.imagePath;
    final raw = widget.ocr?.text ?? widget.existing?.rawText ?? '';
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existing == null ? 'Kiểm tra khoản chi' : 'Sửa khoản chi',
        ),
      ),
      body: Form(
        key: form,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (image != null)
              Image.file(
                File(image),
                height: 220,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Text('Không đọc được ảnh.'),
              ),
            if (widget.ocr != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Thời gian nhận dạng: ${widget.ocr!.milliseconds} ms. Kiểm tra thông tin trước khi lưu.',
                ),
              ),
            for (final warning in draft?.warnings ?? <String>[])
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  warning,
                  style: const TextStyle(color: Colors.deepOrange),
                ),
              ),
            TextFormField(
              controller: merchant,
              maxLength: 120,
              decoration: const InputDecoration(labelText: 'Cửa hàng'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Nhập tên cửa hàng.' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: amount,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Số tiền (VND)'),
              validator: (v) => ReceiptParser.parseAmount(v ?? '') == null
                  ? 'Nhập số tiền nguyên dương hợp lệ.'
                  : null,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: saving
                  ? null
                  : () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: date ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100, 12, 31),
                      );
                      if (picked != null && mounted) {
                        setState(() => date = picked);
                      }
                    },
              icon: const Icon(Icons.calendar_month),
              label: Text(
                date == null
                    ? 'Chọn ngày hóa đơn'
                    : DateFormat('dd/MM/yyyy').format(date!),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: category,
              decoration: const InputDecoration(labelText: 'Danh mục'),
              items: categories
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: saving ? null : (v) => setState(() => category = v!),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: note,
              maxLength: 500,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Ghi chú'),
            ),
            if (raw.isNotEmpty)
              ExpansionTile(
                title: const Text('Văn bản nhận dạng'),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: SelectableText(raw),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: saving ? null : save,
              icon: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(saving ? 'Đang lưu…' : 'Lưu khoản chi'),
            ),
          ],
        ),
      ),
    );
  }
}
