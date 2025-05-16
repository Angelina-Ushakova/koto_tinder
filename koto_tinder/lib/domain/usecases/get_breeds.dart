import 'package:koto_tinder/domain/repositories/cat_repository.dart';

class GetBreedsUseCase {
  final CatRepository catRepository;

  GetBreedsUseCase({required this.catRepository});

  // Получить все породы
  Future<List<String>> execute() {
    return catRepository.getBreeds();
  }

  // Получить только породы лайкнутых котиков
  Future<List<String>> executeFromLikedCats() async {
    final likedCats = await catRepository.getLikedCats();
    final Set<String> breeds = {};

    // Собираем уникальные породы из лайкнутых котиков
    for (var cat in likedCats) {
      if (cat.breeds != null && cat.breeds!.isNotEmpty) {
        breeds.add(cat.breeds![0].name);
      }
    }

    // Сортируем и возвращаем
    final breedsList = breeds.toList()..sort();

    // Добавляем "Все породы" в начало списка
    if (breedsList.isNotEmpty) {
      breedsList.insert(0, '');
    }

    return breedsList;
  }
}
