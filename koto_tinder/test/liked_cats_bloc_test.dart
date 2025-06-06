import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:koto_tinder/domain/entities/cat.dart';
import 'package:koto_tinder/domain/usecases/get_breeds.dart';
import 'package:koto_tinder/domain/usecases/get_liked_cats.dart';
import 'package:koto_tinder/domain/usecases/remove_liked_cat.dart';
import 'package:koto_tinder/presentation/blocs/liked_cats/liked_cats_bloc.dart';

import 'liked_cats_bloc_test.mocks.dart';

@GenerateMocks([GetLikedCatsUseCase, RemoveLikedCatUseCase, GetBreedsUseCase])
void main() {
  group('LikedCatsBloc', () {
    late LikedCatsBloc likedCatsBloc;
    late MockGetLikedCatsUseCase mockGetLikedCatsUseCase;
    late MockRemoveLikedCatUseCase mockRemoveLikedCatUseCase;
    late MockGetBreedsUseCase mockGetBreedsUseCase;

    // Тестовые данные
    final testBreed1 = Breed(
      id: 'breed1',
      name: 'Persian',
      description: 'Persian cat',
      temperament: 'Calm',
      origin: 'Iran',
      lifeSpan: '12-17',
    );

    final testBreed2 = Breed(
      id: 'breed2',
      name: 'Siamese',
      description: 'Siamese cat',
      temperament: 'Active',
      origin: 'Thailand',
      lifeSpan: '10-15',
    );

    final testCat1 = Cat(
      id: 'cat1',
      url: 'https://example.com/cat1.jpg',
      breeds: [testBreed1],
      likedAt: DateTime(2024, 1, 1, 12, 0),
    );

    final testCat2 = Cat(
      id: 'cat2',
      url: 'https://example.com/cat2.jpg',
      breeds: [testBreed2],
      likedAt: DateTime(2024, 1, 2, 13, 0),
    );

    final testCats = [testCat1, testCat2];
    final testBreeds = ['', 'Persian', 'Siamese'];

    setUp(() {
      mockGetLikedCatsUseCase = MockGetLikedCatsUseCase();
      mockRemoveLikedCatUseCase = MockRemoveLikedCatUseCase();
      mockGetBreedsUseCase = MockGetBreedsUseCase();
    });

    tearDown(() {
      if (likedCatsBloc.isClosed == false) {
        likedCatsBloc.close();
      }
    });

    test('initial state is LikedCatsLoadingState', () {
      likedCatsBloc = LikedCatsBloc(
        getLikedCatsUseCase: mockGetLikedCatsUseCase,
        removeLikedCatUseCase: mockRemoveLikedCatUseCase,
        getBreedsUseCase: mockGetBreedsUseCase,
      );

      expect(likedCatsBloc.state, isA<LikedCatsLoadingState>());
    });

    group('LoadLikedCatsEvent', () {
      blocTest<LikedCatsBloc, LikedCatsState>(
        'emits [LikedCatsLoadingState, LikedCatsLoadedState] when loading cats succeeds',
        setUp: () {
          when(
            mockGetLikedCatsUseCase.execute(),
          ).thenAnswer((_) async => testCats);
        },
        build:
            () => LikedCatsBloc(
              getLikedCatsUseCase: mockGetLikedCatsUseCase,
              removeLikedCatUseCase: mockRemoveLikedCatUseCase,
              getBreedsUseCase: mockGetBreedsUseCase,
            ),
        act: (bloc) => bloc.add(LoadLikedCatsEvent()),
        expect:
            () => [
              isA<LikedCatsLoadingState>(),
              isA<LikedCatsLoadedState>()
                  .having((state) => state.cats, 'cats', testCats)
                  .having((state) => state.selectedBreed, 'selectedBreed', ''),
            ],
        verify: (_) {
          verify(mockGetLikedCatsUseCase.execute()).called(1);
        },
      );

      blocTest<LikedCatsBloc, LikedCatsState>(
        'emits error state when loading cats fails',
        setUp: () {
          when(
            mockGetLikedCatsUseCase.execute(),
          ).thenThrow(Exception('Database error'));
        },
        build:
            () => LikedCatsBloc(
              getLikedCatsUseCase: mockGetLikedCatsUseCase,
              removeLikedCatUseCase: mockRemoveLikedCatUseCase,
              getBreedsUseCase: mockGetBreedsUseCase,
            ),
        act: (bloc) => bloc.add(LoadLikedCatsEvent()),
        expect:
            () => [
              isA<LikedCatsLoadingState>(),
              isA<LikedCatsErrorState>().having(
                (state) => state.message,
                'message',
                contains('Exception'),
              ),
            ],
      );
    });

    group('RemoveLikedCatEvent', () {
      blocTest<LikedCatsBloc, LikedCatsState>(
        'successfully removes cat and reloads list',
        setUp: () {
          when(
            mockRemoveLikedCatUseCase.execute('cat1'),
          ).thenAnswer((_) async => {});
          when(
            mockGetLikedCatsUseCase.execute(),
          ).thenAnswer((_) async => [testCat2]);
          when(
            mockGetBreedsUseCase.executeFromLikedCats(),
          ).thenAnswer((_) async => ['', 'Siamese']);
        },
        build:
            () => LikedCatsBloc(
              getLikedCatsUseCase: mockGetLikedCatsUseCase,
              removeLikedCatUseCase: mockRemoveLikedCatUseCase,
              getBreedsUseCase: mockGetBreedsUseCase,
            ),
        seed:
            () => LikedCatsLoadedState(
              cats: testCats,
              breeds: testBreeds,
              selectedBreed: '',
            ),
        act: (bloc) => bloc.add(RemoveLikedCatEvent('cat1')),
        expect:
            () => [
              isA<LikedCatsLoadingState>(),
              isA<LikedCatsLoadedState>().having(
                (state) => state.cats,
                'cats',
                [testCat2],
              ),
            ],
        verify: (_) {
          verify(mockRemoveLikedCatUseCase.execute('cat1')).called(1);
          // execute() вызывается 2 раза: один для проверки котиков породы, один для LoadLikedCatsEvent
          verify(mockGetLikedCatsUseCase.execute()).called(2);
          verify(mockGetBreedsUseCase.executeFromLikedCats()).called(1);
        },
      );

      blocTest<LikedCatsBloc, LikedCatsState>(
        'emits error state when removing cat fails',
        setUp: () {
          when(
            mockRemoveLikedCatUseCase.execute('cat1'),
          ).thenThrow(Exception('Database error'));
        },
        build:
            () => LikedCatsBloc(
              getLikedCatsUseCase: mockGetLikedCatsUseCase,
              removeLikedCatUseCase: mockRemoveLikedCatUseCase,
              getBreedsUseCase: mockGetBreedsUseCase,
            ),
        seed:
            () => LikedCatsLoadedState(
              cats: testCats,
              breeds: testBreeds,
              selectedBreed: '',
            ),
        act: (bloc) => bloc.add(RemoveLikedCatEvent('cat1')),
        expect:
            () => [
              isA<LikedCatsErrorState>().having(
                (state) => state.message,
                'message',
                contains('Exception'),
              ),
            ],
      );
    });

    group('LoadBreedsEvent', () {
      blocTest<LikedCatsBloc, LikedCatsState>(
        'loads breeds and then loads cats',
        setUp: () {
          when(
            mockGetBreedsUseCase.executeFromLikedCats(),
          ).thenAnswer((_) async => testBreeds);
          when(
            mockGetLikedCatsUseCase.execute(),
          ).thenAnswer((_) async => testCats);
        },
        build:
            () => LikedCatsBloc(
              getLikedCatsUseCase: mockGetLikedCatsUseCase,
              removeLikedCatUseCase: mockRemoveLikedCatUseCase,
              getBreedsUseCase: mockGetBreedsUseCase,
            ),
        act: (bloc) => bloc.add(LoadBreedsEvent()),
        expect:
            () => [
              isA<LikedCatsLoadingState>(),
              isA<LikedCatsLoadedState>()
                  .having((state) => state.breeds, 'breeds', testBreeds)
                  .having((state) => state.cats, 'cats', testCats),
            ],
        verify: (_) {
          verify(mockGetBreedsUseCase.executeFromLikedCats()).called(1);
          verify(mockGetLikedCatsUseCase.execute()).called(1);
        },
      );
    });

    group('FilterByBreedEvent', () {
      blocTest<LikedCatsBloc, LikedCatsState>(
        'filters cats by breed',
        setUp: () {
          when(
            mockGetLikedCatsUseCase.executeByBreed('Persian'),
          ).thenAnswer((_) async => [testCat1]);
        },
        build:
            () => LikedCatsBloc(
              getLikedCatsUseCase: mockGetLikedCatsUseCase,
              removeLikedCatUseCase: mockRemoveLikedCatUseCase,
              getBreedsUseCase: mockGetBreedsUseCase,
            ),
        seed:
            () => LikedCatsLoadedState(
              cats: testCats,
              breeds: testBreeds,
              selectedBreed: '',
            ),
        act: (bloc) => bloc.add(FilterByBreedEvent('Persian')),
        expect:
            () => [
              isA<LikedCatsLoadingState>(),
              isA<LikedCatsLoadedState>()
                  .having((state) => state.cats, 'cats', [testCat1])
                  .having(
                    (state) => state.selectedBreed,
                    'selectedBreed',
                    'Persian',
                  ),
            ],
        verify: (_) {
          verify(mockGetLikedCatsUseCase.executeByBreed('Persian')).called(1);
        },
      );

      blocTest<LikedCatsBloc, LikedCatsState>(
        'shows all cats when filtering by empty breed',
        setUp: () {
          when(
            mockGetLikedCatsUseCase.execute(),
          ).thenAnswer((_) async => testCats);
        },
        build:
            () => LikedCatsBloc(
              getLikedCatsUseCase: mockGetLikedCatsUseCase,
              removeLikedCatUseCase: mockRemoveLikedCatUseCase,
              getBreedsUseCase: mockGetBreedsUseCase,
            ),
        seed:
            () => LikedCatsLoadedState(
              cats: [testCat1],
              breeds: testBreeds,
              selectedBreed: 'Persian',
            ),
        act: (bloc) => bloc.add(FilterByBreedEvent('')),
        expect:
            () => [
              isA<LikedCatsLoadingState>(),
              isA<LikedCatsLoadedState>()
                  .having((state) => state.cats, 'cats', testCats)
                  .having((state) => state.selectedBreed, 'selectedBreed', ''),
            ],
        verify: (_) {
          verify(mockGetLikedCatsUseCase.execute()).called(1);
        },
      );
    });
  });
}
