# Sổ chi tiêu VKU - Lab 3

Ứng dụng Flutter quản lý khoản chi trên Android. Google ML Kit nhận dạng hóa đơn bằng model Latin đóng gói trong APK; dữ liệu lưu bằng Isar Community 3.3.2. Ứng dụng không dùng backend.

Nguyễn Đăng Đức Huy - MSSV 23IT101 - Lớp 23JIT.

## Tài liệu và demo

- [Video thao tác trên Android Emulator](https://drive.google.com/file/d/1SFfTw9aHJyJMmaXVnUevoHFL-DHhIzwU/view)
- [Báo cáo PDF](docs/Bao-cao-Lab-3.pdf) và [bản Markdown](docs/Mini-Project-3-Report.md)
- [Kết quả kiểm tra](docs/KET_QUA_KIEM_THU.md)
- [Hướng dẫn chạy và nộp bài](HUONG_DAN_LAB_3.md)
- [Trang tải bản phát hành](https://github.com/HuyDEV10/vku-expense-tracker/releases). APK cần được đính kèm vào Release; đường dẫn này không thay thế file APK khi chưa có asset.

## Chức năng

- Camera có hình xem trước, khung hóa đơn, bật/tắt đèn và chạm lấy nét khi thiết bị hỗ trợ.
- Chọn ảnh, cắt/xoay, OCR tên cửa hàng, ngày và tổng tiền. Người dùng kiểm tra hoặc nhập lại trước khi lưu.
- Thêm, xem, sửa, xóa khoản chi; tìm kiếm cửa hàng/ghi chú, lọc ngày và năm danh mục.
- Lưu ảnh JPEG trong thư mục riêng, thu nhỏ tối đa rộng 1200 pixel.
- Biểu đồ vòng theo danh mục và cột theo tuần bằng CustomPainter, hỗ trợ chạm để xem số tiền.

## Chạy trên Windows

Môi trường đã build: Flutter 3.47.7, Dart 3.13.5, JDK 21 của Android Studio; máy giả lập Lab3_API35, Android API 35 x86_64. Mã Android đặt mức Java 17. Cài Flutter và Android Studio, thêm Flutter vào PATH, rồi chạy trong thư mục chứa pubspec.yaml:

```powershell
flutter doctor
flutter doctor --android-licenses
flutter pub get
flutter analyze
flutter test
flutter devices
flutter run -d emulator-5554
```

Thay ID bằng thiết bị hiển thị trong `flutter devices`. Schema Isar đã có trong repo; khi sửa collection chạy `dart run build_runner build --delete-conflicting-outputs`.

## Build và cài APK

```powershell
flutter build apk --release
$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
& $adb -s emulator-5554 install -r .\build\app\outputs\flutter-apk\app-release.apk
```

APK nằm ở `build/app/outputs/flutter-apk/app-release.apk`. Cấu hình hiện tại dùng debug signing cho bài lab; cần khóa phát hành riêng nếu đưa lên Play Store. Máy Windows không build bản iOS.

## Kiểm thử

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\kiem-tra-anh.ps1 -DeviceId emulator-5554
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\kiem-tra-android.ps1 -DeviceId emulator-5554
```

Script kiểm tra ảnh tách codec Flutter, zlib và tạo ảnh thu nhỏ. Script Android chạy ML Kit và Isar thật, ghi thời gian `LAB3_OCR_MS`; build trước rồi mới mở giả lập để giảm RAM. Kết quả unit/widget/native Isar đã kiểm tra trên Linux: 21 bài qua. Log Windows hiện có báo kiểm tra hai PNG hoàn tất và APK release 95.577.582 byte, nhưng không ghi đủ đầu ra để xác nhận toàn bộ integration test Android.

Kiểm tra thủ công trên Windows cho thấy lưu ảnh, sửa khoản chi và biểu đồ đúng: Thực phẩm 180.000 đ, Học tập 85.000 đ, tổng 265.000 đ trong tuần 05/10/2026. Một lần OCR hóa đơn có thời gian 1807 ms, chưa đạt mục tiêu dưới 100 ms. Khả năng đèn/lấy nét phụ thuộc camera giả lập.

## Cấu trúc mã nguồn

`lib/models` chứa collection Isar; `lib/services` xử lý OCR, parser, lưu trữ và thống kê; `lib/screens` chứa các màn hình; `lib/widgets` vẽ biểu đồ. `test` kiểm tra nghiệp vụ và widget; `integration_test` kiểm tra plugin Android.

Hai ảnh trong `assets/receipts` là hóa đơn mẫu tự tạo ngày 09/10/2026: food.png tổng 150.000 đ, study.png tổng 85.000 đ. Chúng không phải giao dịch thật.
