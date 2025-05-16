import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:koto_tinder/domain/entities/cat.dart';

class NetworkException implements Exception {
  final String message;

  NetworkException(this.message);

  @override
  String toString() => message;
}

class CatApiDatasource {
  static const String _baseUrl = 'https://api.thecatapi.com/v1';
  static const String _apiKey =
      'live_LzFDe4gFbL7OwJf2uS2mCHgz3vXiJqXCTUNfKOaTCmhQjTzZuGCuituXxusjnKU1';

  // Кэш для хранения ранее загруженных котиков
  final List<Cat> _cachedCats = [];
  int _currentIndex = 0;
  bool _isLoading = false;

  // Метод для проверки соединения
  Future<bool> _checkNetworkConnection() async {
    try {
      final response = await http
          .get(Uri.parse('https://www.google.com'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Метод для получения случайного котика
  Future<Cat> getRandomCat() async {
    // Проверка соединения с интернетом
    if (!await _checkNetworkConnection()) {
      throw NetworkException(
        'Нет подключения к интернету. Проверьте соединение и попробуйте снова.',
      );
    }

    // Если у нас есть кешированные коты и мы не прошли весь список
    if (_cachedCats.isNotEmpty && _currentIndex < _cachedCats.length) {
      final cat = _cachedCats[_currentIndex];
      _currentIndex++;

      // Предзагрузка следующей партии, если мы подходим к концу кеша
      if (_currentIndex >= _cachedCats.length - 2) {
        _preloadMoreCats();
      }

      return cat;
    }

    // Если мы прошли весь список или кеш пуст, делаем новый запрос
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
          throw NetworkException(
            'Нет данных о котиках. Пожалуйста, попробуйте позже.',
          );
        }
      } else {
        throw NetworkException(
          'Ошибка сервера: ${response.statusCode}. Пожалуйста, попробуйте позже.',
        );
      }
    } on SocketException {
      throw NetworkException(
        'Нет подключения к интернету. Проверьте соединение и попробуйте снова.',
      );
    } on HttpException {
      throw NetworkException('Ошибка HTTP. Пожалуйста, попробуйте позже.');
    } on FormatException {
      throw NetworkException(
        'Некорректный формат данных. Пожалуйста, попробуйте позже.',
      );
    } catch (e) {
      throw NetworkException(
        'Произошла ошибка при загрузке данных. Пожалуйста, попробуйте позже.',
      );
    }
  }

  // Асинхронно предзагружаем следующую партию котиков
  void _preloadMoreCats() async {
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
      // Тихая обработка ошибки предзагрузки
    } finally {
      _isLoading = false;
    }
  }

  // Получить список пород (для фильтрации)
  Future<List<String>> getBreeds() async {
    // Проверка соединения с интернетом
    if (!await _checkNetworkConnection()) {
      // Если интернета нет, но у нас есть породы в кэше, возвращаем их
      if (_cachedCats.isNotEmpty) {
        final Set<String> cachedBreeds = {};
        for (var cat in _cachedCats) {
          if (cat.breeds != null && cat.breeds!.isNotEmpty) {
            cachedBreeds.add(cat.breeds![0].name);
          }
        }
        return cachedBreeds.toList()..sort();
      }
      throw NetworkException(
        'Нет подключения к интернету. Проверьте соединение и попробуйте снова.',
      );
    }

    // Собираем уникальные породы из кешированных котиков
    final Set<String> breeds = {};

    for (var cat in _cachedCats) {
      if (cat.breeds != null && cat.breeds!.isNotEmpty) {
        breeds.add(cat.breeds![0].name);
      }
    }

    // Если у нас не достаточно пород в кеше, загрузим больше котиков
    if (breeds.length < 5) {
      try {
        const url = '$_baseUrl/breeds';
        final response = await http
            .get(Uri.parse(url), headers: {'x-api-key': _apiKey})
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final List<dynamic> data = jsonDecode(response.body);
          for (var json in data) {
            if (json['name'] != null) {
              breeds.add(json['name']);
            }
          }
        }
      } catch (e) {
        // Если не удалось загрузить списко пород, возвращаем то, что есть
        if (breeds.isEmpty) {
          throw NetworkException(
            'Ошибка при получении списка пород. Пожалуйста, попробуйте позже.',
          );
        }
      }
    }

    return breeds.toList()..sort();
  }
}
