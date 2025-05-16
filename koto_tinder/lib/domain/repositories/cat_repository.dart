import 'package:koto_tinder/domain/entities/cat.dart';

abstract class CatRepository {
  Future<Cat> getRandomCat();
  Future<List<Cat>> getLikedCats();
  Future<void> likeCat(Cat cat);
  Future<void> removeLikedCat(String catId);
  Future<List<String>> getBreeds();
  Future<List<String>> getLikedCatBreeds();
  Future<List<Cat>> getLikedCatsByBreed(String breed);
  void resetErrorState();
}
