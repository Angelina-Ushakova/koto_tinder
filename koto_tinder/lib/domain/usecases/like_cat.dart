import 'package:koto_tinder/domain/entities/cat.dart';
import 'package:koto_tinder/domain/repositories/cat_repository.dart';

class LikeCatUseCase {
  final CatRepository catRepository;

  LikeCatUseCase({required this.catRepository});

  Future<void> execute(Cat cat) {
    return catRepository.likeCat(cat);
  }
}
