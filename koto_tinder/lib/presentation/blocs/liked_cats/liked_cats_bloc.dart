import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:koto_tinder/domain/entities/cat.dart';
import 'package:koto_tinder/domain/usecases/get_breeds.dart';
import 'package:koto_tinder/domain/usecases/get_liked_cats.dart';
import 'package:koto_tinder/domain/usecases/remove_liked_cat.dart';

// События
abstract class LikedCatsEvent {}

class LoadLikedCatsEvent extends LikedCatsEvent {}

class RemoveLikedCatEvent extends LikedCatsEvent {
  final String catId;

  RemoveLikedCatEvent(this.catId);
}

class LoadBreedsEvent extends LikedCatsEvent {}

class FilterByBreedEvent extends LikedCatsEvent {
  final String breed;

  FilterByBreedEvent(this.breed);
}

// Состояния
abstract class LikedCatsState {}

class LikedCatsLoadingState extends LikedCatsState {}

class LikedCatsLoadedState extends LikedCatsState {
  final List<Cat> cats;
  final List<String> breeds;
  final String selectedBreed;

  LikedCatsLoadedState({
    required this.cats,
    required this.breeds,
    this.selectedBreed = '',
  });
}

class LikedCatsErrorState extends LikedCatsState {
  final String message;

  LikedCatsErrorState(this.message);
}

// Блок
class LikedCatsBloc extends Bloc<LikedCatsEvent, LikedCatsState> {
  final GetLikedCatsUseCase getLikedCatsUseCase;
  final RemoveLikedCatUseCase removeLikedCatUseCase;
  final GetBreedsUseCase getBreedsUseCase;

  String _selectedBreed = '';
  List<String> _breeds = [];

  LikedCatsBloc({
    required this.getLikedCatsUseCase,
    required this.removeLikedCatUseCase,
    required this.getBreedsUseCase,
  }) : super(LikedCatsLoadingState()) {
    on<LoadLikedCatsEvent>(_onLoadLikedCats);
    on<RemoveLikedCatEvent>(_onRemoveLikedCat);
    on<LoadBreedsEvent>(_onLoadBreeds);
    on<FilterByBreedEvent>(_onFilterByBreed);
  }

  Future<void> _onLoadLikedCats(
    LoadLikedCatsEvent event,
    Emitter<LikedCatsState> emit,
  ) async {
    emit(LikedCatsLoadingState());
    try {
      final cats =
          _selectedBreed.isEmpty
              ? await getLikedCatsUseCase.execute()
              : await getLikedCatsUseCase.executeByBreed(_selectedBreed);

      // Если у выбранной породы нет котиков, сбросим фильтр
      if (cats.isEmpty && _selectedBreed.isNotEmpty) {
        _selectedBreed = '';
        final allCats = await getLikedCatsUseCase.execute();
        emit(
          LikedCatsLoadedState(
            cats: allCats,
            breeds: _breeds,
            selectedBreed: _selectedBreed,
          ),
        );
      } else {
        emit(
          LikedCatsLoadedState(
            cats: cats,
            breeds: _breeds,
            selectedBreed: _selectedBreed,
          ),
        );
      }
    } catch (e) {
      emit(LikedCatsErrorState('Ошибка загрузки списка: ${e.toString()}'));
    }
  }

  Future<void> _onRemoveLikedCat(
    RemoveLikedCatEvent event,
    Emitter<LikedCatsState> emit,
  ) async {
    try {
      await removeLikedCatUseCase.execute(event.catId);

      // Проверяем, остались ли котики выбранной породы
      final allCats = await getLikedCatsUseCase.execute();

      // Если нет котиков выбранной породы, сбросим фильтр
      if (_selectedBreed.isNotEmpty &&
          !allCats.any(
            (cat) =>
                cat.breeds != null &&
                cat.breeds!.isNotEmpty &&
                cat.breeds![0].name == _selectedBreed,
          )) {
        _selectedBreed = '';
      }

      // Обновляем список пород
      _breeds = await getBreedsUseCase.executeFromLikedCats();

      // Если в списке пород нет выбранной породы, сбрасываем фильтр
      if (_selectedBreed.isNotEmpty && !_breeds.contains(_selectedBreed)) {
        _selectedBreed = '';
      }

      // Обновляем список котиков
      add(LoadLikedCatsEvent());
    } catch (e) {
      emit(LikedCatsErrorState('Ошибка при удалении котика: ${e.toString()}'));
    }
  }

  Future<void> _onLoadBreeds(
    LoadBreedsEvent event,
    Emitter<LikedCatsState> emit,
  ) async {
    try {
      // Получаем только породы лайкнутых котиков
      _breeds = await getBreedsUseCase.executeFromLikedCats();

      // Всегда добавляем "Все породы" в начало списка
      if (!_breeds.contains('')) {
        _breeds.insert(0, '');
      }

      add(LoadLikedCatsEvent());
    } catch (e) {
      emit(LikedCatsErrorState('Ошибка загрузки пород: ${e.toString()}'));
    }
  }

  Future<void> _onFilterByBreed(
    FilterByBreedEvent event,
    Emitter<LikedCatsState> emit,
  ) async {
    _selectedBreed = event.breed;
    add(LoadLikedCatsEvent());
  }
}
