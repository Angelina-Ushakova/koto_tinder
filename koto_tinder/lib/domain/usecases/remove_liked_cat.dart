import 'package:koto_tinder/domain/repositories/cat_repository.dart';

class RemoveLikedCatUseCase {
  final CatRepository catRepository;

  RemoveLikedCatUseCase({required this.catRepository});

  Future<void> execute(String catId) {
    return catRepository.removeLikedCat(catId);
  }
}
