import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

Offset? cameraFocusPoint(Offset position, Size bounds, double aspectRatio) {
  if (bounds.isEmpty || !aspectRatio.isFinite || aspectRatio <= 0) return null;
  var width = bounds.width;
  var height = width / aspectRatio;
  if (height > bounds.height) {
    height = bounds.height;
    width = height * aspectRatio;
  }
  final left = (bounds.width - width) / 2;
  final top = (bounds.height - height) / 2;
  final x = (position.dx - left) / width;
  final y = (position.dy - top) / height;
  if (x < 0 || x > 1 || y < 0 || y > 1) return null;
  return Offset(x, y);
}

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});
  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? controller;
  String? error;
  bool busy = false, torch = false, initializing = false;
  int generation = 0;
  Future<void>? releasing;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(initialize());
  }

  Future<void> initialize() async {
    if (initializing) return;
    initializing = true;
    final token = ++generation;
    CameraController? candidate;
    try {
      await releasing;
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw StateError('Không có camera. Hãy chọn ảnh từ thư viện.');
      }
      final back = cameras.firstWhere(
        (e) => e.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      candidate = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await candidate.initialize();
      if (!mounted || token != generation) {
        await candidate.dispose();
        return;
      }
      setState(() {
        controller = candidate;
        error = null;
        torch = false;
      });
    } catch (e) {
      if (candidate != null) await candidate.dispose();
      if (mounted && token == generation) {
        setState(() => error = 'Không mở được camera: $e');
      }
    } finally {
      initializing = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      generation++;
      final old = controller;
      controller = null;
      if (old != null) releasing = old.dispose();
    }
    if (state == AppLifecycleState.resumed) {
      unawaited(restart());
    }
  }

  Future<void> restart() async {
    while (initializing) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      if (!mounted) return;
    }
    if (mounted && controller == null) await initialize();
  }

  void message(String value) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(value)));
    }
  }

  Future<void> capture() async {
    if (busy || controller == null) return;
    setState(() => busy = true);
    try {
      final file = await controller!.takePicture();
      if (mounted) Navigator.pop(context, file.path);
    } catch (e) {
      message('Chụp ảnh thất bại: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    generation++;
    WidgetsBinding.instance.removeObserver(this);
    unawaited(controller?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final camera = controller;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chụp hóa đơn'),
        actions: [
          IconButton(
            tooltip: 'Bật/tắt đèn',
            onPressed: camera == null
                ? null
                : () async {
                    try {
                      await camera.setFlashMode(
                        torch ? FlashMode.off : FlashMode.torch,
                      );
                      if (mounted) setState(() => torch = !torch);
                    } catch (_) {
                      message('Camera hiện tại không hỗ trợ đèn.');
                    }
                  },
            icon: Icon(torch ? Icons.flash_on : Icons.flash_off),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(error!),
                          TextButton(
                            onPressed: initialize,
                            child: const Text('Thử lại'),
                          ),
                          const Text('Quay lại để chọn ảnh từ thư viện.'),
                        ],
                      ),
                    ),
                  )
                : camera == null
                ? const Center(child: CircularProgressIndicator())
                : LayoutBuilder(
                    builder: (context, constraints) => GestureDetector(
                      onTapDown: (event) async {
                        try {
                          final point = cameraFocusPoint(
                            event.localPosition,
                            Size(constraints.maxWidth, constraints.maxHeight),
                            1 / camera.value.aspectRatio,
                          );
                          if (point == null) return;
                          await camera.setFocusPoint(point);
                          await camera.setExposurePoint(point);
                        } catch (_) {
                          message(
                            'Camera hiện tại không hỗ trợ lấy nét tại điểm chạm.',
                          );
                        }
                      },
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Center(
                            child: AspectRatio(
                              aspectRatio: 1 / camera.value.aspectRatio,
                              child: CameraPreview(camera),
                            ),
                          ),
                          IgnorePointer(
                            child: Center(
                              child: FractionallySizedBox(
                                widthFactor: .84,
                                heightFactor: .72,
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const Positioned(
                            bottom: 20,
                            left: 16,
                            right: 16,
                            child: Text(
                              'Đặt hóa đơn trong khung. Chạm để lấy nét.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                backgroundColor: Colors.black54,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: FilledButton.icon(
                onPressed: busy || camera == null ? null : capture,
                icon: const Icon(Icons.camera_alt),
                label: Text(busy ? 'Đang chụp…' : 'Chụp ảnh'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
