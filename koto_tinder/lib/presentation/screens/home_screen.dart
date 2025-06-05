import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:koto_tinder/data/datasources/connectivity_service.dart';
import 'package:koto_tinder/data/datasources/preferences_datasource.dart';
import 'package:koto_tinder/di/service_locator.dart';
import 'package:koto_tinder/domain/entities/cat.dart';
import 'package:koto_tinder/domain/usecases/get_random_cat.dart';
import 'package:koto_tinder/domain/usecases/like_cat.dart';
import 'package:koto_tinder/presentation/blocs/home/home_bloc.dart';
import 'package:koto_tinder/presentation/screens/detail_screen.dart';
import 'package:koto_tinder/presentation/screens/liked_cats_screen.dart';
import 'package:koto_tinder/presentation/widgets/error_dialog.dart';
import 'package:koto_tinder/presentation/widgets/like_dislike_button.dart';
import 'package:koto_tinder/utils/image_utils.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  // Для анимации свайпа
  double _dragPosition = 0;
  AnimationController? _animationController;
  Animation<double>? _animation;

  // Визуальный эффект для лайка/дизлайка
  bool _showLikeOverlay = false;
  bool _showDislikeOverlay = false;

  // Создаем блок
  late HomeBloc _homeBloc;

  @override
  void initState() {
    super.initState();

    // Получаем зависимости через DI
    _homeBloc = HomeBloc(
      getRandomCatUseCase: serviceLocator<GetRandomCatUseCase>(),
      likeCatUseCase: serviceLocator<LikeCatUseCase>(),
      preferencesDatasource: serviceLocator<PreferencesDatasource>(),
    );

    // Простой мониторинг сети
    final connectivityService = serviceLocator<ConnectivityService>();
    connectivityService.connectivityStream.listen((isConnected) {
      if (mounted) {
        if (!isConnected) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.wifi_off, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Работаем в оффлайн-режиме'),
                ],
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          // Показываем уведомление о восстановлении соединения
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.wifi, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Интернет восстановлен'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    });

    // Инициализируем контроллер анимации
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Загружаем первого котика при создании экрана
    _homeBloc.add(LoadRandomCatEvent());
  }

  @override
  void dispose() {
    _animationController?.dispose();
    _homeBloc.close();
    super.dispose();
  }

  // Обрабатываем лайк с анимацией
  void _handleLike(Cat cat) {
    setState(() {
      _showLikeOverlay = true;
    });
    // Анимируем свайп вправо и увеличиваем счетчик лайков
    _animateSwipe(true, cat);
  }

  // Обрабатываем дизлайк с анимацией
  void _handleDislike() {
    setState(() {
      _showDislikeOverlay = true;
    });
    // Анимируем свайп влево
    _animateSwipe(false, null);
  }

  // Анимация свайпа
  void _animateSwipe(bool isLike, Cat? cat) {
    // Направление свайпа
    final double endPosition =
    isLike
        ? MediaQuery.of(context).size.width
        : -MediaQuery.of(context).size.width;

    // Настраиваем анимацию
    _animation = Tween<double>(begin: _dragPosition, end: endPosition).animate(
      CurvedAnimation(parent: _animationController!, curve: Curves.easeOut),
    );

    // Слушаем изменения анимации
    _animation?.addListener(() {
      setState(() {
        _dragPosition = _animation!.value;
      });
    });

    // По завершению анимации загружаем нового котика
    _animationController?.reset();
    _animationController?.forward().then((_) {
      if (isLike && cat != null) {
        _homeBloc.add(LikeCatEvent(cat));
      } else {
        _homeBloc.add(DislikeCatEvent());
      }
      setState(() {
        _dragPosition = 0;
        _showLikeOverlay = false;
        _showDislikeOverlay = false;
      });
    });
  }

  // Обработка начала перетаскивания
  void _onDragStart(DragStartDetails details) {
    _animationController?.stop();
  }

  // Обработка обновления перетаскивания
  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragPosition += details.delta.dx;

      // Показываем соответствующий оверлей в зависимости от направления свайпа
      if (_dragPosition > 50) {
        _showLikeOverlay = true;
        _showDislikeOverlay = false;
      } else if (_dragPosition < -50) {
        _showLikeOverlay = false;
        _showDislikeOverlay = true;
      } else {
        _showLikeOverlay = false;
        _showDislikeOverlay = false;
      }
    });
  }

  // Обработка завершения перетаскивания
  void _onDragEnd(DragEndDetails details, Cat cat) {
    // Определяем скорость свайпа
    final double velocity = details.velocity.pixelsPerSecond.dx;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double threshold =
        screenWidth * 0.4; // 40% ширины экрана для срабатывания свайпа

    // Если свайп достаточно сильный или карточка перетащена далеко
    if (velocity.abs() > 1000 || _dragPosition.abs() > threshold) {
      // Если свайп вправо
      if (_dragPosition > 0 || velocity > 1000) {
        _handleLike(cat);
      } else {
        // Если свайп влево
        _handleDislike();
      }
    } else {
      // Возвращаем карточку на место
      _animation = Tween<double>(begin: _dragPosition, end: 0.0).animate(
        CurvedAnimation(parent: _animationController!, curve: Curves.easeOut),
      );

      _animation?.addListener(() {
        setState(() {
          _dragPosition = _animation!.value;
        });
      });

      setState(() {
        _showLikeOverlay = false;
        _showDislikeOverlay = false;
      });

      _animationController?.reset();
      _animationController?.forward();
    }
  }

  // Открываем экран с детальной информацией
  void _openDetailScreen(Cat cat) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DetailScreen(cat: cat)),
    );
  }

  // Открываем экран с лайкнутыми котиками
  void _openLikedCatsScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LikedCatsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => _homeBloc,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('КотоТиндер'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          actions: [
            IconButton(
              icon: const Icon(Icons.favorite),
              onPressed: _openLikedCatsScreen,
              tooltip: 'Понравившиеся котики',
            ),
          ],
        ),
        body: BlocConsumer<HomeBloc, HomeState>(
          listener: (context, state) {
            if (state is HomeErrorState) {
              showErrorDialog(
                context,
                state.message,
                    () => _homeBloc.add(
                  RetryEvent(),
                ), // Используем RetryEvent вместо LoadRandomCatEvent
              );
            }
          },
          builder: (context, state) {
            if (state is HomeLoadingState) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is HomeLoadedState) {
              return Column(
                children: [
                  // Счетчик лайков
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                    child: Text(
                      'Понравившиеся котики: ${state.likeCount}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // Основной контент: карточка и кнопки
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Карточка с котиком
                          Expanded(
                            flex:
                            8, // Отдаем большую часть пространства под карточку
                            child: Center(
                              child: GestureDetector(
                                onHorizontalDragStart: _onDragStart,
                                onHorizontalDragUpdate: _onDragUpdate,
                                onHorizontalDragEnd:
                                    (details) => _onDragEnd(details, state.cat),
                                onTap: () => _openDetailScreen(state.cat),
                                child: Transform.translate(
                                  offset: Offset(_dragPosition, 0),
                                  child: Transform.rotate(
                                    angle:
                                    _dragPosition /
                                        800, // Небольшой поворот для эффекта
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        // Карточка котика
                                        Card(
                                          elevation: 6,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              15,
                                            ),
                                          ),
                                          child: Stack(
                                            children: [
                                              // Изображение котика с использованием кеширования
                                              ClipRRect(
                                                borderRadius:
                                                BorderRadius.circular(15),
                                                child: AspectRatio(
                                                  aspectRatio:
                                                  1.0, // Квадратное соотношение
                                                  child: CachedNetworkImage(
                                                    imageUrl: getOptimizedImageUrl(state.cat.url),
                                                    fit: BoxFit.cover,
                                                    memCacheWidth: 400,
                                                    memCacheHeight: 400,
                                                    placeholder: (context, url) => Container(
                                                      color: Colors.grey[200],
                                                      child: const Center(
                                                        child: CircularProgressIndicator(),
                                                      ),
                                                    ),
                                                    errorWidget: (context, url, error) => Container(
                                                      color: Colors.grey[200],
                                                      child: Column(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: [
                                                          Icon(
                                                            Icons.wifi_off,
                                                            size: 50,
                                                            color: Colors.grey[600],
                                                          ),
                                                          const SizedBox(height: 8),
                                                          Text(
                                                            'Фото недоступно\nбез интернета',
                                                            textAlign: TextAlign.center,
                                                            style: TextStyle(
                                                              color: Colors.grey[600],
                                                              fontSize: 14,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),

                                              // Название породы на полупрозрачном фоне внизу
                                              Positioned(
                                                bottom: 0,
                                                left: 0,
                                                right: 0,
                                                child: Container(
                                                  padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16.0,
                                                    vertical: 12.0,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                    const BorderRadius.vertical(
                                                      bottom:
                                                      Radius.circular(
                                                        15,
                                                      ),
                                                    ),
                                                    gradient: LinearGradient(
                                                      begin:
                                                      Alignment
                                                          .bottomCenter,
                                                      end: Alignment.topCenter,
                                                      colors: [
                                                        Colors.black.withAlpha(
                                                          179,
                                                        ),
                                                        Colors.transparent,
                                                      ],
                                                    ),
                                                  ),
                                                  child: Text(
                                                    state.cat.breeds != null &&
                                                        state
                                                            .cat
                                                            .breeds!
                                                            .isNotEmpty
                                                        ? state
                                                        .cat
                                                        .breeds![0]
                                                        .name
                                                        : 'Неизвестная порода',
                                                    style: const TextStyle(
                                                      fontSize: 22,
                                                      fontWeight:
                                                      FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                              ),

                                              // Оверлей для лайка
                                              if (_showLikeOverlay)
                                                Positioned.fill(
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                      BorderRadius.circular(
                                                        15,
                                                      ),
                                                      color: Colors.green
                                                          .withAlpha(77),
                                                    ),
                                                    child: const Center(
                                                      child: Icon(
                                                        Icons.favorite,
                                                        color: Colors.white,
                                                        size: 80,
                                                      ),
                                                    ),
                                                  ),
                                                ),

                                              // Оверлей для дизлайка
                                              if (_showDislikeOverlay)
                                                Positioned.fill(
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                      BorderRadius.circular(
                                                        15,
                                                      ),
                                                      color: Colors.red
                                                          .withAlpha(77),
                                                    ),
                                                    child: const Center(
                                                      child: Icon(
                                                        Icons.close,
                                                        color: Colors.white,
                                                        size: 80,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Кнопки лайк/дизлайк сразу под карточкой
                          Expanded(
                            flex: 2, // Меньшая часть для кнопок
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                LikeDislikeButton(
                                  icon: Icons.close,
                                  color: Colors.red,
                                  onPressed: _handleDislike,
                                ),
                                LikeDislikeButton(
                                  icon: Icons.favorite,
                                  color: Colors.green,
                                  onPressed: () => _handleLike(state.cat),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            } else {
              return Center(
                child: TextButton(
                  onPressed: () => _homeBloc.add(LoadRandomCatEvent()),
                  child: const Text('Загрузить котика'),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
