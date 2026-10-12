# Hướng dẫn Lab 3 trên Windows

## 1. Môi trường

Cài Flutter, Android Studio, Android SDK và một AVD Android API 35 x86_64. Thêm thư mục bin của Flutter vào PATH, mở PowerShell mới. Chạy flutter doctor và flutter doctor --android-licenses. Visual Studio chỉ cần khi build Windows desktop, không bắt buộc cho APK Android.

Nếu đã có môi trường build thành công, giữ cấu hình đang dùng. Script moi-truong-lab.ps1 nhận FlutterRoot, AndroidSdk, Jdk và TrustStore để cấu hình phiên hiện tại; không chứa đường dẫn riêng của một máy. Ví dụ khi Flutter chưa có PATH:

```powershell
. .\scripts\moi-truong-lab.ps1 -FlutterRoot 'C:\development\flutter'
```

Thay đường dẫn bằng nơi cài Flutter thật. TrustStore là tùy chọn nếu máy đã có truststore riêng; không tắt kiểm tra chứng chỉ.

## 2. Chạy và build

Trong thư mục dự án:

```powershell
flutter pub get
flutter analyze
flutter test
flutter devices
flutter run -d emulator-5554
```

Build release bằng flutter build apk --release. APK nằm tại build/app/outputs/flutter-apk/app-release.apk.

## 3. Chép ảnh mẫu và cài APK

```powershell
$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
& $adb devices
& $adb -s emulator-5554 install -r .\build\app\outputs\flutter-apk\app-release.apk
& $adb -s emulator-5554 shell mkdir -p /sdcard/Pictures
& $adb -s emulator-5554 push .\assets\receipts\food.png /sdcard/Pictures/food.png
& $adb -s emulator-5554 push .\assets\receipts\study.png /sdcard/Pictures/study.png
& $adb -s emulator-5554 shell am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d file:///sdcard/Pictures/food.png
& $adb -s emulator-5554 shell am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d file:///sdcard/Pictures/study.png
```

App: Thêm > Chọn ảnh hóa đơn > Gallery. Food có tổng 150.000 đ; study có tổng 85.000 đ, cùng ngày 09/10/2026. Sửa food thành 180.000 đ để kiểm tra cập nhật; tổng hai khoản là 265.000 đ. Tuần biểu đồ là 05-11/10/2026.

## 4. Kiểm tra và video

Theo docs/TEST_PLAN.md và docs/VIDEO_DEMO.md. Dùng scripts/kiem-tra-lab.ps1 nếu cần chạy toàn bộ kiểm tra; dừng khi có lỗi và lưu đầu ra PowerShell. Không xóa dữ liệu hoặc gỡ app khi đang kiểm tra đóng/mở lại. Tắt Wi-Fi và bật máy bay trước khi chọn ảnh để thể hiện OCR offline trong video.

Video demo: [https://drive.google.com/file/d/1SFfTw9aHJyJMmaXVnUevoHFL-DHhIzwU/view](https://drive.google.com/file/d/1SFfTw9aHJyJMmaXVnUevoHFL-DHhIzwU/view). Kiểm tra link trong cửa sổ ẩn danh. Nếu yêu cầu đăng nhập, sửa quyền chia sẻ thành bất kỳ ai có đường dẫn, người xem.

## 5. Xuất bản và nộp

Mã nguồn: [https://github.com/HuyDEV10/vku-expense-tracker](https://github.com/HuyDEV10/vku-expense-tracker). Đăng đúng APK đã thử lên GitHub Releases: Releases > Draft a new release > tag v1.0.0 > nhánh main > tiêu đề Lab 3 - Sổ chi tiêu VKU > đính kèm app-release.apk > Publish release. Sau khi asset có trên trang, sao chép link tải thực tế; không dùng link giả định trước khi upload.

Báo cáo theo năm mục trong docs/Mini-Project-3-Report.md. PDF được tạo bằng:

```powershell
python -m pip install reportlab pillow
python .\scripts\build_report.py
```

Nộp link GitHub, link APK trực tiếp, link video và PDF 2-4 trang. Trước khi nộp, cập nhật trạng thái APK trong báo cáo theo release thực tế và chỉ đánh dấu các mục đã có kết quả kiểm tra.
