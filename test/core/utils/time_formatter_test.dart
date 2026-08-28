import 'package:flutter_test/flutter_test.dart';
import 'package:paysplit/core/utils/time_formatter.dart';

void main() {
  group('TimeFormatter Tests', () {
    group('formatRemainingCooldown', () {
      test('returns empty string when seconds <= 0', () {
        expect(TimeFormatter.formatRemainingCooldown(0), '');
        expect(TimeFormatter.formatRemainingCooldown(-10), '');
      });

      test('formats hours concisely (e.g. 22h, 1h)', () {
        expect(TimeFormatter.formatRemainingCooldown(22 * 3600), '22h');
        expect(TimeFormatter.formatRemainingCooldown(22 * 3600 + 1800), '22h');
        expect(TimeFormatter.formatRemainingCooldown(1 * 3600), '1h');
      });

      test('formats minutes concisely (e.g. 45p, 1p)', () {
        expect(TimeFormatter.formatRemainingCooldown(45 * 60), '45p');
        expect(TimeFormatter.formatRemainingCooldown(1 * 60), '1p');
        expect(TimeFormatter.formatRemainingCooldown(65), '1p');
      });

      test('formats seconds concisely (e.g. 45s, 1s)', () {
        expect(TimeFormatter.formatRemainingCooldown(45), '45s');
        expect(TimeFormatter.formatRemainingCooldown(1), '1s');
      });
    });

    group('formatRemainingCooldownDetailed', () {
      test('returns "ngay bây giờ" when seconds <= 0', () {
        expect(TimeFormatter.formatRemainingCooldownDetailed(0), 'ngay bây giờ');
        expect(TimeFormatter.formatRemainingCooldownDetailed(-5), 'ngay bây giờ');
      });

      test('formats hours and minutes in Vietnamese', () {
        expect(
          TimeFormatter.formatRemainingCooldownDetailed(22 * 3600),
          '22 giờ',
        );
        expect(
          TimeFormatter.formatRemainingCooldownDetailed(22 * 3600 + 30 * 60),
          '22 giờ 30 phút',
        );
      });

      test('formats minutes and seconds in Vietnamese', () {
        expect(
          TimeFormatter.formatRemainingCooldownDetailed(1 * 60 + 30),
          '1 phút 30 giây',
        );
        expect(
          TimeFormatter.formatRemainingCooldownDetailed(1 * 60),
          '1 phút',
        );
      });

      test('formats seconds in Vietnamese', () {
        expect(
          TimeFormatter.formatRemainingCooldownDetailed(45),
          '45 giây',
        );
      });
    });
  });
}
