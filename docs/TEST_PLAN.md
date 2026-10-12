# Kiểm tra Lab 3

| Phần | Thao tác | Kết quả cần đạt |
| --- | --- | --- |
| OCR | Nhận dạng food.png | Tổng 150000; ngày 09/10/2026; không lấy tiền khách đưa |
| OCR | Nhận dạng study.png | Tổng 85000; kiểm tra tên cửa hàng |
| OCR | Hai tổng khác nhau hoặc không có tổng | Yêu cầu người dùng nhập/xác nhận; không tự chọn giá hàng |
| Camera | Chụp, bật/tắt đèn, chạm lấy nét | Ghi kết quả từng thao tác; nêu khả năng camera giả lập |
| Ảnh | Cắt/xoay rồi hủy | Hủy quay lại; xác nhận dùng đúng ảnh đã cắt |
| Isar | Thêm, đóng app, mở lại | Khoản chi và ảnh còn |
| Isar | Sửa rồi xóa | Tổng cập nhật; ảnh khoản xóa được dọn |
| Dữ liệu | Tiền âm, 0, định dạng sai | Không lưu; có thông báo lỗi |
| Lọc | Ngày/danh mục/tên cửa hàng | Danh sách và biểu đồ dùng cùng bộ lọc |
| Biểu đồ | Tuần qua ranh giới tháng | Thứ hai đến chủ nhật; loại ngày ngoài tuần |
| Offline | Bật chế độ máy bay Android, OCR/lưu | Nhận dạng với model đóng gói; dữ liệu local hoạt động |
| Hiệu năng | Nhận dạng cùng ảnh 5 lần | Ghi lần đầu và 4 lần sau; không tự ghi dưới 100 ms |
| APK | Cài release và mở | Không crash; kiểm tra lại luồng chính |

`flutter test` kiểm tra nghiệp vụ và Isar trên máy chạy test. Lệnh integration_test mới kiểm tra ML Kit và Isar trên Android. Camera/crop, force stop và video cần thao tác thực tế; không suy kết quả từ unit test.
