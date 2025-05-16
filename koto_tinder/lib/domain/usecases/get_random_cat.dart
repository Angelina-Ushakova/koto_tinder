import 'package:koto_tinder/domain/entities/cat.dart';
import 'package:koto_tinder/domain/repositories/cat_repository.dart';

class GetRandomCatUseCase {
  final CatRepository catRepository;

  GetRandomCatUseCase({required this.catRepository});

  Future<Cat> execute() async {
    return await catRepository.getRandomCat();
  }
}
