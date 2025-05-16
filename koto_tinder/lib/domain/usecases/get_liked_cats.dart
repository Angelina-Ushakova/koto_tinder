import 'package:koto_tinder/domain/entities/cat.dart';
import 'package:koto_tinder/domain/repositories/cat_repository.dart';

class GetLikedCatsUseCase {
  final CatRepository catRepository;

  GetLikedCatsUseCase({required this.catRepository});

  Future<List<Cat>> execute() {
    return catRepository.getLikedCats();
  }

  Future<List<Cat>> executeByBreed(String breed) {
    return catRepository.getLikedCatsByBreed(breed);
  }
}
