import 'package:flutter_test/flutter_test.dart';
import 'package:paysplit/features/groups/domain/entities/group_entity.dart';
import 'package:paysplit/features/groups/presentation/widgets/group_avatar.dart';

GroupEntity _group({required String id, required String name}) =>
    GroupEntity(id: id, name: name, memberCount: 1, myBalance: 0, isCaptain: false);

void main() {
  group('GroupEntity.initials', () {
    test('lấy chữ cái đầu của hai từ đầu tiên', () {
      expect(_group(id: 'g1', name: 'Du lịch tháng 12').initials, 'DL');
      expect(_group(id: 'g2', name: 'Nhóm trọ tháng 2').initials, 'NT');
    });

    test('tên một từ chỉ lấy một chữ cái', () {
      expect(_group(id: 'g3', name: 'Team').initials, 'T');
    });

    test('tên rỗng hoặc toàn khoảng trắng vẫn ra giá trị hiển thị được', () {
      expect(_group(id: 'g4', name: '   ').initials, 'PS');
    });
  });

  group('GroupAvatar.paletteFor', () {
    test('cùng một id luôn cho cùng một màu', () {
      final first = GroupAvatar.paletteFor('01a0376c-8e44-781b-ac2f-bfe8b33d6285');
      final second = GroupAvatar.paletteFor('01a0376c-8e44-781b-ac2f-bfe8b33d6285');
      expect(first, second);
    });

    // Các nhóm cùng viết tắt ("Du lịch tháng 9" và "Du lịch tháng 10" đều ra
    // "DL") phải phân biệt được bằng màu nền.
    test('các id khác nhau trải đều trên bảng màu', () {
      final colors = <Object>{};
      for (var i = 0; i < 40; i++) {
        colors.add(GroupAvatar.paletteFor('group-id-$i'));
      }
      expect(colors.length, greaterThan(1));
    });
  });
}
