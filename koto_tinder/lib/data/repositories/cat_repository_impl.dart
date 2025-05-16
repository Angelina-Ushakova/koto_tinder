import 'package:koto_tinder/data/datasources/cat_api_datasource.dart';
import 'package:koto_tinder/domain/entities/cat.dart';
import 'package:koto_tinder/domain/repositories/cat_repository.dart';

class CatRepositoryImpl implements CatRepository {
  final CatApiDatasource catApiDatasource;

  // Хранилище для лайкнутых котиков (только в памяти)
  final List<Cat> _likedCats = [];

  CatRepositoryImpl({required this.catApiDatasource});

  @override
  Future<Cat> getRandomCat() async {
    try {
      final cat = await catApiDatasource.getRandomCat();
      return cat;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<Cat>> getLikedCats() async {
    // Сортируем по времени лайка (сначала новые)
    _likedCats.sort(
      (a, b) =>
          (b.likedAt ?? DateTime.now()).compareTo(a.likedAt ?? DateTime.now()),
    );
    return _likedCats;
  }

  @override
  Future<void> likeCat(Cat cat) async {
    // Проверяем, есть ли уже такой котик в списке лайкнутых
    if (!_likedCats.any((likedCat) => likedCat.id == cat.id)) {
      // Устанавливаем время лайка, если его нет
      final likedCat =
          cat.likedAt == null ? cat.copyWith(likedAt: DateTime.now()) : cat;
      _likedCats.add(likedCat);
    }
  }

  @override
  Future<void> removeLikedCat(String catId) async {
    _likedCats.removeWhere((cat) => cat.id == catId);
  }

  @override
  Future<List<String>> getBreeds() {
    return catApiDatasource.getBreeds();
  }

  @override
  Future<List<String>> getLikedCatBreeds() async {
    final Set<String> breeds = {};

    for (var cat in _likedCats) {
      if (cat.breeds != null && cat.breeds!.isNotEmpty) {
        breeds.add(cat.breeds![0].name);
      }
    }

    return breeds.toList()..sort();
  }

  @override
  Future<List<Cat>> getLikedCatsByBreed(String breed) async {
    if (breed.isEmpty) {
      return getLikedCats();
    }

    return _likedCats
        .where(
          (cat) =>
              cat.breeds != null &&
              cat.breeds!.isNotEmpty &&
              cat.breeds![0].name == breed,
        )
        .toList()
      ..sort(
        (a, b) => (b.likedAt ?? DateTime.now()).compareTo(
          a.likedAt ?? DateTime.now(),
        ),
      );
  }

  @override
  void resetErrorState() {
    // Ничего не делаем, так как это уже не нужно
  }
}
