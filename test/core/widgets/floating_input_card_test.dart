import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:paysplit/core/widgets/floating_input_card.dart';

void main() {
  Widget host(List<Widget> children) => MaterialApp(
    home: Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(children: children),
      ),
    ),
  );

  group('FloatingInputCard', () {
    testWidgets('bấm vào nhãn — ngoài vùng chữ — vẫn đưa được con trỏ vào ô', (
      tester,
    ) async {
      // Thẻ cao ~64px nhưng vùng chữ thật chỉ là dải giữa bên phải icon. Không
      // có bước nhận cú bấm ở mức cả thẻ thì nhãn, icon và phần đệm đều là vùng
      // chết: giao diện to mà bấm thì trượt.
      final controller = TextEditingController();
      final focusNode = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(focusNode.dispose);

      await tester.pumpWidget(
        host([
          FloatingInputCard(
            controller: controller,
            focusNode: focusNode,
            label: 'Email',
            hintText: 'user@email.com',
            icon: HugeIcons.strokeRoundedMail01,
          ),
        ]),
      );

      expect(focusNode.hasFocus, isFalse);

      await tester.tap(find.text('Email'));
      await tester.pumpAndSettle();

      expect(focusNode.hasFocus, isTrue);
    });

    testWidgets('bấm vào icon bên trái cũng mở được ô nhập', (tester) async {
      final controller = TextEditingController();
      final focusNode = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(focusNode.dispose);

      await tester.pumpWidget(
        host([
          FloatingInputCard(
            controller: controller,
            focusNode: focusNode,
            label: 'Email',
            hintText: 'user@email.com',
            icon: HugeIcons.strokeRoundedMail01,
          ),
        ]),
      );

      await tester.tap(find.byIcon(HugeIcons.strokeRoundedMail01));
      await tester.pumpAndSettle();

      expect(focusNode.hasFocus, isTrue);
    });

    testWidgets('focus rơi thẳng vào EditableText nên bàn phím mới bật', (
      tester,
    ) async {
      // Bọc TextFormField trong một `Focus` phụ khiến node phụ đó giành focus:
      // trên mobile bàn phím không hiện vì thứ đang giữ focus không phải ô chữ.
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        host([
          FloatingInputCard(
            controller: controller,
            label: 'Email',
            hintText: 'user@email.com',
            icon: HugeIcons.strokeRoundedMail01,
          ),
        ]),
      );

      await tester.tap(find.text('Email'));
      await tester.pumpAndSettle();

      // Node đang giữ focus phải chính là node của EditableText, không phải
      // một node bao ngoài mang cùng vùng hiển thị.
      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.focusNode.hasFocus, isTrue);
      expect(
        FocusManager.instance.primaryFocus,
        same(editable.focusNode),
      );
    });

    testWidgets('Tab trên web nhảy từ ô này sang đúng ô kế tiếp', (
      tester,
    ) async {
      final first = TextEditingController();
      final second = TextEditingController();
      final firstNode = FocusNode();
      final secondNode = FocusNode();
      for (final d in [first.dispose, second.dispose]) {
        addTearDown(d);
      }
      for (final d in [firstNode.dispose, secondNode.dispose]) {
        addTearDown(d);
      }

      await tester.pumpWidget(
        host([
          FloatingInputCard(
            controller: first,
            focusNode: firstNode,
            label: 'Email',
            hintText: 'user@email.com',
            icon: HugeIcons.strokeRoundedMail01,
          ),
          const SizedBox(height: 16),
          FloatingInputCard(
            controller: second,
            focusNode: secondNode,
            label: 'Mật khẩu',
            hintText: '••••••••',
            icon: HugeIcons.strokeRoundedLockPassword,
            isPassword: true,
          ),
        ]),
      );

      firstNode.requestFocus();
      await tester.pumpAndSettle();
      expect(firstNode.hasFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      // Một node trung gian trong cây sẽ nuốt lượt Tab này và cả hai ô đều
      // không có focus.
      expect(secondNode.hasFocus, isTrue);
      expect(firstNode.hasFocus, isFalse);
    });

    testWidgets('phím hành động của bàn phím gọi onSubmitted', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      var submitted = 0;

      await tester.pumpWidget(
        host([
          FloatingInputCard(
            controller: controller,
            label: 'Email',
            hintText: 'user@email.com',
            icon: HugeIcons.strokeRoundedMail01,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => submitted++,
          ),
        ]),
      );

      await tester.tap(find.text('Email'));
      await tester.pumpAndSettle();
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pumpAndSettle();

      expect(submitted, 1);
    });

    testWidgets('nút hiện/ẩn mật khẩu không bị cú bấm của thẻ nuốt mất', (
      tester,
    ) async {
      final controller = TextEditingController(text: 'secret');
      final focusNode = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(focusNode.dispose);

      await tester.pumpWidget(
        host([
          FloatingInputCard(
            controller: controller,
            focusNode: focusNode,
            label: 'Mật khẩu',
            hintText: '••••••••',
            icon: HugeIcons.strokeRoundedLockPassword,
            isPassword: true,
          ),
        ]),
      );

      expect(find.byIcon(HugeIcons.strokeRoundedViewOffSlash), findsOneWidget);

      await tester.tap(find.byIcon(HugeIcons.strokeRoundedViewOffSlash));
      await tester.pumpAndSettle();

      expect(find.byIcon(HugeIcons.strokeRoundedView), findsOneWidget);
      // Bấm vào con mắt là để đổi chế độ hiển thị, không phải để mở bàn phím.
      expect(focusNode.hasFocus, isFalse);
    });
  });
}
