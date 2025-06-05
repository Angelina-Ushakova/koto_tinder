import 'package:koto_tinder/data/datasources/cat_api_datasource.dart';
import 'package:koto_tinder/data/datasources/cat_local_datasource.dart';
import 'package:koto_tinder/domain/entities/cat.dart';
import 'package:koto_tinder/domain/repositories/cat_repository.dart';

class CatRepositoryImpl implements CatRepository {
  final CatApiDatasource catApiDatasource;
  final CatLocalDatasource catLocalDatasource;

  CatRepositoryImpl({
    required this.catApiDatasource,
    required this.catLocalDatasource,
  });

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
    return await catLocalDatasource.getLikedCats();
  }

  @override
  Future<void> likeCat(Cat cat) async {
    // Устанавливаем время лайка, если его нет
    final likedCat =
        cat.likedAt == null ? cat.copyWith(likedAt: DateTime.now()) : cat;
    await catLocalDatasource.likeCat(likedCat);
  }

  @override
  Future<void> removeLikedCat(String catId) async {
    await catLocalDatasource.removeLikedCat(catId);
  }

  @override
  Future<List<String>> getBreeds() {
    return catApiDatasource.getBreeds();
  }

  @override
  Future<List<String>> getLikedCatBreeds() async {
    return await catLocalDatasource.getLikedCatBreeds();
  }

  @override
  Future<List<Cat>> getLikedCatsByBreed(String breed) async {
    return await catLocalDatasource.getLikedCatsByBreed(breed);
  }

  @override
  void resetErrorState() {
    // Ничего не делаем, так как это уже не нужно
  }
}
