import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koto_tinder/presentation/widgets/like_dislike_button.dart';
import 'package:koto_tinder/presentation/widgets/error_dialog.dart';

void main() {
  group('Widget Tests', () {
    testWidgets('LikeDislikeButton should display icon and respond to tap', (
      WidgetTester tester,
    ) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LikeDislikeButton(
              icon: Icons.favorite,
              color: Colors.red,
              onPressed: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      // Проверяем, что кнопка отображается
      expect(find.byType(LikeDislikeButton), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsOneWidget);

      // Нажимаем на кнопку
      await tester.tap(find.byType(LikeDislikeButton));
      await tester.pump();

      // Проверяем, что обработчик вызвался
      expect(tapped, isTrue);
    });

    testWidgets('LikeDislikeButton should display correct icon color', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LikeDislikeButton(
              icon: Icons.close,
              color: Colors.green,
              onPressed: () {},
            ),
          ),
        ),
      );

      // Находим Icon виджет
      final iconWidget = tester.widget<Icon>(find.byIcon(Icons.close));

      // Проверяем цвет
      expect(iconWidget.color, equals(Colors.green));
    });

    testWidgets('ErrorDialog should display message and buttons', (
      WidgetTester tester,
    ) async {
      bool retryPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorDialog(
              message: 'Test error message',
              onRetry: () {
                retryPressed = true;
              },
            ),
          ),
        ),
      );

      // Проверяем, что диалог отображается
      expect(find.text('Ошибка'), findsOneWidget);
      expect(find.text('Test error message'), findsOneWidget);
      expect(find.text('Закрыть'), findsOneWidget);
      expect(find.text('Повторить'), findsOneWidget);

      // Нажимаем на кнопку "Повторить"
      await tester.tap(find.text('Повторить'));
      await tester.pump();

      // Проверяем, что обработчик вызвался
      expect(retryPressed, isTrue);
    });
  });
}
