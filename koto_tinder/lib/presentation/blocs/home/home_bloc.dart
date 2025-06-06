import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:koto_tinder/domain/entities/cat.dart';
import 'package:koto_tinder/domain/usecases/get_random_cat.dart';
import 'package:koto_tinder/domain/usecases/like_cat.dart';
import 'package:koto_tinder/domain/usecases/get_liked_cats.dart';

// События
abstract class HomeEvent {}

class LoadRandomCatEvent extends HomeEvent {}

class LikeCatEvent extends HomeEvent {
  final Cat cat;

  LikeCatEvent(this.cat);
}

class DislikeCatEvent extends HomeEvent {}

class RetryEvent extends HomeEvent {}

class UpdateLikeCountEvent extends HomeEvent {}

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
  final GetLikedCatsUseCase getLikedCatsUseCase;

  HomeBloc({
    required this.getRandomCatUseCase,
    required this.likeCatUseCase,
    required this.getLikedCatsUseCase,
  }) : super(HomeLoadingState()) {
    on<LoadRandomCatEvent>(_onLoadRandomCat);
    on<LikeCatEvent>(_onLikeCat);
    on<DislikeCatEvent>(_onDislikeCat);
    on<RetryEvent>(_onRetry);
    on<UpdateLikeCountEvent>(_onUpdateLikeCount);
  }

  Future<void> _onLoadRandomCat(
    LoadRandomCatEvent event,
    Emitter<HomeState> emit,
  ) async {
    emit(HomeLoadingState());
    try {
      final cat = await getRandomCatUseCase.execute();
      // Получаем РЕАЛЬНОЕ количество лайкнутых котиков из базы данных
      final likedCats = await getLikedCatsUseCase.execute();
      emit(HomeLoadedState(cat: cat, likeCount: likedCats.length));
    } catch (e) {
      emit(HomeErrorState(e.toString()));
    }
  }

  Future<void> _onLikeCat(LikeCatEvent event, Emitter<HomeState> emit) async {
    try {
      await likeCatUseCase.execute(event.cat);
      // После лайка загружаем нового котика (и счетчик обновится автоматически)
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

  Future<void> _onUpdateLikeCount(
    UpdateLikeCountEvent event,
    Emitter<HomeState> emit,
  ) async {
    // Обновляем только счетчик, не трогая текущего котика
    if (state is HomeLoadedState) {
      final currentState = state as HomeLoadedState;
      try {
        final likedCats = await getLikedCatsUseCase.execute();
        emit(
          HomeLoadedState(cat: currentState.cat, likeCount: likedCats.length),
        );
      } catch (e) {
        // Если ошибка, оставляем состояние как есть
      }
    }
  }
}
