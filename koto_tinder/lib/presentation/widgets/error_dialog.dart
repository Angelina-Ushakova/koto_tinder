import 'package:flutter/material.dart';

class ErrorDialog extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ErrorDialog({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ошибка'),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Закрыть'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onRetry();
          },
          child: const Text('Повторить'),
        ),
      ],
    );
  }
}

// Функция для показа диалога с ошибкой
void showErrorDialog(
  BuildContext context,
  String message,
  VoidCallback onRetry,
) {
  showDialog(
    context: context,
    builder:
        (context) => ErrorDialog(
          message: _formatErrorMessage(message),
          onRetry: onRetry,
        ),
  );
}

// Функция для форматирования сообщения об ошибке
String _formatErrorMessage(String message) {
  // Упрощаем сообщение об ошибке для пользователя
  if (message.contains('SocketException') ||
      message.contains('Failed host lookup')) {
    return 'Нет подключения к интернету. Проверьте соединение и попробуйте снова.';
  } else if (message.contains('TimeoutException')) {
    return 'Сервер не отвечает. Пожалуйста, попробуйте позже.';
  } else if (message.contains('HttpException')) {
    return 'Ошибка соединения с сервером. Пожалуйста, попробуйте позже.';
  } else if (message.contains('FormatException')) {
    return 'Ошибка данных с сервера. Пожалуйста, попробуйте позже.';
  } else if (message.contains('NetworkException')) {
    // Удаляем префикс 'NetworkException:'
    return message.replaceAll('NetworkException:', '').trim();
  } else {
    return message;
  }
}
