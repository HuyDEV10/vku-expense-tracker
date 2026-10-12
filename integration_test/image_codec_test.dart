import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:vku_expense_tracker/services/expense_store.dart';

Uint8List pngImageData(Uint8List png) {
  if (png.length < 8 || png[0] != 137 || png[1] != 80) {
    throw const FormatException('Ảnh không có header PNG.');
  }
  final chunks = BytesBuilder(copy: false);
  var offset = 8;
  final data = ByteData.sublistView(png);
  while (offset + 12 <= png.length) {
    final length = data.getUint32(offset);
    if (length > png.length - offset - 12) {
      throw const FormatException('Chunk PNG bị thiếu dữ liệu.');
    }
    final type = String.fromCharCodes(png.sublist(offset + 4, offset + 8));
    if (type == 'IDAT') {
      chunks.add(Uint8List.sublistView(png, offset + 8, offset + 8 + length));
    }
    offset += length + 12;
    if (type == 'IEND') break;
  }
  return chunks.takeBytes();
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Giải mã PNG và tạo ảnh thu nhỏ trên Android', (tester) async {
    final report = <String, dynamic>{
      'test': 'image_codec',
      'operatingSystem': Platform.operatingSystem,
      'operatingSystemVersion': Platform.operatingSystemVersion,
      'dartVersion': Platform.version,
      'results': <Map<String, dynamic>>[],
    };
    binding.reportData = report;
    final results = report['results'] as List<Map<String, dynamic>>;
    for (final name in ['food', 'study']) {
      final asset = await rootBundle.load('assets/receipts/$name.png');
      final bytes = asset.buffer.asUint8List(
        asset.offsetInBytes,
        asset.lengthInBytes,
      );
      final row = <String, dynamic>{
        'image': name,
        'inputBytes': bytes.length,
        'assetOffset': asset.offsetInBytes,
        'assetLength': asset.lengthInBytes,
      };
      results.add(row);
      try {
        final decoded = zlib.decode(pngImageData(bytes));
        row['zlibDecodedBytes'] = decoded.length;
        row['zlibResultType'] = decoded.runtimeType.toString();
      } catch (error, stack) {
        row['zlibError'] = '$error';
        row['zlibStack'] = '$stack';
      }
      try {
        final jpeg = thumbnail(bytes);
        row['thumbnailBytes'] = jpeg.length;
      } catch (error, stack) {
        row['thumbnailError'] = '$error';
        row['thumbnailStack'] = '$stack';
      }
      try {
        final jpeg = await compute(thumbnail, bytes);
        row['isolateThumbnailBytes'] = jpeg.length;
      } catch (error, stack) {
        row['isolateError'] = '$error';
        row['isolateStack'] = '$stack';
      }
      ui.Codec? codec;
      ui.Image? image;
      try {
        codec = await ui.instantiateImageCodec(bytes);
        image = (await codec.getNextFrame()).image;
        row['flutterImageWidth'] = image.width;
        row['flutterImageHeight'] = image.height;
      } catch (error, stack) {
        row['flutterCodecError'] = '$error';
        row['flutterCodecStack'] = '$stack';
      } finally {
        image?.dispose();
        codec?.dispose();
      }
      debugPrint('LAB3_CODEC_RESULT=$row');
    }
    for (final row in results) {
      expect(
        row.keys.where((key) => key.endsWith('Error')),
        isEmpty,
        reason: 'Giải mã ${row['image']} thất bại. Xem LAB3_CODEC_RESULT.',
      );
      expect(row['flutterImageWidth'], 1000);
      expect(row['flutterImageHeight'], 1300);
      expect(row['thumbnailBytes'], greaterThan(0));
      expect(row['isolateThumbnailBytes'], row['thumbnailBytes']);
    }
  });
}
