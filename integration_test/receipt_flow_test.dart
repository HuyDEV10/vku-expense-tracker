import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vku_expense_tracker/models/expense.dart';
import 'package:vku_expense_tracker/screens/home_screen.dart';
import 'package:vku_expense_tracker/screens/review_screen.dart';
import 'package:vku_expense_tracker/services/expense_store.dart';
import 'package:vku_expense_tracker/services/ocr_service.dart';
import 'package:vku_expense_tracker/services/receipt_parser.dart';

Widget app(Widget home) => MaterialApp(
  locale: const Locale('vi'),
  supportedLocales: const [Locale('vi'), Locale('en')],
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  theme: ThemeData(
    useMaterial3: true,
    colorSchemeSeed: const Color(0xff26705d),
  ),
  home: home,
);
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('OCR Latin và Isar hoạt động trên Android', (tester) async {
    final root = await Directory.systemTemp.createTemp('lab3_native_');
    final receipt = File('${root.path}/food.png');
    final asset = await rootBundle.load('assets/receipts/food.png');
    await receipt.writeAsBytes(
      asset.buffer.asUint8List(asset.offsetInBytes, asset.lengthInBytes),
    );
    expect(await receipt.length(), asset.lengthInBytes);
    final service = OcrService();
    ExpenseStore? store;
    try {
      final results = <OcrResult>[];
      for (var i = 0; i < 5; i++) {
        results.add(await service.recognize(receipt.path));
      }
      debugPrint('LAB3_OCR_MS=${results.map((r) => r.milliseconds).toList()}');
      binding.reportData = {
        'foodOcrMilliseconds': results.map((r) => r.milliseconds).toList(),
        'sampleDate': '2026-10-09',
      };
      final draft = ReceiptParser.parse(results.first.text);
      expect(draft.amount, 150000);
      expect(draft.date, DateTime(2026, 10, 9));
      store = await ExpenseStore.open(directory: root, name: 'native');
      var surfaceConverted = false;
      Future<void> capture(String name) async {
        if (!const bool.fromEnvironment('CAPTURE_SCREENSHOTS')) return;
        if (!surfaceConverted) {
          await binding.convertFlutterSurfaceToImage();
          surfaceConverted = true;
        }
        await tester.pumpAndSettle();
        final bytes = await binding.takeScreenshot(name);
        final external = await getExternalStorageDirectory();
        final folder = Directory('${external!.path}/lab3_screenshots');
        await folder.create(recursive: true);
        await File('${folder.path}/$name.png').writeAsBytes(bytes);
      }

      await tester.pumpWidget(
        app(
          ReviewScreen(store: store, image: receipt.path, ocr: results.first),
        ),
      );
      await tester.pumpAndSettle();
      await capture('01_review_ocr');
      final e = Expense()
        ..merchant = draft.merchant ?? 'MINH AN MARKET'
        ..amount = draft.amount!
        ..date = draft.date!
        ..category = 'Thực phẩm'
        ..rawText = results.first.text
        ..ocrMilliseconds = results.first.milliseconds;
      await store.save(e, sourceImage: receipt.path);
      final id = e.id;
      await tester.pumpWidget(const SizedBox());
      await store.close();
      store = null;
      store = await ExpenseStore.open(directory: root, name: 'native');
      expect(store.items.single.id, id);
      expect(store.items.single.amount, 150000);
      expect(await File(store.items.single.imagePath!).exists(), isTrue);
      final changed = store.items.single..amount = 180000;
      await store.save(changed);
      expect(store.items.single.amount, 180000);
      final studyImage = File('${root.path}/study.png');
      final studyAsset = await rootBundle.load('assets/receipts/study.png');
      await studyImage.writeAsBytes(
        studyAsset.buffer.asUint8List(
          studyAsset.offsetInBytes,
          studyAsset.lengthInBytes,
        ),
      );
      expect(await studyImage.length(), studyAsset.lengthInBytes);
      final studyOcr = await service.recognize(studyImage.path);
      final studyDraft = ReceiptParser.parse(studyOcr.text);
      expect(studyDraft.amount, 85000);
      expect(studyDraft.date, DateTime(2026, 10, 9));
      binding.reportData!['studyOcrMilliseconds'] = studyOcr.milliseconds;
      final second = Expense()
        ..merchant = studyDraft.merchant ?? 'VKU BOOK SHOP'
        ..amount = studyDraft.amount!
        ..date = studyDraft.date!
        ..category = 'Học tập'
        ..rawText = studyOcr.text
        ..ocrMilliseconds = studyOcr.milliseconds;
      await store.save(second, sourceImage: studyImage.path);
      await tester.pumpWidget(app(HomeScreen(store: store)));
      await tester.pumpAndSettle();
      await capture('02_expenses');
      await tester.tap(find.text('Thống kê'));
      await tester.pumpAndSettle();
      await capture('03_categories');
      await tester.drag(find.byType(ListView).first, const Offset(0, -500));
      await tester.pumpAndSettle();
      await capture('04_weekly');
      await tester.pumpWidget(const SizedBox());
      await store.delete(id);
      expect(store.items.length, 1);
    } finally {
      await service.close();
      await store?.close();
      await root.delete(recursive: true);
    }
  });
}
