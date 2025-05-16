import 'package:koto_tinder/data/datasources/cat_api_datasource.dart';
import 'package:koto_tinder/data/repositories/cat_repository_impl.dart';
import 'package:koto_tinder/domain/repositories/cat_repository.dart';
import 'package:koto_tinder/domain/usecases/get_breeds.dart';
import 'package:koto_tinder/domain/usecases/get_random_cat.dart';
import 'package:koto_tinder/domain/usecases/get_liked_cats.dart';
import 'package:koto_tinder/domain/usecases/like_cat.dart';
import 'package:koto_tinder/domain/usecases/remove_liked_cat.dart';

// Простая реализация DI без использования библиотек
class AppDependencies {
  // Синглтон для AppDependencies
  static final AppDependencies _instance = AppDependencies._internal();

  factory AppDependencies() {
    return _instance;
  }

  AppDependencies._internal() {
    _init();
  }

  // Объекты зависимостей
  late CatApiDatasource catApiDatasource;
  late CatRepository catRepository;
  late GetRandomCatUseCase getRandomCatUseCase;
  late GetLikedCatsUseCase getLikedCatsUseCase;
  late LikeCatUseCase likeCatUseCase;
  late RemoveLikedCatUseCase removeLikedCatUseCase;
  late GetBreedsUseCase getBreedsUseCase;

  // Инициализация зависимостей
  void _init() {
    // Источники данных
    catApiDatasource = CatApiDatasource();

    // Репозитории
    catRepository = CatRepositoryImpl(catApiDatasource: catApiDatasource);

    // Use cases
    getRandomCatUseCase = GetRandomCatUseCase(catRepository: catRepository);

    getLikedCatsUseCase = GetLikedCatsUseCase(catRepository: catRepository);

    likeCatUseCase = LikeCatUseCase(catRepository: catRepository);

    removeLikedCatUseCase = RemoveLikedCatUseCase(catRepository: catRepository);

    getBreedsUseCase = GetBreedsUseCase(catRepository: catRepository);
  }
}

// Получаем экземпляр зависимостей
AppDependencies getDependencies() {
  return AppDependencies();
}
