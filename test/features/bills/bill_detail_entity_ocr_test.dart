import 'package:flutter_test/flutter_test.dart';
import 'package:paysplit/features/bills/domain/entities/bill_detail_entity.dart';
import 'package:paysplit/features/bills/domain/entities/bill_entity.dart';

void main() {
  group('BillDetailEntity đọc tiến trình OCR', () {
    // Backend chỉ báo OCR hỏng qua `ocr_job`; bản thân `bill` không đổi khi job
    // thất bại. Đánh rơi trường này ở đây là màn hình mất hẳn khả năng phân biệt
    // "AI hỏng" với "AI chạy xong mà không đọc được món nào".
    BillDetailEntity parse(Map<String, dynamic>? ocrJob) {
      return BillDetailEntity.fromJson({
        'id': 'bill-1',
        'group_id': 'group-1',
        'status': 'draft',
        'ocr_job': ?ocrJob,
      });
    }

    test('job thất bại mang cả trạng thái lẫn mã lỗi', () {
      final bill = parse({
        'status': 'failed',
        'error_message': 'schema_invalid',
      });

      expect(bill.ocrStatus, OcrJobStatus.failed);
      expect(bill.ocrErrorCode, 'schema_invalid');
    });

    test('job còn xếp hàng không bị lẫn thành none', () {
      expect(parse({'status': 'queued'}).ocrStatus, OcrJobStatus.queued);
      expect(parse({'status': 'processing'}).ocrStatus, OcrJobStatus.processing);
    });

    test('job thành công không mang mã lỗi', () {
      final bill = parse({'status': 'succeeded'});

      expect(bill.ocrStatus, OcrJobStatus.succeeded);
      expect(bill.ocrErrorCode, isNull);
    });

    test('hóa đơn nhập tay không có ocr_job thì là none', () {
      expect(parse(null).ocrStatus, OcrJobStatus.none);
    });

    test('trạng thái lạ từ backend rơi về none chứ không ném lỗi', () {
      expect(
        parse({'status': 'sap_co_trong_tuong_lai'}).ocrStatus,
        OcrJobStatus.none,
      );
    });
  });
}
