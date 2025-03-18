import 'package:flutter/foundation.dart' show kIsWeb;

/// Возвращает URL для загрузки изображения с учетом платформы.
/// На веб-платформе использует прокси для обхода CORS-ограничений.
/// На мобильных платформах использует прямую ссылку.
String getOptimizedImageUrl(String originalUrl) {
  if (kIsWeb) {
    // Для веб используем прокси
    return 'https://api.allorigins.win/raw?url=${Uri.encodeComponent(originalUrl)}';
  } else {
    // Для мобильных платформ используем прямую ссылку
    return originalUrl;
  }
}
