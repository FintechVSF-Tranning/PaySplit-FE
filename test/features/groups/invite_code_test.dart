import 'package:flutter_test/flutter_test.dart';
import 'package:paysplit/features/groups/domain/invite_code.dart';

void main() {
  group('extractInviteCode', () {
    // Mã thật của backend là Base62 phân biệt hoa thường; viết hoa mã sẽ khiến
    // GET /groups/invites/{code} trả 404 INVITE_NOT_FOUND.
    test('giữ nguyên hoa thường của mã', () {
      expect(extractInviteCode('xuRWai09'), 'xuRWai09');
      expect(extractInviteCode('https://paysplit.app/j/vkaWVmeW'), 'vkaWVmeW');
    });

    test('tách mã khỏi link đầy đủ', () {
      expect(extractInviteCode('https://paysplit.app/j/pt1sRukj'), 'pt1sRukj');
      expect(extractInviteCode('paysplit.app/j/pt1sRukj'), 'pt1sRukj');
    });

    test('bỏ khoảng trắng, dấu / thừa, query và fragment', () {
      expect(extractInviteCode('  https://paysplit.app/j/xuRWai09/  '), 'xuRWai09');
      expect(extractInviteCode('https://paysplit.app/j/xuRWai09?utm=zalo'), 'xuRWai09');
      expect(extractInviteCode('https://paysplit.app/j/xuRWai09#top'), 'xuRWai09');
    });

    test('mọi mã hợp lệ đều đúng độ dài quy ước', () {
      expect(extractInviteCode('https://paysplit.app/j/xuRWai09').length, kInviteCodeLength);
    });
  });
}
