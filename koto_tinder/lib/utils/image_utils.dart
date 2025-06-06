import 'package:flutter/foundation.dart' show kIsWeb;

/// Возвращает URL для загрузки изображения с учетом платформы.
/// На веб-платформе использует прокси для обхода CORS-ограничений.
/// На мобильных платформах использует прямую ссылку.
String getOptimizedImageUrl(String originalUrl) {
  if (kIsWeb) {
    // Для веб используем прокси
    return 'https://api.allorigins.win/raw?url=${Uri.encodeComponent(originalUrl)}';
  } else {
    // Для мобильных платформ используем прямую ссылку БЕЗ ПРОКСИ
    return originalUrl;
  }
}

/// Обрезает query и fragment — для уникального ключа кэширования картинки кота
String normalizeCatImageUrl(String url) {
  final uri = Uri.parse(url);
  return '${uri.scheme}://${uri.host}${uri.path}';
}
