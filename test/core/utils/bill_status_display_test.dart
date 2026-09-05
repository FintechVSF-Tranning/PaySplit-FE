import 'package:flutter_test/flutter_test.dart';
import 'package:paysplit/core/utils/bill_status_display.dart';

void main() {
  group('billStatusLabel', () {
    test('reviewed là "Chờ duyệt", không phải "Đã duyệt"', () {
      // `reviewed` nghĩa là đã đối soát xong và đang CHỜ chốt sổ. Ghi "Đã duyệt"
      // là nói ngược: người dùng mở một hóa đơn mình biết chắc chưa xong lại
      // thấy nó báo đã duyệt rồi.
      expect(billStatusLabel('reviewed'), 'Chờ duyệt');
      expect(billStatusLabel('reviewed'), isNot('Đã duyệt'));
    });

    test('đủ bốn trạng thái của backend', () {
      expect(billStatusLabel('draft'), 'Nháp');
      expect(billStatusLabel('finalized'), 'Đã chốt');
      expect(billStatusLabel('voided'), 'Đã hủy');
    });

    test('trạng thái lạ trả về nguyên văn thay vì đoán bừa', () {
      // Đoán bừa thành 'Nháp' là cách một trạng thái mới của backend lặng lẽ
      // hiển thị sai trong nhiều tháng.
      expect(billStatusLabel('settled'), 'settled');
      expect(billStatusLabel(''), '');
    });
  });
}
