import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:koto_tinder/di/service_locator.dart';
import 'package:koto_tinder/domain/usecases/get_breeds.dart';
import 'package:koto_tinder/domain/usecases/get_liked_cats.dart';
import 'package:koto_tinder/domain/usecases/remove_liked_cat.dart';
import 'package:koto_tinder/presentation/blocs/liked_cats/liked_cats_bloc.dart';
import 'package:koto_tinder/presentation/screens/detail_screen.dart';
import 'package:koto_tinder/presentation/widgets/cat_card.dart';
import 'package:koto_tinder/presentation/widgets/error_dialog.dart';

class LikedCatsScreen extends StatefulWidget {
  const LikedCatsScreen({super.key});

  @override
  State<LikedCatsScreen> createState() => _LikedCatsScreenState();
}

class _LikedCatsScreenState extends State<LikedCatsScreen> {
  late LikedCatsBloc _likedCatsBloc;
  String _selectedBreed = '';

  @override
  void initState() {
    super.initState();

    // Получаем зависимости через DI
    _likedCatsBloc = LikedCatsBloc(
      getLikedCatsUseCase: serviceLocator<GetLikedCatsUseCase>(),
      removeLikedCatUseCase: serviceLocator<RemoveLikedCatUseCase>(),
      getBreedsUseCase: serviceLocator<GetBreedsUseCase>(),
    );

    // Загружаем список пород и лайкнутых котиков
    _likedCatsBloc.add(LoadBreedsEvent());
  }

  @override
  void dispose() {
    _likedCatsBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Понравившиеся котики'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: BlocProvider(
        create: (context) => _likedCatsBloc,
        child: BlocConsumer<LikedCatsBloc, LikedCatsState>(
          listener: (context, state) {
            if (state is LikedCatsErrorState) {
              showErrorDialog(
                context,
                state.message,
                () => _likedCatsBloc.add(LoadLikedCatsEvent()),
              );
            }

            // Когда пользователь удаляет последнего котика текущей породы,
            // автоматически сбрасываем фильтр
            if (state is LikedCatsLoadedState &&
                _selectedBreed.isNotEmpty &&
                state.cats.isEmpty) {
              _selectedBreed = '';
              _likedCatsBloc.add(FilterByBreedEvent(''));
            }

            // Отслеживаем выбранную породу
            if (state is LikedCatsLoadedState) {
              _selectedBreed = state.selectedBreed;
            }
          },
          builder: (context, state) {
            if (state is LikedCatsLoadingState) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is LikedCatsLoadedState) {
              return Column(
                children: [
                  // Фильтр по породам
                  if (state.breeds.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Фильтр по породе',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                        ),
                        value:
                            state.selectedBreed.isEmpty
                                ? state.breeds.first
                                : state.selectedBreed,
                        items:
                            state.breeds.map((breed) {
                              return DropdownMenuItem<String>(
                                value: breed,
                                child: Text(
                                  breed.isEmpty ? 'Все породы' : breed,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            _likedCatsBloc.add(FilterByBreedEvent(value));
                          }
                        },
                      ),
                    ),

                  // Список котиков
                  Expanded(
                    child:
                        state.cats.isEmpty
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.favorite_border,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    state.selectedBreed.isEmpty
                                        ? 'У вас пока нет лайкнутых котиков'
                                        : 'Нет лайкнутых котиков выбранной породы',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                            : ListView.builder(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              itemCount: state.cats.length,
                              itemBuilder: (context, index) {
                                final cat = state.cats[index];
                                return CatCard(
                                  cat: cat,
                                  showLikedDate: true,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => DetailScreen(cat: cat),
                                      ),
                                    );
                                  },
                                  onRemove: () {
                                    _likedCatsBloc.add(
                                      RemoveLikedCatEvent(cat.id),
                                    );
                                  },
                                );
                              },
                            ),
                  ),
                ],
              );
            } else {
              return Center(
                child: TextButton(
                  onPressed: () => _likedCatsBloc.add(LoadLikedCatsEvent()),
                  child: const Text('Повторить загрузку'),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
