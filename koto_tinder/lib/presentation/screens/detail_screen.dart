import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:koto_tinder/domain/entities/cat.dart';
import 'package:koto_tinder/utils/image_utils.dart';
import 'package:url_launcher/url_launcher.dart';

class DetailScreen extends StatelessWidget {
  final Cat cat;

  const DetailScreen({super.key, required this.cat});

  @override
  Widget build(BuildContext context) {
    // Получаем первую породу (если они есть)
    final breed =
        cat.breeds != null && cat.breeds!.isNotEmpty ? cat.breeds![0] : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(breed?.name ?? 'Детальная информация'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Изображение котика с сохранением оригинальных пропорций и отступами
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Center(
                child: Hero(
                  tag: cat.id,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width - 32,
                      maxHeight: MediaQuery.of(context).size.width * 0.7,
                    ),
                    child: CachedNetworkImage(
                      imageUrl: getOptimizedImageUrl(cat.url),
                      fit: BoxFit.contain, // Сохраняем оригинальные пропорции
                      placeholder:
                          (context, url) => Container(
                            width: MediaQuery.of(context).size.width - 32,
                            height: MediaQuery.of(context).size.width * 0.5,
                            color: Colors.grey[200],
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                      errorWidget:
                          (context, url, error) => SizedBox(
                            width: MediaQuery.of(context).size.width - 32,
                            height: MediaQuery.of(context).size.width * 0.5,
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.error,
                                    size: 50,
                                    color: Colors.red,
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    'Ошибка загрузки изображения',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                          ),
                    ),
                  ),
                ),
              ),
            ),

            // Информация о породе
            if (breed != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        breed.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    _buildInfoRow(
                      'Описание:',
                      breed.description ?? 'Нет данных',
                    ),
                    _buildInfoRow(
                      'Темперамент:',
                      breed.temperament ?? 'Нет данных',
                    ),
                    _buildInfoRow(
                      'Происхождение:',
                      breed.origin ?? 'Нет данных',
                    ),
                    _buildInfoRow(
                      'Продолжительность жизни:',
                      breed.lifeSpan ?? 'Нет данных',
                    ),

                    // Отображаем дату лайка, если она есть
                    if (cat.likedAt != null)
                      _buildInfoRow(
                        'Дата лайка:',
                        '${cat.likedAt!.day}.${cat.likedAt!.month}.${cat.likedAt!.year} ${cat.likedAt!.hour}:${cat.likedAt!.minute.toString().padLeft(2, '0')}',
                      ),

                    if (breed.wikipediaUrl != null) ...[
                      const SizedBox(height: 16),
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            _launchWikipedia(context, breed.wikipediaUrl!);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).primaryColor.withAlpha(26),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.all(8),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.info_outline, color: Colors.blue),
                                SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    'Подробная информация в Wikipedia',
                                    style: TextStyle(
                                      color: Colors.blue,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  child: Text(
                    'Информация о породе недоступна',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Открытие Wikipedia в браузере
  void _launchWikipedia(BuildContext context, String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось открыть ссылку')),
        );
      }
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
