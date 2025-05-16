import 'package:get_it/get_it.dart';
import 'package:koto_tinder/data/datasources/cat_api_datasource.dart';
import 'package:koto_tinder/data/repositories/cat_repository_impl.dart';
import 'package:koto_tinder/domain/repositories/cat_repository.dart';
import 'package:koto_tinder/domain/usecases/get_breeds.dart';
import 'package:koto_tinder/domain/usecases/get_random_cat.dart';
import 'package:koto_tinder/domain/usecases/get_liked_cats.dart';
import 'package:koto_tinder/domain/usecases/like_cat.dart';
import 'package:koto_tinder/domain/usecases/remove_liked_cat.dart';

// Глобальная переменная для доступа к сервис-локатору
final serviceLocator = GetIt.instance;

// Инициализация зависимостей
void setupServiceLocator() {
  // Datasources
  serviceLocator.registerLazySingleton<CatApiDatasource>(
    () => CatApiDatasource(),
  );

  // Repositories
  serviceLocator.registerLazySingleton<CatRepository>(
    () =>
        CatRepositoryImpl(catApiDatasource: serviceLocator<CatApiDatasource>()),
  );

  // Use cases
  serviceLocator.registerLazySingleton<GetRandomCatUseCase>(
    () => GetRandomCatUseCase(catRepository: serviceLocator<CatRepository>()),
  );

  serviceLocator.registerLazySingleton<GetLikedCatsUseCase>(
    () => GetLikedCatsUseCase(catRepository: serviceLocator<CatRepository>()),
  );

  serviceLocator.registerLazySingleton<LikeCatUseCase>(
    () => LikeCatUseCase(catRepository: serviceLocator<CatRepository>()),
  );

  serviceLocator.registerLazySingleton<RemoveLikedCatUseCase>(
    () => RemoveLikedCatUseCase(catRepository: serviceLocator<CatRepository>()),
  );

  serviceLocator.registerLazySingleton<GetBreedsUseCase>(
    () => GetBreedsUseCase(catRepository: serviceLocator<CatRepository>()),
  );
}
