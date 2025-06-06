import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:koto_tinder/domain/entities/cat.dart';
import 'package:koto_tinder/domain/usecases/get_random_cat.dart';
import 'package:koto_tinder/domain/usecases/like_cat.dart';
import 'package:koto_tinder/domain/usecases/get_liked_cats.dart';
import 'package:koto_tinder/presentation/blocs/home/home_bloc.dart';

import 'home_bloc_test.mocks.dart';

@GenerateMocks([GetRandomCatUseCase, LikeCatUseCase, GetLikedCatsUseCase])
void main() {
  group('HomeBloc', () {
    late HomeBloc homeBloc;
    late MockGetRandomCatUseCase mockGetRandomCatUseCase;
    late MockLikeCatUseCase mockLikeCatUseCase;
    late MockGetLikedCatsUseCase mockGetLikedCatsUseCase;

    // Тестовые данные
    final testCat = Cat(
      id: 'test_id',
      url: 'https://example.com/cat.jpg',
      breeds: [
        Breed(
          id: 'breed_id',
          name: 'Test Breed',
          description: 'Test description',
          temperament: 'Friendly',
          origin: 'Test Country',
          lifeSpan: '12-15',
          wikipediaUrl: 'https://wikipedia.org/test',
        ),
      ],
    );

    final testLikedCats = [testCat];

    setUp(() {
      mockGetRandomCatUseCase = MockGetRandomCatUseCase();
      mockLikeCatUseCase = MockLikeCatUseCase();
      mockGetLikedCatsUseCase = MockGetLikedCatsUseCase();

      // Настройка моков по умолчанию
      when(mockGetLikedCatsUseCase.execute()).thenAnswer((_) async => []);
      when(mockLikeCatUseCase.execute(any)).thenAnswer((_) async => {});
    });

    tearDown(() {
      if (homeBloc.isClosed == false) {
        homeBloc.close();
      }
    });

    test('initial state is HomeLoadingState', () {
      homeBloc = HomeBloc(
        getRandomCatUseCase: mockGetRandomCatUseCase,
        likeCatUseCase: mockLikeCatUseCase,
        getLikedCatsUseCase: mockGetLikedCatsUseCase,
      );

      expect(homeBloc.state, isA<HomeLoadingState>());
    });

    group('LoadRandomCatEvent', () {
      blocTest<HomeBloc, HomeState>(
        'emits [HomeLoadingState, HomeLoadedState] when loading cat succeeds',
        setUp: () {
          when(
            mockGetRandomCatUseCase.execute(),
          ).thenAnswer((_) async => testCat);
          when(
            mockGetLikedCatsUseCase.execute(),
          ).thenAnswer((_) async => testLikedCats);
        },
        build:
            () => HomeBloc(
              getRandomCatUseCase: mockGetRandomCatUseCase,
              likeCatUseCase: mockLikeCatUseCase,
              getLikedCatsUseCase: mockGetLikedCatsUseCase,
            ),
        act: (bloc) => bloc.add(LoadRandomCatEvent()),
        expect:
            () => [
              isA<HomeLoadingState>(),
              isA<HomeLoadedState>()
                  .having((state) => state.cat, 'cat', testCat)
                  .having((state) => state.likeCount, 'likeCount', 1),
            ],
        verify: (_) {
          verify(mockGetRandomCatUseCase.execute()).called(1);
          verify(mockGetLikedCatsUseCase.execute()).called(1);
        },
      );

      blocTest<HomeBloc, HomeState>(
        'emits [HomeLoadingState, HomeErrorState] when loading cat fails',
        setUp: () {
          when(
            mockGetRandomCatUseCase.execute(),
          ).thenThrow(Exception('Network error'));
          when(mockGetLikedCatsUseCase.execute()).thenAnswer((_) async => []);
        },
        build:
            () => HomeBloc(
              getRandomCatUseCase: mockGetRandomCatUseCase,
              likeCatUseCase: mockLikeCatUseCase,
              getLikedCatsUseCase: mockGetLikedCatsUseCase,
            ),
        act: (bloc) => bloc.add(LoadRandomCatEvent()),
        expect:
            () => [
              isA<HomeLoadingState>(),
              isA<HomeErrorState>().having(
                (state) => state.message,
                'message',
                contains('Exception'),
              ),
            ],
      );
    });

    group('LikeCatEvent', () {
      blocTest<HomeBloc, HomeState>(
        'successfully likes cat and loads new cat',
        setUp: () {
          when(mockLikeCatUseCase.execute(any)).thenAnswer((_) async => {});
          when(
            mockGetRandomCatUseCase.execute(),
          ).thenAnswer((_) async => testCat);
          when(
            mockGetLikedCatsUseCase.execute(),
          ).thenAnswer((_) async => testLikedCats);
        },
        build:
            () => HomeBloc(
              getRandomCatUseCase: mockGetRandomCatUseCase,
              likeCatUseCase: mockLikeCatUseCase,
              getLikedCatsUseCase: mockGetLikedCatsUseCase,
            ),
        seed: () => HomeLoadedState(cat: testCat, likeCount: 0),
        act: (bloc) => bloc.add(LikeCatEvent(testCat)),
        expect:
            () => [
              isA<HomeLoadingState>(),
              isA<HomeLoadedState>().having(
                (state) => state.likeCount,
                'likeCount',
                1,
              ),
            ],
        verify: (_) {
          verify(mockLikeCatUseCase.execute(testCat)).called(1);
          verify(mockGetRandomCatUseCase.execute()).called(1);
          verify(mockGetLikedCatsUseCase.execute()).called(1);
        },
      );

      blocTest<HomeBloc, HomeState>(
        'emits error state when liking cat fails',
        setUp: () {
          when(
            mockLikeCatUseCase.execute(any),
          ).thenThrow(Exception('Database error'));
          when(mockGetLikedCatsUseCase.execute()).thenAnswer((_) async => []);
        },
        build:
            () => HomeBloc(
              getRandomCatUseCase: mockGetRandomCatUseCase,
              likeCatUseCase: mockLikeCatUseCase,
              getLikedCatsUseCase: mockGetLikedCatsUseCase,
            ),
        seed: () => HomeLoadedState(cat: testCat, likeCount: 0),
        act: (bloc) => bloc.add(LikeCatEvent(testCat)),
        expect:
            () => [
              isA<HomeErrorState>().having(
                (state) => state.message,
                'message',
                contains('Exception'),
              ),
            ],
      );
    });

    group('DislikeCatEvent', () {
      blocTest<HomeBloc, HomeState>(
        'loads new cat when disliking',
        setUp: () {
          when(
            mockGetRandomCatUseCase.execute(),
          ).thenAnswer((_) async => testCat);
          when(
            mockGetLikedCatsUseCase.execute(),
          ).thenAnswer((_) async => testLikedCats);
        },
        build:
            () => HomeBloc(
              getRandomCatUseCase: mockGetRandomCatUseCase,
              likeCatUseCase: mockLikeCatUseCase,
              getLikedCatsUseCase: mockGetLikedCatsUseCase,
            ),
        seed: () => HomeLoadedState(cat: testCat, likeCount: 1),
        act: (bloc) => bloc.add(DislikeCatEvent()),
        expect:
            () => [
              isA<HomeLoadingState>(),
              isA<HomeLoadedState>().having(
                (state) => state.likeCount,
                'likeCount',
                1,
              ),
            ],
        verify: (_) {
          verify(mockGetRandomCatUseCase.execute()).called(1);
          verify(mockGetLikedCatsUseCase.execute()).called(1);
          // Verify that like use case is NOT called for dislike
          verifyNever(mockLikeCatUseCase.execute(any));
        },
      );
    });

    group('RetryEvent', () {
      blocTest<HomeBloc, HomeState>(
        'loads new cat when retrying',
        setUp: () {
          when(
            mockGetRandomCatUseCase.execute(),
          ).thenAnswer((_) async => testCat);
          when(
            mockGetLikedCatsUseCase.execute(),
          ).thenAnswer((_) async => testLikedCats);
        },
        build:
            () => HomeBloc(
              getRandomCatUseCase: mockGetRandomCatUseCase,
              likeCatUseCase: mockLikeCatUseCase,
              getLikedCatsUseCase: mockGetLikedCatsUseCase,
            ),
        seed: () => HomeErrorState('Some error'),
        act: (bloc) => bloc.add(RetryEvent()),
        expect:
            () => [
              isA<HomeLoadingState>(),
              isA<HomeLoadedState>()
                  .having((state) => state.cat, 'cat', testCat)
                  .having((state) => state.likeCount, 'likeCount', 1),
            ],
      );
    });
  });
}
