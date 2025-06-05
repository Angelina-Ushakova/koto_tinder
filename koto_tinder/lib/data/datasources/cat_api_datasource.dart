import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:koto_tinder/data/datasources/cat_local_datasource.dart';
import 'package:koto_tinder/data/datasources/connectivity_service.dart';
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

  final CatLocalDatasource _localDatasource;
  final ConnectivityService _connectivityService;

  // Кэш для хранения ранее загруженных котиков в памяти
  final List<Cat> _cachedCats = [];
  int _currentIndex = 0;
  bool _isLoading = false;

  CatApiDatasource({
    required CatLocalDatasource localDatasource,
    required ConnectivityService connectivityService,
  }) : _localDatasource = localDatasource,
       _connectivityService = connectivityService;

  // Метод для получения случайного котика
  Future<Cat> getRandomCat() async {
    final bool isConnected = await _connectivityService.isConnected;

    // Если есть интернет, пытаемся загрузить новых котиков
    if (isConnected) {
      try {
        return await _getRandomCatFromApi();
      } catch (e) {
        // Если API недоступен, падаем на кэш
        return await _getRandomCatFromCache();
      }
    } else {
      // Нет интернета - работаем с кэшем
      return await _getRandomCatFromCache();
    }
  }

  // Получение котика из API
  Future<Cat> _getRandomCatFromApi() async {
    // Если у нас есть кешированные коты в памяти и мы не прошли весь список
    if (_cachedCats.isNotEmpty && _currentIndex < _cachedCats.length) {
      final cat = _cachedCats[_currentIndex];
      _currentIndex++;

      // Сохраняем в локальную базу данных
      await _localDatasource.cacheCat(cat);

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
          // Сохраняем в кеш памяти и сбрасываем индекс
          _cachedCats.clear();
          _cachedCats.addAll(data.map((json) => Cat.fromJson(json)).toList());
          _currentIndex = 1;

          final cat = _cachedCats[0];

          // Сохраняем всех котиков в локальную базу данных
          for (final cachedCat in _cachedCats) {
            await _localDatasource.cacheCat(cachedCat);
          }

          // Очищаем старый кэш
          await _localDatasource.clearOldCachedCats();

          return cat;
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

  // Получение котика из кэша
  Future<Cat> _getRandomCatFromCache() async {
    final cachedCat = await _localDatasource.getRandomCachedCat();
    if (cachedCat != null) {
      return cachedCat;
    } else {
      throw NetworkException(
        'Нет сохраненных котиков. Подключитесь к интернету для загрузки новых котиков.',
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
          final newCats = data.map((json) => Cat.fromJson(json)).toList();
          _cachedCats.addAll(newCats);

          // Сохраняем в локальную базу данных
          for (final cat in newCats) {
            await _localDatasource.cacheCat(cat);
          }
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
    final bool isConnected = await _connectivityService.isConnected;

    if (!isConnected) {
      // Если интернета нет, возвращаем породы из кэша
      final cachedCats = await _localDatasource.getCachedCats();
      final Set<String> cachedBreeds = {};
      for (var cat in cachedCats) {
        if (cat.breeds != null && cat.breeds!.isNotEmpty) {
          cachedBreeds.add(cat.breeds![0].name);
        }
      }
      return cachedBreeds.toList()..sort();
    }

    // Собираем уникальные породы из кешированных котиков в памяти
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
        // Если не удалось загрузить список пород, возвращаем то, что есть
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
