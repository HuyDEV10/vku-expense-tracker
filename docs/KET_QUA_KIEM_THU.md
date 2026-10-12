# Kết quả kiểm tra Lab 3

Ngày cập nhật: 12/10/2026. Phân biệt kiểm thử tự động với minh chứng thao tác trên Windows.

## Kiểm thử tự động đã có kết quả

Trên Linux x64, Flutter 3.47.7 / Dart 3.13.5: sinh schema thành công, flutter analyze không có vấn đề và 21 bài kiểm thử qua. Gồm 10 parser, 3 thống kê, 3 biểu đồ, 2 lưu trữ Isar native và 3 tọa độ lấy nét.

Transcript Windows `kiem-tra-anh.log` báo “Hai ảnh PNG đã qua kiểm tra”, nhưng không ghi đầu ra từng assertion. `kiem-tra-lab.log` ghi APK release 95.577.582 byte. Chưa có log đầy đủ xác nhận toàn bộ integration test OCR/Isar Windows, không đánh dấu các bài đó đã đạt chỉ từ việc build thành công.

## Minh chứng thủ công trên Android API 35 x86_64

| Mục | Kết quả quan sát |
| --- | --- |
| Cài APK | adb install trả Success; app mở được |
| Lưu hóa đơn | MINH AN MARKET, 150.000 đ, 09/10/2026, Thực phẩm; có ảnh thu nhỏ |
| Sửa | Số tiền đổi thành 180.000 đ |
| Thống kê danh mục | 2 khoản chi; Thực phẩm 180.000 đ, Học tập 85.000 đ; tổng 265.000 đ |
| Thống kê tuần | Tuần 05/10/2026, T6 265.000 đ; chọn cột có thông tin tiền |
| OCR hóa đơn | Màn hình chi tiết hiển thị 1807 ms; không phải trung bình nhiều lần |
| Trạng thái mạng | Ảnh chi tiết có biểu tượng máy bay; chưa đủ để xác nhận trình tự OCR offline |
| Camera | Preview và overlay hiển thị; ảnh chụp cảnh mô phỏng được chuyển sang form duyệt |
| Ảnh không có chữ | OCR 1429 ms; cảnh báo thiếu tên/ngày/tổng, yêu cầu nhập tay |

## Chưa có đủ minh chứng

- Flash, chạm lấy nét, xoay/cắt sau chụp: có mã, cần thao tác được ghi rõ trong video.
- Đóng/mở lại dữ liệu và xóa: có bài kiểm thử Linux, chưa có minh chứng riêng trên Windows.
- Video đã được người thực hiện cung cấp; cần kiểm tra mở được bằng cửa sổ ẩn danh.
- OCR dưới 100 ms: chưa đạt với số đo 1807 ms trên giả lập. Cần ghi các lần gọi đầu và sau khởi tạo riêng khi đo thêm.

## Lỗi ở môi trường kiểm tra trước

Giả lập phần mềm API 28 từng nhận dạng được tổng 150000 và ngày 09/10/2026, nhưng dừng khi giải mã PNG để tạo thumbnail. Thời gian OCR mỗi lần khoảng 7,8-15,2 giây. Ảnh PNG giống nguồn từng byte và giải mã được trên Linux. Luồng giao diện Windows API 35 hiện lưu ảnh thành công; chưa chạy lại chính xác phép thử API 28 để kết luận lỗi gốc đã được xử lý.

Lỗi Dart resolvedExecutable null trong console Windows thuộc phiên môi trường chạy trước khi chuyển sang PowerShell thường. Sau đó APK đã build và cài thành công. Không đưa lỗi môi trường cũ thành lỗi hiện tại của ứng dụng.

## Bản phát hành v1.0.0

Release công khai ngày 12/10/2026 có asset app-release.apk ở trạng thái uploaded, dung lượng 95.577.582 byte, khớp dung lượng trong log build Windows. SHA-256 do GitHub cung cấp: `229834c2437a0bff70692b81ab509967dfecbafc84e9d28387de107d8fe0a323`. Đây là đối chiếu metadata; chưa tải APK về để tính lại hash hoặc cài thử file từ Release.

[Tải APK](https://github.com/HuyDEV10/vku-expense-tracker/releases/download/v1.0.0/app-release.apk).
