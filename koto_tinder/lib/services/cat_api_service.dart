import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:koto_tinder/models/cat.dart';

class CatApiService {
  static const String _baseUrl = 'https://api.thecatapi.com/v1';
  static const String _apiKey =
      'live_LzFDe4gFbL7OwJf2uS2mCHgz3vXiJqXCTUNfKOaTCmhQjTzZuGCuituXxusjnKU1';

  // Простой кеш для избежания повторных запросов к API
  final List<Cat> _cachedCats = [];
  int _currentIndex = 0;

  // Флаг для отслеживания, идет ли загрузка
  bool _isLoading = false;

  Future<Cat> getRandomCat() async {
    // Если у нас уже есть кешированные коты, и мы не прошли весь список
    if (_cachedCats.isNotEmpty && _currentIndex < _cachedCats.length) {
      final cat = _cachedCats[_currentIndex];
      _currentIndex++;

      // Предзагрузка следующей партии, если мы подходим к концу кеша
      if (_currentIndex >= _cachedCats.length - 2) {
        preloadMoreCats();
      }

      return cat;
    }

    // Если мы прошли весь список или кеш пуст, делаем новый запрос
    // Запрашиваем сразу несколько котов для кеширования
    // Вместо использования print будем формировать сообщения в лог
    try {
      const url = '$_baseUrl/images/search?has_breeds=1&limit=10';

      final response = await http
          .get(Uri.parse(url), headers: {'x-api-key': _apiKey})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        if (data.isNotEmpty) {
          // Сохраняем в кеш и сбрасываем индекс
          _cachedCats.clear();
          _cachedCats.addAll(data.map((json) => Cat.fromJson(json)).toList());
          _currentIndex =
          1; // Используем первого кота сейчас, следующего - при следующем вызове
          return _cachedCats[0];
        } else {
          throw Exception('Нет данных о котиках');
        }
      } else {
        throw Exception('Ошибка API: ${response.statusCode}');
      }
    } catch (e) {
      // Если в кеше есть хоть один кот, используем его в случае ошибки
      if (_cachedCats.isNotEmpty) {
        return _cachedCats[0];
      }

      throw Exception('Ошибка подключения: $e');
    }
  }

  /// Асинхронно предзагружает следующую партию котиков
  void preloadMoreCats() async {
    // Если уже идет загрузка или кеш достаточно полон, не делаем ничего
    if (_isLoading || _cachedCats.length - _currentIndex > 5) {
      return;
    }

    _isLoading = true;

    try {
      const url = '$_baseUrl/images/search?has_breeds=1&limit=10';
      final response = await http
          .get(Uri.parse(url), headers: {'x-api-key': _apiKey})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          // Добавляем новых котиков в конец кеша
          _cachedCats.addAll(data.map((json) => Cat.fromJson(json)).toList());
        }
      }
    } catch (e) {
      // Обработка ошибки без использования print
    } finally {
      _isLoading = false;
    }
  }
}
