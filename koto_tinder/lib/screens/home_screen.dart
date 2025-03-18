import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:koto_tinder/models/cat.dart';
import 'package:koto_tinder/services/cat_api_service.dart';
import 'package:koto_tinder/screens/detail_screen.dart';
import 'package:koto_tinder/widgets/like_dislike_button.dart';
import 'package:koto_tinder/utils/image_utils.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  // Сервис для API запросов
  final CatApiService _catApiService = CatApiService();

  // Текущий котик для отображения
  Cat? _currentCat;

  // Индикатор загрузки
  bool _isLoading = true;

  // Счетчик лайков
  int _likeCount = 0;

  // Для анимации свайпа
  double _dragPosition = 0;
  AnimationController? _animationController;
  Animation<double>? _animation;

  // Визуальный эффект для лайка/дизлайка
  bool _showLikeOverlay = false;
  bool _showDislikeOverlay = false;

  @override
  void initState() {
    super.initState();

    // Инициализируем контроллер анимации
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Загружаем первого котика при создании экрана
    _loadRandomCat();
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  // Метод для загрузки случайного котика
  Future<void> _loadRandomCat() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final cat = await _catApiService.getRandomCat();
      setState(() {
        _currentCat = cat;
        _isLoading = false;
        _dragPosition = 0;
        _showLikeOverlay = false;
        _showDislikeOverlay = false;
      });
    } catch (e) {
      // Обрабатываем ошибку без создания неиспользуемой переменной
      setState(() {
        _isLoading = false;
      });

      // Показываем ошибку и предлагаем повторить
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки: $e'),
            action: SnackBarAction(
              label: 'Повторить',
              onPressed: _loadRandomCat,
            ),
          ),
        );
      }
    }
  }

  // Обрабатываем лайк с анимацией
  void _handleLike() {
    setState(() {
      _showLikeOverlay = true;
    });
    // Анимируем свайп вправо и увеличиваем счетчик лайков
    _animateSwipe(true);
  }

  // Обрабатываем дизлайк с анимацией
  void _handleDislike() {
    setState(() {
      _showDislikeOverlay = true;
    });
    // Анимируем свайп влево
    _animateSwipe(false);
  }

  // Анимация свайпа
  void _animateSwipe(bool isLike) {
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
      if (isLike) {
        setState(() {
          _likeCount++;
        });
      }
      _loadRandomCat();
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
  void _onDragEnd(DragEndDetails details) {
    // Определяем скорость свайпа
    final double velocity = details.velocity.pixelsPerSecond.dx;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double threshold =
        screenWidth * 0.4; // 40% ширины экрана для срабатывания свайпа

    // Если свайп достаточно сильный или карточка перетащена далеко
    if (velocity.abs() > 1000 || _dragPosition.abs() > threshold) {
      // Если свайп вправо
      if (_dragPosition > 0 || velocity > 1000) {
        _handleLike();
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
  void _openDetailScreen() {
    if (_currentCat != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetailScreen(cat: _currentCat!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('КотоТиндер'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _currentCat == null
              ? const Center(child: Text('Не удалось загрузить котика'))
              : Column(
                children: [
                  // Счетчик лайков
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                    child: Text(
                      'Понравившиеся котики: $_likeCount',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // Основной контент: карточка и кнопки в более компактном размещении
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
                                onHorizontalDragEnd: _onDragEnd,
                                onTap: _openDetailScreen,
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
                                                    imageUrl:
                                                        getOptimizedImageUrl(
                                                          _currentCat!.url,
                                                        ),
                                                    fit:
                                                        BoxFit
                                                            .cover, // Обрезать для соответствия квадрату
                                                    placeholder:
                                                        (
                                                          context,
                                                          url,
                                                        ) => Container(
                                                          color:
                                                              Colors.grey[200],
                                                          child: const Center(
                                                            child: Column(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .center,
                                                              children: [
                                                                CircularProgressIndicator(),
                                                                SizedBox(
                                                                  height: 10,
                                                                ),
                                                                Text(
                                                                  'Загрузка котика...',
                                                                  style: TextStyle(
                                                                    color:
                                                                        Colors
                                                                            .grey,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                    errorWidget: (
                                                      context,
                                                      url,
                                                      error,
                                                    ) {
                                                      // Обрабатываем ошибку без создания неиспользуемой переменной
                                                      return const Center(
                                                        child: Column(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            Icon(
                                                              Icons.error,
                                                              size: 50,
                                                              color: Colors.red,
                                                            ),
                                                            SizedBox(
                                                              height: 10,
                                                            ),
                                                            Text(
                                                              'Ошибка загрузки изображения',
                                                              style: TextStyle(
                                                                color:
                                                                    Colors.red,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                    },
                                                    // Настройки кеширования
                                                    memCacheWidth: 800,
                                                    maxHeightDiskCache: 800,
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
                                                    _currentCat!.breeds !=
                                                                null &&
                                                            _currentCat!
                                                                .breeds!
                                                                .isNotEmpty
                                                        ? _currentCat!
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
                                  onPressed: _handleLike,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
    );
  }
}
