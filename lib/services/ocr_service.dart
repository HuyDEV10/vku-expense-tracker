import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrResult {
  const OcrResult(this.text, this.milliseconds);
  final String text;
  final int milliseconds;
}

class OcrService {
  TextRecognizer? _recognizer;
  Future<OcrResult> recognize(String path) async {
    _recognizer ??= TextRecognizer(script: TextRecognitionScript.latin);
    final watch = Stopwatch()..start();
    final result = await _recognizer!.processImage(
      InputImage.fromFilePath(path),
    );
    watch.stop();
    return OcrResult(result.text, watch.elapsedMilliseconds);
  }

  Future<void> close() async {
    await _recognizer?.close();
    _recognizer = null;
  }
}
