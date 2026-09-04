# Verify: Thuế, phí, khuyến mãi và đối soát Bill Detail · spec 0004 · updated 2026-09-04

_Các bước được suy ra từ tiêu chí chấp nhận của spec 0004. `/check verify` chạy các bước này, `/test` khóa các hành vi bền vững._

## UI / manual

- [ ] Mở một bill có tổng tiền món gốc, giảm giá từng món, phí, VAT và voucher → thẻ hiển thị đủ bảy dòng theo đúng thứ tự và Tổng cộng thanh toán lấy từ tổng tự tính → AC-UI-5
- [ ] Chạm vào thẻ khi bill được sửa → modal `Phụ phí, Thuế & Khuyến mãi` mở, chỉ có ba ô nhập phí, VAT và voucher, tổng khuyến mãi từng món chỉ đọc và không có ô nhập tổng tiền → AC-UI-5
- [ ] Chọn chip phần trăm cho phí, VAT và voucher trên bill có tiền món thực tế biết trước → mỗi chip dùng tiền món thực tế làm gốc, làm tròn tới VND và live preview cập nhật ngay → AC-UI-5
- [ ] Sửa tay ba giá trị tiền, thử giá trị âm hoặc voucher lớn hơn số tiền còn lại → giá trị được giới hạn hợp lệ và tổng tự tính không nhỏ hơn 0 → AC-UI-5
- [ ] Thay đổi giá trị rồi chọn Hủy → modal đóng và bill không đổi, sau đó mở lại, thay đổi và chọn Lưu áp dụng → thẻ cùng cảnh báo cập nhật ngay và bill được đánh dấu có thay đổi → AC-UI-5, AC-UI-8
- [ ] Mở bill có tổng tự tính thấp hơn tổng hóa đơn → cảnh báo hiển thị đúng số thiếu, chọn Thêm phụ thu → phí dịch vụ tăng đúng phần thiếu, không tạo món mới và cảnh báo chuyển trạng thái ngay → AC-UI-6
- [ ] Mở bill có tổng tự tính cao hơn tổng hóa đơn → cảnh báo hiển thị đúng số dư, chọn Bù vào Voucher → voucher tăng đúng phần dư và cảnh báo chuyển trạng thái ngay → AC-UI-6
- [ ] Trong trạng thái thiếu hoặc dư, chọn Cập nhật Tổng bill → tổng hóa đơn nhận tổng tự tính và cảnh báo chuyển sang khớp → AC-UI-6
- [ ] Mở bill vừa lệch tổng vừa có món chưa gán → cùng một cảnh báo hiển thị cả số tiền lệch và tên cùng số tiền của món chưa gán, thao tác chốt vẫn bị chặn → AC-UI-6, AC-UI-7
- [ ] Mở bill chỉ đọc → thẻ vẫn hiển thị chuỗi tính tiền và cảnh báo, nhưng không mở modal và không có hành động thay đổi tiền → AC-UI-5, AC-UI-7
- [ ] Chạy màn hình ở light theme, dark theme, chiều rộng 320 px và cỡ chữ lớn → nội dung vẫn đọc được, modal cuộn tới hai nút cuối và không tràn ngang → AC-UI-5
- [ ] Mở modal ở chiều rộng 320 px và 360 px với cỡ chữ mặc định → label ngắn nằm cùng hàng với đủ ba chip, không có `(VND)` lặp lại và không tràn ngang → AC-UI-5
- [ ] Mở modal với text scale 1.6 → nhóm chip xuống hàng, chữ và vùng chạm không bị thu nhỏ, modal vẫn cuộn tới hai nút Hủy và Lưu áp dụng → AC-UI-5
- [ ] Lưu nháp sau khi áp dụng điều chỉnh → request hiện tại gửi phí, VAT, voucher, tổng hóa đơn đối soát và version, dữ liệu tải lại khớp phản hồi Backend → AC-UI-8

## Commands

- [ ] `flutter analyze` → kết thúc với mã 0 và không có lỗi phân tích → AC-UI-5, AC-UI-6, AC-UI-7, AC-UI-8
- [ ] `flutter test test/features/bills/presentation/widgets/bill_adjustments_section_test.dart test/features/bills/bill_detail_page_test.dart` → mọi test trọng tâm đạt → AC-UI-5, AC-UI-6, AC-UI-7, AC-UI-8
- [ ] `flutter test` → toàn bộ test của dự án đạt → AC-UI-5, AC-UI-6, AC-UI-7, AC-UI-8

## Acceptance criteria coverage

- AC-UI-5 được kiểm qua chuỗi tính tiền, modal, chip, live preview, giới hạn giá trị, quyền chỉ đọc và giao diện thích ứng.
- AC-UI-6 được kiểm qua trạng thái khớp, thiếu, dư, món chưa gán và ba hành động đối soát.
- AC-UI-7 được kiểm qua quyền chỉnh sửa và điều kiện chặn chốt khi còn món chưa gán hoặc tổng tiền lệch.
- AC-UI-8 được kiểm qua thay đổi local, request lưu nháp có version và dữ liệu tải lại từ Backend.
