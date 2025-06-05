import 'package:koto_tinder/data/datasources/database_helper.dart';
import 'package:koto_tinder/domain/entities/cat.dart';

class CatLocalDatasource {
  final DatabaseHelper _databaseHelper;

  CatLocalDatasource({required DatabaseHelper databaseHelper})
    : _databaseHelper = databaseHelper;

  // Методы для работы с лайкнутыми котиками
  Future<void> likeCat(Cat cat) async {
    await _databaseHelper.insertLikedCat(cat);
  }

  Future<void> removeLikedCat(String catId) async {
    await _databaseHelper.deleteLikedCat(catId);
  }

  Future<List<Cat>> getLikedCats() async {
    return await _databaseHelper.getLikedCats();
  }

  Future<List<Cat>> getLikedCatsByBreed(String breed) async {
    return await _databaseHelper.getLikedCatsByBreed(breed);
  }

  Future<List<String>> getLikedCatBreeds() async {
    final cats = await _databaseHelper.getLikedCats();
    final Set<String> breeds = {};

    for (var cat in cats) {
      if (cat.breeds != null && cat.breeds!.isNotEmpty) {
        breeds.add(cat.breeds![0].name);
      }
    }

    final breedsList = breeds.toList()..sort();

    // Добавляем "Все породы" в начало списка
    if (breedsList.isNotEmpty) {
      breedsList.insert(0, '');
    }

    return breedsList;
  }

  // Методы для работы с кэшированными котиками
  Future<void> cacheCat(Cat cat) async {
    await _databaseHelper.insertCachedCat(cat);
  }

  Future<List<Cat>> getCachedCats({int limit = 20}) async {
    return await _databaseHelper.getCachedCats(limit: limit);
  }

  Future<void> clearOldCachedCats({int keepCount = 50}) async {
    await _databaseHelper.clearOldCachedCats(keepCount: keepCount);
  }

  // Получить случайного котика из кэша
  Future<Cat?> getRandomCachedCat() async {
    final cachedCats = await getCachedCats();
    if (cachedCats.isEmpty) return null;

    // Возвращаем случайного котика
    cachedCats.shuffle();
    return cachedCats.first;
  }
}
