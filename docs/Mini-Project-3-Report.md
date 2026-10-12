# MINI PROJECT 3 - SỔ CHI TIÊU VKU

## 1. GENERAL INFORMATION & DELIVERABLE LINKS

Ứng dụng quản lý chi tiêu và nhận dạng hóa đơn bằng Flutter, lưu dữ liệu local với Isar Community thay cho SQLite. Phạm vi thực hiện là Android Emulator trên Windows.

| Thành viên | MSSV | Lớp | Công việc |
| --- | --- | --- | --- |
| Nguyễn Đăng Đức Huy | 23IT101 | 23JIT | Flutter, camera, OCR, Isar, biểu đồ và kiểm thử |

Repository: [HuyDEV10/vku-expense-tracker](https://github.com/HuyDEV10/vku-expense-tracker). Video: [Demo Lab 3](https://drive.google.com/file/d/1SFfTw9aHJyJMmaXVnUevoHFL-DHhIzwU/view). APK: đã build và cài trên giả lập; [trang Releases](https://github.com/HuyDEV10/vku-expense-tracker/releases) là nơi đăng file, chưa xác nhận có asset tải xuống tại thời điểm lập báo cáo. Ngày cập nhật: 12/10/2026.

## 2. FEATURE CHECKLIST

| Chức năng | Thực hiện | Kết quả kiểm tra |
| --- | --- | --- |
| Camera và xử lý ảnh | Preview, overlay, flash, chạm lấy nét; cắt/xoay bằng image_cropper | Đã có preview, khung và ảnh chụp; flash, lấy nét và xoay/cắt cần minh chứng thao tác riêng |
| OCR offline | ML Kit Latin đóng gói trong APK; regex tiền, ngày và cửa hàng; form duyệt | Nhận dạng được hóa đơn mẫu; số đo 1807 ms chưa đạt dưới 100 ms; ảnh có chế độ máy bay chưa chứng minh toàn bộ trình tự offline |
| Lưu dữ liệu local | Isar CRUD, 5 danh mục; ảnh thu nhỏ lưu riêng | Đã lưu kèm ảnh và sửa 150.000 thành 180.000 đ; mở lại và xóa chưa có minh chứng đầy đủ trên Windows |
| Thống kê | CustomPainter vẽ vòng danh mục và cột 7 ngày | Tổng 265.000 đ đúng; chạm cột T6 hiển thị 265.000 đ |

## 3. TECHNICAL ARCHITECTURE

Mã nguồn chia thành models, services, screens và widgets. Camera hoặc thư viện cung cấp ảnh cho bộ cắt. ML Kit đọc ảnh sau xử lý; ReceiptParser lấy tên cửa hàng, ngày và tổng tiền. Màn hình kiểm tra cho phép sửa các trường trước khi ghi Isar. Danh sách và thống kê cập nhật từ cùng ExpenseStore.

Expense lưu id, ngày, cửa hàng, số tiền nguyên VND, danh mục, ghi chú, đường dẫn ảnh, văn bản OCR, thời gian OCR và thời điểm tạo. Có năm danh mục: Thực phẩm, Học tập, Du lịch, Thiết bị, Giải trí. Ứng dụng không gửi hóa đơn lên máy chủ.

Parser ưu tiên nhãn TỔNG CỘNG, GRAND TOTAL và THANH TOÁN; bỏ tiền khách đưa, tiền thừa và tạm tính. Tổng tiền thiếu hoặc mâu thuẫn phải nhập lại. Ngày kiểm tra theo lịch, không chấp nhận ngày như 31/02. Màn hình duyệt và lớp lưu trữ kiểm tra số tiền dương và danh mục hợp lệ.

Ảnh được xoay theo EXIF, thu nhỏ tối đa rộng 1200 pixel và mã hóa JPEG chất lượng 85 bằng compute. File được lưu vào thư mục receipts trước giao dịch Isar. Nếu giao dịch lỗi, ảnh mới được xóa; khi thay/xóa khoản chi, ảnh cũ được dọn. Lần mở tiếp theo kiểm tra các file không còn liên kết bản ghi.

Biểu đồ vòng cộng tiền theo danh mục; biểu đồ cột cộng theo từng ngày từ thứ hai đến chủ nhật. Canvas và CustomPainter tự vẽ biểu đồ; vùng chạm được tính để chọn danh mục/ngày. Bộ lọc tìm kiếm, danh mục và ngày dùng chung cho danh sách và thống kê.

OcrService giữ lại TextRecognizer giữa các lần dùng. Stopwatch đo quanh processImage, bao gồm thời gian gọi plugin và xử lý native; số đo không gồm chọn ảnh, cắt ảnh hoặc lưu Isar. Lần gọi đầu có thể gồm khởi tạo model. Mục tiêu 100 ms phải so với phép đo thực tế, không thay bằng số ước lượng.

## 4. EVIDENCE & TEST RESULTS

Môi trường Windows: Flutter 3.47.7, Dart 3.13.5, JDK 21 và Android Emulator Lab3_API35 x86_64. Log ngày 12/10 ghi APK release 95.577.582 byte; adb install báo Success. Transcript kiểm tra ảnh báo hai PNG hoàn tất, nhưng không chứa đầu ra chi tiết. Chưa có log đầy đủ của integration test OCR/Isar trên Windows.

Kiểm thử trước đó trên Linux: flutter analyze không có vấn đề, 21 bài unit/widget/native Isar qua. Nội dung gồm parser, thống kê, vùng chạm biểu đồ, tọa độ lấy nét và lưu trữ thật. Kết quả này không thay thế kiểm thử camera/ML Kit trên Android. Lỗi giải mã PNG từng gặp ở giả lập phần mềm API 28 chưa tái hiện khi lưu ảnh qua giao diện Windows; chưa có phép chạy lại tương đương để kết luận nguyên nhân đã được sửa.

Minh chứng Windows cho thấy MINH AN MARKET có ngày 09/10/2026, tiền 150.000 đ và ảnh thu nhỏ; sau sửa là 180.000 đ. Thêm khoản Học tập 85.000 đ cho tổng 265.000 đ. Biểu đồ vòng khớp hai danh mục; tuần 05/10 có cột T6 265.000 đ và thông tin khi chọn cột.

Ảnh chi tiết hóa đơn hiển thị OCR 1807 ms và biểu tượng máy bay. Vì ảnh là trạng thái sau lưu, cần xem video trình tự tắt mạng rồi OCR để xác nhận phép thử offline. Camera đã chụp cảnh mô phỏng và chuyển sang màn hình duyệt sau 1429 ms; khi không có chữ hóa đơn, ứng dụng báo thiếu cửa hàng/ngày/tổng và cho nhập tay. Các số đo trên giả lập chưa đạt mục tiêu dưới 100 ms.

Video đã được người thực hiện quay và cung cấp link; nội dung và quyền truy cập chưa được kiểm tra độc lập trong lần rà soát này. Ảnh minh chứng được cung cấp từ phiên kiểm tra thủ công; chưa đính kèm vào bản công khai này. Hai hóa đơn mẫu là dữ liệu tự tạo, không phải giao dịch thật.

## 5. CHALLENGES & SOLUTIONS

Hóa đơn có nhiều dòng tiền nên chọn số lớn nhất dễ nhầm tiền khách đưa. Parser phân loại nhãn tổng và yêu cầu kiểm tra lại kết quả thiếu/mâu thuẫn. Ảnh camera/crop nằm trong thư mục tạm được sao chép vào vùng dữ liệu ứng dụng trước khi lưu khoản chi.

Giả lập phù hợp kiểm tra bằng ảnh mẫu nhưng không đại diện cho camera thật hoặc tốc độ thiết bị thật. Cần bổ sung minh chứng flash/lấy nét/cắt xoay, kiểm tra mở lại/xóa trên Windows và đo nhiều lần OCR ở bản release. Hạn chế dưới 100 ms được ghi theo số đo thực tế; iOS không được build hoặc kiểm thử trên máy Windows.
