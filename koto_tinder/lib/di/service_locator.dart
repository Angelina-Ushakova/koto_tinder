import 'package:get_it/get_it.dart';
import 'package:koto_tinder/data/datasources/cat_api_datasource.dart';
import 'package:koto_tinder/data/datasources/cat_local_datasource.dart';
import 'package:koto_tinder/data/datasources/connectivity_service.dart';
import 'package:koto_tinder/data/datasources/database_helper.dart';
import 'package:koto_tinder/data/datasources/preferences_datasource.dart';
import 'package:koto_tinder/data/datasources/enhanced_image_cache_service.dart';
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
  // Сервисы
  serviceLocator.registerLazySingleton<ConnectivityService>(
    () => ConnectivityService(),
  );

  serviceLocator.registerLazySingleton<DatabaseHelper>(() => DatabaseHelper());

  serviceLocator.registerLazySingleton<PreferencesDatasource>(
    () => PreferencesDatasource(),
  );

  serviceLocator.registerLazySingleton<EnhancedImageCacheService>(
    () => EnhancedImageCacheService(),
  );

  // Datasources
  serviceLocator.registerLazySingleton<CatLocalDatasource>(
    () => CatLocalDatasource(databaseHelper: serviceLocator<DatabaseHelper>()),
  );

  serviceLocator.registerLazySingleton<CatApiDatasource>(
    () => CatApiDatasource(
      localDatasource: serviceLocator<CatLocalDatasource>(),
      connectivityService: serviceLocator<ConnectivityService>(),
      imageCacheService: serviceLocator<EnhancedImageCacheService>(),
    ),
  );

  // Repositories
  serviceLocator.registerLazySingleton<CatRepository>(
    () => CatRepositoryImpl(
      catApiDatasource: serviceLocator<CatApiDatasource>(),
      catLocalDatasource: serviceLocator<CatLocalDatasource>(),
    ),
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
