import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:koto_tinder/data/datasources/preferences_datasource.dart';
import 'package:koto_tinder/domain/entities/cat.dart';
import 'package:koto_tinder/domain/usecases/get_random_cat.dart';
import 'package:koto_tinder/domain/usecases/like_cat.dart';

// События
abstract class HomeEvent {}

class LoadRandomCatEvent extends HomeEvent {}

class LikeCatEvent extends HomeEvent {
  final Cat cat;

  LikeCatEvent(this.cat);
}

class DislikeCatEvent extends HomeEvent {}

class RetryEvent extends HomeEvent {}

// Состояния
abstract class HomeState {}

class HomeLoadingState extends HomeState {}

class HomeLoadedState extends HomeState {
  final Cat cat;
  final int likeCount;

  HomeLoadedState({required this.cat, required this.likeCount});
}

class HomeErrorState extends HomeState {
  final String message;

  HomeErrorState(this.message);
}

// Блок
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final GetRandomCatUseCase getRandomCatUseCase;
  final LikeCatUseCase likeCatUseCase;
  final PreferencesDatasource preferencesDatasource;
  int _likeCount = 0;

  HomeBloc({
    required this.getRandomCatUseCase,
    required this.likeCatUseCase,
    required this.preferencesDatasource,
  }) : super(HomeLoadingState()) {
    on<LoadRandomCatEvent>(_onLoadRandomCat);
    on<LikeCatEvent>(_onLikeCat);
    on<DislikeCatEvent>(_onDislikeCat);
    on<RetryEvent>(_onRetry);

    // Загружаем счетчик при создании
    _loadLikeCount();
  }

  Future<void> _loadLikeCount() async {
    _likeCount = await preferencesDatasource.getLikeCount();
  }

  Future<void> _onLoadRandomCat(
    LoadRandomCatEvent event,
    Emitter<HomeState> emit,
  ) async {
    emit(HomeLoadingState());
    try {
      final cat = await getRandomCatUseCase.execute();
      // Обновляем счетчик при загрузке
      _likeCount = await preferencesDatasource.getLikeCount();
      emit(HomeLoadedState(cat: cat, likeCount: _likeCount));
    } catch (e) {
      emit(HomeErrorState(e.toString()));
    }
  }

  Future<void> _onLikeCat(LikeCatEvent event, Emitter<HomeState> emit) async {
    try {
      await likeCatUseCase.execute(event.cat);
      await preferencesDatasource.incrementLikeCount();
      _likeCount = await preferencesDatasource.getLikeCount();
      add(LoadRandomCatEvent());
    } catch (e) {
      emit(HomeErrorState(e.toString()));
    }
  }

  Future<void> _onDislikeCat(
    DislikeCatEvent event,
    Emitter<HomeState> emit,
  ) async {
    add(LoadRandomCatEvent());
  }

  Future<void> _onRetry(RetryEvent event, Emitter<HomeState> emit) async {
    add(LoadRandomCatEvent());
  }
}
